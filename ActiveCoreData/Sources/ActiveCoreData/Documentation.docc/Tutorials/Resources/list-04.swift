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
            .toolbar {
                Button("Add", systemImage: "plus") {
                    Task {
                        await BookStore.add(
                            isbn: "9780060512750",
                            title: "The Dispossessed",
                            pages: 341,
                            authorName: "Ursula K. Le Guin"
                        )
                    }
                }
            }
        }
    }
}
