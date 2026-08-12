import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("ManagedObjectFind")
struct ManagedObjectFindTests {
	let stack = TestStack()

	@Test("Returns nil when the store is empty")
	func returnsNilWhenTheStoreIsEmpty() {
		#expect(stack.read { TestAuthor.find(id: "1", context: $0) } == nil)
	}

	@Test("Returns nil when nothing matches")
	func returnsNilWhenNothingMatches() {
		stack.insertAuthor(id: "1", name: "Ada")

		#expect(stack.read { TestAuthor.find(id: "2", context: $0) } == nil)
	}

	@Test("Finds a row by an arbitrary column")
	func findsARowByAnArbitraryColumn() {
		stack.insertAuthor(id: "1", name: "Ada")
		stack.insertAuthor(id: "2", name: "Grace")

		let found = stack.read { TestAuthor.find(column: "name", value: "Grace", context: $0) }

		#expect(found?.id == "2")
	}

	@Test("find(id:) is shorthand for the id column")
	func findByIDIsShorthandForTheIDColumn() {
		stack.insertAuthor(id: "abc", name: "Ada")

		let byID = stack.read { TestAuthor.find(id: "abc", context: $0) }
		let byColumn = stack.read { TestAuthor.find(column: "id", value: "abc", context: $0) }

		#expect(byID != nil)
		#expect(byID == byColumn)
	}

	@Test("Finds rows by a non-string column")
	func findsRowsByNonStringColumns() {
		let born = Date(timeIntervalSince1970: 1_000_000)
		let uuid = UUID()
		stack.insertAuthor(id: "1", name: "Ada", rating: 7, active: true, born: born, uuid: uuid)
		stack.insertAuthor(id: "2", name: "Grace", rating: 3, active: false)

		#expect(stack.read { TestAuthor.find(column: "rating", value: 7, context: $0) }?.id == "1")
		#expect(stack.read { TestAuthor.find(column: "active", value: true, context: $0) }?.id == "1")
		#expect(stack.read { TestAuthor.find(column: "born", value: born, context: $0) }?.id == "1")
		#expect(stack.read { TestAuthor.find(column: "uuid", value: uuid, context: $0) }?.id == "1")
	}

	@Test("Returns a match when several rows qualify")
	func returnsAMatchWhenSeveralRowsQualify() {
		stack.insertAuthor(id: "1", name: "Ada")
		stack.insertAuthor(id: "2", name: "Ada")

		let found = stack.read { TestAuthor.find(column: "name", value: "Ada", context: $0) }

		#expect(found?.name == "Ada")
	}

	@Test("Only searches its own entity")
	func onlySearchesItsOwnEntity() {
		stack.insertAuthor(id: "shared", name: "Ada")
		stack.insertBook(id: "shared", title: "Notes")

		#expect(stack.read { TestAuthor.find(id: "shared", context: $0) }?.name == "Ada")
		#expect(stack.read { TestBook.find(id: "shared", context: $0) }?.title == "Notes")
	}

	@Test("Sees unsaved inserts made in the same context")
	func seesUnsavedInsertsInTheSameContext() {
		stack.write { context in
			let author = TestAuthor(context: context)
			author.id = "pending"

			#expect(TestAuthor.find(id: "pending", context: context) === author)

			context.rollback()
		}
	}

	@Test("Does not see unsaved inserts made in another context")
	func doesNotSeeUnsavedInsertsFromAnotherContext() {
		let other = stack.makeBackgroundContext()
		other.performAndWait {
			let author = TestAuthor(context: other)
			author.id = "pending"
		}

		#expect(stack.read { TestAuthor.find(id: "pending", context: $0) } == nil)
	}

	@Test("Returns the object bound to the context it was passed")
	func returnsAnObjectBoundToThePassedContext() {
		stack.insertAuthor(id: "1", name: "Ada")

		let viewObjectID = stack.read { context -> NSManagedObjectID? in
			let author = TestAuthor.find(id: "1", context: context)
			#expect(author?.managedObjectContext === context)

			return author?.objectID
		}

		let backgroundObjectID = stack.write { context -> NSManagedObjectID? in
			let author = TestAuthor.find(id: "1", context: context)
			#expect(author?.managedObjectContext === context)

			return author?.objectID
		}

		#expect(viewObjectID != nil)
		#expect(viewObjectID == backgroundObjectID)
	}

	@Test("Finds a row whose value contains predicate metacharacters")
	func findsAValueContainingMetacharacters() {
		stack.insertAuthor(id: "1", name: #"100% "real" %@"#)

		let found = stack.read { TestAuthor.find(column: "name", value: #"100% "real" %@"#, context: $0) }

		#expect(found?.id == "1")
	}
}
