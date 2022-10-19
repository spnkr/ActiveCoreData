import Foundation
import CoreData

public protocol CoreDataSearchable where Self: NSFetchRequestResult {
    init(context: NSManagedObjectContext)
    
    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension CoreDataSearchable {
    static func searchFor(_ predicate: NSPredicate?, context:NSManagedObjectContext) -> [Self] {
        let request = NSFetchRequest<Self>()
        request.predicate = predicate
        request.entity = self.entity()
        return (try? context.fetch(request)) ?? []
    }
}
