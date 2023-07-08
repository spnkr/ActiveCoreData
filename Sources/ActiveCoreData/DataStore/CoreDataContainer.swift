
import Foundation
import CoreData
import NotificationCenter

public protocol CoreDataContainer {
    /// Thread safety is up to you
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
}
