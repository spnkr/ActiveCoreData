import CoreData
import Foundation


public protocol ManagedObjectLoad where Self: NSFetchRequestResult {

	init(context: NSManagedObjectContext)
	static func entity() -> NSEntityDescription
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectLoad {
	static func load(column: String, value: Any, context: NSManagedObjectContext) -> Self? {
		let request = NSFetchRequest<Self>()
		request.predicate = NSPredicate("\(column) = %@", value)
		request.entity = entity()

		do {
			let objects: [Self] = try context.fetch(request)

			if let object = objects.first {
				return object
			}
		} catch {
			// TODO: log if you want
			// Log.log(level: .error, "findOrCreate context fetch failure: \(error.localizedDescription)")
		}

		return nil
	}

	/// Same as `load(column: String, value: Any, ...`, but with the column name set to `id`.
	static func load(id: String, context: NSManagedObjectContext) -> Self? {
		return load(column: "id", value: id, context: context)
	}
}
