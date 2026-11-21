-- Remember which CRM origin started OAuth (prod vs localhost) so the
-- code exchange uses the same redirect_uri Meta saw at authorize time.
alter table public.meta_oauth_states
  add column if not exists app_origin text;
