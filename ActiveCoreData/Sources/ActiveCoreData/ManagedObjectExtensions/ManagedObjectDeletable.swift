import CoreData
import Foundation

/// Deletes objects in bulk.
///
/// ```swift
/// await store.backgroundContext.enqueue { context in
///     let removed = Book.destroyAll(matching: NSPredicate("read = %@", true), context: context)
///     print("cleared \(removed) finished books")
///     context.flush()
/// }
/// ```
///
/// > Warning: Unlike the other protocols in ActiveCoreData, this one only works on
/// > `NSManagedObject` subclasses — the default implementation force-casts `Self` to
/// > `NSManagedObject.Type`. Conforming a type that is merely `NSFetchRequestResult` compiles and
/// > then traps at runtime.
public protocol ManagedObjectDeletable {
	/// Deletes every object of this entity in `context`.
	static func destroyAll(context: NSManagedObjectContext)

	/// Deletes the objects matching a predicate and reports how many.
	static func destroyAll(matching: NSPredicate?, context: NSManagedObjectContext) -> Int
}

public extension ManagedObjectDeletable {
	/// Deletes every object of this entity in `context`.
	///
	/// ```swift
	/// await store.backgroundContext.enqueue { context in
	///     Book.destroyAll(context: context)
	///     context.flush()
	/// }
	/// ```
	///
	/// Shorthand for ``destroyAll(matching:context:)`` with no predicate, discarding the count.
	///
	/// - Parameter context: A background context. Nothing is removed from the store until you save.
	static func destroyAll(context: NSManagedObjectContext) {
		_ = destroyAll(matching: nil, context: context)
	}

	/// Deletes the objects matching a predicate and reports how many were deleted.
	///
	/// ```swift
	/// let removed = Book.destroyAll(matching: NSPredicate("author = nil"), context: context)
	/// ```
	///
	/// Objects are fetched and then deleted one at a time, which is what makes the count accurate
	/// and — more importantly — what makes your model's delete rules run. Deleting an `Author`
	/// whose `books` relationship cascades takes its books with it, and every affected object your
	/// app is already holding is marked `isDeleted` straight away.
	///
	/// > Tip: That per-object walk is also the cost. For tens of thousands of rows, reach for
	/// > `NSBatchDeleteRequest` instead: it runs entirely in the store, in one statement. The
	/// > trade-off is that it bypasses the context completely — no delete rules, no `isDeleted`, no
	/// > notifications — so you must merge the returned object IDs back yourself with
	/// > `NSManagedObjectContext.mergeChanges(fromRemoteContextSave:into:)` or your UI will show
	/// > rows that no longer exist.
	///
	/// > Important: Asserts in debug builds when handed a main-queue context. Deletes belong on
	/// > ``Container/backgroundContext``.
	///
	/// - Parameters:
	///   - matching: The predicate to filter by, or `nil` to delete everything.
	///   - context: A background context. Nothing is removed from the store until you save.
	/// - Returns: The number of objects deleted, or `0` when the fetch fails.
	static func destroyAll(matching: NSPredicate? = nil, context: NSManagedObjectContext) -> Int {
		assertContextIsWritable(context)

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
