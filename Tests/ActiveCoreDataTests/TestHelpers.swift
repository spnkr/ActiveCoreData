import XCTest
@testable import ActiveCoreData
import CoreData

extension Author: ManagedObjectPlus { }
extension Book: ManagedObjectPlus { }
extension City: ManagedObjectPlus { }
extension Country: ManagedObjectPlus { }
extension Language: ManagedObjectPlus { }

func pred(_ string: String, _ args: Any?...) -> NSPredicate {
    NSPredicate(string, args)
}
