import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("ManagedObjectFindOrCreate")
struct ManagedObjectFindOrCreateTests {
	let stack = TestStack()

	@Test("Creates a row when none matches, setting the key column")
	func createsARowWhenNoneMatches() {
		stack.write { context in
			let author = TestAuthor.findOrCreate(column: "name", value: "Ada", context: context)

			#expect(author.name == "Ada")
			#expect(author.isInserted)
			#expect(author.managedObjectContext === context)
			#expect(TestAuthor.countFor(nil, context: context) == 1)
		}
	}

	@Test("Returns the existing row instead of creating a duplicate")
	func returnsTheExistingRow() {
		stack.insertAuthor(id: "1", name: "Ada")

		stack.write { context in
			let author = TestAuthor.findOrCreate(column: "name", value: "Ada", context: context)

			#expect(author.id == "1")
			#expect(author.isInserted == false)
			#expect(TestAuthor.countFor(nil, context: context) == 1)
		}
	}

	@Test("findOrCreate(id:) is shorthand for the id column")
	func findOrCreateByIDIsShorthandForTheIDColumn() {
		stack.write { context in
			let author = TestAuthor.findOrCreate(id: "abc", context: context)

			#expect(author.id == "abc")
			#expect(author.isInserted)
		}
	}

	@Test("findOrCreate(id:) returns the existing row")
	func findOrCreateByIDReturnsTheExistingRow() {
		stack.insertAuthor(id: "abc", name: "Ada")

		stack.write { context in
			let author = TestAuthor.findOrCreate(id: "abc", context: context)

			#expect(author.name == "Ada")
			#expect(author.isInserted == false)
			#expect(TestAuthor.countFor(nil, context: context) == 1)
		}
	}

	@Test("Calling it twice in the same unsaved context returns the same object")
	func isIdempotentWithinAnUnsavedContext() {
		stack.write { context in
			let first = TestAuthor.findOrCreate(id: "abc", context: context)
			let second = TestAuthor.findOrCreate(id: "abc", context: context)

			#expect(first === second)
			#expect(TestAuthor.countFor(nil, context: context) == 1)
		}
	}

	@Test("Finds the row it created once it has been saved")
	func findsWhatItCreatedAfterSaving() {
		stack.write { context in
			TestAuthor.findOrCreate(id: "abc", context: context).name = "Ada"
			try? context.save()
		}

		stack.write { context in
			let author = TestAuthor.findOrCreate(id: "abc", context: context)

			#expect(author.name == "Ada")
			#expect(author.isInserted == false)
		}
	}

	@Test("Matches on every column when given several")
	func matchesOnEveryColumnWhenGivenSeveral() {
		stack.insertAuthor(id: "1", name: "Ada", rating: 7)

		stack.write { context in
			let author = TestAuthor.findOrCreate(columns: ["name", "rating"], values: ["Ada", 7], context: context)

			#expect(author.id == "1")
			#expect(author.isInserted == false)
		}
	}

	@Test("Creates a row when only some of the columns match")
	func createsARowWhenOnlySomeColumnsMatch() {
		stack.insertAuthor(id: "1", name: "Ada", rating: 7)

		stack.write { context in
			let author = TestAuthor.findOrCreate(columns: ["name", "rating"], values: ["Ada", 3], context: context)

			#expect(author.id == nil)
			#expect(author.isInserted)
			#expect(TestAuthor.countFor(nil, context: context) == 2)
		}
	}

	@Test("Sets every key column on a row it creates")
	func setsEveryKeyColumnOnANewRow() {
		let born = Date(timeIntervalSince1970: 1_000_000)

		stack.write { context in
			let author = TestAuthor.findOrCreate(
				columns: ["id", "name", "rating", "active", "born"],
				values: ["1", "Ada", 7, true, born],
				context: context
			)

			#expect(author.id == "1")
			#expect(author.name == "Ada")
			#expect(author.rating == 7)
			#expect(author.active)
			#expect(author.born == born)
		}
	}

	@Test("Does not persist the new row until the context is saved")
	func doesNotPersistUntilSaved() {
		stack.write { context in
			_ = TestAuthor.findOrCreate(id: "abc", context: context)
		}

		#expect(stack.read { TestAuthor.find(id: "abc", context: $0) } == nil)

		stack.write { context in
			try? context.save()
		}

		#expect(stack.read { TestAuthor.find(id: "abc", context: $0) } != nil)
	}

	@Test("Keeps entities separate")
	func keepsEntitiesSeparate() {
		stack.write { context in
			let author = TestAuthor.findOrCreate(id: "shared", context: context)
			let book = TestBook.findOrCreate(id: "shared", context: context)

			#expect(author.entity.name == "TestAuthor")
			#expect(book.entity.name == "TestBook")
			#expect(TestAuthor.countFor(nil, context: context) == 1)
			#expect(TestBook.countFor(nil, context: context) == 1)
		}
	}
}
