import Foundation
import CoreData

/// Everything ActiveCoreData offers, in one conformance.
///
/// ## Overview
///
/// This is the line you write. Add it once per entity, next to your generated `NSManagedObject`
/// subclass, and that entity gains ``ManagedObjectFind``, ``ManagedObjectFindOrCreate``,
/// ``ManagedObjectMatching``, ``ManagedObjectCountable`` and ``ManagedObjectDeletable``:
///
/// ```swift
/// import ActiveCoreData
/// import CoreData
///
/// extension Book: ManagedObjectExtended {}
/// ```
///
/// There is no body to fill in. Every requirement — `init(context:)`, `entity()` and
/// `fetchRequest()` — is already satisfied by `NSManagedObject`, whether you let Xcode generate the
/// class for you or write it by hand.
///
/// ```swift
/// let book = Book.findOrCreate(id: isbn, context: context)   // ManagedObjectFindOrCreate
/// let ursula = Author.find(id: "le-guin", context: context)  // ManagedObjectFind
/// let long = Book.matching("pages > %d", 300, context: context)  // ManagedObjectMatching
/// let count = Book.countFor(nil, context: context)           // ManagedObjectCountable
/// Book.destroyAll(context: context)                          // ManagedObjectDeletable
/// ```
///
/// ## Taking less than all of it
///
/// The five protocols are independent, so conform to only the ones an entity should expose. This
/// is worth doing for entities that must never be bulk-deleted, or that have no natural key:
///
/// ```swift
/// // An audit log you can search but never mass-delete from application code.
/// extension AuditEntry: ManagedObjectFind, ManagedObjectMatching, ManagedObjectCountable {}
/// ```
///
/// > Tip: ``ManagedObjectFind/find(id:context:)`` and
/// > ``ManagedObjectFindOrCreate/findOrCreate(id:context:)`` assume a `String` attribute literally
/// > named `id`. If your entity keys on something else, conform anyway and use the `column:`
/// > variants — or add `id` to the model and get `Identifiable` conformance for SwiftUI at the same
/// > time.
public protocol ManagedObjectExtended: ManagedObjectFind,
									   ManagedObjectFindOrCreate,
									   ManagedObjectMatching,
									   ManagedObjectCountable,
									   ManagedObjectDeletable { }
