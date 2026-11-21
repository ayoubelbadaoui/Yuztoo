# Coding standards — Yuztoo Sales CRM

Adapted from IMIGO CRM enterprise coding standards. Goal: prevent race conditions, egress waste, and DDD leaks.

---

## Supabase query patterns

### DO: explicit selects

```javascript
const { data, error } = await supabase
  .from('deals')
  .select('id, title, stage, amount, owner_id, updated_at')
  .eq('id', id)
  .single()
```

Avoid `select('*')` on hot paths.

### DO: paginate list endpoints

```javascript
// Service returns a page, not the whole table
const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 25))
const from = (page - 1) * pageSize
const to = from + pageSize - 1

const { data, error, count } = await supabase
  .from('leads')
  .select('id, name, company, stage, amount, updated_at', { count: 'exact' })
  .eq('workspace_id', workspaceId)
  .order('updated_at', { ascending: false })
  .range(from, to)
```

UI tables must use a pager (`page` / `total` / page-size selector). Reset to page 1 when search, segment, or sort changes. See [supabase/06-performance.md](../supabase/06-performance.md).

### DO: `.maybeSingle()` for existence checks

```javascript
const { data, error } = await supabase
  .from('accounts')
  .select('id')
  .eq('external_yuztoo_merchant_id', merchantId)
  .maybeSingle()

const exists = data != null
```

Do **not** use `.limit(1)` + `length > 0` for existence — arrays + timing cause false negatives.

### DO: treat not-found as expected when appropriate

```javascript
if (error) {
  if (error.code === 'PGRST116') return null
  throw error
}
```

---

## State management

### DO: preserve state on transient errors

Do not reset UI state to a default on network blips — keep last known good state and show an error toast.

### DO: avoid immediate re-fetch after a successful write

After insert/update succeeds, update local state from the response; don’t race a follow-up select unless required for consistency.

### DO: stable refs in realtime effects

Keep the latest callback in a `useRef` so channel handlers don’t stale-close over old state.

---

## Error handling

### DO: distinguish expected vs unexpected

- Unique violation `23505` → often “already exists”  
- `PGRST116` → not found  
- Everything else → throw / surface error  

### DO: service return shape

```javascript
return { data, error: null }
// or
return { data: null, error }
```

---

## Async operations

### DO: guard double-submit

Use a `fetchingRef` / disabled button / loading flag so the same mutation cannot fire twice.

### DO: loading in `try/finally`

Always clear loading in `finally`.

---

## DDD

- No `supabase` import outside `features/**/services/**`  
- Hooks call services only  
- Pure formatters live in `helpers/` or `domain/`  

---

## Testing (minimum)

- Critical service paths (create deal, assign owner, stage change)  
- RLS assumptions documented or covered by SQL tests when available  

---

## Review

Use [CODE_REVIEW_CHECKLIST.md](./CODE_REVIEW_CHECKLIST.md).
