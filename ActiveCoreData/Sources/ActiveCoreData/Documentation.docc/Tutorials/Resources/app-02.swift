import ActiveCoreData
import SwiftUI

@main
struct BookshelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataStore.shared.viewContext)
        }
    }
}
