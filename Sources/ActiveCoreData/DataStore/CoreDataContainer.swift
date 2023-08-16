
import Foundation
import CoreData

public protocol CoreDataContainer {
    /// ActiveCoreDataStore is thread safe. If you implement your own data store, be sure to consider thread safety.
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
}
