# 0002. Model provider–client as `has_many :through` a `Subscription`

- **Status:** Accepted
- **Date:** 2026-10-02

## Context

Providers have many clients, and clients can have many providers. For each provider a
client is signed up with, there is exactly one plan. The same client can be premium with
one provider and basic with another, so the plan belongs to the *relationship*.

## Options considered

- **A: `plan` column on `clients`:** can't represent a different plan per provider.
- **B: `has_and_belongs_to_many`:** the join table can't hold attributes and has no model
  for validations.
- **C: a join model carrying `plan`:** holds attributes, validations, and future lifecycle
  fields.

## Decision

C, a `Subscription` model (`provider_id`, `client_id`, `plan`), used through
`has_many :through`.

The name `Subscription` reads naturally with a plan. `Enrollment` and `Membership` were
equally valid; what matters is using the name consistently.

## Consequences

- Both directions are plain associations: `provider.clients`, `client.providers`.
- Every future extension (discharge, plan history, billing) lands on this model.
- **Reconsider if:** never. This is the canonical Rails shape for an attribute on a relationship.
