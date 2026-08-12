import Foundation
import CoreData

public extension NSPredicate {
	/// Create an NSPredicate more concisely. `Predicate("color = %@ and city = %@", "Blue", city)` instead of `NSPredicate(format:"color = %@ and city = %@", argumentArray:["Blue", city])`.
	convenience init(_ string: String, _ args: Any?...) {
		self.init(format: string, argumentArray: args as [Any])
	}
}
