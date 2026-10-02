# 0004. Journal entries belong to the client, sorted by `created_at` then `id`

- **Status:** Accepted
- **Date:** 2026-10-02

## Context

Clients post freeform journal entries. A client's entries, and the entries across a
provider's clients, are read sorted by date.

## Options considered

- **Owner:** the client (a shared journal), or the subscription (per-provider entries).
- **Sort key:** `created_at` (insert time), or a separate event date such as `recorded_at`.
- **Where the order lives:** in the association definition, or in a named scope.

## Decision

- `JournalEntry belongs_to :client`.
- `scope :newest_first, -> { order(created_at: :desc, id: :desc) }`.
- `Client has_many :journal_entries, dependent: :restrict_with_error`: entries are health
  records, so a client with entries cannot be destroyed.

## Consequences

- Every provider a client works with sees the same entries.
- `id` breaks ties, so the order is always the same. Pagination requires that.
- A named scope doesn't leak into other queries. A default order on the association would
  need `reorder` to undo.
- **Reconsider if:**
  - Entries need per-provider visibility: add an optional `subscription_id`.
  - Clients need to backdate entries: add `recorded_at`, sort by it, and index
    `[client_id, recorded_at]`.
