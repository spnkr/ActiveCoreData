import SwiftUI

struct ContentView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)])
    private var books: FetchedResults<Book>

    var body: some View {
        NavigationStack {
            List(books) { book in
                VStack(alignment: .leading) {
                    Text(book.title ?? "Untitled")
                    Text(book.author?.name ?? "Unknown author")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Bookshelf")
        }
    }
}
