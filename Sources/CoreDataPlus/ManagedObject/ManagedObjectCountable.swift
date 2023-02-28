import CoreData
import Foundation

public protocol ManagedObjectCountable where Self: NSFetchRequestResult {
    init(context: NSManagedObjectContext)

    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectCountable {
    
    /// Gets a count of objects matching the passed Predicate.
    /// - Parameters:
    ///   - predicate: Any valid ```NSPredicate```
    ///   - context: Any ``NSManagedObjectContext``
    /// - Returns: `Int`
    static func countFor(_ predicate: NSPredicate?, context: NSManagedObjectContext) -> Int {
        
        let request = NSFetchRequest<Self>()
        request.predicate = predicate
        request.entity = entity()

        return (try? context.count(for: request)) ?? 0
    }
    
    /// Gets a count of objects matching the passed Predicate.
    /// - Parameters:
    ///   - predicate: Any valid ```NSPredicate```
    ///   - using: A ```ContextMode``` specifying a foreground or background context. You need to provide these contexts once, using ``CoreDataPlus/CoreDataPlus/setup(viewContext:backgroundContext:logHandler:)``. If you don't want to provide contexts, use ``CoreDataPlus/ManagedObjectCountable/countFor(_:context:)`` instead.
    /// - Returns: Int
    static func countFor(_ predicate: NSPredicate?, using: ContextMode = .foreground) -> Int {
        let context = contextModeToNSManagedObjectContext(using)
        
        return countFor(predicate, context: context)
    }
}
