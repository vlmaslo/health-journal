# 0005. Choose indexes for how the data is read

- **Status:** Accepted
- **Date:** 2026-10-02

## Context

Each index speeds up reads but costs write time and storage. Only add the ones that serve
a known read path: clients of a provider, providers of a client, a client's journal by
date, and the journal across all of a provider's clients by date.

## Decision

- `subscriptions`:
  - unique `[provider_id, client_id]` (also serves "clients of a provider", since a
    composite index covers lookups on its first column);
  - `[client_id]` (serves "providers of a client").
  - The standalone `provider_id` index is skipped (`index: false`).
- `journal_entries`: `[client_id, created_at]` only. It serves a client's feed already in
  sorted order, and makes a standalone `client_id` index redundant.

## Consequences

- No redundant indexes.
- **Known gap:** the provider-wide feed (`provider.journal_entries.newest_first`) still
  sorts after the join. The index orders each client's entries, not the merged feed. At
  scale this needs `provider_id` copied onto entries, or a per-provider feed table.
- **Could add:** `[client_id, provider_id]` in place of `[client_id]`, so "providers of a
  client" can be answered from the index alone.
