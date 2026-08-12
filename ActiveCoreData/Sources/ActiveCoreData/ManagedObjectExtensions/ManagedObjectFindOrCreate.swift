import CoreData

/// Fetches an object by its key, inserting one if it is not there yet.
///
/// This is the upsert at the heart of ActiveCoreData, and the reason importing a feed or syncing an
/// API response stops being a chore:
///
/// ```swift
/// for payload in response.books {
///     let book = Book.findOrCreate(id: payload.isbn, context: context)
///     book.title = payload.title
///     book.pages = payload.pages
/// }
///
/// context.flush()
/// ```
///
/// Run that twice and you still have one row per ISBN.
public protocol ManagedObjectFindOrCreate where Self: NSFetchRequestResult {
	// Tip: You will probably want to define id, as part of the Identifiable protocol. If you add this as a column in your db, you get automatic conformance. If your NSManagedObject doesn't have an `id` property in the database, you'd implement this:
	// var id: String { get set }

	/// Inserts a new instance into `context`. Supplied by `NSManagedObject`.
	init(context: NSManagedObjectContext)

	/// The entity this class represents. Supplied by `NSManagedObject`.
	static func entity() -> NSEntityDescription

	/// A fetch request for this entity. Supplied by `NSManagedObject`.
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}


public extension ManagedObjectFindOrCreate {
	/// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.
	///
	/// The compound form, for entities keyed on more than one attribute. Every column must match
	/// for a row to count as found; when nothing matches, a new object is inserted with all of them
	/// already set.
	///
	/// ```swift
	/// let edition = Edition.findOrCreate(
	///     columns: ["isbn", "printing"],
	///     values: [isbn, 2],
	///     context: context
	/// )
	/// ```
	///
	/// > Warning: `columns` and `values` are positional and must be the same length, and `columns`
	/// > must not be empty. Neither is checked: a mismatch traps or raises from `NSPredicate`
	/// > rather than returning an error. Column names are interpolated into the predicate format
	/// > string, so they must be literals you control.
	///
	/// - Parameters:
	///   - columns: Names of the columns that together identify a row (the primary key).
	///   - values: The values those columns should have, in the same order.
	///   - context: A background context. Nothing is written to the store until you save.
	/// - Returns: The existing object, or a newly inserted one with every key column already set.
	static func findOrCreate(columns: [String], values: [Any], context: NSManagedObjectContext) -> Self {
		let request = NSFetchRequest<Self>()
		request.predicate = NSPredicate(format: columns.map({ " \($0) = %@ " }).joined(separator: " AND "), argumentArray: values)
		request.entity = entity()

		do {
			let objects: [Self] = try context.fetch(request)

			if let object = objects.first {
				return object
			}
		} catch {
			// TODO: fix
			// Log.log(level: .error, "findOrCreate context fetch failure: \(error.localizedDescription)")
		}

		let object = Self(context: context)

		if let object = object as? NSManagedObject {
			for (index, item) in columns.enumerated() {
				object.setValue(values[index], forKey: item)
			}
		}

		return object
	}

	/// Finds the object whose `column` equals `value`, inserting one with that value already set if
	/// there is none.
	///
	/// ```swift
	/// let author = Author.findOrCreate(column: "name", value: "Ursula K. Le Guin", context: context)
	/// ```
	///
	/// - Parameters:
	///   - column: The attribute that identifies the row.
	///   - value: The value that attribute should have.
	///   - context: A background context. Nothing is written to the store until you save.
	/// - Returns: The existing object, or a newly inserted one.
	static func findOrCreate(column: String, value: Any, context: NSManagedObjectContext) -> Self {
		return findOrCreate(columns: [column], values: [value], context: context)
	}

	/// Finds the object with this `id`, inserting one if there is none.
	///
	/// The call you will reach for most:
	///
	/// ```swift
	/// await store.backgroundContext.enqueue { context in
	///     let book = Book.findOrCreate(id: isbn, context: context)
	///     book.title = title
	///     context.flush()
	/// }
	/// ```
	///
	/// Call it twice in one unsaved context and you get the same object back both times — the fetch
	/// sees pending inserts, so no duplicate is created. Call it in two *different* contexts before
	/// either saves and you get two rows, because neither fetch can see the other's pending work.
	/// That is a property of Core Data, not of this method, and it is why all your writes should
	/// go through one background context.
	///
	/// > Important: Asserts in debug builds when handed a main-queue context. Upserts belong on
	/// > ``Container/backgroundContext``.
	///
	/// > Note: If two devices sharing a CloudKit store both create the same key, you will get two
	/// > rows and no error — `NSPersistentCloudKitContainer` does not support uniqueness
	/// > constraints, so the store cannot enforce what this method assumes. See
	/// > <doc:UnderTheHood#CloudKit-changes-what-unique-means> before relying on this for synced
	/// > data.
	///
	/// - Parameters:
	///   - id: The value of the `id` attribute.
	///   - context: A background context.
	/// - Returns: The existing object, or a newly inserted one with `id` already set.
	static func findOrCreate(id: String, context: NSManagedObjectContext) -> Self {
		assertContextIsWritable(context)

		return findOrCreate(columns: ["id"], values: [id], context: context)
	}
}
