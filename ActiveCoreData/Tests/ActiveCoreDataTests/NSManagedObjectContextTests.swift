import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("NSManagedObjectContext.flush()")
struct ContextFlushTests {
	let stack = TestStack()

	@Test("Persists pending changes")
	func persistsPendingChanges() {
		stack.write { context in
			let author = TestAuthor(context: context)
			author.id = "1"
			author.name = "Ada"
			context.flush()

			#expect(context.hasChanges == false)
		}

		#expect(stack.read { TestAuthor.find(id: "1", context: $0) }?.name == "Ada")
	}

	@Test("Is a no-op when there is nothing to save")
	func isANoOpWhenThereIsNothingToSave() {
		stack.write { context in
			context.flush()

			#expect(context.hasChanges == false)
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
	}

	@Test("Swallows save failures rather than throwing")
	func swallowsSaveFailures() {
		stack.write { context in
			// `name` is a required attribute, so this row cannot be validated on save.
			_ = TestStrict(context: context)

			context.flush()

			// The error was swallowed, so the changes are still sitting in the context.
			#expect(context.hasChanges)

			context.rollback()
		}

		#expect(stack.read { TestStrict.countFor(nil, context: $0) } == 0)
	}

	@Test("Persists deletions")
	func persistsDeletions() {
		stack.insertAuthor(id: "1")

		stack.write { context in
			_ = TestAuthor.destroyAll(matching: nil, context: context)
			context.flush()
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
	}
}

@Suite("NSManagedObjectContext.enqueue(_:)")
struct ContextEnqueueTests {
	let stack = TestStack()

	@Test("Runs the block on the context's own queue")
	func runsTheBlockOnTheContextsQueue() async {
		let context = stack.backgroundContext
		var ranOnTheMainThread = true
		var receivedContext: NSManagedObjectContext?

		await context.enqueue { ctx in
			ranOnTheMainThread = Thread.isMainThread
			receivedContext = ctx
		}

		#expect(ranOnTheMainThread == false)
		#expect(receivedContext === context)
	}

	@Test("Suspends until the block has finished")
	func suspendsUntilTheBlockHasFinished() async {
		let context = stack.backgroundContext
		var finished = false

		await context.enqueue { _ in
			Thread.sleep(forTimeInterval: 0.05)
			finished = true
		}

		#expect(finished)
	}

	@Test("Work done in the block is visible afterwards")
	func workDoneInTheBlockIsVisibleAfterwards() async {
		await stack.backgroundContext.enqueue { context in
			let author = TestAuthor(context: context)
			author.id = "1"
			author.name = "Ada"
			context.flush()
		}

		#expect(stack.read { TestAuthor.find(id: "1", context: $0) }?.name == "Ada")
	}

	@Test("Serialises concurrent callers onto one queue")
	func serialisesConcurrentCallers() async {
		let context = stack.backgroundContext
		let counter = Counter()

		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<100 {
				group.addTask {
					await context.enqueue { _ in counter.value += 1 }
				}
			}
		}

		#expect(counter.value == 100)
	}

	@Test("Leaves changes pending when the block does not save")
	func leavesChangesPendingWhenTheBlockDoesNotSave() async {
		let context = stack.backgroundContext

		await context.enqueue { ctx in
			let author = TestAuthor(context: ctx)
			author.id = "1"
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
		#expect(context.performAndWait { context.hasChanges })
	}
}

@Suite("NSManagedObjectContext.enqueueThrowing(_:)")
struct ContextEnqueueThrowingTests {
	let stack = TestStack()

	@Test("Returns normally when the block succeeds")
	func returnsNormallyWhenTheBlockSucceeds() async throws {
		try await stack.backgroundContext.enqueueThrowing { context in
			let author = TestAuthor(context: context)
			author.id = "1"
			author.name = "Ada"
			try context.save()
		}

		#expect(stack.read { TestAuthor.find(id: "1", context: $0) }?.name == "Ada")
	}

	@Test("Rethrows the block's error unchanged")
	func rethrowsTheBlocksError() async {
		await #expect(throws: CoreDataError.canNotFindModel) {
			try await stack.backgroundContext.enqueueThrowing { _ in
				throw CoreDataError.canNotFindModel
			}
		}
	}

	@Test("Surfaces a save failure instead of swallowing it")
	func surfacesASaveFailure() async {
		await #expect(throws: (any Error).self) {
			try await stack.backgroundContext.enqueueThrowing { context in
				// `name` is required, so validation fails on save.
				_ = TestStrict(context: context)
				try context.save()
			}
		}

		#expect(stack.read { TestStrict.countFor(nil, context: $0) } == 0)
	}

	@Test("Runs the block on the context's own queue")
	func runsTheBlockOnTheContextsQueue() async throws {
		let context = stack.backgroundContext
		var receivedContext: NSManagedObjectContext?

		try await context.enqueueThrowing { receivedContext = $0 }

		#expect(receivedContext === context)
	}

	@Test("A thrown error leaves earlier changes pending, not persisted")
	func aThrownErrorLeavesEarlierChangesPending() async {
		let context = stack.backgroundContext

		try? await context.enqueueThrowing { ctx in
			let author = TestAuthor(context: ctx)
			author.id = "1"

			throw CoreDataError.youAreTryingToWriteOnTheViewContext
		}

		#expect(stack.read { TestAuthor.countFor(nil, context: $0) } == 0)
		#expect(context.performAndWait { context.hasChanges })
	}
}

/// A reference box so concurrent closures can share a counter.
private final class Counter: @unchecked Sendable {
	var value = 0
}
