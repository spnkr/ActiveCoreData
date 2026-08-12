import CoreData
import Foundation

@testable import ActiveCoreData

/// A throwaway Core Data stack backed by an in-memory SQLite store.
///
/// Each instance gets its own coordinator and store, so tests are fully isolated from one another
/// even when they run in parallel. `/dev/null` is Apple's supported way of asking for a SQLite
/// store that never touches the disk, and it keeps real SQL semantics (unlike `NSInMemoryStoreType`).
final class TestStack: Container {
	let container: NSPersistentContainer
	let viewContext: NSManagedObjectContext
	let backgroundContext: NSManagedObjectContext

	init(name: String = "TestModel") {
		container = NSPersistentContainer(name: name, managedObjectModel: TestModel.model)

		let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
		description.type = NSSQLiteStoreType
		description.shouldAddStoreAsynchronously = false
		container.persistentStoreDescriptions = [description]

		var loadError: Error?
		container.loadPersistentStores { loadError = $1 }
		precondition(loadError == nil, "Failed to load the in-memory test store: \(loadError!)")

		viewContext = container.viewContext
		viewContext.automaticallyMergesChangesFromParent = true

		backgroundContext = container.newBackgroundContext()
		backgroundContext.automaticallyMergesChangesFromParent = true
		backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
	}

	/// Runs `body` on the background context's queue and returns its result.
	@discardableResult
	func write<T>(_ body: (NSManagedObjectContext) throws -> T) rethrows -> T {
		try backgroundContext.performAndWait { try body(backgroundContext) }
	}

	/// Runs `body` on the view context's queue and returns its result.
	@discardableResult
	func read<T>(_ body: (NSManagedObjectContext) throws -> T) rethrows -> T {
		try viewContext.performAndWait { try body(viewContext) }
	}

	/// A second, independent background context, for tests that need to observe another writer.
	func makeBackgroundContext() -> NSManagedObjectContext {
		let context = container.newBackgroundContext()
		context.automaticallyMergesChangesFromParent = true

		return context
	}
}

// MARK: - Fixtures

extension TestStack {
	/// Inserts and saves an author, returning its `id`.
	@discardableResult
	func insertAuthor(
		id: String,
		name: String? = nil,
		rating: Int64 = 0,
		active: Bool = false,
		born: Date? = nil,
		uuid: UUID? = nil
	) -> String {
		write { context in
			let author = TestAuthor(context: context)
			author.id = id
			author.name = name
			author.rating = rating
			author.active = active
			author.born = born
			author.uuid = uuid
			try? context.save()
		}

		return id
	}

	/// Inserts and saves a book, optionally attached to the author with the given `id`.
	@discardableResult
	func insertBook(id: String, title: String? = nil, pages: Int64 = 0, authorID: String? = nil) -> String {
		write { context in
			let book = TestBook(context: context)
			book.id = id
			book.title = title
			book.pages = pages

			if let authorID {
				book.author = TestAuthor.find(id: authorID, context: context)
			}

			try? context.save()
		}

		return id
	}
}
