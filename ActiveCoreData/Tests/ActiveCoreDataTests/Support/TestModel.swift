import CoreData
import Foundation

@testable import ActiveCoreData

// MARK: - Entities

/// An author. Every attribute is optional so that tests can create partially populated rows
/// without tripping Core Data validation on save.
final class TestAuthor: NSManagedObject {
	@NSManaged var id: String?
	@NSManaged var name: String?
	@NSManaged var born: Date?
	@NSManaged var uuid: UUID?
	@NSManaged var rating: Int64
	@NSManaged var active: Bool
	@NSManaged var books: Set<TestBook>
}

extension TestAuthor: ManagedObjectExtended {}

/// A book, related to at most one ``TestAuthor``.
final class TestBook: NSManagedObject {
	@NSManaged var id: String?
	@NSManaged var title: String?
	@NSManaged var pages: Int64
	@NSManaged var author: TestAuthor?
}

extension TestBook: ManagedObjectExtended {}

/// An entity with a required attribute, used to exercise the paths where Core Data refuses to save.
final class TestStrict: NSManagedObject {
	@NSManaged var name: String?
}

extension TestStrict: ManagedObjectExtended {}

// MARK: - Model

/// The managed object model the test suite runs against, built in code so the tests need no
/// compiled `.momd` resource and no Xcode project.
///
/// The model is created exactly once and shared by every ``TestStack``: Core Data supports one
/// model instance backing many coordinators, and a single instance keeps the class-to-entity
/// mapping that `NSManagedObject.entity()` relies on unambiguous.
enum TestModel {
	static let model: NSManagedObjectModel = makeModel()

	private static func makeModel() -> NSManagedObjectModel {
		let author = NSEntityDescription()
		author.name = "TestAuthor"
		author.managedObjectClassName = NSStringFromClass(TestAuthor.self)

		let book = NSEntityDescription()
		book.name = "TestBook"
		book.managedObjectClassName = NSStringFromClass(TestBook.self)

		let strict = NSEntityDescription()
		strict.name = "TestStrict"
		strict.managedObjectClassName = NSStringFromClass(TestStrict.self)

		let authorBooks = NSRelationshipDescription()
		authorBooks.name = "books"
		authorBooks.destinationEntity = book
		authorBooks.minCount = 0
		authorBooks.maxCount = 0 // 0 means "to many"
		authorBooks.deleteRule = .cascadeDeleteRule
		authorBooks.isOptional = true

		let bookAuthor = NSRelationshipDescription()
		bookAuthor.name = "author"
		bookAuthor.destinationEntity = author
		bookAuthor.minCount = 0
		bookAuthor.maxCount = 1
		bookAuthor.deleteRule = .nullifyDeleteRule
		bookAuthor.isOptional = true

		authorBooks.inverseRelationship = bookAuthor
		bookAuthor.inverseRelationship = authorBooks

		author.properties = [
			attribute("id", .string),
			attribute("name", .string),
			attribute("born", .date),
			attribute("uuid", .uuid),
			attribute("rating", .integer64, isOptional: false, defaultValue: 0),
			attribute("active", .boolean, isOptional: false, defaultValue: false),
			authorBooks,
		]

		book.properties = [
			attribute("id", .string),
			attribute("title", .string),
			attribute("pages", .integer64, isOptional: false, defaultValue: 0),
			bookAuthor,
		]

		strict.properties = [
			attribute("name", .string, isOptional: false),
		]

		let model = NSManagedObjectModel()
		model.entities = [author, book, strict]

		return model
	}

	private static func attribute(
		_ name: String,
		_ type: NSAttributeDescription.AttributeType,
		isOptional: Bool = true,
		defaultValue: Any? = nil
	) -> NSAttributeDescription {
		let attribute = NSAttributeDescription()
		attribute.name = name
		attribute.type = type
		attribute.isOptional = isOptional
		attribute.defaultValue = defaultValue

		return attribute
	}
}
