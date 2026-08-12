import Foundation
import CoreData

public protocol ManagedObjectExtended: ManagedObjectFind,
									   ManagedObjectFindOrCreate,
									   ManagedObjectMatching,
									   ManagedObjectCountable,
									   ManagedObjectDeletable { }
