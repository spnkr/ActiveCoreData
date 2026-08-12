import CoreData
import Foundation

public protocol ManagedObjectDeletable {
	static func destroyAll(context: NSManagedObjectContext)
	static func destroyAll(matching: NSPredicate?, context: NSManagedObjectContext) -> Int
}

public extension ManagedObjectDeletable {
	static func destroyAll(context: NSManagedObjectContext) {
		_ = destroyAll(matching: nil, context: context)
	}
	static func destroyAll(matching: NSPredicate? = nil, context: NSManagedObjectContext) -> Int {
		assert(context != DataStore.shared.viewContext, "Because destroyAll can write to the database, you must not use the viewContext. Use the background context instead.")
		
		let request = (self as! NSManagedObject.Type).fetchRequest() // swiftlint:disable:this force_cast
		request.entity = (self as! NSManagedObject.Type).entity() // swiftlint:disable:this force_cast

		request.predicate = matching
		
		var objects: [Any]
		do {
			objects = try context.fetch(request)
		} catch {
			objects = []
		}
		for obj in objects {
			context.delete(obj as! NSManagedObject) // swiftlint:disable:this force_cast
		}

		return objects.count
	}
}
