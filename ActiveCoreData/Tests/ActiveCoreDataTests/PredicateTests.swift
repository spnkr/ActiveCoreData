import CoreData
import Foundation
import Testing

@testable import ActiveCoreData

@Suite("NSPredicate(_:_:) convenience initialiser")
struct PredicateTests {
	@Test("Produces the same predicate as NSPredicate(format:argumentArray:)")
	func matchesTheArgumentArrayInitialiser() {
		let concise = NSPredicate("color = %@ and city = %@", "Blue", "Leeds")
		let verbose = NSPredicate(format: "color = %@ and city = %@", argumentArray: ["Blue", "Leeds"])

		#expect(concise.predicateFormat == verbose.predicateFormat)
	}

	@Test("Substitutes a single argument")
	func substitutesASingleArgument() {
		#expect(NSPredicate("name = %@", "Ada").predicateFormat == #"name == "Ada""#)
	}

	@Test("Substitutes arguments positionally")
	func substitutesArgumentsPositionally() {
		let predicate = NSPredicate("alpha = %@ and beta = %@", "one", "two")

		#expect(predicate.predicateFormat == #"alpha == "one" AND beta == "two""#)
	}

	@Test("Accepts a format string with no arguments")
	func acceptsAFormatStringWithNoArguments() {
		#expect(NSPredicate("rating > 3").evaluate(with: ["rating": 4]))
		#expect(NSPredicate("rating > 3").evaluate(with: ["rating": 2]) == false)
	}

	@Test("Substitutes a nil argument as null")
	func substitutesANilArgumentAsNull() {
		// Documenting the behaviour rather than endorsing it: use `name == nil` in the format
		// string if you want to match rows with no value.
		#expect(NSPredicate("name = %@", nil).predicateFormat == "name == <null>")
	}

	@Test(
		"Evaluates against an object",
		arguments: [
			("Ada", true),
			("Grace", false),
		]
	)
	func evaluatesAgainstAnObject(candidate: String, expected: Bool) {
		#expect(NSPredicate("name = %@", "Ada").evaluate(with: ["name": candidate]) == expected)
	}

	@Test("Treats arguments as values, not as format placeholders")
	func treatsArgumentsAsValues() {
		// A value containing what looks like a placeholder must not be re-interpreted.
		let predicate = NSPredicate("name = %@", "%@ and %K")

		#expect(predicate.evaluate(with: ["name": "%@ and %K"]))
	}

	@Test("Quotes values containing quotes and apostrophes")
	func quotesAwkwardValues() {
		let predicate = NSPredicate("name = %@", #"O'Brien "the third""#)

		#expect(predicate.evaluate(with: ["name": #"O'Brien "the third""#]))
		#expect(predicate.evaluate(with: ["name": "O'Brien"]) == false)
	}

	@Test("Substitutes non-string arguments")
	func substitutesNonStringArguments() {
		let date = Date(timeIntervalSince1970: 1_000)
		let uuid = UUID()

		#expect(NSPredicate("rating = %@", 5).evaluate(with: ["rating": 5]))
		#expect(NSPredicate("active = %@", true).evaluate(with: ["active": true]))
		#expect(NSPredicate("born = %@", date).evaluate(with: ["born": date]))
		#expect(NSPredicate("uuid = %@", uuid).evaluate(with: ["uuid": uuid]))
	}

	@Test("Substitutes a collection argument for IN")
	func substitutesACollectionArgument() {
		let predicate = NSPredicate("id IN %@", ["a", "b"])

		#expect(predicate.evaluate(with: ["id": "a"]))
		#expect(predicate.evaluate(with: ["id": "c"]) == false)
	}

	@Test("Works as a fetch request predicate")
	func worksAsAFetchRequestPredicate() {
		let stack = TestStack()
		stack.insertAuthor(id: "1", name: "Ada")
		stack.insertAuthor(id: "2", name: "Grace")

		let matches = stack.read { TestAuthor.matching(NSPredicate("name = %@", "Grace"), context: $0) }

		#expect(matches.map(\.id) == ["2"])
	}
}
