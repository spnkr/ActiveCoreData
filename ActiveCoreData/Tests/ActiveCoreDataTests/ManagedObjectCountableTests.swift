import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("ManagedObjectCountable")
struct ManagedObjectCountableTests {
	let stack = TestStack()

	@Test("Counts zero for an empty store")
	func countsZeroForAnEmptyStore() {
		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
	}

	@Test("Counts every row for a nil predicate")
	func countsEveryRowForANilPredicate() {
		stack.insertAuthor(id: "1")
		stack.insertAuthor(id: "2")

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 2)
	}

	@Test("Counts only the matching rows")
	func countsOnlyTheMatchingRows() {
		stack.insertAuthor(id: "1", rating: 7)
		stack.insertAuthor(id: "2", rating: 3)
		stack.insertAuthor(id: "3", rating: 9)

		#expect(stack.read { TestAuthor.countFor(NSPredicate("rating > %@", 5), context: $0) } == 2)
	}

	@Test("Counts zero when nothing matches")
	func countsZeroWhenNothingMatches() {
		stack.insertAuthor(id: "1", name: "Ada")

		#expect(stack.read { TestAuthor.countFor(NSPredicate("name = %@", "Nobody"), context: $0) } == 0)
	}

	@Test("Counts only its own entity")
	func countsOnlyItsOwnEntity() {
		stack.insertAuthor(id: "1")
		stack.insertBook(id: "2")
		stack.insertBook(id: "3")

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 1)
		#expect(stack.read { TestBook.countFor(nil, context: $0) } == 2)
	}

	@Test("Includes unsaved inserts made in the same context")
	func includesUnsavedInsertsInTheSameContext() {
		stack.insertAuthor(id: "1")

		stack.write { context in
			_ = TestAuthor(context: context)

			#expect(TestAuthor.countFor(nil, context: context) == 2)

			context.rollback()
		}
	}

	@Test("Excludes rows deleted in the same context")
	func excludesRowsDeletedInTheSameContext() {
		stack.insertAuthor(id: "1")
		stack.insertAuthor(id: "2")

		stack.write { context in
			guard let author = TestAuthor.find(id: "1", context: context) else {
				Issue.record("expected to find the author")
				return
			}

			context.delete(author)

			#expect(TestAuthor.countFor(nil, context: context) == 1)
		}
	}

	@Test("Reflects rows removed by another context once they are saved")
	func reflectsRowsRemovedByAnotherContext() {
		stack.insertAuthor(id: "1")
		stack.insertAuthor(id: "2")

		stack.write { context in
			_ = TestAuthor.destroyAll(matching: NSPredicate("id = %@", "1"), context: context)
			try? context.save()
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 1)
	}
}
