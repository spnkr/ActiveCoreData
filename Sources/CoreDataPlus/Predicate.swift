import Foundation
import CoreData

public typealias Predicate = NSPredicate

public extension NSPredicate {
    /// Create an NSPredicate.
    ///
    /// Before:
    ///
    ///     NSPredicate(format:"color = %@ and city = %@",
    ///                 argumentArray:["Blue", city])
    ///
    /// After:
    ///
    ///     Predicate("color = %@ and city = %@", "Blue", city)
    ///
    convenience init(_ string: String, _ args: Any?...) {
        self.init(format:string, argumentArray:args as [Any])
    }
}

public extension NSSortDescriptor {
    convenience init<Root, Value>(_ keyPath: KeyPath<Root, Value>) {
        self.init(keyPath: keyPath, ascending: true)
    }
}
