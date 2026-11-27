# Supabase bible — changelog

Record when chapters were written or re-verified against official Supabase documentation.  
When an official page changes a rule we depend on, update the chapter and add a row here.

| Date | What | Official sources checked |
|------|------|--------------------------|
| 2026-11-27 | Meta App Review data deletion: `meta_user_id` on credentials, `meta_data_deletion_requests` (RLS + deny-all + revoke), Edge `meta-data-deletion` (`verify_jwt=false`) + oauth-complete stores ASID; public status page `/suppression-donnees/statut/` | [Facebook Login data deletion](https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback); Edge Function JWT verify off for signed webhooks; RLS (service role bypass); Advisors security/performance |
| 2026-11-21 | Initial bible (docs-only phase): README, holly book, chapters 01–09 | Securing your API; The Supabase way to build; Row Level Security; Views; API keys; Custom claims & RBAC; Users; JWT claims; Edge CORS & auth headers; Realtime getting started & Postgres Changes; Storage access control & ownership; Advisors; Index performance KB; Product security; Rotating keys; CLI migrations / local workflow |
| 2026-11-21 | Added `10-firebase-bridge.md`: dual-stack account sync (Supabase CRM ↔ Firebase product) so linked accounts stay updated via Edge/CF | Architecture / Edge chapters; app SECURITY_GUIDELINES bridge notes |
| 2026-11-21 | Bootstrap: `workspaces` + `workspace_members` RLS on project Yuztoo; Auth login/register gate in Sales CRM SPA | RLS guides; API keys (publishable in `.env.local`) |
| 2026-11-21 | List pagination default (leads 25/page, max 100); docs in `06-performance`, holly book, coding standards | Performance / egress — no unbounded tables |
| 2026-11-21 | Marketing publish worker: `meta-publish-worker` + `pg_cron`/`pg_net` every minute; cron secret in `private.edge_config` + Vault | [Scheduling Edge Functions](https://supabase.com/docs/guides/functions/schedule-functions) |
