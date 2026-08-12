import CoreData
import Foundation

/// A source of the two managed object contexts ActiveCoreData expects an app to have: one for
/// reading on the main thread, and one for writing in the background.
///
/// ## Overview
///
/// Core Data does not tell you how many contexts to have or what to use them for. ActiveCoreData
/// takes a position: **one main-queue context that you only read from, and one private-queue
/// context that you write on.** `Container` is the name for that pair.
///
/// If you are starting a new app, ``DataStore`` already conforms and there is nothing to write:
///
/// ```swift
/// let books = Book.matching(nil, context: DataStore.shared.viewContext)
/// ```
///
/// If your app already owns its Core Data stack, conform your own type and keep the stack you have:
///
/// ```swift
/// extension PersistenceController: Container {
///     var viewContext: NSManagedObjectContext { container.viewContext }
///     var backgroundContext: NSManagedObjectContext { writeContext }
/// }
/// ```
///
/// > Note: No helper in ActiveCoreData ever reaches through this protocol to find a context. Every
/// > `find`, `matching`, `findOrCreate` and `destroyAll` takes the context you hand it, so the
/// > library never has an opinion about which store an object came from. `Container` exists so the
/// > two contexts your app passes around have one agreed name and one agreed meaning.
///
/// ## Two contexts, not two hundred
///
/// A common instinct is to spin up a fresh background context per operation. That works, but each
/// context keeps its own registered objects and its own change tracking, so the same row fetched by
/// two contexts becomes two separate instances that must then be merged back through the
/// coordinator. A single long-lived writer serialises your writes for free and keeps one object
/// graph instead of *n*.
///
/// > Tip: Reach for an extra context when you want to *throw work away* — a large import that may
/// > need to be abandoned, or a scratch edit backing a modal sheet. `context.reset()` on a
/// > throwaway context is cheap; on your one shared writer it invalidates every object your app is
/// > holding.
public protocol Container {
	/// The main-queue context, for reading.
	///
	/// Bind this to SwiftUI's `\.managedObjectContext` and read from it on the main thread. Every
	/// helper that can write — ``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` and
	/// ``ManagedObjectDeletable/destroyAll(matching:context:)`` — asserts in debug builds when it
	/// is handed a main-queue context, so mistakes surface immediately rather than as a hang.
	var viewContext: NSManagedObjectContext { get }

	/// The private-queue context, for writing.
	///
	/// Everything that changes the store belongs here, inside
	/// ``CoreData/NSManagedObjectContext/enqueue(_:)``:
	///
	/// ```swift
	/// await store.backgroundContext.enqueue { context in
	///     Book.findOrCreate(id: isbn, context: context).title = title
	///     context.flush()
	/// }
	/// ```
	var backgroundContext: NSManagedObjectContext { get }
}
