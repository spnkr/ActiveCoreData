# Setting up your store

Use the stack that comes with the library, or keep the one you have.

## Overview

ActiveCoreData needs a managed object context and nothing else. Every helper takes one as an
argument, so the library never has to know where your store came from. That leaves you two ways in:
use ``DataStore``, or conform your own type to ``Container``.

## The zero-config path

``DataStore/shared`` opens your model, loads the store, and hands you two contexts:

```swift
let store = DataStore.shared

let books = Book.matching(nil, context: store.viewContext)

await store.backgroundContext.enqueue { context in
    Book.findOrCreate(id: isbn, context: context).title = title
    context.flush()
}
```

There is nothing to initialise and nothing to inject. The store is created lazily on first use, at
the standard location for your app, from the model in your bundle.

### How your model is found

``DataStore`` needs the name of the model to open. It works that out in two steps:

1. The `persistentContainerName` key inside an `ActiveCoreData` dictionary in your `Info.plist`.
2. Failing that, the first compiled model (`.momd`) in the main bundle.

Step 2 covers the ordinary case — one `Bookshelf.xcdatamodeld`, one app target — so most apps never
touch their `Info.plist`. Set the key when your app ships more than one model, or when a dependency
brings its own and you cannot be sure which one gets found first:

```xml
<key>ActiveCoreData</key>
<dict>
    <key>persistentContainerName</key>
    <string>Bookshelf</string>
</dict>
```

The value is the model's name without any extension: `Bookshelf`, not `Bookshelf.xcdatamodeld` and
not `Bookshelf.momd`.

> Warning: ``DataStore/persistentContainerName`` traps with a diagnostic when neither step finds a
> name. That happens in targets with no model of their own — a unit test bundle, an app extension,
> a preview host. Those targets should not touch ``DataStore/shared``; build a ``Container`` and
> point it wherever that target should look.

### Isolation

``DataStore/shared`` is `@MainActor`. Read the property on the main actor, keep the context it gives
you, then hop to that context's queue:

```swift
@MainActor
func save(title: String) async {
    let context = DataStore.shared.backgroundContext

    await context.enqueue { context in
        // ...
    }
}
```

The context object itself is safe to hold and pass around. What is never safe is *using* a context,
or an object it owns, off its own queue.

## Bringing your own stack

``DataStore`` deliberately has no configuration. The moment you need to set anything on an
`NSPersistentStoreDescription`, keep your own container and conform it to ``Container``:

```swift
import ActiveCoreData
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private let writeContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Bookshelf")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error { fatalError("Unresolved error \(error)") }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        writeContext = container.newBackgroundContext()
        writeContext.automaticallyMergesChangesFromParent = true
        writeContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
}

extension PersistenceController: Container {
    var viewContext: NSManagedObjectContext { container.viewContext }
    var backgroundContext: NSManagedObjectContext { writeContext }
}
```

Nothing else changes. Every helper still takes a context, so your call sites are identical whichever
route you took.

You will want your own stack for App Groups, `NSPersistentHistoryTrackingKey`, store encryption, a
read-only store, staged migrations, or `NSPersistentCloudKitContainer`.

> Important: Set `mergePolicy` on your writer, as above. The default is `NSErrorMergePolicy`, which
> turns every optimistic-locking conflict into a thrown save error — and
> ``CoreData/NSManagedObjectContext/flush()`` swallows thrown save errors. The combination loses
> writes quietly. `mergeByPropertyObjectTrump` resolves conflicts property by property in favour of
> what is in memory, which is almost always what a single-writer app wants.

## CloudKit

`NSPersistentCloudKitContainer` is a drop-in replacement in the code above, and every helper works
against it unchanged:

```swift
container = NSPersistentCloudKitContainer(name: "Bookshelf")
```

Two constraints come with it, and both matter for how you use this library:

- **Every attribute must be optional or have a default value**, and **uniqueness constraints are not
  supported**. So the store cannot enforce that an `id` is unique, which is the assumption
  ``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` is built on.
- **Sync is eventually consistent.** Two devices can create the same key while offline, and both
  rows arrive when they reconnect.

See <doc:UnderTheHood#CloudKit-changes-what-unique-means> for what to do about it.

## Testing

Point a store at `/dev/null` and SQLite keeps the whole database in memory. It is faster than a
temporary file, needs no cleanup, and — unlike `NSInMemoryStoreType` — behaves like the real store,
because it *is* the real store:

```swift
let container = NSPersistentContainer(name: "Bookshelf")
let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
description.shouldAddStoreAsynchronously = false
container.persistentStoreDescriptions = [description]
container.loadPersistentStores { _, error in precondition(error == nil) }
```

Give each test its own container and they are fully isolated, so they can run in parallel. This is
how ActiveCoreData's own test suite works.

> Tip: `NSInMemoryStoreType` looks like the obvious choice and is the wrong one. It is a different
> store type with its own quirks: no real SQL, different predicate evaluation, no support for batch
> requests or persistent history. Tests that pass against it can still fail against the store you
> ship.

## Topics

### Types

- ``DataStore``
- ``Container``
