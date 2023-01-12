//
//  ContentView.swift
//  Example App
//
//  Created by Will Jessop on 10/26/22.
//

import SwiftUI
import CoreData
import CoreDataPlus
import CoreDataPlusSyntacticSugar

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
                    HStack {
                        Image(systemName: "plus")
                        Text("Add test data").fontWeight(.bold)
                    }
                    .foregroundColor(.blue)
                    .onTapGesture {
                        self.addTestData()
                    }
                    Spacer(minLength: 20)
                    
                    Text("Saving").underline()
                    Text("Core Data is saved to disk when the app goes into the background.\n\nOr you can click the \"Save all\" button.")
                    Spacer(minLength: 20)
                    
                    Text("New Book object with id = 100").underline()
                    Text("Demonstrates what happens when you create a variable using findOrCreate(id:)")
                    Spacer(minLength: 20)
                    
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
                        let book = Book.findOrCreate(id: "100", using: .custom(nsManagedObjectContext: viewContext))
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
                        Author.destroyAll()
                    })
                    .foregroundColor(.red)
                    
                    Button("Delete books", action: {
                        Book.destroyAll()
                    })
                    .foregroundColor(.red)
                    
                    
                    
                    
                }
                
            }
            Text("Select an item")
        }
        .navigationViewStyle(.stack)
    }
    
    private func addTestData() {
        
        // TODO: document
        Task {
            await CoreDataPlus.shared.performInBackground(schedule: .enqueued, {
                dump("🛣🛣🛣🛣🛣🛣🛣 bckgrouind")
            })
        }
        

        // TODO: document
        CoreDataPlus.shared.performInBackground {
            
            // create some authors
            // using the name field as the unique identifier
            // TODO: add better docs on how to handle id/identifiable with core data (not library-specific)
            let murakami = Author.findOrCreate(column: "name", value: "Haruki Murakami", using: .background)
            let jk = Author.findOrCreate(column: "name", value: "J. K. Rowling", using: .background)
            
            // using id as the unique identifier
            let lydia = Author.findOrCreate(id: "1234", using: .background)
            lydia.name = "Lydia Millet"
            
            var authors = [murakami, jk, lydia]
            
            for _ in 0..<10 {
                let newItem = Book.findOrCreate(id: UUID().uuidString, using: .background)
                newItem.title = "Harry Potter Vol. \(Int.random(in: 1...1000))"
                
                newItem.addToAuthors(authors.randomElement()!)
                
                // add a 2nd author to some books
                if Int.random(in: 1...100) > 50 {
                    newItem.addToAuthors(authors.randomElement()!)
                }
            }
            
            try? CoreDataPlus.shared.backgroundContext?.save()
        }
    }
    private func deleteAllBooks() {
        Book.destroyAll(using: .background)
    }
    private func deleteAllAuthors() {
        Author.destroyAll()
    }
    private func deleteAllBooksAndAuthors() {
        Author.destroyAll()
        Book.destroyAll()
        
    }
    
    private func addBook() {
        let newBook = Book.findOrCreate(id: UUID().uuidString, using: .foreground)
        newBook.title = "Book \(Int.random(in: 1...1000))"
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { books[$0] }.forEach(viewContext.delete)
        }
    }
}

