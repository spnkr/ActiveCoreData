import CoreData
import Foundation

/// Traps in debug builds when a helper that can write to the store is handed a main-queue context.
///
/// `DataStore.viewContext` is a main-queue context meant for reads; writes belong on
/// `DataStore.backgroundContext`. Compiled out of release builds, like any other `assert`.
func assertContextIsWritable(_ context: NSManagedObjectContext, function: StaticString = #function) {
	assert(
		context.concurrencyType != .mainQueueConcurrencyType,
		"""
		\(function) can write to the database, so it must not be passed a main-queue context \
		such as viewContext. Use a background context instead.
		"""
	)
}
