import CoreData
import Foundation

public protocol ManagedObjectMatching where Self: NSFetchRequestResult {
	init(context: NSManagedObjectContext)

	static func entity() -> NSEntityDescription
	static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectMatching {

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
