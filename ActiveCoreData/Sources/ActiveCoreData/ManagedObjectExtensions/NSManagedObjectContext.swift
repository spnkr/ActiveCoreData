import Foundation
import CoreData

public extension NSManagedObjectContext {
	/// Saves, ignoring any error.
	///
	/// ```swift
	/// await store.backgroundContext.enqueue { context in
	///     Book.findOrCreate(id: isbn, context: context).title = title
	///     context.flush()
	/// }
	/// ```
	///
	/// Call it at the end of a unit of work. Saving is cheap when there is nothing to save — Core
	/// Data returns immediately if `hasChanges` is `false` — so there is no need to guard the call.
	///
	/// > Warning: The name is honest about what this does: it pushes changes out and does not tell
	/// > you if they went nowhere. A failed save leaves everything sitting in the context, so the
	/// > changes are not lost, but they are not on disk either and the next `flush()` will fail the
	/// > same way. Validation errors are the usual cause: a required attribute left unset, or a
	/// > relationship whose minimum count is not met.
	/// >
	/// > When a save failing would matter — a purchase, an edit the user typed, anything you would
	/// > show an error for — use ``enqueueThrowing(_:)`` and `try context.save()` instead, and
	/// > handle the error.
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

public extension NSManagedObjectContext {
	/// Runs a throwing block on this context's queue and suspends until it finishes, propagating
	/// any error it throws.
	///
	/// The counterpart to ``enqueue(_:)`` for work whose failure you want to handle:
	///
	/// ```swift
	/// let context = DataStore.shared.backgroundContext
	///
	/// do {
	///     try await context.enqueueThrowing { context in
	///         guard let book = Book.find(id: isbn, context: context) else { return }
	///
	///         try book.markAsRead()
	///         try context.save()
	///     }
	/// } catch {
	///     // handle the error here
	/// }
	/// ```
	///
	/// Errors come back unchanged — your own error types, or Core Data's `NSError` from a failed
	/// `save()`. When the block throws, whatever it had already changed stays pending in the
	/// context rather than being rolled back; call `context.rollback()` in your `catch` if you want
	/// the context clean.
	///
	/// - Parameter block: The work to run, handed this context. Runs exactly once.
	/// - Throws: Whatever `block` throws.
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

public extension NSManagedObjectContext {
	/// Runs the given block on this context's queue and suspends
	/// until it completes. Persists *only if* you call ``flush()``.
	///
	/// This is how every write in your app should start:
	///
	/// ```swift
	/// let context = DataStore.shared.backgroundContext
	///
	/// await context.enqueue { context in
	///     let author = Author.findOrCreate(id: "le-guin", context: context)
	///     author.name = "Ursula K. Le Guin"
	///
	///     let book = Book.findOrCreate(id: isbn, context: context)
	///     book.title = "The Dispossessed"
	///     book.author = author
	///
	///     context.flush()
	/// }
	///
	/// // The save has landed. Safe to refresh the UI.
	/// ```
	///
	/// Use the `context` handed to the block rather than the one you called this on. They are the
	/// same object, but shadowing it means you cannot accidentally reach for a different context
	/// from inside — the mistake this whole API exists to prevent.
	///
	/// > Important: A managed object must never leave the queue it belongs to. Do not return one
	/// > from the block or capture one from outside it. Pass an `NSManagedObjectID` across the
	/// > boundary and re-fetch on the other side with `context.object(with:)`. Object IDs are the
	/// > only part of Core Data's object graph that is safe to share between contexts.
	///
	/// - Parameter block: The work to run, handed this context. Runs exactly once.
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
