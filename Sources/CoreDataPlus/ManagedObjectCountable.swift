import CoreData
import Foundation

public protocol ManagedObjectCountable where Self: NSFetchRequestResult {
    init(context: NSManagedObjectContext)

    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectCountable {
    static func countFor(_ predicate: NSPredicate?, using: ContextMode) -> Int {
        let context = contextModeToNSManagedObjectContext(using)
        
        let request = NSFetchRequest<Self>()
        request.predicate = predicate
        request.entity = entity()

        return (try? context.count(for: request)) ?? 0
    }
}
