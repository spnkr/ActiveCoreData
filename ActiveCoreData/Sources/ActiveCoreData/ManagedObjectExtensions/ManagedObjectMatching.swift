import CoreData
import Foundation

/// Fetches every object satisfying a predicate, with optional sorting and a limit.
///
/// ```swift
/// let longBooks = Book.matching(
///     "pages > %d", 300,
///     context: context,
///     sortBy: [NSSortDescriptor(key: "title", ascending: true)],
///     limit: 10
/// )
/// ```
public protocol ManagedObjectMatching where Self: NSFetchRequestResult {
	/// Inserts a new instance into `context`. Supplied by `NSManagedObject`.
	init(context: NSManagedObjectContext)

	/// The entity this class represents. Supplied by `NSManagedObject`.
	static func entity() -> NSEntityDescription

	/// A fetch request for this entity. Supplied by `NSManagedObject`.
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectMatching {

	/// Fetches every object matching a predicate written as a format string.
	///
	/// ```swift
	/// let ursulas = Book.matching("author.name = %@", "Ursula K. Le Guin", context: context)
	/// let long = Book.matching("pages > %d", 300, context: context)
	/// let all = Book.matching("TRUEPREDICATE", context: context)
	/// ```
	///
	/// > Note: `context:` comes straight after the arguments rather than at the end, because the
	/// > variadic `args` would otherwise swallow it. The
	/// > ``matching(_:sortBy:limit:context:)`` overload, which takes a ready-made `NSPredicate`,
	/// > puts `context:` last. It is an inconsistency worth knowing about before the compiler tells
	/// > you off.
	///
	/// The arguments go through `getVaList`, so they must be `CVarArg` — which covers `String`,
	/// the numeric types, `Bool`, `Date` and any `NSObject`. If you need to pass a Swift array or
	/// an optional, build an ``Foundation/NSPredicate/init(_:_:)`` and use the other overload.
	///
	/// - Parameters:
	///   - format: A predicate format string, e.g. `"pages > %d AND author.name = %@"`.
	///   - args: Values substituted into `format`, positionally.
	///   - context: The context to fetch in. Returned objects belong to it.
	///   - sortBy: Sort descriptors, applied in order. Unsorted when `nil`.
	///   - limit: Stop after this many objects. Unlimited when `nil`.
	/// - Returns: The matching objects, or an empty array when the fetch fails.
	static func matching(
		_ format: String,
		_ args: CVarArg...,
		context: NSManagedObjectContext,
		sortBy: [NSSortDescriptor]? = nil,
		limit: Int? = nil
	) -> [Self] {
		let predicate = NSPredicate(format: format, arguments: getVaList(args))

		return matching(predicate, sortBy: sortBy, limit: limit, context: context)
	}

	/// Fetches every object matching a predicate, or every object when the predicate is `nil`.
	///
	/// ```swift
	/// // Everything, newest first.
	/// let books = Book.matching(
	///     nil,
	///     sortBy: [NSSortDescriptor(key: "published", ascending: false)],
	///     context: context
	/// )
	///
	/// // The three longest.
	/// let longest = Book.matching(
	///     NSPredicate("pages > %@", 0),
	///     sortBy: [NSSortDescriptor(key: "pages", ascending: false)],
	///     limit: 3,
	///     context: context
	/// )
	/// ```
	///
	/// > Tip: A `limit` without a `sortBy` returns an arbitrary slice — the store is free to hand
	/// > back rows in whatever order it finds them. "The first 10" only means something once you
	/// > have said what "first" is.
	///
	/// Returns objects, not faults you have to think about: Core Data hands back real instances
	/// whose attributes are filled in on first access. Walking a relationship on each of them is
	/// where the cost hides — see <doc:UnderTheHood#Faulting-batching-and-the-row-cache>.
	///
	/// - Parameters:
	///   - predicate: The predicate to filter by, or `nil` for everything.
	///   - sortBy: Sort descriptors, applied in order. Unsorted when `nil`.
	///   - limit: Stop after this many objects. Unlimited when `nil`.
	///   - context: The context to fetch in. Returned objects belong to it.
	/// - Returns: The matching objects, or an empty array when the fetch fails.
	static func matching(_ predicate: NSPredicate?,
						  sortBy: [NSSortDescriptor]? = nil,
						  limit: Int? = nil,
						 context: NSManagedObjectContext) -> [Self] {
		let request = NSFetchRequest<Self>()
		request.predicate = predicate
		request.entity = entity()

		if let limit = limit {
			request.fetchLimit = limit
		}

		if let sortBy = sortBy {
			request.sortDescriptors = sortBy
		}

		return (try? context.fetch(request)) ?? []
	}
}
