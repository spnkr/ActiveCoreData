import CoreData
import Foundation

public protocol ManagedObjectDeletable {
    /// Removes all objects from the context, and saves the context.
    static func destroyAll(context: NSManagedObjectContext)
    static func destroyAll(using: ContextMode)
}

public extension ManagedObjectDeletable {
    static func destroyAll(context: NSManagedObjectContext) {
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
    }
    
    static func destroyAll(using: ContextMode = .foreground) {
        let context = contextModeToNSManagedObjectContext(using)
        
        destroyAll(context: context)
    }
}
