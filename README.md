# Health Journal — Providers, Clients & Journal Entries

A Rails 8.1 data model for **providers** (e.g. dietitians), their **clients**, and client
**journal entries**, with four ActiveRecord queries over them.

## Requirements

- Ruby 3.4.11 (pinned in `.ruby-version`)
- PostgreSQL 14+ running locally (e.g. `brew services start postgresql@15`)

The app connects over localhost as your OS user with no password. Override with
`DATABASE_URL` if your setup differs.

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

## Run the queries

```bash
bin/rails queries:demo
bin/rails "queries:demo[ben@example.com,erin@example.com]"   # pick a provider and client
```

Prints each query's generated SQL and its results against seed data.

| # | Question | Code |
|---|---|---|
| 1 | All clients for a provider | `provider.clients` |
| 2 | All providers for a client | `client.providers` |
| 3 | A client's journal entries, by date | `client.journal_entries.newest_first` |
| 4 | Entries across all of a provider's clients, by date | `provider.journal_entries.newest_first` |

Query 4 is a nested `has_many :journal_entries, through: :clients`. It compiles to a single
query joining `journal_entries → clients → subscriptions`, filtered on `provider_id`; a test
asserts the query count.

## Tests

```bash
bin/rails test
```

Minitest with fixtures. Each database-level rule (NOT NULL, foreign keys, unique indexes,
plan CHECK constraint) has a test that saves with `validate: false` to prove the database
enforces it without help from the model.

## Schema

```
Provider ──< Subscription >── Client ──< JournalEntry
                  │
          plan: basic | premium
```

| Table | Columns | Constraints and indexes |
|---|---|---|
| `providers`, `clients` | `name`, `email` | both NOT NULL; unique index on `email` |
| `subscriptions` | `provider_id`, `client_id`, `plan` | FKs; unique `[provider_id, client_id]`; `[client_id]`; `plan` NOT NULL, default `basic`, CHECK `IN ('basic','premium')` |
| `journal_entries` | `client_id`, `body` (text) | FK; `body` NOT NULL; composite `[client_id, created_at]` |

## Design decisions

One line each; the linked records in [`docs/adr/`](docs/adr/README.md) have the options
weighed and the triggers for revisiting.

- **Every rule is enforced in the model and the database.** Validations give friendly
  errors; constraints hold for every writer.
  [ADR 0001](docs/adr/0001-enforce-rules-in-model-and-database.md)
- **`plan` lives on the `Subscription` join model**, since a client can hold a different
  plan with each provider. [ADR 0002](docs/adr/0002-subscription-join-model.md)
- **`plan` is a string enum plus a CHECK constraint**: readable in raw SQL, and no integer
  mapping to corrupt. [ADR 0003](docs/adr/0003-plan-as-string-enum-with-check.md)
- **Journal entries belong to the client**, are sorted by `created_at` then `id`, and block
  client deletion. [ADR 0004](docs/adr/0004-journal-entries-belong-to-client.md)
- **Indexes match the read paths**, with no redundant ones.
  [ADR 0005](docs/adr/0005-indexes-for-access-paths.md)
- **Emails are normalized on write** (`normalizes :email` strips and downcases), so the
  plain unique index is effectively case-insensitive. Alternative: a Postgres `citext`
  column, which enforces it in the database for every writer.

## If the dataset were very large

- **Paginate with keyset pagination, not OFFSET:**
  `WHERE (created_at, id) < (?, ?) ORDER BY created_at DESC, id DESC LIMIT 25`.
  The cost per page stays constant, and results don't shift as new entries arrive.
- **Query 4 still needs a sort.** `[client_id, created_at]` orders each client's entries,
  but merging many clients' feeds requires sorting. Options:
  - copy `provider_id` onto entries, or keep a per-provider feed table, indexed on
    `(provider_id, created_at)`
  - a materialized view
- **Eager-load** (`includes(:client)`) when rendering feeds to avoid N+1 queries.
- **Further out:** counter caches for counts, read replicas, and time-based partitioning
  of `journal_entries`.

## Out of scope

- **No HTTP API, authentication, or authorization.** In production, scope every query
  through `subscriptions` so a provider only sees their own clients.
- **No encryption at rest.** Journal entries are health data; use Rails `encrypts :body`,
  and `encrypts :email, deterministic: true` so the unique index still works.
- **No audit logging.**
