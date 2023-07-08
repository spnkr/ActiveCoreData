import CoreData
import Foundation

public protocol ManagedObjectFind where Self: NSFetchRequestResult {
    // Tip: You will probably want to define id, as part of the Identifiable protocol. If you add this as a column in your db, you get automatic conformance. If your NSManagedObject doesn't have an `id` property in the database, you'd implement this:
    // var id: String { get set }

    init(context: NSManagedObjectContext)
    static func entity() -> NSEntityDescription
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

public extension ManagedObjectFind {
    
    /// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.
    /// - Parameters:
    ///   - column: Name of column that uniquely identifies a row (primary key).
    ///   - value: Value of the primary key.
    ///   - context: NSManagedObjectContext to use
    /// - Returns: An instance of the object, or nil
    
    /// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, returns nil.
    /// - Parameters:
    ///   - column: Name of column that uniquely identifies a row (primary key).
    ///   - value: Value of the primary key.
    ///   - using: Optional. Specify `.foreground` for the main view context (operates on the main thread). Use `.background` to use a shared background context that automatically merges into the view context. Use `.custom(nsManagedObjectContext:)` to choose your own NSManagedObjectContext.
    /// - Returns: An instance of the object, or nil.
    static func find(column: String, value: Any, using: ContextMode = .foreground) -> Self? {
        let context = contextModeToNSManagedObjectContext(using)
        
        return find(column: column, value: value, context: context)
    }
    
    /// Same as `find(column: String, value: Any, using: ContextMode = .foreground)`, but allows you to pass your own `NSManagedObjectContext`.
    static func find(column: String, value: Any, context: NSManagedObjectContext) -> Self? {
        
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
            ActiveCoreDataLogger.shared.log("FindButDoNotCreateById context fetch failure: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Same as `find(column: String, value: Any, ...`, but with the column name set to `id`.
    static func find(id: String, using: ContextMode = .foreground) -> Self? {
        return find(column: "id", value: id, using: using)
    }
    
    /// Same as `find(column: String, value: Any, ...`, but with the column name set to `id`.
    static func find(id: String, context: NSManagedObjectContext) -> Self? {
        return find(column: "id", value: id, context: context)
    }
    
}
