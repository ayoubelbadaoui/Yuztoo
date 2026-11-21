import { jsonResponse, withCors } from '../_shared/cors.ts'
import {
  finalizePostStatus,
  publishToChannel,
} from '../_shared/metaPublish.ts'
import { createAdminClient, createUserClient } from '../_shared/supabase.ts'

async function handle(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return jsonResponse({ ok: false, error: 'Method not allowed' }, 405)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return jsonResponse({ ok: false, error: 'Unauthorized' }, 401)
    }

    const body = (await req.json()) as {
      workspaceId?: string
      postId?: string
      runId?: string
    }
    if (!body.workspaceId || !body.postId) {
      return jsonResponse(
        { ok: false, error: 'workspaceId and postId required' },
        400,
      )
    }

    const userClient = createUserClient(authHeader)
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return jsonResponse({ ok: false, error: 'Unauthorized' }, 401)
    }

    const { data: membership } = await userClient
      .from('workspace_members')
      .select('role')
      .eq('workspace_id', body.workspaceId)
      .eq('user_id', user.id)
      .maybeSingle()
    if (!membership || !['owner', 'admin', 'seller'].includes(membership.role)) {
      return jsonResponse({ ok: false, error: 'Forbidden' }, 403)
    }

    const admin = createAdminClient()
    const { data: post } = await admin
      .from('marketing_posts')
      .select(
        'id, workspace_id, format, caption, link_url, media_id, status, marketing_media ( public_url, mime_type )',
      )
      .eq('id', body.postId)
      .eq('workspace_id', body.workspaceId)
      .maybeSingle()

    if (!post) {
      return jsonResponse({ ok: false, error: 'Post not found' }, 404)
    }

    const media = post.marketing_media as
      | { public_url: string; mime_type: string }
      | null

    let runId = body.runId ?? null
    if (!runId) {
      const { data: dueRun } = await admin
        .from('marketing_post_runs')
        .select('id')
        .eq('post_id', post.id)
        .in('status', ['pending', 'failed'])
        .order('occurrence_index', { ascending: true })
        .limit(1)
        .maybeSingle()
      runId = dueRun?.id ?? null
    }

    const { data: targets } = await admin
      .from('marketing_post_targets')
      .select('id, channel_id, status')
      .eq('post_id', post.id)

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
      .update({ status: 'publishing', updated_at: new Date().toISOString() })
      .eq('id', post.id)

    let published = 0
    let failed = 0

    for (const target of targets ?? []) {
      // Recurring runs re-publish even if a previous occurrence succeeded.
      if (target.status === 'published' && !runId) {
        published += 1
        continue
      }

      await admin
        .from('marketing_post_targets')
        .update({
          status: 'pending',
          error: null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', target.id)

      const result = await publishToChannel(admin, {
        channelId: target.channel_id,
        caption: post.caption,
        linkUrl: post.link_url,
        mediaUrl: media?.public_url ?? null,
        mimeType: media?.mime_type ?? null,
        format: post.format,
      })

      if (!result.ok) {
        failed += 1
        await admin
          .from('marketing_post_targets')
          .update({
            status: 'failed',
            error: result.error,
            updated_at: new Date().toISOString(),
          })
          .eq('id', target.id)

        if (runId) {
          await admin
            .from('marketing_publish_jobs')
            .update({
              status: 'failed',
              last_error: result.error,
              attempts: 1,
              updated_at: new Date().toISOString(),
            })
            .eq('post_id', post.id)
            .eq('run_id', runId)
            .eq('channel_id', target.channel_id)
            .eq('status', 'pending')
        }
        continue
      }

      published += 1
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

      if (runId) {
        await admin
          .from('marketing_publish_jobs')
          .update({
            status: 'done',
            last_error: null,
            updated_at: new Date().toISOString(),
          })
          .eq('post_id', post.id)
          .eq('run_id', runId)
          .eq('channel_id', target.channel_id)
          .in('status', ['pending', 'running'])
      }
    }

    const runStatus =
      published > 0 && failed > 0
        ? 'partial'
        : published > 0
          ? 'published'
          : 'failed'

    if (runId) {
      await admin
        .from('marketing_post_runs')
        .update({
          status: runStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', runId)
    }

    const status = await finalizePostStatus(admin, post.id, published, failed)

    return jsonResponse({ ok: true, status, published, failed })
  } catch {
    return jsonResponse({ ok: false, error: 'Publish failed' }, 500)
  }
}

Deno.serve(withCors(handle))
