# ``ActiveCoreData``

A lightweight, Active Record–ish layer over Core Data. Find, create, count and delete your objects
in one line, and keep the stack you already have.

## Overview

Core Data is a good database and an awkward API. Reading one row takes a fetch request, an entity
description, a predicate and a `do`/`catch`; nine times out of ten what you wanted was:

```swift
let book = Book.find(id: isbn, context: context)
```

ActiveCoreData adds that line, and a handful like it, to any `NSManagedObject` subclass. It does it
with protocol extensions, so there is no base class to inherit from, no wrapper types, and nothing
between your objects and Core Data. Your entities stay `NSManagedObject`s. `@FetchRequest`,
`NSFetchedResultsController`, CloudKit sync, batch requests and the debugger all keep working
exactly as they did.

The whole library is one conformance per entity:

```swift
import ActiveCoreData
import CoreData

extension Book: ManagedObjectExtended {}
```

and then:

```swift
// Read, on the main thread.
let books = Book.matching("pages > %d", 300, context: store.viewContext)
let ursula = Author.find(id: "le-guin", context: store.viewContext)
let total = Book.countFor(nil, context: store.viewContext)

// Write, in the background.
await store.backgroundContext.enqueue { context in
    let book = Book.findOrCreate(id: isbn, context: context)
    book.title = "The Dispossessed"
    context.flush()
}
```

### New to Core Data?

Start with <doc:GettingStarted>, which builds a small bookshelf app from an empty project, then work
through the <doc:tutorials/Bookshelf> tutorials. You do not need to understand contexts, faults or
merge policies first — the articles introduce each one at the point it starts to matter.

### Already know Core Data?

There is no stack to adopt and no migration to plan. Conform your existing entities to
``ManagedObjectExtended``, conform whatever type owns your `NSPersistentContainer` to ``Container``,
and use as much or as little as you like. <doc:AdoptingInAnExistingApp> maps each helper to the raw
Core Data it replaces so you can see exactly what you are getting.

### The one rule

Read on ``Container/viewContext``. Write on ``Container/backgroundContext``, inside
``CoreData/NSManagedObjectContext/enqueue(_:)``.

```swift
await store.backgroundContext.enqueue { context in
    // ...changes...
    context.flush()
}
```

Every helper that can write asserts in debug builds when handed a main-queue context, so if you
forget, you find out at your desk rather than in a crash report. <doc:WorkingWithContexts> explains
why the split exists and what happens when you ignore it.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:tutorials/Bookshelf>
- ``ManagedObjectExtended``

### Setting up

- <doc:SettingUpYourStore>
- ``DataStore``
- ``Container``

### Reading

- <doc:FindingObjects>
- ``ManagedObjectFind``
- ``ManagedObjectMatching``
- ``ManagedObjectCountable``

### Writing

- <doc:SavingChanges>
- ``ManagedObjectFindOrCreate``
- ``ManagedObjectDeletable``

### Contexts and concurrency

- <doc:WorkingWithContexts>

### Going further

- <doc:AdoptingInAnExistingApp>
- <doc:UnderTheHood>
