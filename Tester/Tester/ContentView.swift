//
import Foundation


import SwiftUI
import CoreData
import ActiveCoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
						Text("Item at \(item.timestamp!, formatter: itemFormatter)\n\(item.title)")
                    } label: {
                        Text(item.timestamp!, formatter: itemFormatter)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
				.navigationTitle("Yeooo")
        }
    }

    private func addItem() {
		Task {
			await DataStore.shared.backgroundContext.enqueue { context in
				let i = Item.findOrCreate(id: UUID().uuidString, context: context)
				i.timestamp = Date()
				i.title = "\(Int.random(in: 1...10000))"
				context.flush()
			}
		}
     		
        // withAnimation {
        //     let newItem = Item(context: viewContext)
        //     newItem.timestamp = Date()
       
        //     do {
        //         try viewContext.save()
        //     } catch {
        //         // Replace this implementation with code to handle the error appropriately.
        //         // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        //         let nsError = error as NSError
        //         fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        //     }
        // }
    }

	// you can use non-active core data methods too
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

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

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
