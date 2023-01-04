import CoreData
import Foundation
import CoreDataPlus

public extension ManagedObjectDeletable {
    
    static func destroyAll(using: ContextMode = .foreground, saveAfter: Bool = true, wrapInContextPerformBlock: Bool = true) {
        let context = contextModeToNSManagedObjectContext(using)
        
        destroyAll(context: context, saveAfter: saveAfter, wrapInContextPerformBlock: wrapInContextPerformBlock)
    }
}
