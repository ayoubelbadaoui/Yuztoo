import { getConfig } from '../_shared/config.ts'
import { jsonResponse, withCors } from '../_shared/cors.ts'
import {
  finalizePostStatus,
  publishToChannel,
} from '../_shared/metaPublish.ts'
import { createAdminClient } from '../_shared/supabase.ts'

type JobRow = {
  id: string
  workspace_id: string
  post_id: string
  run_id: string | null
  channel_id: string
  attempts: number
}

async function authorize(req: Request): Promise<boolean> {
  const cronHeader = req.headers.get('x-cron-secret')
  if (cronHeader) {
    const expected = await getConfig('PUBLISH_CRON_SECRET')
    return Boolean(expected && cronHeader === expected)
  }

  const auth = req.headers.get('Authorization')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (auth?.startsWith('Bearer ') && serviceKey) {
    return auth.slice('Bearer '.length) === serviceKey
  }
  return false
}

async function handle(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return jsonResponse({ ok: false, error: 'Method not allowed' }, 405)
    }

    if (!(await authorize(req))) {
      return jsonResponse({ ok: false, error: 'Unauthorized' }, 401)
    }

    const admin = createAdminClient()
    const nowIso = new Date().toISOString()

    const { data: dueJobs, error: dueError } = await admin
      .from('marketing_publish_jobs')
      .select('id, workspace_id, post_id, run_id, channel_id, attempts')
      .eq('status', 'pending')
      .lte('next_attempt_at', nowIso)
      .order('next_attempt_at', { ascending: true })
      .limit(40)

    if (dueError) {
      return jsonResponse({ ok: false, error: 'Claim failed' }, 500)
    }

    const jobs = (dueJobs ?? []) as JobRow[]
    if (jobs.length === 0) {
      return jsonResponse({ ok: true, processed: 0, runs: 0 })
    }

    const jobIds = jobs.map((j) => j.id)
    await admin
      .from('marketing_publish_jobs')
      .update({
        status: 'running',
        updated_at: nowIso,
      })
      .in('id', jobIds)
      .eq('status', 'pending')

    const byRun = new Map<string, JobRow[]>()
    for (const job of jobs) {
      const key = job.run_id ?? `post:${job.post_id}`
      const list = byRun.get(key) ?? []
      list.push(job)
      byRun.set(key, list)
    }

    let processed = 0
    let runsDone = 0

    for (const group of byRun.values()) {
      const first = group[0]
      const postId = first.post_id
      const runId = first.run_id

      const { data: post } = await admin
        .from('marketing_posts')
        .select(
          'id, format, caption, link_url, status, marketing_media ( public_url, mime_type )',
        )
        .eq('id', postId)
        .maybeSingle()

      if (!post) {
        await admin
          .from('marketing_publish_jobs')
          .update({
            status: 'failed',
            last_error: 'Publication introuvable',
            updated_at: new Date().toISOString(),
          })
          .in(
            'id',
            group.map((j) => j.id),
          )
        continue
      }

      if (post.status === 'draft') {
        await admin
          .from('marketing_publish_jobs')
          .update({
            status: 'cancelled',
            updated_at: new Date().toISOString(),
          })
          .in(
            'id',
            group.map((j) => j.id),
          )
        continue
      }

      const mediaRaw = post.marketing_media as
        | { public_url: string; mime_type: string }
        | Array<{ public_url: string; mime_type: string }>
        | null
      const media = Array.isArray(mediaRaw) ? (mediaRaw[0] ?? null) : mediaRaw

      if (runId) {
        await admin
          .from('marketing_post_runs')
          .update({
            status: 'publishing',
            updated_at: new Date().toISOString(),
          })
          .eq('id', runId)
      }

      await admin
        .from('marketing_posts')
        .update({
          status: 'publishing',
          updated_at: new Date().toISOString(),
        })
        .eq('id', postId)

      let published = 0
      let failed = 0

      for (const job of group) {
        processed += 1
        const attempts = (job.attempts ?? 0) + 1

        const { data: target } = await admin
          .from('marketing_post_targets')
          .select('id')
          .eq('post_id', postId)
          .eq('channel_id', job.channel_id)
          .maybeSingle()

        if (target) {
          await admin
            .from('marketing_post_targets')
            .update({
              status: 'pending',
              error: null,
              updated_at: new Date().toISOString(),
            })
            .eq('id', target.id)
        }

        const result = await publishToChannel(admin, {
          channelId: job.channel_id,
          caption: post.caption,
          linkUrl: post.link_url,
          mediaUrl: media?.public_url ?? null,
          mimeType: media?.mime_type ?? null,
          format: post.format,
        })

        if (!result.ok) {
          failed += 1
          const retry = attempts < 3
          await admin
            .from('marketing_publish_jobs')
            .update({
              status: retry ? 'pending' : 'failed',
              attempts,
              last_error: result.error,
              next_attempt_at: retry
                ? new Date(Date.now() + attempts * 60_000).toISOString()
                : new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .eq('id', job.id)

          if (target) {
            await admin
              .from('marketing_post_targets')
              .update({
                status: 'failed',
                error: result.error,
                updated_at: new Date().toISOString(),
              })
              .eq('id', target.id)
          }
          continue
        }

        published += 1
        await admin
          .from('marketing_publish_jobs')
          .update({
            status: 'done',
            attempts,
            last_error: null,
            updated_at: new Date().toISOString(),
          })
          .eq('id', job.id)

        if (target) {
          await admin
            .from('marketing_post_targets')
            .update({
              status: 'published',
              error: null,
              permalink: result.permalink,
              meta_post_id: result.metaPostId,
              meta_container_id: result.metaContainerId,
              updated_at: new Date().toISOString(),
            })
            .eq('id', target.id)
        }
      }

      const runStatus =
        published > 0 && failed > 0
          ? 'partial'
          : published > 0
            ? 'published'
            : 'failed'

      if (runId) {
        // Keep run pending if some jobs are still retrying.
        const { count: stillPending } = await admin
          .from('marketing_publish_jobs')
          .select('id', { count: 'exact', head: true })
          .eq('run_id', runId)
          .eq('status', 'pending')

        await admin
          .from('marketing_post_runs')
          .update({
            status: (stillPending ?? 0) > 0 ? 'publishing' : runStatus,
            updated_at: new Date().toISOString(),
          })
          .eq('id', runId)
      }

      await finalizePostStatus(admin, postId, published, failed)
      runsDone += 1
    }

    return jsonResponse({
      ok: true,
      processed,
      runs: runsDone,
    })
  } catch {
    return jsonResponse({ ok: false, error: 'Worker failed' }, 500)
  }
}

Deno.serve(withCors(handle))
