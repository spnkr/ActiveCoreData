import Foundation
import CoreData

public protocol FindButDoNotCreatableById where Self: NSFetchRequestResult {
    var id: String { get set }
    
    init(context: NSManagedObjectContext)
    
    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension FindButDoNotCreatableById {
    static func findButDoNotCreate(id: String, context: NSManagedObjectContext) -> Self? {
        let request = NSFetchRequest<Self>()
        request.predicate = NSPredicate("id = %@", id)
        request.fetchLimit = 1
        request.entity = entity()

        do {
            let objects: [Self] = try context.fetch(request)

            if let object = objects.first {
                return object
            }
        } catch {
            CoreDataLogger.shared.log("FindButDoNotCreatableById context fetch failure: \(error.localizedDescription)")
        }
        
        return nil
    }
}

public protocol FindOrCreatableBy where Self: NSFetchRequestResult {
    // suggested: use id. add this as a column in your db. reason: you are probably conforming to Identifiable in your NSManagedObject subclass.
    // var id: String { get set }
    
    init(context: NSManagedObjectContext)
    
    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension FindOrCreatableBy {
    static func findOrCreate(id: String, context: NSManagedObjectContext) -> Self {
        
        // TODO: log developer errors as warnings:
        // dump(entity().attributesByName["id"]!.type == NSAttributeDescription.AttributeType.string)
        // entity().attributesByName["idx"]?.type
        
        findOrCreate(column: "id", value: id, context: context)
    }
    
    static func findOrCreate(column: String, value: Any, context: NSManagedObjectContext) -> Self {
        let request = NSFetchRequest<Self>()
        request.predicate = Predicate("\(column) = %@", value)
        request.entity = entity()

        do {
            let objects: [Self] = try context.fetch(request)

            if let object = objects.first {
                return object
            }
        } catch {
            CoreDataLogger.shared.log("findOrCreate context fetch failure: \(error.localizedDescription)")
        }

        let object = Self(context: context)
        
        if let object = object as? NSManagedObject {
            object.setValue(value, forKey: column)
        }
        
        return object
    }
    
    
    static func findButDoNotCreate(id: String, context: NSManagedObjectContext) -> Self? {
        
        // TODO: log developer errors as warnings:
        // dump(entity().attributesByName["id"]!.type == NSAttributeDescription.AttributeType.string)
        // entity().attributesByName["idx"]?.type
        
        findButDoNotCreate(column: "id", value: id, context: context)
    }
    
    static func findButDoNotCreate(column: String, value: Any, context: NSManagedObjectContext) -> Self? {
        let request = NSFetchRequest<Self>()
        request.predicate = Predicate("\(column) = %@", value)
        request.fetchLimit = 1
        request.entity = entity()

        do {
            let objects: [Self] = try context.fetch(request)

            if let object = objects.first {
                return object
            }
        } catch {
            CoreDataLogger.shared.log("FindButDoNotCreatableById context fetch failure: \(error.localizedDescription)")
        }
        
        return nil
    }
}
