import Foundation
import CoreData


extension City {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<City> {
        return NSFetchRequest<City>(entityName: "City")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var country: Country?

}

extension City : Identifiable {

}
