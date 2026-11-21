-- Scheduler for Meta publications: claim due marketing_publish_jobs via Edge worker.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

create index if not exists marketing_publish_jobs_due_idx
  on public.marketing_publish_jobs (status, next_attempt_at)
  where status = 'pending';

create index if not exists marketing_post_runs_due_idx
  on public.marketing_post_runs (status, run_at)
  where status = 'pending';

-- Shared secret for cron → Edge (also readable by Edge via get_edge_config).
insert into private.edge_config (key, value, updated_at)
values (
  'PUBLISH_CRON_SECRET',
  encode(extensions.gen_random_bytes(32), 'hex'),
  now()
)
on conflict (key) do update
  set value = excluded.value,
      updated_at = now();

-- Vault entries for pg_net (idempotent-ish).
do $$
declare
  v_url text := 'https://zdzzmzcoxdogeqydargo.supabase.co';
  v_secret text;
  v_url_id uuid;
  v_secret_id uuid;
begin
  select value into v_secret
  from private.edge_config
  where key = 'PUBLISH_CRON_SECRET';

  select id into v_url_id from vault.secrets where name = 'project_url' limit 1;
  if v_url_id is null then
    perform vault.create_secret(v_url, 'project_url');
  else
    perform vault.update_secret(v_url_id, v_url);
  end if;

  select id into v_secret_id from vault.secrets where name = 'publish_cron_secret' limit 1;
  if v_secret_id is null then
    perform vault.create_secret(v_secret, 'publish_cron_secret');
  else
    perform vault.update_secret(v_secret_id, v_secret);
  end if;
end $$;

-- Replace existing job if re-applied.
do $$
begin
  perform cron.unschedule('marketing-publish-worker');
exception
  when others then null;
end $$;

select cron.schedule(
  'marketing-publish-worker',
  '* * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
      || '/functions/v1/meta-publish-worker',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'publish_cron_secret')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);
