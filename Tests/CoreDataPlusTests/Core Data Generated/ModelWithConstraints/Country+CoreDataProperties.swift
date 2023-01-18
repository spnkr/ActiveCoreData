import Foundation
import CoreData


extension Country {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Country> {
        return NSFetchRequest<Country>(entityName: "Country")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var cities: NSSet?
    @NSManaged public var languages: NSSet?

}

// MARK: Generated accessors for cities
extension Country {

    @objc(addCitiesObject:)
    @NSManaged public func addToCities(_ value: City)

    @objc(removeCitiesObject:)
    @NSManaged public func removeFromCities(_ value: City)

    @objc(addCities:)
    @NSManaged public func addToCities(_ values: NSSet)

    @objc(removeCities:)
    @NSManaged public func removeFromCities(_ values: NSSet)

}

// MARK: Generated accessors for languages
extension Country {

    @objc(addLanguagesObject:)
    @NSManaged public func addToLanguages(_ value: Language)

    @objc(removeLanguagesObject:)
    @NSManaged public func removeFromLanguages(_ value: Language)

    @objc(addLanguages:)
    @NSManaged public func addToLanguages(_ values: NSSet)

    @objc(removeLanguages:)
    @NSManaged public func removeFromLanguages(_ values: NSSet)

}

extension Country : Identifiable {

}
