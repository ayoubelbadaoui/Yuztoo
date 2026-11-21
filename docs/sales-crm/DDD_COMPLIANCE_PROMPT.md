# DDD Compliance Prompt — Yuztoo Sales CRM

**Use this in all AI-assisted development.** Adapted from IMIGO CRM.

---

## MANDATORY rules

```
CRITICAL: This codebase follows Domain-Driven Design (DDD).

1. NEVER use direct Supabase calls in UI / hooks / pages
   - FORBIDDEN in components/hooks: supabase.from(...), supabase.rpc(...)
   - REQUIRED: call functions from src/features/{domain}/services/

2. Service layer
   - All data access goes through src/features/{domain}/services/
   - Services own error handling and return shape
   - Create the service function first, then use it from UI

3. File structure
   - Components: src/features/{domain}/components/ or containers/
   - Services:   src/features/{domain}/services/{domain}Service.js
   - Hooks:      src/features/{domain}/hooks/  (call services only)
   - Domain pure helpers: src/features/{domain}/domain/ or helpers/

4. If a service function does not exist
   - Add it in the domain service file first
   - Follow { data, error } return pattern
   - Then import it in the component/hook

5. Acceptable exceptions
   - Realtime: *Realtime.js under services/ only; hooks only subscribe/cleanup
   - Shared shell outside features/ (layout, auth context) — still no ad-hoc table access

6. Error handling
   - Services return: { data: T | null, error: Error | null }
   - Always check error before using data
   - Treat "not found" as expected when appropriate

7. Before writing code
   - Search for an existing service function
   - Prefer extending a service over new direct DB access
```

---

## Correct vs incorrect

### Incorrect

```javascript
import { supabase } from '../../../lib/supabase'

const fetchDeal = async (id) => {
  const { data, error } = await supabase.from('deals').select('*').eq('id', id).single()
}
```

### Correct

```javascript
import { getDealById } from '../services/dealService'

const fetchDeal = async (id) => {
  const { data, error } = await getDealById(id)
  if (error) return
  // use data
}
```

---

## New service function pattern

```javascript
// src/features/deals/services/dealService.js
import { supabase } from '../../../lib/supabase'

/**
 * @returns {Promise<{data: object|null, error: Error|null}>}
 */
export async function getDealById(id) {
  try {
    const { data, error } = await supabase
      .from('deals')
      .select('id, title, stage, amount, account_id, owner_id, updated_at')
      .eq('id', id)
      .single()
    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error }
  }
}
```

---

## Pre-commit checklist

- [ ] No `supabase.from` / `supabase.rpc` in feature components or hooks  
- [ ] All data access via services  
- [ ] Explicit column selects (no `*` on hot paths)  
- [ ] `{ data, error }` handling  
- [ ] Realtime only under `services/`  

**DDD is not optional.**
