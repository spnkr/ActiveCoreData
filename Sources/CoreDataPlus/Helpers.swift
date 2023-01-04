import Foundation
import CoreData

internal func raiseError(_ e: InternalError) {
    fatalError(e.localizedDescription)
}
