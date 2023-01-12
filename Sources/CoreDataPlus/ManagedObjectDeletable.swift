import CoreData
import Foundation

public protocol ManagedObjectDeletable {
    /// Removes all objects from the context, and saves the context.
    static func destroyAll(context: NSManagedObjectContext, saveAfter: Bool, wrapInContextPerformBlock: Bool)
}

public extension ManagedObjectDeletable {
    
    
    /// jkdfjdfjns
    /// - Parameters:
    ///   - context: one
    ///   - saveAfter: two
    ///   - wrapInContextPerformBlock: three
    static func destroyAll(context: NSManagedObjectContext, saveAfter: Bool = true, wrapInContextPerformBlock: Bool = true) {
        if wrapInContextPerformBlock {
            context.perform {
                _destroyAll(context: context, saveAfter: saveAfter)
            }
        } else {
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
    
    /// abc
    /// - Parameters:
    ///   - using: ok
    ///   - saveAfter: yes
    ///   - wrapInContextPerformBlock: Nope
    static func destroyAll(using: ContextMode = .foreground, saveAfter: Bool = true, wrapInContextPerformBlock: Bool = true) {
        let context = contextModeToNSManagedObjectContext(using)
        
        destroyAll(context: context, saveAfter: saveAfter, wrapInContextPerformBlock: wrapInContextPerformBlock)
    }
}
