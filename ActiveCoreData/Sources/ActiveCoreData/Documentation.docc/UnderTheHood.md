# Under the hood

What Core Data is doing behind these helpers, and the places where knowing it changes what you
write.

## Overview

Nothing here is required reading. Every article before this one is enough to ship an app. This is
for the point where the profiler says something you did not expect, or a crash report arrives that
you cannot reproduce.

## Faulting, batching and the row cache

A fetch does not hand you objects with their data already loaded, and it does not hand you empty
shells either. It hands you **faults** — real instances whose attribute storage is filled in on
first access — while the values themselves sit in the persistent store's **row cache**, keyed by
object ID. Firing an attribute fault is a lookup in that cache, not a trip to SQLite.

That is why `Book.matching(nil, context: context)` over a thousand rows is one query, and why
reading `book.title` afterwards costs nothing.

Relationships are where it changes. A relationship fault has no cached row to fire against, so
touching one issues a fetch:

```swift
// One query for the books. Then one more for every distinct author.
for book in Book.matching(nil, context: context) {
    print(book.author?.name ?? "")
}
```

The helpers here build a plain `NSFetchRequest`, so when you need to fix this, build the request
yourself:

```swift
let request: NSFetchRequest<Book> = Book.fetchRequest()
request.relationshipKeyPathsForPrefetching = ["author"]
request.fetchBatchSize = 50

let books = (try? context.fetch(request)) ?? []
```

`relationshipKeyPathsForPrefetching` collapses the N+1 into two queries. `fetchBatchSize` changes
the return value into a proxy array that materialises objects in batches as you walk it, which is
what you want behind a table view over ten thousand rows and pointless for a list of twenty.

> Tip: `ManagedObjectCountable/countFor(_:context:)` never participates in any of this. It compiles
> to `SELECT COUNT(*)`, materialises nothing, and adds nothing to the row cache. Reaching for
> `matching(...).count` instead builds every object just to ask how many there were.

> Note: The row cache belongs to the persistent store, so every context on the same coordinator
> shares it. What each context keeps privately is its set of registered objects and its change
> tracking — so the cost of an extra context is a second copy of the *object graph*, not a second
> copy of the *data*. This is why one long-lived writer is cheaper than a context per operation, and
> why the saving is smaller than people assume.

## Objects belong to a queue, and their context does not retain them back

`NSManagedObject` is not `Sendable`, and no amount of `@unchecked` will make it so. An object is
usable only from the queue of the context that owns it. Cross that line and you get corruption that
surfaces later, somewhere else.

`NSManagedObjectID` is the exception: it is immutable, thread-safe, and the intended way to refer to
a row across contexts.

```swift
// Get an ID out...
let id: NSManagedObjectID? = await withCheckedContinuation { continuation in
    background.perform {
        continuation.resume(returning: Book.find(id: isbn, context: background)?.objectID)
    }
}

// ...and turn it back into an object on the other side.
if let id, let book = try? store.viewContext.existingObject(with: id) as? Book {
    // ...
}
```

> Important: `object(with:)` and `existingObject(with:)` are not interchangeable. `object(with:)`
> always returns something — a fault that traps when you fire it if the row has since been deleted.
> `existingObject(with:)` hits the store and throws instead. Prefer the throwing one whenever the
> ID has been sitting around, which is nearly always the case if it travelled between contexts.

> Warning: The ID of a newly inserted object is **temporary** until its context is saved, and a
> temporary ID means nothing to any other context. Save before you hand one over, or call
> `try context.obtainPermanentIDs(for: [object])` to allocate the permanent ID early. This is the
> usual explanation for "the object I just created cannot be found on the main thread".

> Warning: Never ask an object which context it belongs to.
> `NSManagedObject.managedObjectContext` is declared `unowned(unsafe)` — it does not retain the
> context, and it is not nilled out when the context is deallocated. Reading it afterwards
> dereferences freed memory. An app whose contexts live forever will never see this; an app that
> makes a scratch context per import or per editing sheet will see it as a crash rate that grows
> with usage and never reproduces on a developer's machine. Thread the context through explicitly —
> which is why every helper in this library takes one as an argument.

> Tip: Add `-com.apple.CoreData.ConcurrencyDebug 1` to your scheme's launch arguments today. Core
> Data will trap the instant an object or context is touched from the wrong queue, turning a
> once-a-month field crash into an immediate, precisely located stack trace. Nothing else in the
> Core Data toolbox pays for itself this quickly.

## Predicates, indexes and what SQLite can actually use

Core Data translates as much of your predicate as it can into SQL and evaluates the remainder in
memory after fetching. Which side of that line you land on decides whether a query is an index seek
or a full scan.

Reliably pushed down: comparisons against attributes, `AND`/`OR`/`NOT`, `IN`, `BETWEEN`,
`BEGINSWITH`, and traversals across to-one relationships. Never pushed down: anything referring to a
transient property or a computed Swift property, because SQLite has no column for it.

> Warning: `NSPredicate(block:)` cannot be used with a SQLite store at all — Core Data raises rather
> than silently fetching everything. If you need arbitrary Swift logic, fetch with the narrowest
> predicate you can express and filter the result in Swift.

On indexes:

- Tick **Indexed** on any attribute you pass to ``ManagedObjectFind/find(column:value:context:)`` or
  ``ManagedObjectFindOrCreate/findOrCreate(columns:values:context:)``. An upsert loop over a
  thousand rows without one is a thousand table scans.
