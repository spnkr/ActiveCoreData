import Foundation
import ObjectiveC
import CoreData

private var AssociatedObjectHandleNSManagedObjectContextLabelName: UInt8 = 20
public extension NSManagedObjectContext {
	public var label: Any? {
		get {
			return objc_getAssociatedObject(self, &AssociatedObjectHandleNSManagedObjectContextLabelName)
		}
		set {
			// TODO: - check OBJC_ASSOCIATION_RETAIN_NONATOMIC is right
			objc_setAssociatedObject(self, &AssociatedObjectHandleNSManagedObjectContextLabelName, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

public extension NSManagedObjectContext {
	/// Runs the given block on this context's queue and suspends until it completes.
	///
	/// let foo = 10
	/// let context = DB.background
	///
	/// do {
	/// 	try await context.performAsyncThrowing { ctx in
	/// 		guard let bar = User.find("983", context: ctx) else { return }
	///
	/// 		try bar.doSomething(foo + 10)
	/// 	}
	/// } catch {
	/// 	// handle the error here
	/// }
	public func performAsyncThrowing(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
		try await withCheckedThrowingContinuation { continuation in
			perform {
				do {
					try block(self)
					continuation.resume(returning: ())
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
	}
	
	/// Runs the given block on this context's queue and suspends until it completes.
	///
	/// let foo = 10
	/// let context = DB.background
	///
	/// await context.performAsync { ctx in
	/// 	guard let bar = User.find("983", context: ctx) else { return }
	/// 	bar.doSomething(foo + 10)
	/// }
	public func performAsync(_ block: @escaping (NSManagedObjectContext) -> Void) async {
		await withCheckedContinuation { continuation in
			perform {
				block(self)
				continuation.resume()
			}
		}
	}
}

public struct DBContext {
	@TaskLocal public static var current: NSManagedObjectContext?
}

public func backgroundDo(_ work: @escaping (NSManagedObjectContext) -> Void) async {
	await ActiveCoreDataStore.shared.backgroundContext.performAsync { ctx in
		// Switch to a new task so we can use the async Task-local feature.
		Task {
			// Bind 'ctx' to the 'DBContext.current' TaskLocal for this scope.
			await DBContext.$current.withValue(ctx) {
				// Within this closure, DBContext.current == ctx
				work(ctx)
			}
		}
	}
}
public func mainDo(_ work: @escaping (NSManagedObjectContext) -> Void) async {
	await ActiveCoreDataStore.shared.viewContext.performAsync { ctx in
		// Switch to a new task so we can use the async Task-local feature.
		Task {
			// Bind 'ctx' to the 'DBContext.current' TaskLocal for this scope.
			await DBContext.$current.withValue(ctx) {
				// Within this closure, DBContext.current == ctx
				work(ctx)
			}
		}
	}
}

public extension ManagedObjectFindOrCreateBy {
	public static func findNew(id: String) -> Self? {
		guard let ctx = DBContext.current else { return nil }
		
		let u = Self.findOrCreate(id: id, context: ctx)
		
		// do fetch with ctx
		dump("Finding \(id) w/ context \(ctx.label)")
		
		return u
	}
}
