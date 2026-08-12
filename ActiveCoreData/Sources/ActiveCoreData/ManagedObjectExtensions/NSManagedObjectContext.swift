import Foundation
import CoreData

public extension NSManagedObjectContext {
	/// saves
	func flush() {
		// let areTestsRunning = ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
 
		// if !areTestsRunning {
		// 	// prevent future accidental editing of data on wrong context
		// 	assert(self != DB.main, "only save and edit on the background NSManagedObjectContext please")
		// }

		do {
			try save()
		} catch {
			// Log.error("\(error)")
		}
	}
}

/// let foo = 10
/// let context = DB.background
///
/// do {
/// 	try await context.enqueueThrowing { ctx in
/// 		guard let bar = User.find("983", context: ctx) else { return }
///
/// 		try bar.doSomething(foo + 10)
/// 		ctx.persist()
/// 	}
/// } catch {
/// 	// handle the error here
/// }
public extension NSManagedObjectContext {
	func enqueueThrowing(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
		try await withCheckedThrowingContinuation { continuation in
			perform {
				do {
					try block(self)
					continuation.resume(returning: ())
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
	}
}

/// let foo = 10
/// let context = DB.background
///
/// await context.enqueue { ctx in
/// 	guard let bar = User.find("983", context: ctx) else { return }
/// 	bar.doSomething(foo + 10)
/// 	ctx.persist()
/// }
public extension NSManagedObjectContext {
	/// Runs the given block on this context's queue and suspends
	/// until it completes. Persists *only if* you call `persist()`.
	func enqueue(_ block: @escaping (NSManagedObjectContext) -> Void) async {
		// note:
		// why withCheckedContinuation + perform? to avoid dealing with new structured concurrency's side effects with regard to .perform
		// perform(schedule: .enqueued), and perform(schedule: .enqueued) didn't behave like perform—they execute blocks out of order.
		await withCheckedContinuation { continuation in
			perform {
				block(self)
				continuation.resume()
			}
		}
	}
}
