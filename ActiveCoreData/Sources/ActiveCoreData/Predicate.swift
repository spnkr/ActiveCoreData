import Foundation
import CoreData

public extension NSPredicate {
	/// Create an NSPredicate more concisely. `Predicate("color = %@ and city = %@", "Blue", city)` instead of `NSPredicate(format:"color = %@ and city = %@", argumentArray:["Blue", city])`.
	///
	/// ```swift
	/// NSPredicate("author.name = %@", "Ursula K. Le Guin")
	/// NSPredicate("pages > %@ AND read = %@", 300, false)
	/// NSPredicate("id IN %@", ["le-guin", "atwood"])
	/// ```
	///
	/// Arguments are substituted as *values*, never as syntax. A title containing `%@`, a quote or
	/// an apostrophe is matched literally, so you can pass a search field's contents straight in
	/// without escaping anything:
	///
	/// ```swift
	/// // Matches the literal string, no matter what the user typed.
	/// NSPredicate("title = %@", searchField.text)
	/// ```
	///
	/// > Warning: That guarantee applies to the *arguments*. The format string itself is parsed, so
	/// > building it by interpolation — `NSPredicate("\(column) = %@", value)` — puts whatever is in
	/// > `column` into the grammar. Keep attribute names as literals, or substitute them with `%K`.
	///
	/// > Note: Passing `nil` produces `attribute == <null>`, which is not the same as
	/// > `attribute == nil` and will not match rows with no value. Write `NSPredicate("born = nil")`
	/// > for that.
	///
	/// > Tip: Watch out for attribute names that collide with the predicate grammar's own keywords —
	/// > `first`, `last`, `size`, `any`, `all`, `none`. `NSPredicate("first = %@", x)` parses
	/// > `first` as the aggregate operator, not as your attribute. Use `%K` to be unambiguous:
	/// > `NSPredicate("%K = %@", "first", x)`.
	///
	/// - Parameters:
	///   - string: A predicate format string.
	///   - args: Values substituted into `string`, positionally.
	convenience init(_ string: String, _ args: Any?...) {
		self.init(format: string, argumentArray: args as [Any])
	}
}
