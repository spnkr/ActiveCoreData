import CoreData
import Foundation

public protocol ManagedObjectFindOrCreateBy where Self: NSFetchRequestResult {
    // suggested: use id. add this as a column in your db. reason: you are probably conforming to Identifiable in your NSManagedObject subclass.
    // var id: String { get set }

    init(context: NSManagedObjectContext)

    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectFindOrCreateBy {
    // MARK: - Using NSManagedObjectContext
    /// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.
    /// - Parameters:
    ///   - column: Name of column that uniquely identifies a row (primary key).
    ///   - value: Value of the primary key.
    ///   - context: NSManagedObjectContext to use
    /// - Returns: An instance of the object
    static func findOrCreate(id: String, context: NSManagedObjectContext) -> Self {
        
        // if entity().attributesByName["id"]?.type != NSAttributeDescription.AttributeType.string {
        //     fatalError("The column id must be of type String. Set this in your xcdatamodel. id is currently of type \(entity().attributesByName["name"]?.attributeValueClassName ?? "<unknown>")")
        // }
        
        return findOrCreate(column: "id", value: id, context: context)
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
            CoreDataPlusLogger.shared.log("findOrCreate context fetch failure: \(error.localizedDescription)")
        }
        
        let object = Self(context: context)
        
        if let object = object as? NSManagedObject {
            object.setValue(value, forKey: column)
        }
        
        return object
    }
    
    static func findButDoNotCreate(id: String, context: NSManagedObjectContext) -> Self? {
        if entity().attributesByName["id"]?.type != NSAttributeDescription.AttributeType.string {
            fatalError("The column id must be of type String. Set this in your xcdatamodel. id is currently of type \(entity().attributesByName["name"]?.attributeValueClassName ?? "<unknown>")")
        }
        
        return findButDoNotCreate(column: "id", value: id, context: context)
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
            CoreDataPlusLogger.shared.log("FindButDoNotCreateById context fetch failure: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Using ContextMode
    static func findOrCreate(id: String, using: ContextMode = .foreground) -> Self {
        let context = contextModeToNSManagedObjectContext(using)
        
        return findOrCreate(column: "id", value: id, context: context)
    }
    
    /// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.
    /// - Parameters:
    ///   - column: Name of column that uniquely identifies a row (primary key).
    ///   - value: Value of the primary key.
    ///   - using: Optional. Specify `.foreground` for the main view context (operates on the main thread). Use `.background` to use a shared background context that automatically merges into the view context. Use `.custom(nsManagedObjectContext:)` to choose your own NSManagedObjectContext.
    /// - Returns: An instance of the object
    static func findOrCreate(column: String, value: Any, using: ContextMode = .foreground) -> Self {
        let context = contextModeToNSManagedObjectContext(using)
        
        return findOrCreate(column: column, value: value, context: context)
    }
    
    static func findButDoNotCreate(id: String, using: ContextMode = .foreground) -> Self? {
        return findButDoNotCreate(column: "id", value: id, using: using)
    }
    
    static func findButDoNotCreate(column: String, value: Any, using: ContextMode = .foreground) -> Self? {
        let context = contextModeToNSManagedObjectContext(using)
        
        return findButDoNotCreate(column: column, value: value, context: context)
    }
}
