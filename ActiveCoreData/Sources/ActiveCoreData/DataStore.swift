import CoreData
import Foundation

open class DataStore: Container {
	@MainActor public static let shared = DataStore()
	
	/// Read-only context for use on main thread.
	public lazy var viewContext: NSManagedObjectContext = {
		let c = persistentContainer.viewContext
		c.automaticallyMergesChangesFromParent = true
		return c
	}()
	
	/// Single background context for all writes, and background data loading.
	public lazy var backgroundContext: NSManagedObjectContext = {
		let newbackgroundContext = persistentContainer.newBackgroundContext()
		newbackgroundContext.automaticallyMergesChangesFromParent = true
		newbackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		return newbackgroundContext
	}()
	
	lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: Self.persistentContainerName)
		
		container.loadPersistentStores(completionHandler: { (_, error) in
			
		})
		
		return container
	}()
	
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
