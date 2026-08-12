import CoreData
import Foundation

/// Fetches a single object by the value of one attribute.
///
/// Conform via ``ManagedObjectExtended``, or on its own when an entity should be searchable but not
/// creatable or deletable:
///
/// ```swift
/// extension Author: ManagedObjectFind {}
///
/// let ursula = Author.find(id: "le-guin", context: context)
/// ```
///
/// All three requirements are already met by `NSManagedObject`, so the conformance is empty.
public protocol ManagedObjectFind where Self: NSFetchRequestResult {

	/// Inserts a new instance into `context`. Supplied by `NSManagedObject`.
	init(context: NSManagedObjectContext)

	/// The entity this class represents. Supplied by `NSManagedObject`.
	static func entity() -> NSEntityDescription

	/// A fetch request for this entity. Supplied by `NSManagedObject`.
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectFind {
	/// Returns the first object whose `column` equals `value`, or `nil` if there is none.
	///
	/// ```swift
	/// let ursula = Author.find(column: "name", value: "Ursula K. Le Guin", context: context)
	/// let debut = Book.find(column: "pages", value: 189, context: context)
	/// ```
	///
	/// The fetch is unsorted and unlimited, so when several rows qualify you get whichever one the
	/// store returns first — which is *not* a stable order. Use this for lookups by something
	/// unique; reach for ``ManagedObjectMatching/matching(_:sortBy:limit:context:)`` when "the
	/// first" needs to mean something.
	///
	/// Pending changes count. An object you inserted into `context` and have not saved yet is
	/// found by this call; an object another context inserted and has not saved yet is not.
	///
	/// > Warning: `column` is interpolated straight into the predicate format string, so it must be
	/// > a literal attribute name you control — never anything derived from user input. `value` is
	/// > safely substituted through `%@` and can be anything.
	///
	/// - Parameters:
	///   - column: The attribute name to match on.
	///   - value: The value to match. Any type Core Data can store.
	///   - context: The context to fetch in. The returned object belongs to it.
	/// - Returns: A matching object, or `nil` when nothing matches or the fetch fails.
	/// - Complexity: One round trip to the store, or none if the row is already in `context`'s row
	///   cache. Index the column in your model if you call this on a hot path.
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
	///
	/// ```swift
	/// let ursula = Author.find(id: "le-guin", context: context)
	/// ```
	///
	/// Requires a `String` attribute named `id` on the entity. Adding one is worth it anyway: it
	/// gives you `Identifiable` for free, which is what SwiftUI's `List` and `ForEach` want.
	///
	/// - Parameters:
	///   - id: The value of the `id` attribute.
	///   - context: The context to fetch in. The returned object belongs to it.
	/// - Returns: A matching object, or `nil` when nothing matches.
	static func find(id: String, context: NSManagedObjectContext) -> Self? {
		return find(column: "id", value: id, context: context)
	}
}
