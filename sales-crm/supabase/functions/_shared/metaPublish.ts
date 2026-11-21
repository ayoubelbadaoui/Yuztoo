import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'

const GRAPH_VERSION = 'v22.0'

type ChannelRow = {
  id: string
  kind: 'facebook-page' | 'instagram'
  meta_page_id: string | null
  meta_ig_id: string | null
  status: string
}

export async function graphPost<T>(
  path: string,
  token: string,
  body: Record<string, unknown>,
): Promise<{ ok: true; data: T } | { ok: false; message: string }> {
  const res = await fetch(`https://graph.facebook.com/${GRAPH_VERSION}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })
  const json = await res.json()
  if (!res.ok) {
    return {
      ok: false,
      message: json?.error?.message ?? 'Graph request failed',
    }
  }
  return { ok: true, data: json as T }
}

async function waitIgContainer(containerId: string, token: string) {
  for (let i = 0; i < 12; i += 1) {
    const res = await fetch(
      `https://graph.facebook.com/${GRAPH_VERSION}/${containerId}?fields=status_code`,
      { headers: { Authorization: `Bearer ${token}` } },
    )
    const json = await res.json()
    const code = json?.status_code as string | undefined
    if (code === 'FINISHED') return true
    if (code === 'ERROR' || code === 'EXPIRED') return false
    await new Promise((r) => setTimeout(r, 2500))
  }
  return false
}

async function publishFacebookPhotoStory(input: {
  pageId: string
  token: string
  mediaUrl: string
}) {
  // Page Stories API: unpublished photo upload, then /photo_stories.
  const uploaded = await graphPost<{ id?: string }>(
    `/${input.pageId}/photos`,
    input.token,
    {
      url: input.mediaUrl,
      published: false,
    },
  )
  if (!uploaded.ok || !uploaded.data.id) {
    return uploaded.ok
      ? { ok: false as const, message: 'Photo story introuvable après upload' }
      : uploaded
  }

  const published = await graphPost<{ success?: boolean; post_id?: string }>(
    `/${input.pageId}/photo_stories`,
    input.token,
    { photo_id: uploaded.data.id },
  )
  if (!published.ok) return published
  if (!published.data.success && !published.data.post_id) {
    return { ok: false as const, message: 'Publication story photo refusée' }
  }
  return {
    ok: true as const,
    data: { id: published.data.post_id ?? uploaded.data.id, post_id: published.data.post_id },
  }
}

async function publishFacebookVideoStory(input: {
  pageId: string
  token: string
  mediaUrl: string
}) {
  // Page Stories API: start session → rupload file_url → finish.
  const started = await graphPost<{ video_id?: string; upload_url?: string }>(
    `/${input.pageId}/video_stories`,
    input.token,
    { upload_phase: 'start' },
  )
  if (!started.ok || !started.data.video_id || !started.data.upload_url) {
    return started.ok
      ? { ok: false as const, message: 'Session upload story vidéo impossible' }
      : started
  }

  const uploadRes = await fetch(started.data.upload_url, {
    method: 'POST',
    headers: {
      Authorization: `OAuth ${input.token}`,
      file_url: input.mediaUrl,
    },
  })
  const uploadJson = await uploadRes.json().catch(() => ({}))
  if (!uploadRes.ok || uploadJson?.success === false) {
    return {
      ok: false as const,
      message:
        uploadJson?.error?.message ??
        'Upload story vidéo vers Meta a échoué',
    }
  }

  const finished = await graphPost<{ success?: boolean; post_id?: string }>(
    `/${input.pageId}/video_stories`,
    input.token,
    {
      video_id: started.data.video_id,
      upload_phase: 'finish',
    },
  )
  if (!finished.ok) return finished
  if (!finished.data.success && !finished.data.post_id) {
    return { ok: false as const, message: 'Publication story vidéo refusée' }
  }
  return {
    ok: true as const,
    data: {
      id: finished.data.post_id ?? started.data.video_id,
      post_id: finished.data.post_id,
    },
  }
}

export async function publishFacebookPage(input: {
  pageId: string
  token: string
  caption: string
  linkUrl: string | null
  mediaUrl: string | null
  mimeType: string | null
  format: string
}) {
  if (input.format === 'story') {
    if (!input.mediaUrl) {
      return { ok: false as const, message: 'Une story Facebook exige un média' }
    }
    if (input.mimeType?.startsWith('video/')) {
      return publishFacebookVideoStory({
        pageId: input.pageId,
        token: input.token,
        mediaUrl: input.mediaUrl,
      })
    }
    if (input.mimeType?.startsWith('image/') || !input.mimeType) {
      return publishFacebookPhotoStory({
        pageId: input.pageId,
        token: input.token,
        mediaUrl: input.mediaUrl,
      })
    }
    return {
      ok: false as const,
      message: 'Format média non supporté pour une story Facebook',
    }
  }

  if (input.mediaUrl && input.mimeType?.startsWith('image/')) {
    return graphPost<{ id?: string; post_id?: string }>(
      `/${input.pageId}/photos`,
      input.token,
      {
        url: input.mediaUrl,
        caption: input.caption,
        published: true,
      },
    )
  }

  if (input.mediaUrl && input.mimeType?.startsWith('video/')) {
    return graphPost<{ id?: string }>(`/${input.pageId}/videos`, input.token, {
      file_url: input.mediaUrl,
      description: input.caption,
      published: true,
    })
  }

  const body: Record<string, unknown> = {
    message: input.caption,
    published: true,
  }
  if (input.linkUrl) body.link = input.linkUrl
  return graphPost<{ id?: string }>(`/${input.pageId}/feed`, input.token, body)
}

