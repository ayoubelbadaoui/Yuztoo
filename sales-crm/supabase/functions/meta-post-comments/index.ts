import { jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient, createUserClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'

const COMMENT_FIELDS =
  'id,from{id,name},message,created_time,like_count,comment_count,can_comment,can_remove,can_hide,is_hidden,user_likes,parent{id}'

type Action = 'list' | 'reply' | 'delete' | 'like' | 'unlike'

type GraphComment = {
  id?: string
  message?: string
  created_time?: string
  like_count?: number
  comment_count?: number
  can_comment?: boolean
  can_remove?: boolean
  can_hide?: boolean
  is_hidden?: boolean
  user_likes?: boolean
  from?: { id?: string; name?: string }
  parent?: { id?: string }
  comments?: { data?: GraphComment[] }
}

async function graphGet<T>(
  path: string,
  token: string,
): Promise<{ ok: true; data: T } | { ok: false; message: string }> {
  const res = await fetch(`https://graph.facebook.com/${GRAPH_VERSION}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  })
  const json = await res.json()
  if (!res.ok) {
    return { ok: false, message: json?.error?.message ?? 'Graph GET failed' }
  }
  return { ok: true, data: json as T }
}

async function graphSend<T>(
  method: 'POST' | 'DELETE',
  path: string,
  token: string,
  body?: Record<string, unknown>,
): Promise<{ ok: true; data: T } | { ok: false; message: string }> {
  const res = await fetch(`https://graph.facebook.com/${GRAPH_VERSION}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  })
  const json = await res.json().catch(() => ({}))
  if (!res.ok) {
    return {
      ok: false,
      message: json?.error?.message ?? `Graph ${method} failed`,
    }
  }
  return { ok: true, data: json as T }
}

function mapComment(row: GraphComment) {
  return {
    id: row.id ?? '',
    message: row.message ?? '',
    createdAt: row.created_time ?? new Date().toISOString(),
    fromName: row.from?.name ?? 'Utilisateur',
    fromId: row.from?.id ?? null,
    likeCount: row.like_count ?? 0,
    replyCount: row.comment_count ?? row.comments?.data?.length ?? 0,
    canReply: row.can_comment !== false,
    canDelete: row.can_remove !== false,
    likedByPage: Boolean(row.user_likes),
    isHidden: Boolean(row.is_hidden),
    parentId: row.parent?.id ?? null,
    replies: (row.comments?.data ?? []).map((reply) => ({
      ...mapComment(reply),
      replies: [],
    })),
  }
}

function commentsUnsupportedMessage(graphMessage: string): string | null {
  const lower = graphMessage.toLowerCase()
  if (
    lower.includes('nonexisting field (comments)') ||
    lower.includes('nonexisting field(comments)') ||
    lower.includes('unsupported get request')
  ) {
    return 'Les commentaires ne sont pas disponibles sur ce type de publication Meta (ex. Story).'
  }
  return null
}

async function assertMember(
  authHeader: string,
  workspaceId: string,
): Promise<{ ok: true; userId: string } | { ok: false; status: number; error: string }> {
  const userClient = createUserClient(authHeader)
  const {
    data: { user },
    error,
  } = await userClient.auth.getUser()
  if (error || !user) return { ok: false, status: 401, error: 'Unauthorized' }

  const { data: membership } = await userClient
    .from('workspace_members')
    .select('role')
    .eq('workspace_id', workspaceId)
    .eq('user_id', user.id)
    .maybeSingle()
  if (!membership || !['owner', 'admin', 'seller'].includes(membership.role)) {
    return { ok: false, status: 403, error: 'Forbidden' }
  }
  return { ok: true, userId: user.id }
}

/** HTTP 200 + ok:false so supabase-js surfaces the real message instead of "non-2xx". */
function bizError(error: string) {
  return jsonResponse({ ok: false, error }, 200)
}

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
      action?: Action
      workspaceId?: string
      postId?: string
      channelId?: string
      commentId?: string | null
      message?: string
    }

    if (!body.action || !body.workspaceId || !body.postId || !body.channelId) {
      return bizError('action, workspaceId, postId, channelId required')
    }

    const member = await assertMember(authHeader, body.workspaceId)
    if (!member.ok) {
      return jsonResponse({ ok: false, error: member.error }, member.status)
    }

    const admin = createAdminClient()
    const { data: post } = await admin
      .from('marketing_posts')
      .select('id, format')
      .eq('id', body.postId)
      .eq('workspace_id', body.workspaceId)
      .maybeSingle()

    if (!post) {
      return bizError('Publication introuvable')
    }

    if (post.format === 'story') {
      return jsonResponse({
        ok: true,
        comments: [],
        unsupported: true,
        error:
          'Les Stories Facebook / Instagram n’exposent pas de fil de commentaires via l’API Meta.',
      })
    }

    const { data: target } = await admin
      .from('marketing_post_targets')
      .select('meta_post_id, status, channel_id')
      .eq('post_id', body.postId)
      .eq('channel_id', body.channelId)
      .eq('workspace_id', body.workspaceId)
      .maybeSingle()

    if (!target?.meta_post_id || target.status !== 'published') {
      return bizError('Publication Meta introuvable pour ce compte')
    }

    const { data: channel } = await admin
      .from('marketing_channels')
      .select('id, kind, workspace_id')
      .eq('id', body.channelId)
      .eq('workspace_id', body.workspaceId)
      .maybeSingle()
    if (!channel) {
      return bizError('Compte introuvable')
    }

    const { data: cred } = await admin
      .from('meta_channel_credentials')
      .select('access_token')
      .eq('channel_id', body.channelId)
      .maybeSingle()
    if (!cred?.access_token) {
      return bizError('Jeton Meta manquant')
    }

    const token = cred.access_token
    const objectId = target.meta_post_id

    if (body.action === 'list') {
      const nested =
        channel.kind === 'instagram'
          ? COMMENT_FIELDS
          : `${COMMENT_FIELDS},comments.limit(25){${COMMENT_FIELDS}}`
      const listed = await graphGet<{ data?: GraphComment[] }>(
        `/${objectId}/comments?filter=stream&limit=50&fields=${encodeURIComponent(nested)}`,
        token,
      )
      if (!listed.ok) {
        const unsupported = commentsUnsupportedMessage(listed.message)
        if (unsupported) {
          return jsonResponse({
            ok: true,
            comments: [],
            unsupported: true,
            error: unsupported,
          })
        }
        return bizError(listed.message)
      }
      return jsonResponse({
        ok: true,
        comments: (listed.data.data ?? []).map(mapComment),
      })
    }

    if (body.action === 'reply') {
      const message = body.message?.trim() ?? ''
      if (!message) {
        return bizError('Message vide')
      }
      const parentId = body.commentId?.trim() || objectId
      const created = await graphSend<{ id?: string }>(
        'POST',
        `/${parentId}/comments`,
        token,
        { message },
      )
      if (!created.ok) {
        return bizError(
          commentsUnsupportedMessage(created.message) ?? created.message,
        )
      }
      return jsonResponse({ ok: true, id: created.data.id ?? null })
    }

    if (body.action === 'delete') {
      if (!body.commentId) {
        return bizError('commentId required')
      }
      const deleted = await graphSend<{ success?: boolean }>(
        'DELETE',
        `/${body.commentId}`,
        token,
      )
      if (!deleted.ok) {
        return bizError(deleted.message)
      }
      return jsonResponse({ ok: true })
    }

    if (body.action === 'like' || body.action === 'unlike') {
      if (!body.commentId) {
        return bizError('commentId required')
      }
      const liked = await graphSend<{ success?: boolean }>(
        body.action === 'like' ? 'POST' : 'DELETE',
        `/${body.commentId}/likes`,
        token,
      )
      if (!liked.ok) {
        return bizError(liked.message)
      }
      return jsonResponse({ ok: true })
    }

    return bizError('Unknown action')
  } catch {
    return jsonResponse({ ok: false, error: 'Comment action failed' }, 500)
  }
}

Deno.serve(withCors(handle))
