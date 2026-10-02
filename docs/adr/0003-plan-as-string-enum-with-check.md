# 0003. Store `plan` as a string enum plus a CHECK constraint

- **Status:** Accepted
- **Date:** 2026-10-02

## Context

`plan` has two values, `basic` and `premium`. It must be impossible to store anything else.

## Options considered

- **Integer enum (`basic: 0`):** compact, but opaque in raw SQL, and reordering the mapping
  silently corrupts data.
- **String enum:** readable everywhere; a few bytes more per row.
- **Native Postgres enum type:** strict, but hard to change (`ALTER TYPE` can't drop a value).
- **`plans` lookup table:** flexible, but heavy for two values with no attributes.

## Decision

A string-backed Rails enum with `validate: true`, plus `CHECK (plan IN ('basic','premium'))`,
`NOT NULL`, and a default of `basic`.

## Consequences

- An invalid value is a validation error (not an `ArgumentError`) in the app, and a
  constraint violation for any other writer.
- The enum generates scopes (`Subscription.premium`) that other models can reuse with `merge`.
- Adding a plan needs a migration to update the CHECK constraint as well as the enum.
- **Reconsider if:** plans gain attributes (price, limits, features). Then move to a `plans`
  table with a foreign key.
