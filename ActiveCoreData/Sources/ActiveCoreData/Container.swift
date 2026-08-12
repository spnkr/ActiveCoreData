import CoreData
import Foundation


public protocol Container {
	var viewContext: NSManagedObjectContext { get }
	var backgroundContext: NSManagedObjectContext { get }
}
