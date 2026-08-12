# Saving changes

Create, update, delete, and know whether it worked.

## Overview

Every write follows the same shape:

```swift
await store.backgroundContext.enqueue { context in
    // ...changes...
    context.flush()
}
```

``CoreData/NSManagedObjectContext/enqueue(_:)`` gets you onto the context's queue and suspends until
the block finishes. ``CoreData/NSManagedObjectContext/flush()`` saves. Once `enqueue` returns, the
save has landed and ``Container/viewContext`` has already merged it.

> Important: Writes go on ``Container/backgroundContext``. ``ManagedObjectFindOrCreate/findOrCreate(id:context:)``
> and ``ManagedObjectDeletable/destroyAll(matching:context:)`` assert in debug builds when handed a
> main-queue context.

## Creating and updating

``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` is an upsert: it returns the object with
that key, inserting one if there is not one already.

```swift
await store.backgroundContext.enqueue { context in
    let book = Book.findOrCreate(id: isbn, context: context)
    book.title = "The Dispossessed"
    book.pages = 341

    context.flush()
}
```

This is what makes importing painless. The same loop handles a first sync and the hundredth:

```swift
await store.backgroundContext.enqueue { context in
    for payload in response.books {
        let author = Author.findOrCreate(id: payload.authorID, context: context)
        author.name = payload.authorName

        let book = Book.findOrCreate(id: payload.isbn, context: context)
        book.title = payload.title
        book.pages = payload.pages
        book.author = author
    }

    context.flush()
}
```

One save at the end, not one per row. Core Data batches the whole thing into a single transaction,
and a thousand small saves are far more expensive than one large one.

Key on something other than `id` with the `column:` form, or on several attributes at once:

```swift
let author = Author.findOrCreate(column: "name", value: "Ursula K. Le Guin", context: context)

let edition = Edition.findOrCreate(
    columns: ["isbn", "printing"],
    values: [isbn, 2],
    context: context
)
```

### One writer, or duplicates

`findOrCreate` sees pending changes in the context it is given, so calling it twice before saving
returns the same object. It cannot see pending changes in a *different* context. Two contexts that
both upsert `"le-guin"` before either saves will produce two rows.

That is Core Data's behaviour, not this library's, and the fix is the one this library already
recommends: put every write through a single background context. A private-queue context serialises
the work handed to it, so your upserts cannot interleave.

> Tip: For belt and braces, add a uniqueness constraint on `id` in the model editor (select the
> entity, then **Constraints**). The store then rejects duplicates outright, and
> `mergeByPropertyObjectTrump` — which ``DataStore/backgroundContext`` sets for you — folds the
> loser into the winner rather than throwing. This does not work with CloudKit; see
> <doc:UnderTheHood#CloudKit-changes-what-unique-means>.

## Deleting

```swift
await store.backgroundContext.enqueue { context in
    let removed = Book.destroyAll(matching: NSPredicate("read = %@", true), context: context)
    context.flush()
}
```

``ManagedObjectDeletable/destroyAll(context:)`` clears the entity entirely. Both fetch the objects
and delete them one at a time, which is what makes your model's delete rules run — deleting an
`Author` whose `books` relationship cascades takes the books with it — and what makes the returned
count accurate.

For tens of thousands of rows, use `NSBatchDeleteRequest` instead. See
<doc:UnderTheHood#Batch-operations-go-around-the-context>.

## When a save fails

``CoreData/NSManagedObjectContext/flush()`` is deliberately quiet. It tries to save and, if that
fails, does nothing about it. Your changes are not lost — they are still pending in the context —
but they are not on disk either.

That is fine for a background import you will retry anyway. It is not fine for something the user
typed. When the outcome matters, use ``CoreData/NSManagedObjectContext/enqueueThrowing(_:)`` and
save yourself:

```swift
do {
    try await store.backgroundContext.enqueueThrowing { context in
        let book = Book.findOrCreate(id: isbn, context: context)
        book.title = title

        try context.save()
    }
} catch {
    // Show the user something.
    await store.backgroundContext.enqueue { $0.rollback() }
}
```

Saves fail for a small number of reasons, and validation is nearly all of them: a required attribute
left `nil`, a string longer than its maximum, a to-one relationship with a minimum count of one
still empty. The `NSError` carries `NSValidationKeyErrorKey` and the offending object, so log the
whole thing rather than `localizedDescription`.

> Note: A thrown error does not roll anything back. The failed changes stay pending in the context
> and the next save will fail the same way. Call `context.rollback()` in your `catch` if you want
> a clean slate — but remember it discards *everything* pending, including work from an unrelated
> block that has not saved yet. One more reason each `enqueue` block should be a complete unit of
> work that ends in a save.

## Undo

Core Data has an undo manager, and it is off by default on background contexts — which is what you
want, since recording undo for a large import costs memory for nothing. To offer undo for user
edits, set one on the context that makes them:

```swift
context.undoManager = UndoManager()
```

## Topics

### Protocols

- ``ManagedObjectFindOrCreate``
- ``ManagedObjectDeletable``
