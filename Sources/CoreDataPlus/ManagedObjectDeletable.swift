import CoreData
import Foundation

public protocol ManagedObjectDeletable {
    /// Removes all objects from the context, and saves the context.
    static func destroyAll(using: ContextMode, saveAfter: Bool, wrapInContextPerformBlock: Bool)
}

public extension ManagedObjectDeletable {
    
    static func destroyAll(using: ContextMode = .foreground, saveAfter: Bool = true, wrapInContextPerformBlock: Bool = true) {
        let context = contextModeToNSManagedObjectContext(using)
        
        context.perform {
            _destroyAll(context: context, saveAfter: saveAfter)
        }
    }
    
    private static func _destroyAll(context: NSManagedObjectContext, saveAfter: Bool = true) {
        let request = (self as! NSManagedObject.Type).fetchRequest()
        request.entity = (self as! NSManagedObject.Type).entity()

        var objects: [Any]
        do {
            objects = try context.fetch(request)
        } catch {
            objects = []
        }
        for obj in objects {
            context.delete(obj as! NSManagedObject)
        }

        try! context.save()
    }
}
