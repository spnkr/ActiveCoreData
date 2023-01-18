import XCTest
@testable import CoreDataPlus
import CoreData

extension Author: ManagedObjectPlus { }
extension Book: ManagedObjectPlus { }
extension City: ManagedObjectPlus { }
extension Country: ManagedObjectPlus { }
extension Language: ManagedObjectPlus { }

func pred(_ string: String, _ args: Any?...) -> Predicate {
    Predicate(string, args)
}
