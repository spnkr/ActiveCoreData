import CoreData
import Foundation

public protocol ManagedObjectDeletable {
    /// Removes all objects from the context
    static func destroyAll(context: NSManagedObjectContext)
    /// Removes all objects from the foreground or background context
    static func destroyAll(using: ContextMode)
    /// Removes all objects matching the predicate from the context
    static func destroyAll(matching: Predicate?, context: NSManagedObjectContext)
    /// Removes all objects matching the predicate from the foreground or background context
    static func destroyAll(matching: Predicate?, using: ContextMode)
}

public extension ManagedObjectDeletable {
    static func destroyAll(context: NSManagedObjectContext) {
        destroyAll(matching: nil, context: context)
    }
    static func destroyAll(using: ContextMode = .foreground) {
        destroyAll(context: contextModeToNSManagedObjectContext(using))
    }
    static func destroyAll(matching: Predicate? = nil, using: ContextMode = .foreground) {
        destroyAll(matching: matching, context: contextModeToNSManagedObjectContext(using))
    }
    static func destroyAll(matching: Predicate? = nil, context: NSManagedObjectContext) {
        let request = (self as! NSManagedObject.Type).fetchRequest()
        request.entity = (self as! NSManagedObject.Type).entity()
        
        request.predicate = matching
        
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
}



