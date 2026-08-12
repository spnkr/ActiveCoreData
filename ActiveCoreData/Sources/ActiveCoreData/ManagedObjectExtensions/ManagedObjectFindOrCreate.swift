import CoreData

public protocol ManagedObjectFindOrCreate where Self: NSFetchRequestResult {
	// Tip: You will probably want to define id, as part of the Identifiable protocol. If you add this as a column in your db, you get automatic conformance. If your NSManagedObject doesn't have an `id` property in the database, you'd implement this:
	// var id: String { get set }

	init(context: NSManagedObjectContext)
	static func entity() -> NSEntityDescription
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}


public extension ManagedObjectFindOrCreate {
	/// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.
	/// - Parameters:
	///   - column: Name of column that uniquely identifies a row (primary key).
	///   - value: Value of the primary key.
	///   - context: NSManagedObjectContext. Required.
	/// - Returns: An instance of the object
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

	static func findOrCreate(column: String, value: Any, context: NSManagedObjectContext) -> Self {
		return findOrCreate(columns: [column], values: [value], context: context)
	}

	static func findOrCreate(id: String, context: NSManagedObjectContext) -> Self {
		assertContextIsWritable(context)

		return findOrCreate(columns: ["id"], values: [id], context: context)
	}
}

