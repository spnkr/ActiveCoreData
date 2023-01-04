import CoreData
import Foundation
import CoreDataPlus

public extension ManagedObjectFindOrCreateBy {
    public static func findOrCreate(id: String, using: ContextMode = .foreground) -> Self {
        let context = contextModeToNSManagedObjectContext(using)
        
        return findOrCreate(column: "id", value: id, context: context)
    }
    
    /// Finds an instance of the NSManagedObject that has a column (property) matching the passed value. If it doesn't exist in the database, creates one, and returns it.
    /// - Parameters:
    ///   - column: Name of column that uniquely identifies a row (primary key).
    ///   - value: Value of the primary key.
    ///   - using: Optional. Specify `.foreground` for the main view context (operates on the main thread). Use `.background` to use a shared background context that automatically merges into the view context. Use `.custom(nsManagedObjectContext:)` to choose your own NSManagedObjectContext.
    /// - Returns: An instance of the object
    public static func findOrCreate(column: String, value: Any, using: ContextMode = .foreground) -> Self {
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

public class Hahaha {
    
    /// kjnsfdkjfsdjkfsd
    public func yo() {
        print("1")
    }
}




internal func raiseError(_ e: InternalError) {
    fatalError(e.localizedDescription)
}

internal func contextModeToNSManagedObjectContext(_ using: ContextMode) -> NSManagedObjectContext {
    switch using {
    case .foreground:
        return CoreDataPlus.shared.viewContext
    case .background:
        guard let c = CoreDataPlus.shared.backgroundContext else {
            raiseError(.noBackground)
            return CoreDataPlus.shared.viewContext
        }
        return c
    case .custom(let context):
        return context
    }
}



internal enum InternalError: Error, LocalizedError {
    case setupAlreadyCalled
    case setupNotCalled
    
    case noBackground
    
    public var errorDescription: String? {
        switch self {
        case .noBackground:
            return "No background context specified. Use .setup with a backgroundContext: parameter."
        default:
            return "\(self)"
        }
    }
}
