# Getting started

Build a small bookshelf app, from an empty project to a working list, in about ten minutes.

## Overview

This article assumes you have used Swift and SwiftUI a little, and Core Data not at all. Everything
Core Data–specific is introduced as it comes up. By the end you will have an app that stores books
and authors on disk and shows them in a list that updates itself.

If you would rather follow along step by step in Xcode with the code beside you, the
<doc:tutorials/Bookshelf> tutorials cover the same ground in that format.

## Add the package

In Xcode, choose **File ▸ Add Package Dependencies…**, paste the repository URL, and add the
`ActiveCoreData` library to your app target.

## Describe your data

Core Data does not read your Swift types. It works from a **model**: a file describing your
entities, their attributes, and how they relate. Choose **File ▸ New ▸ File ▸ Data Model** and name
it `Bookshelf`. You will get `Bookshelf.xcdatamodeld`.

> Important: Name the model after your app or your data, and remember the name. ``DataStore`` finds
> it for you when there is exactly one, which is the case here. See <doc:SettingUpYourStore> if you
> end up with more than one.

Open it and add two entities.

**Author**

| Attribute | Type   | Optional |
| --------- | ------ | -------- |
| `id`      | String | no       |
| `name`    | String | yes      |

**Book**

| Attribute | Type    | Optional |
| --------- | ------- | -------- |
| `id`      | String  | no       |
| `title`   | String  | yes      |
| `pages`   | Integer 64 | no    |

Then add the relationship. On `Author`, add a relationship called `books`, destination `Book`, type
**To Many**. On `Book`, add one called `author`, destination `Author`, type **To One**, and set each
one's **Inverse** to the other.

> Tip: Every relationship should have an inverse. Core Data uses it to keep both sides consistent
> when you assign one — set `book.author` and that book appears in `author.books` immediately,
> without you touching it. Xcode warns when an inverse is missing, and the warning is worth
> believing.

### Why `id`?

Nothing in Core Data requires an `id` attribute. ActiveCoreData's most convenient calls —
``ManagedObjectFind/find(id:context:)`` and ``ManagedObjectFindOrCreate/findOrCreate(id:context:)``
— look for a `String` attribute with exactly that name, so adding one buys you the short form. It
also gives you `Identifiable` conformance for free, which is what SwiftUI's `List` and `ForEach`
want.

While you are in the model editor, select the `id` attribute on `Book`, open the data model
inspector, and tick **Indexed**. You will be looking books up by `id` constantly, and an index is
the difference between a lookup and a table scan.

## Turn on the helpers

Xcode generates an `NSManagedObject` subclass for each entity automatically. You never see the file,
but the classes exist and you can extend them. Make a new Swift file called `Model+ActiveCoreData.swift`:

```swift
import ActiveCoreData
import CoreData

extension Author: ManagedObjectExtended {}
extension Book: ManagedObjectExtended {}
```

That is the whole setup. ``ManagedObjectExtended`` has no requirements you need to satisfy yourself
— `NSManagedObject` already provides all of them — so both extensions are empty, and both entities
now have every helper in the library.

## Wire up the app

``DataStore`` opens your store and gives you two contexts. A **context** is a scratchpad: you fetch
objects into it, change them, and save. ``Container/viewContext`` is the one for reading on the main
thread, and it is what SwiftUI wants:

```swift
import ActiveCoreData
import SwiftUI

@main
struct BookshelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataStore.shared.viewContext)
        }
    }
}
```

Nothing else to configure. The store is created on first use, in the standard location, and it is
the same `NSPersistentContainer` you would have set up by hand.

## Write something

Writing happens on the *other* context, in the background, so a slow save never stutters your UI:

```swift
@MainActor
func addBook(isbn: String, title: String, authorName: String) async {
    let context = DataStore.shared.backgroundContext

    await context.enqueue { context in
        let author = Author.findOrCreate(column: "name", value: authorName, context: context)

        let book = Book.findOrCreate(id: isbn, context: context)
        book.title = title
        book.author = author

        context.flush()
    }
}
```

Three things are happening here.

``CoreData/NSManagedObjectContext/enqueue(_:)`` runs your block on the context's own queue and
suspends until it is done. Core Data objects are tied to the queue of the context that owns them, and
this is how you get onto it.

``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` fetches the book with that ISBN, or inserts
a new one with `id` already set. Run this function twice with the same ISBN and you still have one
book and one author — which is exactly what you want when the data is coming from a server that
does not know what you already have.

``CoreData/NSManagedObjectContext/flush()`` saves. Until you call it, everything you changed lives
only in that context.

Because ``Container/viewContext`` was created with `automaticallyMergesChangesFromParent` turned on,
the save reaches the main-thread context by itself and any SwiftUI view watching it redraws. There
is no notification to observe and nothing to refresh.

## Read it back

`@FetchRequest` keeps a view in sync with the store, and it works unchanged — your entities are
still ordinary `NSManagedObject`s:

```swift
struct ContentView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)])
    private var books: FetchedResults<Book>

    var body: some View {
        List(books) { book in
            VStack(alignment: .leading) {
                Text(book.title ?? "Untitled")
                Text(book.author?.name ?? "Unknown author")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

For a one-off read outside a view — a share sheet, a widget snapshot, a decision in a view model —
use the helpers directly against ``Container/viewContext``:

```swift
let store = DataStore.shared

let longBooks = Book.matching(
    "pages > %d", 300,
    context: store.viewContext,
    sortBy: [NSSortDescriptor(key: "title", ascending: true)]
)

let ursula = Author.find(id: "le-guin", context: store.viewContext)
let total = Book.countFor(nil, context: store.viewContext)
```

> Tip: `@FetchRequest` for anything a view displays, the helpers for anything you are about to make
> a decision with. `@FetchRequest` re-runs itself when the store changes; a helper gives you the
> answer once, right now.

## Delete something

```swift
@MainActor
func deleteFinishedBooks() async {
    let context = DataStore.shared.backgroundContext

    await context.enqueue { context in
        let removed = Book.destroyAll(matching: NSPredicate("read = %@", true), context: context)
        print("removed \(removed) books")
        context.flush()
    }
}
```

## Where to go next

- <doc:FindingObjects> — predicates, sorting, limits, and which read to reach for.
- <doc:SavingChanges> — upserts, deletes, and what to do when a save fails.
- <doc:WorkingWithContexts> — the read/write split, and the rules about passing objects around.
- <doc:UnderTheHood> — what Core Data is actually doing underneath, once you are curious.
