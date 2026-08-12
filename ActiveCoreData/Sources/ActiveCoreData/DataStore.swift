import CoreData
import Foundation

/// A ready-made Core Data stack: find your model, open the store, hand you a reading context and a
/// writing context.
///
/// ## Overview
///
/// `DataStore` is the zero-configuration path. It finds your compiled model in the app bundle,
/// loads the store, and exposes the two contexts described by ``Container``. For a new app there
/// is nothing to set up and nothing to pass around:
///
/// ```swift
/// // Read, on the main thread.
/// let books = Book.matching(nil, context: DataStore.shared.viewContext)
///
/// // Write, in the background.
/// let context = DataStore.shared.backgroundContext
/// await context.enqueue { context in
///     Book.findOrCreate(id: isbn, context: context).title = "The Dispossessed"
///     context.flush()
/// }
/// ```
///
/// ## Naming your model
///
/// `DataStore` needs to know which model to open. It works that out in two steps, in order:
///
/// 1. The `persistentContainerName` key inside an `ActiveCoreData` dictionary in your `Info.plist`.
/// 2. Failing that, the first compiled model (`.momd`) it finds in the main bundle.
///
/// Step 2 covers the common case — one `Bookshelf.xcdatamodeld` in one app target — so most apps
/// never touch their `Info.plist`. Set the key explicitly when your app ships more than one model,
/// or when the model file is not named after the store you want:
///
/// ```xml
/// <key>ActiveCoreData</key>
/// <dict>
///     <key>persistentContainerName</key>
///     <string>Bookshelf</string>
/// </dict>
/// ```
///
/// > Warning: ``persistentContainerName`` traps with a diagnostic when neither step yields a name,
/// > which happens in a target with no model of its own — a test bundle, an app extension, or a
/// > SwiftUI preview host. Those targets should not use ``shared`` at all; build a stack that
/// > conforms to ``Container`` instead and point it at whichever store the target should see.
///
/// ## When to use something else
///
/// `DataStore` is `open`, but it is a small class with a fixed opinion: one store, at the default
/// location, with no options set. You will outgrow it the moment you need to configure
/// `NSPersistentStoreDescription` — App Groups, `NSPersistentHistoryTrackingKey`, encryption, a
/// read-only store, or `NSPersistentCloudKitContainer`. That is not a failure of the library. Keep
/// your own stack and conform it to ``Container``; every helper in ActiveCoreData takes a context,
/// so nothing else about your code changes.
///
/// > Important: ``shared`` is `@MainActor`. Read the property on the main actor, hold the context
/// > it hands back, and then hop to that context's own queue with
/// > ``CoreData/NSManagedObjectContext/enqueue(_:)``. The context object is safe to keep; what is
/// > never safe is touching a context, or an object it owns, off its own queue.
open class DataStore: Container {
	/// The shared stack.
	///
	/// Isolated to the main actor, so reach for it from main-actor code and pass the context onward:
	///
	/// ```swift
	/// @MainActor
	/// func add(isbn: String, title: String) async {
	///     let context = DataStore.shared.backgroundContext
	///
	///     await context.enqueue { context in
	///         Book.findOrCreate(id: isbn, context: context).title = title
	///         context.flush()
	///     }
	/// }
	/// ```
	@MainActor public static let shared = DataStore()

	/// Read-only context for use on main thread.
	///
	/// Backed by `NSPersistentContainer.viewContext`, with `automaticallyMergesChangesFromParent`
	/// turned on so saves made on ``backgroundContext`` land here without any notification
	/// plumbing of your own. Bind it to SwiftUI's `\.managedObjectContext` and let `@FetchRequest`
	/// do the rest.
	///
	/// > Important: Read-only is a convention, not a lock — Core Data will happily let you mutate
	/// > an object registered here. The helpers that write assert against it in debug builds, but
	/// > direct property assignment is yours to police. Writing on the main queue blocks the frame
	/// > you are drawing, and any conflict is resolved against a context whose merge policy is the
	/// > default `NSErrorMergePolicy`, which fails rather than merges.
	public lazy var viewContext: NSManagedObjectContext = {
		let c = persistentContainer.viewContext
		c.automaticallyMergesChangesFromParent = true
		return c
	}()

	/// Single background context for all writes, and background data loading.
	///
	/// Created with `newBackgroundContext()`, so it owns a private queue. Two settings are applied:
	///
	/// - `automaticallyMergesChangesFromParent` — picks up saves made elsewhere in the coordinator.
	/// - `mergePolicy = .mergeByPropertyObjectTrump` — on a conflict, the version in memory wins,
	///   property by property. Without this the default `NSErrorMergePolicy` turns every optimistic
	///   locking conflict into a thrown save error, and ``CoreData/NSManagedObjectContext/flush()``
	///   swallows those silently.
	///
	/// > Note: One writer for the whole app is deliberate. A private-queue context serialises the
	/// > work handed to it, so a single shared writer gives you write serialisation for free — and
	/// > it is what stops two concurrent upserts of the same key from both missing and both
	/// > inserting.
	public lazy var backgroundContext: NSManagedObjectContext = {
		let newbackgroundContext = persistentContainer.newBackgroundContext()
		newbackgroundContext.automaticallyMergesChangesFromParent = true
		newbackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		return newbackgroundContext
	}()

	/// The underlying container, created on first use and loaded synchronously.
	lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: Self.persistentContainerName)

		container.loadPersistentStores(completionHandler: { (_, error) in

		})

		return container
	}()

	/// The name of the model `DataStore` opens.
	///
	/// Resolved once, on first use, from the `Info.plist` key or the first compiled model in the
	/// main bundle. See <doc:SettingUpYourStore> for the lookup rules.
	///
	/// - Warning: Traps with a diagnostic when the name cannot be worked out. Reading this property
	///   from a target that has no model of its own — a test bundle or an app extension — is the
	///   usual cause.
	public static let persistentContainerName: String = {
		guard let name = resolvePersistentContainerName(
			infoDictionary: Bundle.main.infoDictionary,
			momdURLs: Bundle.main.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? []
		) else {
			preconditionFailure("""
				ActiveCoreData could not work out the name of your Core Data model: no compiled \
				model (.momd) was found in the main bundle. Add an "ActiveCoreData" dictionary to \
				your Info.plist with a "persistentContainerName" key naming your model.
				""")
		}

		return name
	}()

	/// Works out the name to hand to `NSPersistentContainer`.
	///
	/// The `ActiveCoreData.persistentContainerName` key in the Info.plist wins. When it is missing
	/// the name is guessed from the first compiled model in the bundle.
	///
	/// - Parameters:
	///   - infoDictionary: The bundle's `Info.plist` contents, or `nil` when it has none.
	///   - momdURLs: URLs of the compiled models in the bundle.
	/// - Returns: The model name, or `nil` when neither source yields one.
	static func resolvePersistentContainerName(infoDictionary: [String: Any]?, momdURLs: [URL]) -> String? {
		if let activeCoreDataDict = infoDictionary?["ActiveCoreData"] as? [String: Any],
		   let containerName = activeCoreDataDict["persistentContainerName"] as? String {
			return containerName
		}

		// Fallback option when the Info.plist key is missing
		return momdURLs.first?.lastPathComponent.replacingOccurrences(of: ".momd", with: "")
	}
}
