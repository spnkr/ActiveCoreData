# Finding objects

Four ways to read, and how to pick between them.

## Overview

Reading is safe to do on ``Container/viewContext``, on the main thread. None of the calls in this
article change anything, and none of them throw — a failed fetch gives you `nil`, an empty array or
zero.

| You want | Use |
| --- | --- |
| One object, by its key | ``ManagedObjectFind/find(id:context:)`` |
| One object, by some other attribute | ``ManagedObjectFind/find(column:value:context:)`` |
| Several objects | ``ManagedObjectMatching/matching(_:sortBy:limit:context:)`` |
| Just how many | ``ManagedObjectCountable/countFor(_:context:)`` |

## One object

```swift
let ursula = Author.find(id: "le-guin", context: context)
let byName = Author.find(column: "name", value: "Ursula K. Le Guin", context: context)
let short  = Book.find(column: "pages", value: 189, context: context)
```

`value` can be anything Core Data stores: a string, a number, a `Bool`, a `Date`, a `UUID`.

Both return `nil` when nothing matches — and when several rows match, both return whichever the
store hands back first. That is not a stable order, so use `find` for things that are unique and
reach for `matching` with a sort descriptor when "the first one" needs to mean something.

> Warning: `column` is interpolated into the predicate format string. It must be a literal
> attribute name you control, never a value from user input or a server response.

## Several objects

There are two overloads. The format-string one reads well for the common case:

```swift
let long = Book.matching("pages > %d", 300, context: context)
let ursulas = Book.matching("author.name = %@", "Ursula K. Le Guin", context: context)
```

and takes sorting and a limit too:

```swift
let topTen = Book.matching(
    "pages > %d", 300,
    context: context,
    sortBy: [NSSortDescriptor(key: "title", ascending: true)],
    limit: 10
)
```

> Note: `context:` comes right after the arguments here, not at the end. The variadic argument list
> would otherwise swallow it. The predicate overload below puts `context:` last, which is worth
> knowing before the compiler tells you off.

The other overload takes a ready-made predicate, and `nil` means everything:

```swift
let all = Book.matching(nil, context: context)

let newest = Book.matching(
    nil,
    sortBy: [NSSortDescriptor(key: "published", ascending: false)],
    limit: 20,
    context: context
)
```

Use it when the predicate is built somewhere else, is compound, or needs an argument the variadic
form cannot take — a Swift array, or an optional:

```swift
var clauses = [NSPredicate("read = %@", false)]

if let author {
    clauses.append(NSPredicate("author = %@", author))
}

let unread = Book.matching(
    NSCompoundPredicate(andPredicateWithSubpredicates: clauses),
    sortBy: [NSSortDescriptor(key: "title", ascending: true)],
    context: context
)
```

> Tip: A `limit` with no `sortBy` gives you an arbitrary slice. The store returns rows in whatever
> order it finds them, which may be insertion order today and something else after a migration.

## Counting

```swift
let total = Book.countFor(nil, context: context)
let unread = Book.countFor(NSPredicate("read = %@", false), context: context)
```

Always prefer this to `matching(...).count`. Core Data turns it into a `SELECT COUNT(*)`: no objects
are created, nothing lands in the row cache, and counting ten thousand rows costs the same as
counting one.

## Writing predicates

``Foundation/NSPredicate/init(_:_:)`` is a shorter spelling of
`NSPredicate(format:argumentArray:)`:

```swift
NSPredicate("pages > %@ AND read = %@", 300, false)
NSPredicate("author.name BEGINSWITH[cd] %@", query)
NSPredicate("id IN %@", ["le-guin", "atwood"])
NSPredicate("books.@count > %@", 3)
```

Arguments are substituted as values, never as syntax, so a search term containing quotes, an
apostrophe or a literal `%@` is matched as typed:

```swift
// Safe with anything the user types.
Book.matching(NSPredicate("title CONTAINS[cd] %@", searchText), context: context)
```

A few things to know:

- `[c]` is case-insensitive, `[d]` ignores diacritics, `[cd]` both. For anything a human typed into
  a search field, you almost always want `[cd]`.
- `nil` as an argument produces `attribute == <null>`, which does **not** match rows with no value.
  Write `NSPredicate("born = nil")` for that.
- Attribute names that collide with the predicate grammar's keywords — `first`, `last`, `size`,
  `any`, `all`, `none` — get parsed as operators. Use `%K` to be explicit:
  `NSPredicate("%K = %@", "first", value)`.
- Relationships work in predicates: `"author.name = %@"` for to-one, `"books.@count > %@"` and
  `"ANY books.pages > %@"` for to-many.

## What you get back

Real objects, belonging to the context you passed in, with their attributes ready to read. Fetching
does not give you a set of empty shells to worry about.

What can surprise you is what happens next. Reading a *relationship* on each returned object fires a
separate fetch for each one:

```swift
// One fetch for the books, then one more per book.
for book in Book.matching(nil, context: context) {
    print(book.author?.name ?? "")
}
```

See <doc:UnderTheHood#Faulting-batching-and-the-row-cache> for how to avoid it.

## Reading in SwiftUI

For anything a view displays, `@FetchRequest` is still the right tool — it re-runs itself when the
store changes, and these helpers do not:

```swift
@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)])
private var books: FetchedResults<Book>
```

Use the helpers for one-off reads: a decision in a view model, a widget snapshot, a share extension.

## Topics

### Protocols

- ``ManagedObjectFind``
- ``ManagedObjectMatching``
- ``ManagedObjectCountable``
