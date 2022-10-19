import CoreData
import Foundation

public protocol ManagedObjectSearchable where Self: NSFetchRequestResult {
    init(context: NSManagedObjectContext)

    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectSearchable {
    static func searchFor(_ predicate: NSPredicate?, context: NSManagedObjectContext) -> [Self] {
        let request = NSFetchRequest<Self>()
        request.predicate = predicate
        request.entity = entity()
        return (try? context.fetch(request)) ?? []
    }
}
