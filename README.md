
# CoreDataPlus ![](https://img.shields.io/badge/-Early%20Access-blue)

Lightweight Active-record-ish pattern.

☁️ Works great with, or without, CloudKit.

✅ Manage your `NSManagedObjectContext`(s) however you want.

👨‍💻 Works with automatic or manual `NSManagedObject` code generation.

# Contents

- [Installation](#installation)
- [Example App](#example-app)
- [Documentation](#documentation)
    - [Predicate](#predicate)
    - [`NSManagedObject` Extensions](#nsmanagedobject-extensions)
- [Automatic Context Management](#automatic-context-management)
- [Logging](#logging)
- [Quick Start with SwiftUI](#quick-start-with-swiftui)
- [Class Reference (beta)](https://spnkr.github.io/CoreDataPlus/documentation/coredataplus/)

# Installation

```swift
import CoreDataPlus

// An existing NSManagedObject
public class Drawing: NSManagedObject { }

extension Drawing: ManagedObjectPlus {
                   
}
```

You can also import just the features you want to use by replacing `ManagedObjectPlus` with one or more of the available `ManagedObject*` protocols:

```swift
extension Drawing: ManagedObjectDeletable,
                   ManagedObjectCountable,
                   ManagedObjectSearchable,
                   ManagedObjectFindOrCreateBy {
                   
}
```

# Example App

Open `Example App/Example App.xcodeproj`.

<img src="https://user-images.githubusercontent.com/11250/207498227-0009e1e4-4201-449a-b205-d9b9cae78f89.png" height="200" />
    
# Documentation

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

### `empty()`

Returns a new, non-nil, `NSPredicate` object that will match every single row in the database.

> This is especially helpful with:
> 1. The [@FetchRequest property wrapper](https://developer.apple.com/documentation/swiftui/fetchrequest). Using a nil predicate can cause unexpected behavior if you dynamically assign or edit the predicate at runtime.
> 2. Other Core Data quirks around nil predicates and updating when you do fancy stuff.
> 
> Before: `@FetchRequest(sortDescriptors: [], predicate: nil)`
> After: `@FetchRequest(sortDescriptors: [], predicate: Predicate.empty())`




## `NSManagedObject` Extensions
### `findOrCreate`

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


### `findButDoNotCreate`

Same as `findOrCreate`, but returns `nil` if there is no object in the database.

```swift
if let d = Drawing.findButDoNotCreate(id: "10001", context: viewContext) {
    d.timestamp = Date()
    d.title = "My title"
}
```

### `countFor`

Gets a count of objects matching the passed `Predicate`

```swift
let count = Drawing.countFor(Predicate("someField = %@", true), context: viewContext)
```

### `searchFor`

Gets all objects matching the passed `Predicate`

```swift
let results = Drawing.searchFor(Predicate("foo = %@", "bar"), context: viewContext)

print("\(results.count) objects found")

for drawing in results {
    dump(drawing)
}
```


### `destroyAll`

Removes all objects from Core Data.
*Deletes them from the context.*

```swift
Drawing.destroyAll(context: viewContext)
```


You can also specify a predicate to only delete some items:
```swift
let withSpanishLanguage = Predicate("languages contains %@", es)
Country.destroyAll(matching: withSpanishLanguage)
```

Remember to save the context after deleting objects.



## Logging

By default, log messages do not appear. To take action when there's a problem, use `CoreDataPlus.Logger.configure(...)`

```swift
CoreDataPlus.Logger.configure(logHandler: { message in
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
        
        CoreDataPlus.Logger.configure(logHandler: { message in
            print("A log message from the data layer: \(message)")
        })
        
        return true
    }
}
```


## Automatic Context Management

Optional. If you specify a view context and a background context using `CoreDataPlus.setup(...)`, you can simplify passing of `NSManagedObjectContext` objects.

For example, `Book.findOrCreate(id:"123", context: foo)` becomes `Book.findOrCreate(id:"123")` and `Author.findOrCreate(id:"123", context: bar)` becomes `Author.findOrCreate(id:"123", using: .background)`. See the included example app for more examples.



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
- [ ] Option to disable automatic saving when using `destroyAll`
- [ ] Add docs on `NSPersistentContainer` agnosticity
- [ ] Have an idea? Open an issue!

