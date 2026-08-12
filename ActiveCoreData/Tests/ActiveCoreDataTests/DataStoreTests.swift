import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

// `DataStore.shared` reads the *main* bundle, which under `swift test` is the test runner rather
// than an app, so the singleton itself is not exercised here. The name resolution it depends on is
// pulled out into a pure function, and that is what these tests cover.
@Suite("DataStore.resolvePersistentContainerName")
struct DataStoreNameResolutionTests {
	@Test("Prefers the Info.plist key over the bundled model")
	func prefersTheInfoPlistKey() {
		let name = DataStore.resolvePersistentContainerName(
			infoDictionary: ["ActiveCoreData": ["persistentContainerName": "Library"]],
			momdURLs: [URL(fileURLWithPath: "/somewhere/Guessed.momd")]
		)

		#expect(name == "Library")
	}

	@Test("Falls back to the first bundled model, without its extension")
	func fallsBackToTheFirstBundledModel() {
		let name = DataStore.resolvePersistentContainerName(
			infoDictionary: [:],
			momdURLs: [
				URL(fileURLWithPath: "/somewhere/Library.momd"),
				URL(fileURLWithPath: "/somewhere/Other.momd"),
			]
		)

		#expect(name == "Library")
	}

	@Test("Uses only the last path component of the model URL")
	func usesOnlyTheLastPathComponent() {
		let name = DataStore.resolvePersistentContainerName(
			infoDictionary: nil,
			momdURLs: [URL(fileURLWithPath: "/a/deeply/nested.momd/path/Library.momd")]
		)

		#expect(name == "Library")
	}

	@Test("Returns nil when there is nothing to go on")
	func returnsNilWhenThereIsNothingToGoOn() {
		#expect(DataStore.resolvePersistentContainerName(infoDictionary: nil, momdURLs: []) == nil)
		#expect(DataStore.resolvePersistentContainerName(infoDictionary: [:], momdURLs: []) == nil)
	}

	@Test(
		"Falls back when the Info.plist entry is the wrong shape",
		arguments: [
			["ActiveCoreData": "Library"],
			["ActiveCoreData": ["persistentContainerName": 42]],
			["ActiveCoreData": ["someOtherKey": "Library"]],
			["SomethingElse": ["persistentContainerName": "Library"]],
		] as [[String: Any]]
	)
	func fallsBackWhenTheInfoPlistEntryIsTheWrongShape(infoDictionary: [String: Any]) {
		let name = DataStore.resolvePersistentContainerName(
			infoDictionary: infoDictionary,
			momdURLs: [URL(fileURLWithPath: "/somewhere/Guessed.momd")]
		)

		#expect(name == "Guessed")
	}
}

@Suite("Container")
struct ContainerTests {
	let stack = TestStack()

	@Test("A stack exposes a main-queue view context and a private-queue background context")
	func exposesTheExpectedContexts() {
		let container: any Container = stack

		#expect(container.viewContext.concurrencyType == .mainQueueConcurrencyType)
		#expect(container.backgroundContext.concurrencyType == .privateQueueConcurrencyType)
	}

	@Test("Both contexts are backed by the same store")
	func bothContextsAreBackedByTheSameStore() {
		#expect(stack.viewContext.persistentStoreCoordinator === stack.backgroundContext.persistentStoreCoordinator)
	}

	@Test("The view context picks up changes saved on the background context")
	func theViewContextPicksUpBackgroundChanges() {
		stack.insertAuthor(id: "1", name: "Ada")

		#expect(stack.read { TestAuthor.find(id: "1", context: $0) }?.name == "Ada")
	}
}
