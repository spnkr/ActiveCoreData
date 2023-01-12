// 

import Foundation
import SwiftUI
import CoreDataPlus

struct BookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var book: Book
    
    public var body: some View {
        ScrollView {
            VStack {
                Text(book.title ?? "No title")
                    .font(.title)
                
                ForEach((book.authors?.allObjects as? [Author] ?? []), id: \.self) { author in
                    HStack(spacing: 5) {
                        Text(author.name ?? "No name")
                        Button("❌", action: {
                            book.removeFromAuthors(author)
                        })
                    }
                }
                
                
                VStack(spacing: 100) {
                    Button("Add author\nHaruki Murakami", action: {
                        let murakami = Author.findOrCreate(column: "name", value: "Haruki Murakami", context: viewContext)
                        book.addToAuthors(murakami)
                    })
                    .buttonStyle(.bordered)
                    
                    Button("Add author\nMurakami, J.K., or Millet", action: {
                        let names = [
                            "Haruki Murakami",
                            "J. K. Rowling",
                            "Lydia Millet"
                        ]
                        
                        book.addToAuthors(Author.findOrCreate(column: "name", value: names.randomElement()!, context: viewContext))
                    })
                    .buttonStyle(.bordered)
                    
                    Button("Add new fictional author", action: {
                        book.addToAuthors(Author.findOrCreate(column: "name", value: "Author \(Int.random(in: 1...1000))", context: viewContext))
                    })
                    .buttonStyle(.bordered)
                    
                    Button("Add new fictional author", action: {
                        book.addToAuthors(Author.findOrCreate(column: "name", value: "Author \(Int.random(in: 1...1000))", context: viewContext))
                    })
                    .buttonStyle(.bordered)
                }
                
                
            }
        }
    }
}
