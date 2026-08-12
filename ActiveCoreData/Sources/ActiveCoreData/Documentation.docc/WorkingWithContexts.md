# Working with contexts

Read on one context, write on the other, and never let an object cross between them.

## Overview

A managed object context is a scratchpad. You fetch objects into it, change them, and save. Objects
belong to the context that fetched them, and — this is the part that catches people — they belong to
that context's **queue** as well.

ActiveCoreData assumes two contexts, described by ``Container``:

- ``Container/viewContext`` runs on the main queue. Read from it. Bind it to SwiftUI.
- ``Container/backgroundContext`` runs on a private queue. Do all your writing here.

## Getting onto the queue

You may only touch a context, or any object it owns, from that context's own queue.
``CoreData/NSManagedObjectContext/enqueue(_:)`` is how you get there:

```swift
let context = store.backgroundContext

await context.enqueue { context in
    let book = Book.findOrCreate(id: isbn, context: context)
    book.title = title
    context.flush()
}
```

It wraps Core Data's `perform` in a continuation, so it reads like ordinary `async` code but keeps
Core Data's own scheduling guarantees. Blocks handed to one context run one at a time, in the order
they arrive.

Shadow the outer name with the block's parameter, as above. They are the same object, but shadowing
means you cannot accidentally reach for a different context from inside the block — the exact
mistake this API exists to prevent.

Use ``CoreData/NSManagedObjectContext/enqueueThrowing(_:)`` when you want failures back:

```swift
try await context.enqueueThrowing { context in
    try context.save()
}
```

> Note: Why a continuation around `perform` rather than Core Data's own `async` overloads? Because
> `perform(schedule:)` with `.enqueued` and `.immediate` do not preserve submission order the way
> plain `perform` does. `enqueue` sticks to the ordering guarantee, and pays a continuation for it.

## Never move an object between contexts

An `NSManagedObject` is bound to one context on one queue. Passing one out of an `enqueue` block, or
capturing one from outside, is a data race — and often a silent one, right up until it is a crash in
someone else's stack trace.

Pass an `NSManagedObjectID` instead. It is the only part of Core Data's object graph that is safe to
share:

```swift
let bookID: NSManagedObjectID? = await withCheckedContinuation { continuation in
    background.perform {
        continuation.resume(returning: Book.find(id: isbn, context: background)?.objectID)
    }
}

guard let bookID else { return }

await MainActor.run {
    let book = store.viewContext.object(with: bookID) as? Book
    // Safe: this one belongs to viewContext.
}
```

> Warning: An object ID for a newly inserted object is **temporary** until the context is saved.
> Hand one to another context before the save and the lookup fails. Save first, or call
> `try context.obtainPermanentIDs(for: [object])` to force permanent IDs early.

### Do not reach for `object.managedObjectContext`

It is tempting to ask an object which context it belongs to instead of threading one through. Don't.
`NSManagedObject.managedObjectContext` is declared `unowned(unsafe)` — it does not retain the
context, and Core Data does not nil it out when the context goes away. Read it after the context has
been deallocated and you are dereferencing freed memory.

You will not see this in a small app, where the context lives as long as the process. You will see
it in an app that creates scratch contexts for imports or editing sheets, as a crash rate that
climbs with usage and never reproduces on your desk.

The API here is built so you never need it: every helper takes a context explicitly, and
``CoreData/NSManagedObjectContext/enqueue(_:)`` hands one to your block. Thread the context through;
never ask an object for it.

## Why writes are kept off the view context

Three reasons, in order of how likely you are to be bitten:

1. **Frames.** A save is synchronous. On the main queue it blocks the frame you are drawing, and a
   save that touches a few thousand rows drops several.
2. **Merge policy.** ``DataStore/viewContext`` keeps Core Data's default `NSErrorMergePolicy`,
   because a read-only context should never have a conflict to resolve. Write on it and any conflict
   becomes a thrown save error — which ``CoreData/NSManagedObjectContext/flush()`` swallows.
   ``DataStore/backgroundContext`` is configured with `mergeByPropertyObjectTrump` precisely because
   it is the one expected to resolve conflicts.
3. **One writer means no interleaving.** ``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` is a
   fetch followed by an insert. Two contexts running that at once, both missing, both insert. A
   single private-queue writer serialises the work and the race cannot happen.

The helpers that write assert against a main-queue context in debug builds, so you find out
immediately. The assert is compiled out of release builds — it is a development aid, not a runtime
guard.

## How changes reach your UI

Both contexts set `automaticallyMergesChangesFromParent`, so a save on the writer is merged into
``Container/viewContext`` for you. `@FetchRequest` and `NSFetchedResultsController` see it and your
views redraw. There is nothing to observe and nothing to invalidate.

Objects already registered in ``Container/viewContext`` are updated in place, which means SwiftUI
sees property changes on the very same instances your views are holding.

> Tip: If a view is showing stale data after a save, the usual cause is a fetch that ran once and
> was never repeated — a helper call in a view model, rather than `@FetchRequest`. These helpers
> answer a question at a point in time; they do not subscribe to anything.

## Debugging concurrency

Add this launch argument to your scheme and Core Data will trap the instant an object or context is
touched from the wrong queue:

```
-com.apple.CoreData.ConcurrencyDebug 1
```

Turn it on now, not after the crash reports start. It converts a class of bug that reproduces once a
month in the field into an immediate, precisely-located trap. Nothing else in the Core Data toolbox
comes close to it for value.

Two more worth knowing:

```
-com.apple.CoreData.SQLDebug 1
-com.apple.CoreData.MigrationDebug 1
```

`SQLDebug` logs every statement Core Data runs, with timings. It is how you discover that one
harmless-looking loop is issuing four hundred queries.

## Topics

### Types

- ``Container``
- ``DataStore``