export async function publishInstagram(input: {
  igId: string
  token: string
  caption: string
  mediaUrl: string | null
  mimeType: string | null
  format: string
}) {
  if (!input.mediaUrl) {
    return { ok: false as const, message: 'Instagram exige un média public' }
  }

  const containerBody: Record<string, unknown> = {
    caption: input.caption,
  }

  if (input.format === 'story') {
    containerBody.media_type = 'STORIES'
    if (input.mimeType?.startsWith('video/')) {
      containerBody.video_url = input.mediaUrl
    } else {
      containerBody.image_url = input.mediaUrl
    }
  } else if (input.format === 'reel' || input.mimeType?.startsWith('video/')) {
    containerBody.media_type = 'REELS'
    containerBody.video_url = input.mediaUrl
  } else {
    containerBody.image_url = input.mediaUrl
  }

  const created = await graphPost<{ id?: string }>(
    `/${input.igId}/media`,
    input.token,
    containerBody,
  )
  if (!created.ok || !created.data.id) {
    return created.ok
      ? { ok: false as const, message: 'Conteneur IG introuvable' }
      : created
  }

  const ready = await waitIgContainer(created.data.id, input.token)
  if (!ready) {
    return { ok: false as const, message: 'Traitement IG échoué ou expiré' }
  }

  const published = await graphPost<{ id?: string }>(
    `/${input.igId}/media_publish`,
    input.token,
    { creation_id: created.data.id },
  )
  if (!published.ok) return published
  return {
    ok: true as const,
    data: {
      id: published.data.id,
      container_id: created.data.id,
    },
  }
}

export type PublishChannelResult = {
  channelId: string
  ok: boolean
  error: string | null
  metaPostId: string | null
  metaContainerId: string | null
  permalink: string | null
}

export async function publishToChannel(
  admin: SupabaseClient,
  input: {
    channelId: string
    caption: string
    linkUrl: string | null
    mediaUrl: string | null
    mimeType: string | null
    format: string
  },
): Promise<PublishChannelResult> {
  const { data: channel } = await admin
    .from('marketing_channels')
    .select('id, kind, meta_page_id, meta_ig_id, status')
    .eq('id', input.channelId)
    .maybeSingle()

  const { data: cred } = await admin
    .from('meta_channel_credentials')
    .select('access_token')
    .eq('channel_id', input.channelId)
    .maybeSingle()

  if (!channel || channel.status === 'disconnected' || !cred?.access_token) {
    return {
      channelId: input.channelId,
      ok: false,
      error: 'Compte déconnecté ou jeton manquant',
      metaPostId: null,
      metaContainerId: null,
      permalink: null,
    }
  }

  const ch = channel as ChannelRow
  let result:
    | { ok: true; data: { id?: string; post_id?: string; container_id?: string } }
    | { ok: false; message: string }

  if (ch.kind === 'facebook-page' && ch.meta_page_id) {
    result = await publishFacebookPage({
      pageId: ch.meta_page_id,
      token: cred.access_token,
      caption: input.caption,
      linkUrl: input.linkUrl,
      mediaUrl: input.mediaUrl,
      mimeType: input.mimeType,
      format: input.format,
    })
  } else if (ch.kind === 'instagram' && ch.meta_ig_id) {
    result = await publishInstagram({
      igId: ch.meta_ig_id,
      token: cred.access_token,
      caption: input.caption,
      mediaUrl: input.mediaUrl,
      mimeType: input.mimeType,
      format: input.format,
    })
  } else {
    result = { ok: false, message: 'Identifiants Meta incomplets' }
  }

  if (!result.ok) {
    return {
      channelId: input.channelId,
      ok: false,
      error: result.message,
      metaPostId: null,
      metaContainerId: null,
      permalink: null,
    }
  }

  const metaId = result.data.post_id ?? result.data.id ?? null
  let permalink: string | null = null
  if (metaId && ch.kind === 'facebook-page') {
    if (input.format === 'story') {
      permalink = `https://www.facebook.com/stories/${metaId}`
    } else {
      const res = await fetch(
        `https://graph.facebook.com/${GRAPH_VERSION}/${metaId}?fields=permalink_url`,
        { headers: { Authorization: `Bearer ${cred.access_token}` } },
      )
      const json = await res.json()
      permalink = json?.permalink_url ?? null
    }
  }

  return {
    channelId: input.channelId,
    ok: true,
    error: null,
    metaPostId: metaId,
    metaContainerId: result.data.container_id ?? null,
    permalink,
  }
}

export async function finalizePostStatus(
  admin: SupabaseClient,
  postId: string,
  published: number,
  failed: number,
) {
  const [{ count: pendingRuns }, { count: openJobs }] = await Promise.all([
    admin
      .from('marketing_post_runs')
      .select('id', { count: 'exact', head: true })
      .eq('post_id', postId)
      .in('status', ['pending', 'publishing']),
    admin
      .from('marketing_publish_jobs')
      .select('id', { count: 'exact', head: true })
      .eq('post_id', postId)
      .in('status', ['pending', 'running']),
  ])

  const stillOpen = (pendingRuns ?? 0) > 0 || (openJobs ?? 0) > 0
  let status: string
  if (stillOpen) {
    status = 'scheduled'
  } else if (published > 0 && failed > 0) {
    status = 'partial'
  } else if (published > 0) {
    status = 'published'
  } else {
    status = 'failed'
  }

  await admin
    .from('marketing_posts')
    .update({
      status,
      published_at: published > 0 ? new Date().toISOString() : null,
      recurrence_active: stillOpen,
      updated_at: new Date().toISOString(),
    })
    .eq('id', postId)

  return status
}
