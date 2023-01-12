import CoreData
import Foundation

public protocol ManagedObjectSearchable where Self: NSFetchRequestResult {
    init(context: NSManagedObjectContext)

    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectSearchable {
    static func searchFor(_ predicate: NSPredicate?,
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
    
    static func searchFor(_ predicate: NSPredicate?,
                          sortBy: [NSSortDescriptor]? = nil,
                          limit: Int? = nil,
                          using: ContextMode) -> [Self] {
        let context = contextModeToNSManagedObjectContext(using)
        
        return searchFor(predicate, sortBy: sortBy, limit: limit, context: context)
    }
}
