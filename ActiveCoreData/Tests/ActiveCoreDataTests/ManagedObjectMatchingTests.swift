import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("ManagedObjectMatching")
struct ManagedObjectMatchingTests {
	let stack = TestStack()

	private func insertAuthors() {
		stack.insertAuthor(id: "1", name: "Ada", rating: 7, active: true)
		stack.insertAuthor(id: "2", name: "Grace", rating: 3, active: true)
		stack.insertAuthor(id: "3", name: "Barbara", rating: 9, active: false)
	}

	// MARK: - Predicate overload

	@Test("Returns everything for a nil predicate")
	func returnsEverythingForANilPredicate() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching(nil, context: $0) }

		#expect(matches.count == 3)
	}

	@Test("Returns an empty array when the store is empty")
	func returnsAnEmptyArrayWhenTheStoreIsEmpty() {
		#expect(stack.read { TestAuthor.matching(nil, context: $0) }.isEmpty)
	}

	@Test("Returns an empty array when nothing matches")
	func returnsAnEmptyArrayWhenNothingMatches() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching(NSPredicate("name = %@", "Nobody"), context: $0) }

		#expect(matches.isEmpty)
	}

	@Test("Filters by predicate")
	func filtersByPredicate() {
		insertAuthors()

		let matches = stack.read {
			TestAuthor.matching(
				NSPredicate("rating > %@", 5),
				sortBy: [NSSortDescriptor(key: "id", ascending: true)],
				context: $0
			)
		}

		#expect(matches.map(\.id) == ["1", "3"])
	}

	@Test("Sorts ascending")
	func sortsAscending() {
		insertAuthors()

		let matches = stack.read {
			TestAuthor.matching(nil, sortBy: [NSSortDescriptor(key: "name", ascending: true)], context: $0)
		}

		#expect(matches.map(\.name) == ["Ada", "Barbara", "Grace"])
	}

	@Test("Sorts descending")
	func sortsDescending() {
		insertAuthors()

		let matches = stack.read {
			TestAuthor.matching(nil, sortBy: [NSSortDescriptor(key: "rating", ascending: false)], context: $0)
		}

		#expect(matches.map(\.rating) == [9, 7, 3])
	}

	@Test("Applies several sort descriptors in order")
	func appliesSeveralSortDescriptorsInOrder() {
		stack.insertAuthor(id: "1", name: "Ada", rating: 1)
		stack.insertAuthor(id: "2", name: "Ada", rating: 2)
		stack.insertAuthor(id: "3", name: "Grace", rating: 1)

		let matches = stack.read {
			TestAuthor.matching(
				nil,
				sortBy: [
					NSSortDescriptor(key: "name", ascending: true),
					NSSortDescriptor(key: "rating", ascending: false),
				],
				context: $0
			)
		}

		#expect(matches.map(\.id) == ["2", "1", "3"])
	}

	@Test("Applies a fetch limit")
	func appliesAFetchLimit() {
		insertAuthors()

		let matches = stack.read {
			TestAuthor.matching(nil, sortBy: [NSSortDescriptor(key: "id", ascending: true)], limit: 2, context: $0)
		}

		#expect(matches.map(\.id) == ["1", "2"])
	}

	@Test("A limit larger than the result set returns everything")
	func aLimitLargerThanTheResultSetReturnsEverything() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching(nil, limit: 100, context: $0) }

		#expect(matches.count == 3)
	}

	@Test("Combines predicate, sort and limit")
	func combinesPredicateSortAndLimit() {
		insertAuthors()

		let matches = stack.read {
			TestAuthor.matching(
				NSPredicate("active = %@", true),
				sortBy: [NSSortDescriptor(key: "rating", ascending: false)],
				limit: 1,
				context: $0
			)
		}

		#expect(matches.map(\.name) == ["Ada"])
	}

	@Test("Only returns rows of its own entity")
	func onlyReturnsRowsOfItsOwnEntity() {
		stack.insertAuthor(id: "1", name: "Ada")
		stack.insertBook(id: "2", title: "Notes")

		#expect(stack.read { TestAuthor.matching(nil, context: $0) }.count == 1)
		#expect(stack.read { TestBook.matching(nil, context: $0) }.count == 1)
	}

	@Test("Sees unsaved inserts made in the same context")
	func seesUnsavedInsertsInTheSameContext() {
		stack.write { context in
			let author = TestAuthor(context: context)
			author.name = "Pending"

			#expect(TestAuthor.matching(nil, context: context).count == 1)

			context.rollback()
		}
	}

	// MARK: - Variadic format overload

	@Test("Accepts a format string and arguments")
	func acceptsAFormatStringAndArguments() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching("name = %@", "Grace", context: $0) }

		#expect(matches.map(\.id) == ["2"])
	}

	@Test("Accepts numeric format specifiers")
	func acceptsNumericFormatSpecifiers() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching("rating > %d", 5, context: $0) }

		#expect(Set(matches.map(\.id)) == ["1", "3"])
	}

	@Test("Accepts several arguments")
	func acceptsSeveralArguments() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching("name = %@ AND rating = %d", "Ada", 7, context: $0) }

		#expect(matches.map(\.id) == ["1"])
	}

	@Test("Accepts a format string with no arguments")
	func acceptsAFormatStringWithNoArguments() {
		insertAuthors()

		let matches = stack.read { TestAuthor.matching("rating > 5", context: $0) }

		#expect(matches.count == 2)
	}

	@Test("Honours sort and limit on the format overload")
	func honoursSortAndLimitOnTheFormatOverload() {
		insertAuthors()

		let matches = stack.read {
			TestAuthor.matching(
				"rating > %d",
				0,
				context: $0,
				sortBy: [NSSortDescriptor(key: "rating", ascending: true)],
				limit: 2
			)
		}

		#expect(matches.map(\.rating) == [3, 7])
	}
}
