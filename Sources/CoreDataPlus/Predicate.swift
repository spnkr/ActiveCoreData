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
    
    /// A predicate that matches every object.
    /// Easier than having to write conditions for 'if the predicate is nil'.
    static func empty() -> NSPredicate {
        Predicate("1 = 1")
    }
}
