# 0001. Enforce every rule in both the model and the database

- **Status:** Accepted
- **Date:** 2026-10-02

## Context

Model validations only run for code that goes through ActiveRecord with validations on.
Raw SQL, `update_column`, `insert_all`, other services, and concurrent requests all bypass
them. `validates :uniqueness` checks and then inserts: two concurrent requests can both
pass the check.

## Decision

Every validation has a matching database constraint: `NOT NULL`, foreign keys, unique
indexes, and CHECK. Model validations remain for friendly error messages.

Each database rule has a test that saves with `save!(validate: false)` and expects the
database error (for example `NotNullViolation` or `RecordNotUnique`).

## Consequences

- Correctness doesn't depend on every writer being well-behaved.
- Rules live in two places, so a change needs both a migration and a model edit.
- **Reconsider if:** never. This is the default for data we can't afford to corrupt.
