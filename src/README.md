# Code Style and Architecture

## Database Access

There are several reasonable ways to interact with a database for a project like this.
For example:

- Raw SQL queries for relational databases, which are defined using [prepared statements](https://en.wikipedia.org/wiki/Prepared_statement) and executed later
- Query builders which assemble SQL query strings for relational databases out of composable parts
- Non-relational databases like key-value stores, which may store structured data without type metadata

([ORM](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)s (object-relational mappers)
map objects to relational databases. Roc does not have objects, and ORMs don't make sense in Roc.)

For this particular code base, I decided to use raw SQL prepared statements. As noted above, I think
there are other approaches that are reasonable too! I just had to pick something, and personally I like
raw SQL as long as the queries are fairly distinct (as opposed to being composed of many different
slight variations, in which case a query builder becomes much more appealing), because working in
raw SQL removes a layer of translation. I'm directly writing the exact query the database will see.

On the Roc side, I chose to give each query its own type annotation which exactly reflects what the
query takes in, and what it returns. An alternative approach is to reuse common types (e.g. `User`,
which could have all the fields in the `User` table) and then have the queries `SELECT` more fields
than are strictly necessary for that use case, just to fully populate the reused type.

The reason I did this is for performance. Over-selecting can cause performance problems in real-world
code bases—and, in an amusing coincidence, it actually caused [a performance problem in `realworld`
code bases too](https://realworld-docs.netlify.app/specifications/backend/api-response-format/#multiple-articles)—and
so I prefer to have each query accept only the inputs it needs, and return only the outputs that will
be used by the caller. This does result in more one-off type annotations, but I'm fine with that tradeoff.

## Code Sharing across Queries

Since SQL queries return plain data, I used structural records for them. I'm not trying to
give them magical auto-updating behaviors or custom serialization or anything like that.
I'm essentially treating the prepared statements as functions that happen to live in a database,
and I'm annotating those functions' arguments and return types based on what information
they take and what information they return, just like any function.

This approach shares no code between query implementations. A downside of this is that if there's a desire
to make a change to a bunch of related queries at once, each query must be updated separately. For example,
if there's a new column added to the `articles` table, then several queries which return articles might
need to be updated individually to return it.

On the other hand, a corresponding upside to this approach is that each query can be modified individually
without breaking the others. This can be very nice for backwards-compatibility, where you may want to
offer new versions of a query while keeping the old one at a different URL so that existing clients
don't break when you introduce the new version. The more the queries rely on code sharing, the harder it
is to correctly introduce a new variation without breaking existing ones.

In this design, introducing a backwards-compatible new version of a query is trivial to get right;
you copy-paste the existing one, make the desired changes, and put it on a new endpoint. Since it's not
sharing any code with the existing one, there's no risk of breaking existing clients.

Again, both approaches are reasonable and have their own tradeoffs! This project is not trying to take
a stance on one being better than the other (for this project, let alone in general), it's just the
approach I decided to use here.

## Module Structure

I made modules named after database tables, e.g. the `Articles` module corresponds to the `articles` table.
