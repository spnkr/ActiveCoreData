import CoreData
import Foundation

enum CoreDataError: Error {
	case canNotFindModel
	case youAreTryingToWriteOnTheViewContext
}
