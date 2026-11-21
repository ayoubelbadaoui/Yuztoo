# 05 — Realtime and Storage

## Realtime

Use Realtime for inbox badges, pipeline boards, WhatsApp threads, etc. — never for unbounded whole-table feeds.

### Rules for Sales CRM

1. Implement channels in `features/<domain>/services/*Realtime.ts` only.  
2. Hooks only subscribe and clean up on unmount.  
3. Always **filter** by `workspace_id` (and often `owner_id` / conversation id).  
4. Assume RLS still applies to Postgres Changes — policies must allow the subscriber to see the rows.  

Official: [Getting Started with Realtime](https://supabase.com/docs/guides/realtime/getting_started), [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes), [Realtime architecture](https://supabase.com/docs/guides/realtime/architecture).

### Filter example (conceptual)

```ts
// Inside a *Realtime service — filter is mandatory
channel.on('postgres_changes', {
  event: '*',
  schema: 'public',
  table: 'inbox_messages',
  filter: `workspace_id=eq.${workspaceId}`,
}, handler)
```

### Ops notes

- Cleanup: `removeChannel` / unsubscribe on unmount — leaked channels burn connections.  
- Troubleshooting: [Postgres Changes troubleshooting](https://supabase.com/kb/troubleshooting/realtime-postgres-changes-troubleshooting).

---

## Storage

Use private buckets for contract signatures, marketing media, WhatsApp media — public buckets only when the product truly needs anonymous read.

### Access control

- Policies on `storage.objects` mirror workspace membership (path prefix e.g. `{workspace_id}/…`).  
- Official: [Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control), [Ownership](https://supabase.com/docs/guides/storage/security/ownership).

### Upsert needs three privileges

Uploading a **new** file ≠ replacing one. For upsert / overwrite, policies must allow **INSERT + SELECT + UPDATE**. Missing UPDATE → silent or confusing failures. Upload RLS errors: [403 on upload](https://supabase.com/kb/troubleshooting/storage-error-403-forbidden-new-row-violates-row-level-security-policy-on-upload-a94384).

### After revoke

Private objects can remain reachable via old signed URLs until they expire. Plan short TTLs for sensitive contract proof. KB: [Private bucket files still accessible after remove access](https://supabase.com/kb/troubleshooting/storage-private-bucket-files-still-accessible-after-remove-access-or-logout).

### Scaling / cost

Large media (marketing stories, reels) → watch quotas and caching. Official: [Storage optimizations](https://supabase.com/docs/guides/storage/production/scaling). Helpers: [Storage helper functions](https://supabase.com/docs/guides/storage/schema/helper-functions).

## Official sources

- [Realtime getting started](https://supabase.com/docs/guides/realtime/getting_started)  
- [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes)  
- [Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control)  
- [Storage ownership](https://supabase.com/docs/guides/storage/security/ownership)  
- [Storage optimizations](https://supabase.com/docs/guides/storage/production/scaling)  
