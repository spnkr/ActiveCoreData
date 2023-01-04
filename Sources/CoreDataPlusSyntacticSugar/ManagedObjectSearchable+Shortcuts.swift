import CoreData
import CoreDataPlus
import Foundation

public extension ManagedObjectSearchable {
    static func searchFor(_ predicate: NSPredicate?,
                          sortBy: [NSSortDescriptor]? = nil,
                          limit: Int? = nil,
                          using: ContextMode) -> [Self] {
        let context = contextModeToNSManagedObjectContext(using)
        
        return searchFor(predicate, sortBy: sortBy, limit: limit, context: context)
    }
}
