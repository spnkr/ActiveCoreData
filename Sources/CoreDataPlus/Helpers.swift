import Foundation
import CoreData

internal func raiseError(_ e: InternalError) {
    fatalError(e.localizedDescription)
}

internal func contextModeToNSManagedObjectContext(_ using: ContextMode) -> NSManagedObjectContext {
    switch using {
    case .foreground:
        return CoreDataPlus.shared.viewContext
    case .background:
        guard let c = CoreDataPlus.shared.backgroundContext else {
            raiseError(.noBackground)
            return CoreDataPlus.shared.viewContext
        }
        return c
    case .custom(let context):
        return context
    }
}