- `BEGINSWITH` can use an index, because the match is anchored to the start of the value.
  `CONTAINS` and `ENDSWITH` cannot: there is no way to seek to an unanchored substring, so every
  row is examined.
- A compound index over `(a, b)` also serves a query on `a` alone, but not one on `b` alone —
  matching works left to right. Order the columns accordingly.
- A sort descriptor over an indexed attribute lets the store satisfy `ORDER BY` from the index and
  stop as soon as `fetchLimit` is reached. Sorting on an unindexed attribute means reading and
  sorting the whole result first, and then throwing most of it away.

> Tip: `[cd]` is the most expensive thing most apps put in a predicate. Case- and
> diacritic-insensitive comparison cannot use an ordinary index, so a search field that fires
> `CONTAINS[cd]` on every keystroke scans the table each time. The fix is to do the normalising once
> at write time: store a `searchTitle` attribute holding
> `title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)`, index it,
> and query it with a plain `BEGINSWITH`.

> Note: `IN %@` becomes an SQL `IN (?, ?, …)` with one bound variable per element, and SQLite caps
> how many a statement may have. A few hundred is fine; an unbounded list built from a server
> response is a crash waiting for a big enough response. Chunk it.

## Batch operations go around the context

`NSBatchDeleteRequest`, `NSBatchUpdateRequest` and `NSBatchInsertRequest` execute inside the store,
in one statement, without loading anything. They are enormously faster than the per-object walk that
``ManagedObjectDeletable/destroyAll(matching:context:)`` performs — and they achieve it by skipping
everything the context does for you.

No delete rules run, so cascades do not happen and your object graph is left inconsistent. No
validation runs. No `isDeleted`. No change notifications, so every context in your app carries on
believing in rows that no longer exist.

Which means the merge step is not optional:

```swift
let request = NSBatchDeleteRequest(fetchRequest: Book.fetchRequest())
request.resultType = .resultTypeObjectIDs

let result = try context.execute(request) as? NSBatchDeleteResult
let ids = result?.result as? [NSManagedObjectID] ?? []

NSManagedObjectContext.mergeChanges(
    fromRemoteContextSave: [NSDeletedObjectsKey: ids],
    into: [store.viewContext, store.backgroundContext]
)
```

> Important: The rule of thumb — use ``ManagedObjectDeletable/destroyAll(matching:context:)`` when
> you want delete rules, an accurate count and a consistent object graph, which is nearly always.
> Reach for a batch request when the row count is large enough that the per-object walk is the
> bottleneck, and accept that you now own the merge.

## CloudKit changes what unique means

`NSPersistentCloudKitContainer` is a drop-in replacement for `NSPersistentContainer` as far as this
library is concerned. Every helper works against it unchanged. What changes is the guarantee
underneath ``ManagedObjectFindOrCreate/findOrCreate(id:context:)``.

CloudKit imposes rules on your model:

- Every attribute must be optional or carry a default value.
- Every relationship must be optional and must have an inverse.
- **Uniqueness constraints are not supported.**

That last one is the important one. A local-only store can enforce that `Book.id` is unique, and
combined with `mergeByPropertyObjectTrump` a duplicate insert is folded into the existing row rather
than becoming a second one. With CloudKit that safety net is gone: the constraint cannot exist, so
nothing stops two rows sharing a key.

And sync is eventually consistent, so it will happen. Two devices, both offline, both upsert
`"le-guin"`. Each finds nothing locally and inserts. When they reconnect, both rows arrive and both
are valid.

> Important: `findOrCreate` cannot protect you here, and neither can the store. Deduplication is an
> application-level job with CloudKit, and Apple's own sample code treats it that way. Observe
> `.NSPersistentStoreRemoteChange`, fetch the rows sharing a key, pick a winner by a rule every
> device computes identically — lowest UUID, earliest `createdAt`, never "the one I have" — move the
> losers' relationships across, and delete them.

> Tip: The cheapest defence is to stop generating collidable keys. If the `id` for a row is derived
> from its content or comes from a server, both devices create the *same* key and CloudKit's own
> record-level merge handles it. Duplicates only appear when each device invents a key of its own,
> which is exactly what `UUID().uuidString` at insertion time does.

> Note: Two more CloudKit limits worth designing around early. A `CKRecord` is capped at 1 MB, so
> tick **Allows External Storage** on binary attributes and let Core Data keep the bytes beside the
> database rather than inside the row. And there is no cross-record transaction: one local save
> becomes several record writes that land independently, so a reader on another device can
> legitimately observe half of your change.

## Why `enqueue` wraps `perform`

``CoreData/NSManagedObjectContext/enqueue(_:)`` is a `withCheckedContinuation` around
`perform`, rather than Core Data's own `async` overloads.

Plain `perform` guarantees that blocks handed to a context run in the order they were submitted.
`perform(schedule:)` relaxes that — `.immediate` may run the block synchronously on the calling
thread if it is already the right queue, and `.enqueued` reorders relative to `.immediate` work. For
an API whose whole job is "all writes go through here, one at a time, in order", the ordering
guarantee is the feature. The continuation is what it costs.

> Note: The block is deliberately not `async`. There is no suspension point inside it, so it runs
> to completion on the context's queue before the next one starts, and the unit of work you wrote
> is the unit of work Core Data sees. An `async` block would let unrelated work interleave between
> your fetch and your save, which is precisely the race
> ``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` depends on not happening.
