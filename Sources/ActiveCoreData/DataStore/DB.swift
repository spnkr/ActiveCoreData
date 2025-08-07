import CoreData

public class DB: @unchecked Sendable {
	public static var background: NSManagedObjectContext {
		ActiveCoreDataStore.shared.backgroundContext
	}
	public static var main: NSManagedObjectContext {
		ActiveCoreDataStore.shared.viewContext
	}
}
