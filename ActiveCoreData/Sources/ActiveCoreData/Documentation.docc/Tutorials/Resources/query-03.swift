import ActiveCoreData
import CoreData

@MainActor
enum BookQueries {
    static func search(_ text: String) -> [Book] {
        let context = DataStore.shared.viewContext

        return Book.matching(
            NSPredicate("title CONTAINS[cd] %@", text),
            sortBy: [NSSortDescriptor(key: "title", ascending: true)],
            context: context
        )
    }

    static var unreadCount: Int {
        Book.countFor(NSPredicate("read = %@", false), context: DataStore.shared.viewContext)
    }

    @discardableResult
    static func clearFinished() async -> Int {
        let context = DataStore.shared.backgroundContext

        return await withCheckedContinuation { continuation in
            context.perform {
                let removed = Book.destroyAll(
                    matching: NSPredicate("read = %@", true),
                    context: context
                )
                context.flush()
                continuation.resume(returning: removed)
            }
        }
    }
}
