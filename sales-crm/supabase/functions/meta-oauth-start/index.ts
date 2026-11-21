import { getConfig } from '../_shared/config.ts'
import { ALLOWED_ORIGINS, jsonResponse, withCors } from '../_shared/cors.ts'
import { createAdminClient, createUserClient } from '../_shared/supabase.ts'

const GRAPH_VERSION = 'v22.0'
const SCOPES = [
  'public_profile',
  'pages_show_list',
  'pages_messaging',
  'pages_manage_metadata',
  'pages_manage_posts',
  'pages_read_engagement',
  'pages_read_user_content',
  'pages_manage_engagement',
  'publish_video',
  'instagram_basic',
  'instagram_manage_messages',
  'instagram_manage_comments',
  'instagram_content_publish',
  'business_management',
].join(',')

async function resolveRedirectUri(req: Request): Promise<string | null> {
  const origin = req.headers.get('origin')
  if (origin && ALLOWED_ORIGINS.has(origin)) {
    return `${origin}/meta-oauth`
  }
  return getConfig('META_OAUTH_REDIRECT_URI')
}

async function handle(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    const appId = await getConfig('META_APP_ID')
    const redirectUri = await resolveRedirectUri(req)
    const configId = await getConfig('META_LOGIN_CONFIG_ID')
    if (!appId || !redirectUri) {
      return jsonResponse({ error: 'Meta OAuth is not configured' }, 500)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const body = (await req.json()) as {
      workspaceId?: string
      returnTo?: string
    }
    if (!body.workspaceId) {
      return jsonResponse({ error: 'workspaceId required' }, 400)
    }

    const userClient = createUserClient(authHeader)
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const { data: membership } = await userClient
      .from('workspace_members')
      .select('role')
      .eq('workspace_id', body.workspaceId)
      .eq('user_id', user.id)
      .maybeSingle()

    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      return jsonResponse({ error: 'Forbidden' }, 403)
    }

    const admin = createAdminClient()
    const returnTo = body.returnTo?.startsWith('/')
      ? body.returnTo
      : '/?page=channels'
    const appOrigin = new URL(redirectUri).origin

    const { data: stateRow, error: stateError } = await admin
      .from('meta_oauth_states')
      .insert({
        workspace_id: body.workspaceId,
        user_id: user.id,
        return_to: returnTo,
        app_origin: appOrigin,
      })
      .select('id')
      .single()

    if (stateError || !stateRow) {
      return jsonResponse({ error: 'Could not start OAuth' }, 500)
    }

    const url = new URL(`https://www.facebook.com/${GRAPH_VERSION}/dialog/oauth`)
    url.searchParams.set('client_id', appId)
    url.searchParams.set('redirect_uri', redirectUri)
    url.searchParams.set('state', stateRow.id)
    url.searchParams.set('response_type', 'code')
    if (configId) {
      // Facebook Login for Business: permissions come from the configuration
      url.searchParams.set('config_id', configId)
      url.searchParams.set('override_default_response_type', 'true')
    } else {
      url.searchParams.set('scope', SCOPES)
    }

    return jsonResponse({ authorizeUrl: url.toString() })
  } catch {
    return jsonResponse({ error: 'Request failed' }, 500)
  }
}

Deno.serve(withCors(handle))
