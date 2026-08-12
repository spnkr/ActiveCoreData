# Adopting in an existing app

What each helper replaces, what it costs, and where it stops.

## Overview

If you already know Core Data, the useful question is not "what does this do" but "what is it doing
on my behalf, and what does it prevent me from doing". The answer to the second is: nothing. There is
no base class, no wrapper type, no separate stack. Your entities remain `NSManagedObject`s and every
Core Data API you already use keeps working.

Adoption is incremental. Conform one entity, use one helper, leave the rest alone.

## What you actually add

Two things:

```swift
// 1. Per entity.
extension Book: ManagedObjectExtended {}

// 2. Once, if you want the Container vocabulary.
extension PersistenceController: Container {
    var viewContext: NSManagedObjectContext { container.viewContext }
    var backgroundContext: NSManagedObjectContext { writeContext }
}
```

Step 2 is optional. Every helper takes an `NSManagedObjectContext` directly, so you can use the
whole library without ``Container`` or ``DataStore`` ever appearing in your code.

## The translation table

**Fetch one**

```swift
// Before
let request: NSFetchRequest<Book> = Book.fetchRequest()
request.predicate = NSPredicate(format: "id == %@", isbn)
request.fetchLimit = 1
let book = (try? context.fetch(request))?.first

// After
let book = Book.find(id: isbn, context: context)
```

**Fetch many, sorted**

```swift
// Before
let request: NSFetchRequest<Book> = Book.fetchRequest()
request.predicate = NSPredicate(format: "pages > %d", 300)
request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
let books = (try? context.fetch(request)) ?? []

// After
let books = Book.matching(
    "pages > %d", 300,
    context: context,
    sortBy: [NSSortDescriptor(key: "title", ascending: true)]
)
```

**Count**

```swift
// Before
let count = (try? context.count(for: request)) ?? 0

// After
let count = Book.countFor(NSPredicate("pages > %@", 300), context: context)
```

**Upsert**

```swift
// Before
let request: NSFetchRequest<Book> = Book.fetchRequest()
request.predicate = NSPredicate(format: "id == %@", isbn)
request.fetchLimit = 1
let book: Book
if let existing = (try? context.fetch(request))?.first {
    book = existing
} else {
    book = Book(context: context)
    book.id = isbn
}

// After
let book = Book.findOrCreate(id: isbn, context: context)
```

**Delete a set**

```swift
// Before
let request: NSFetchRequest<NSFetchRequestResult> = Book.fetchRequest()
request.predicate = NSPredicate(format: "read == YES")
for case let object as NSManagedObject in (try? context.fetch(request)) ?? [] {
    context.delete(object)
}

// After
let removed = Book.destroyAll(matching: NSPredicate("read = %@", true), context: context)
```

**Background work**

```swift
// Before
await withCheckedContinuation { continuation in
    context.perform {
        // ...
        continuation.resume()
    }
}

// After
await context.enqueue { context in
    // ...
}
```

## What it costs you

Worth knowing before you commit:

- **Read failures are swallowed.** `find`, `matching` and `countFor` return `nil`, `[]` and `0`
  rather than throwing. In practice a fetch against a loaded store fails for reasons you cannot
  recover from anyway, but if you have telemetry on fetch errors today, you will lose it.
- **`flush()` swallows save failures too.** Use ``CoreData/NSManagedObjectContext/enqueueThrowing(_:)``
  with `try context.save()` where the outcome matters. See <doc:SavingChanges#When-a-save-fails>.
- **No `fetchBatchSize`, `propertiesToFetch`, `relationshipKeyPathsForPrefetching` or
  `returnsObjectsAsFaults`.** These helpers build a plain `NSFetchRequest`. When you need to tune
  one, build it yourself — the two styles coexist fine in the same function.
- **`find` and `matching` do not deduplicate against pending deletes in other contexts**, same as a
  raw fetch.

## What it deliberately does not do

- **No fetched results controller.** Use `@FetchRequest` or `NSFetchedResultsController` for
  anything a view displays. These helpers answer a question once; they do not subscribe.
- **No batch requests.** `NSBatchDeleteRequest`, `NSBatchUpdateRequest` and
  `NSBatchInsertRequest` bypass the context by design, so wrapping them in an API that takes a
  context would be misleading. See <doc:UnderTheHood#Batch-operations-go-around-the-context>.
- **No migration or model versioning.** Unchanged, and still yours.
- **No async fetching.** `NSAsynchronousFetchRequest` and `fetch(_:) async` are untouched.

## Keeping your own stack

``DataStore`` is a convenience, not a requirement, and it has no configuration hooks — no
`NSPersistentStoreDescription` access, no store options, no CloudKit variant. If you need any of
that, keep your container and conform it to ``Container``. See <doc:SettingUpYourStore#Bringing-your-own-stack>.

One thing to check while you are there: your writing context's merge policy. The default is
`NSErrorMergePolicy`, and combined with ``CoreData/NSManagedObjectContext/flush()`` swallowing save
errors, a conflict becomes a silently dropped write. ``DataStore`` sets
`mergeByPropertyObjectTrump` on its writer for exactly this reason.

## Coexisting

You do not have to choose per file, or even per function:

```swift
await context.enqueue { context in
    // Helper for the lookup...
    let author = Author.findOrCreate(id: authorID, context: context)

    // ...and a hand-built request where it earns its keep.
    let request: NSFetchRequest<Book> = Book.fetchRequest()
    request.predicate = NSPredicate(format: "author == %@", author)
    request.fetchBatchSize = 50
    request.relationshipKeyPathsForPrefetching = ["author"]

    for book in (try? context.fetch(request)) ?? [] {
        book.authorName = author.name
    }

    context.flush()
}
```
