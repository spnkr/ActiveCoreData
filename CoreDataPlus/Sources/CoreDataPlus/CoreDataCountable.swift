import Foundation
import CoreData

public protocol CoreDataCountable where Self: NSFetchRequestResult {
    init(context: NSManagedObjectContext)
    
    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension CoreDataCountable {
    static func countFor(_ predicate: NSPredicate?, context:NSManagedObjectContext) -> Int {
        
        CoreDataLogger.shared.log("counting \(predicate.debugDescription)")
        
        let request = NSFetchRequest<Self>()
        request.predicate = predicate
        request.entity = self.entity()
        
        return (try? context.count(for: request)) ?? 0
    }
}
