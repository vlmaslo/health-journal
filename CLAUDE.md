# CLAUDE.md

Rails 8.1 data model for providers, clients, subscriptions (a join model carrying a
`basic`/`premium` plan), and client journal entries. It is models, queries, and tests only;
there are no controllers. See `README.md` for setup and the schema.

## Commands

```bash
bundle exec rspec            # RSpec + FactoryBot; must stay green
bundle exec rubocop          # rubocop-rails-omakase; must report no offenses (-a to autocorrect)
bin/rails queries:demo       # prints the four queries with their SQL
bin/rails db:seed            # idempotent seed data
```

## Architecture decisions

Decisions are recorded as ADRs in `docs/adr/` (index: `docs/adr/README.md`).

- **Before changing models, migrations, indexes, or queries, read the relevant ADRs.**
- Do not silently contradict an ADR. If a change conflicts with one, say so, and propose a
  new ADR (copy `docs/adr/template.md`, next number) in the same change.

## Conventions

- **Every rule is enforced twice** (ADR 0001). A new validation needs a matching database
  constraint, plus a spec that uses `save!(validate: false)` and expects the database error.
- **Ordering lives in named scopes** (e.g. `newest_first`), never in association definitions.
  Sorts include `id` as a tiebreaker.
- **Journal entries are health data.** Never add `dependent: :destroy` or other hard-delete
  paths for them. Never write entry bodies or emails to logs or console output;
  `filter_parameters` only scrubs request parameters.
- Before finishing a change, run `bundle exec rspec` and `bundle exec rubocop`.
