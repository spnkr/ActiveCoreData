# CoreDataPlus ![](https://img.shields.io/badge/-Early%20Access-blue)

Lightweight Active-record-ish pattern.

☁️ Works great with, or without, CloudKit.
✅ Manage your `NSManagedObjectContext`(s) however you want.
👨‍💻 Works with automatic or manual `NSManagedObject` code generation.

## Installation

```swift
import CoreDataPlus

// An existing NSManagedObject
public class Drawing: NSManagedObject { }

extension Drawing: CoreDataDeletable,
                   CoreDataCountable,
                   CoreDataSearchable,
                   FindOrCreatableBy {
                   
}
```

    
## `Predicate`

Adds a new, more concise, initializer for `NSPredicate`. Aliased as `Predicate`.

You can type

```swift
Predicate("color = %@ and city = %@", "Blue", city)
```

Instead of

``` swift
NSPredicate(format:"color = %@ and city = %@", argumentArray:["Blue", city])
```




## `findOrCreate`

Finds an instance of the `NSManagedObject` that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.

```swift
let d = Drawing.findOrCreate(column: "my-column", value: "123456789", context: viewContext)
d.timestamp = Date()
```

The idea is that each object has a unique, deterministic, human-readable, identifier. So if you have a `User` with an `id` of `123`, you can do `let user = User.findOrCreate(id: "123")` whenever and wherever you need access to the user object.

#### Shortcut:
If your xcdatamodel has a `String` property called `id`, you can use this shortcut:

```swift
let d = Drawing.findOrCreate(id: "123", context: viewContext)
```

*Tip: If you're using SwiftUI, adding a `String` column `id` plays nicely with `Identifiable`*


## `findButDoNotCreate`

Same as `findOrCreate`, but returns `nil` if there is no object in the database.

```swift
if let d = Drawing.findButDoNotCreate(id: "10001", context: viewContext) {
    d.timestamp = Date()
    d.title = "My title"
}
```

## `countFor`

Gets a count of objects matching the passed `Predicate`

```swift
let count = Drawing.countFor(Predicate("someField = %@", true), context: viewContext)
```

## `searchFor`

Gets all objects matching the passed `Predicate`

```swift
let results = Drawing.searchFor(Predicate("foo = %@", "bar"), context: viewContext)

print("\(results.count) objects found")

for drawing in results {
    dump(drawing)
}
```


## `destroyAll`

Removes all objects from Core Data.
*Deletes them from the context, and saves the context.*

```swift
Drawing.destroyAll(context: viewContext)
```




## Logging

By default, log messages do not appear. To take action when there's a problem, use `CoreDataLogger.configure(...)`

```swift
CoreDataLogger.configure(logHandler: { message in
    print("A log message from the data layer: \(message)")
})
```

*Recommended: set the `logHandler` in your AppDelegate*. Example below:

```swift
// Your app's main .swift file:
import SwiftUI

@main
struct MyFancyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


// A new file called AppDelegate.swift
import Foundation
import UIKit
import CoreDataPlus

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        CoreDataLogger.configure(logHandler: { message in
            print("A log message from the data layer: \(message)")
        })
        
        return true
    }
}
```


## Quick Start with SwiftUI

You can pass the `viewContext` variable as the `context` for all this library's methods.

Most SwiftUI quickstart guides use `.environment(\.managedObjectContext, foo)` on the view, along with 


Main app file:

```swift
import SwiftUI

@main
struct MyFancyApp: App {
    let persistenceController = PersistenceController.shared // from the default Xcode new project setup
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

```

ContentView file:

```swift
import SwiftUI
import CoreData
import CoreDataPlus

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            Button("Hello", action: {
                Drawing.destroyAll(context: self.viewContext)
            })
        }
    }
}
```


## Todo
- [ ] Unit tests
- [ ] Example app
- [ ] Option to disable automatic saving when using `destroyAll`
- [ ] Have an idea? Open an issue!

