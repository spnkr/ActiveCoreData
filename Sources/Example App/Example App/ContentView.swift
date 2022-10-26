//
//  ContentView.swift
//  Example App
//
//  Created by Will Jessop on 10/26/22.
//

import SwiftUI
import CoreData
import CoreDataPlus

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    var body: some View {
        NavigationView {
            List {
                Section(footer: VStack(alignment: .leading) {
                    Spacer()
                    Text("Saving").fontWeight(.bold)
                    Text("Core Data is saved to disk when the app goes into the background.")
                    Spacer()
                    Text("Or you can click the \"Save all\" button.")
                    Spacer()
                    Spacer()
                    Text("New Book object with id = 100").fontWeight(.bold)
                    Text("Demonstrates what happens when you create a variable using findOrCreate(id:)")
                    Spacer()
                })  {
                    ForEach(books) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            Text(book.title!)
                            Text("\((book.authors?.allObjects as! [Author]).map { author in author.name! }.joined())")
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                
                
                
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                    
                    Button(action: addBook) {
                        Label("Add Book", systemImage: "plus")
                    }
                    
                    Button(action: deleteAllBooksAndAuthors) {
                        Label("Delete all books and authors", systemImage: "trash")
                    }
                    
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("New Book object with id = 100", action: {
                        let book = Book.findOrCreate(id: "100", context: viewContext)
                        book.title = "Book(id=100) last touched \(Date().formatted(date: .abbreviated, time: .complete))"
                    })
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    
                    Button("Save all", action: {
                        try! viewContext.save()
                    })
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    Button("Delete authors", action: {
                        Author.destroyAll(context: viewContext)
                    })
                    .foregroundColor(.red)
                    
                    Button("Delete books", action: {
                        Book.destroyAll(context: viewContext)
                    })
                    .foregroundColor(.red)
                    
                    
                    
                    
                }
                
            }
            Text("Select an item")
        }
    }
    
    private func deleteAllBooks() {
        Book.destroyAll(context: viewContext)
    }
    private func deleteAllAuthors() {
        Author.destroyAll(context: viewContext)
    }
    private func deleteAllBooksAndAuthors() {
        Author.destroyAll(context: viewContext)
        Book.destroyAll(context: viewContext)
    }
    
    private func addBook() {
        let newBook = Book.findOrCreate(id: UUID().uuidString, context: viewContext)
        newBook.title = "Book \(Int.random(in: 1...1000))"
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { books[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
