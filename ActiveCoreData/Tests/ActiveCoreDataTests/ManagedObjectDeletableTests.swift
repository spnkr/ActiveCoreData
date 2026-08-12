import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("ManagedObjectDeletable")
struct ManagedObjectDeletableTests {
	let stack = TestStack()

	@Test("Deletes every row and reports how many")
	func deletesEveryRowAndReportsHowMany() {
		stack.insertAuthor(id: "1")
		stack.insertAuthor(id: "2")
		stack.insertAuthor(id: "3")

		let deleted = stack.write { context -> Int in
			let count = TestAuthor.destroyAll(matching: nil, context: context)
			try? context.save()

			return count
		}

		#expect(deleted == 3)
		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
	}

	@Test("Deletes only the rows matching the predicate")
	func deletesOnlyTheMatchingRows() {
		stack.insertAuthor(id: "1", rating: 7)
		stack.insertAuthor(id: "2", rating: 3)
		stack.insertAuthor(id: "3", rating: 9)

		let deleted = stack.write { context -> Int in
			let count = TestAuthor.destroyAll(matching: NSPredicate("rating > %@", 5), context: context)
			try? context.save()

			return count
		}

		#expect(deleted == 2)
		#expect(stack.read { TestAuthor.matching(nil, context: $0) }.map(\.id) == ["2"])
	}

	@Test("Reports zero when the store is empty")
	func reportsZeroWhenTheStoreIsEmpty() {
		#expect(stack.write { TestAuthor.destroyAll(matching: nil, context: $0) } == 0)
	}

	@Test("Reports zero when nothing matches")
	func reportsZeroWhenNothingMatches() {
		stack.insertAuthor(id: "1", name: "Ada")

		let deleted = stack.write { TestAuthor.destroyAll(matching: NSPredicate("name = %@", "Nobody"), context: $0) }

		#expect(deleted == 0)
		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 1)
	}

	@Test("The convenience overload deletes everything")
	func theConvenienceOverloadDeletesEverything() {
		stack.insertAuthor(id: "1")
		stack.insertAuthor(id: "2")

		stack.write { context in
			TestAuthor.destroyAll(context: context)
			try? context.save()
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
	}

	@Test("Marks rows deleted before the context is saved")
	func marksRowsDeletedBeforeSaving() {
		stack.insertAuthor(id: "1")

		stack.write { context in
			let author = TestAuthor.find(id: "1", context: context)

			#expect(TestAuthor.destroyAll(matching: nil, context: context) == 1)
			#expect(author?.isDeleted == true)
		}

		// Nothing was saved, so the row is still in the store.
		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 1)
	}

	@Test("Only deletes rows of its own entity")
	func onlyDeletesRowsOfItsOwnEntity() {
		stack.insertAuthor(id: "1")
		stack.insertBook(id: "2")

		stack.write { context in
			TestAuthor.destroyAll(context: context)
			try? context.save()
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
		#expect(stack.read { TestBook.countFor(nil, context: $0) } == 1)
	}

	@Test("Honours the model's delete rules")
	func honoursTheModelsDeleteRules() {
		stack.insertAuthor(id: "1", name: "Ada")
		stack.insertBook(id: "b1", title: "Notes", authorID: "1")
		stack.insertBook(id: "b2", title: "Other")

		stack.write { context in
			// TestAuthor.books cascades, so deleting the author takes its books with it.
			_ = TestAuthor.destroyAll(matching: NSPredicate("id = %@", "1"), context: context)
			try? context.save()
		}

		#expect(stack.read { TestBook.matching(nil, context: $0) }.map(\.id) == ["b2"])
	}

	@Test("Deletes rows inserted but not yet saved in the same context")
	func deletesUnsavedInsertsInTheSameContext() {
		stack.write { context in
			let author = TestAuthor(context: context)
			author.id = "pending"

			#expect(TestAuthor.destroyAll(matching: nil, context: context) == 1)

			try? context.save()
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
	}

	@Test("Deleting twice reports zero the second time")
	func deletingTwiceReportsZeroTheSecondTime() {
		stack.insertAuthor(id: "1")

		stack.write { context in
			#expect(TestAuthor.destroyAll(matching: nil, context: context) == 1)
			try? context.save()
			#expect(TestAuthor.destroyAll(matching: nil, context: context) == 0)
		}
	}
}
