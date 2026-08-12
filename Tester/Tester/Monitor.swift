//
import Foundation

import CoreData
import Foundation
import ActiveCoreData

class Monitor {
	static let shared = Monitor()
	
	func doSomething() {
		let c = ActiveCoreData.DataStore.shared.backgroundContext
		
		c.perform {
			let i = Item.findOrCreate(id: UUID().uuidString, context: c)
			i.title = "Foo"
			i.timestamp = Date()
			try! c.save()
		}
	}
}
