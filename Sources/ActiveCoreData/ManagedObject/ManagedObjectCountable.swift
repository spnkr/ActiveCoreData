import CoreData
import Foundation

public protocol ManagedObjectCountable where Self: NSFetchRequestResult {
	init(context: NSManagedObjectContext)

	static func entity() -> NSEntityDescription
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectCountable {

	/// Gets a count of objects matching the passed Predicate.
	/// - Parameters:
	///   - predicate: Any valid ```NSPredicate```
	///   - context: Any ``NSManagedObjectContext``
	/// - Returns: `Int`
	static func countFor(_ predicate: NSPredicate?, context: NSManagedObjectContext) -> Int {

		let request = NSFetchRequest<Self>()
		request.predicate = predicate
		request.entity = entity()

		return (try? context.count(for: request)) ?? 0
	}
}
