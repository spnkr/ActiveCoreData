import SwiftUI

struct ContentView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)])
    private var books: FetchedResults<Book>

    var body: some View {
        NavigationStack {
            List {
            }
            .navigationTitle("Bookshelf")
        }
    }
}
