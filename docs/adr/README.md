# Architecture Decision Records

One short file per decision, numbered in the order the decisions were made. Each records
the context, the options weighed, the decision, and what would make us revisit it.
New records start from `template.md`.

| # | Decision | Status |
|---|---|---|
| [0001](0001-enforce-rules-in-model-and-database.md) | Enforce every rule in model and database | Accepted |
| [0002](0002-subscription-join-model.md) | Provider–client via `Subscription` join model | Accepted |
| [0003](0003-plan-as-string-enum-with-check.md) | `plan` as string enum + CHECK constraint | Accepted |
| [0004](0004-journal-entries-belong-to-client.md) | Journal entries belong to client; sort by `created_at`, `id` | Accepted |
| [0005](0005-indexes-for-access-paths.md) | Indexes chosen for how data is read | Accepted |
