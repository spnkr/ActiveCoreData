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
}
