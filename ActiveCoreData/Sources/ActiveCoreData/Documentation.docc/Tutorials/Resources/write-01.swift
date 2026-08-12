import ActiveCoreData
import CoreData

@MainActor
enum BookStore {
    static func add(isbn: String, title: String, pages: Int64, authorName: String) async {
        let context = DataStore.shared.backgroundContext
    }
}
