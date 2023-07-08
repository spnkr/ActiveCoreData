import Foundation
import CoreData

internal func raiseError(_ e: InternalError) {
    fatalError(e.localizedDescription)
}

internal func contextModeToNSManagedObjectContext(_ using: ContextMode) -> NSManagedObjectContext {
    switch using {
    case .foreground:
        return ActiveCoreData.shared.viewContext
    case .background:
        guard let c = ActiveCoreData.shared.backgroundContext else {
            raiseError(.noBackground)
            return ActiveCoreData.shared.viewContext
        }
        return c
    case .custom(let context):
        return context
    }
}
