import Foundation
import CoreData


public protocol CoreDataDeletable {
  static func destroyAll(context: NSManagedObjectContext)
}

public extension CoreDataDeletable {
    static func destroyAll(context: NSManagedObjectContext) {
        context.perform {
            let request = (self as! NSManagedObject.Type).fetchRequest()
            request.entity = (self as! NSManagedObject.Type).entity()
            
        var objects:[Any]
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
    
    static func destroyAllNoWrap(context: NSManagedObjectContext) {
        let request = (self as! NSManagedObject.Type).fetchRequest()
        request.entity = (self as! NSManagedObject.Type).entity()
        
        var objects:[Any]
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
