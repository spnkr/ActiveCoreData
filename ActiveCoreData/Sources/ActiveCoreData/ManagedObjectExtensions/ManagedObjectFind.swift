import CoreData
import Foundation

public protocol ManagedObjectFind where Self: NSFetchRequestResult {

	init(context: NSManagedObjectContext)
	static func entity() -> NSEntityDescription
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectFind {
	static func find(column: String, value: Any, context: NSManagedObjectContext) -> Self? {
		let request = NSFetchRequest<Self>()
		request.predicate = NSPredicate("\(column) = %@", value)
		request.entity = entity()

		do {
			let objects: [Self] = try context.fetch(request)

			if let object = objects.first {
				return object
			}
		} catch {
			// Log.log(level: .error, "find context fetch failure: \(error.localizedDescription)")
		}

		return nil
	}

	/// Same as `load(column: String, value: Any, ...`, but with the column name set to `id`.
	static func find(id: String, context: NSManagedObjectContext) -> Self? {
		return find(column: "id", value: id, context: context)
	}
}
