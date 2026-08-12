import CoreData
import Foundation

/// Counts objects without loading them.
///
/// ```swift
/// let unread = Book.countFor(NSPredicate("read = %@", false), context: context)
/// ```
public protocol ManagedObjectCountable where Self: NSFetchRequestResult {
	/// Inserts a new instance into `context`. Supplied by `NSManagedObject`.
	init(context: NSManagedObjectContext)

	/// The entity this class represents. Supplied by `NSManagedObject`.
	static func entity() -> NSEntityDescription

	/// A fetch request for this entity. Supplied by `NSManagedObject`.
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectCountable {

	/// Counts the objects matching a predicate, or every object when the predicate is `nil`.
	///
	/// ```swift
	/// let total = Book.countFor(nil, context: context)
	/// let long = Book.countFor(NSPredicate("pages > %@", 300), context: context)
	///
	/// if Book.countFor(NSPredicate("id = %@", isbn), context: context) == 0 {
	///     // ...
	/// }
	/// ```
	///
	/// > Tip: Always prefer this to `matching(...).count`. Core Data turns it into a `SELECT
	/// > COUNT(*)`, so nothing is materialised into the context and nothing is added to the row
	/// > cache. Counting ten thousand books costs the same as counting one.
	///
	/// Pending changes are included: objects inserted into `context` but not yet saved are counted,
	/// and objects deleted in `context` but not yet saved are not. Core Data does the arithmetic
	/// against the store count rather than re-running the query in memory.
	///
	/// - Parameters:
	///   - predicate: The predicate to filter by, or `nil` to count everything.
	///   - context: The context to count in.
	/// - Returns: The number of matching objects, or `0` when the count fails.
	/// - Complexity: One `COUNT` query. No objects are faulted in.
	static func countFor(_ predicate: NSPredicate?, context: NSManagedObjectContext) -> Int {

		let request = NSFetchRequest<Self>()
		request.predicate = predicate
		request.entity = entity()

		return (try? context.count(for: request)) ?? 0
	}
}
