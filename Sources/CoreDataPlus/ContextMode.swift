import Foundation
import CoreData

public enum ContextMode {
    case foreground
    case background
    case custom(nsManagedObjectContext: NSManagedObjectContext)
}
