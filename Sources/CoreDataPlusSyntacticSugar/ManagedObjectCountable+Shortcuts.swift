import CoreData
import CoreDataPlus
import Foundation

public extension ManagedObjectCountable {
    /// fdskjksfdj
    /// - Parameters:
    ///   - predicate: Predicate
    ///   - using: `ContextMode`
    /// - Returns: Int
    ///
    /// Experiment:
    /// Hello
    static func countFor(_ predicate: NSPredicate?, using: ContextMode) -> Int {
        let context = contextModeToNSManagedObjectContext(using)
        
        return countFor(predicate, context: context)
    }
}
