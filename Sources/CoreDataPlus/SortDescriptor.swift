import Foundation
import CoreData

public typealias SortDescriptor = NSSortDescriptor

public extension NSSortDescriptor {
    convenience init<Root, Value>(_ keyPath: KeyPath<Root, Value>) {
        self.init(keyPath: keyPath, ascending: true)
    }
}
