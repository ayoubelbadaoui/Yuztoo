# Code review checklist — Yuztoo Sales CRM

Adapted from IMIGO CRM. Use before opening or approving a PR.

## Minimum bar

- [ ] PR explains **what** and **why**  
- [ ] No new DDD violations (`supabase` only in `features/**/services/**`)  
- [ ] Explicit selects; pagination on growing lists  
- [ ] Filtered realtime if used  
- [ ] Loading / empty / error UI states  
- [ ] No secrets committed; no service role in client  
- [ ] RLS considered for any new table  
- [ ] `npm run build` / lint (and relevant tests) pass  

## Standards

| Document | Purpose |
|----------|---------|
| [CODING_STANDARDS.md](./CODING_STANDARDS.md) | Query, state, async |
| [../DDD_COMPLIANCE_PROMPT.md](../DDD_COMPLIANCE_PROMPT.md) | DDD rules |
| [../SECURITY_GUIDELINES.md](../SECURITY_GUIDELINES.md) | Security |
