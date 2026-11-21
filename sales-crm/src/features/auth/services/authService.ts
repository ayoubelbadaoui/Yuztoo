import type {
  AuthSession,
  AuthUser,
  WorkspaceMembership,
  WorkspaceRole,
} from '@/features/auth/domain/session'
import { pickActiveWorkspace } from '@/features/auth/domain/session'
import { supabase } from '@/lib/supabaseClient'

type Result<T> = { data: T | null; error: Error | null }

const ACTIVE_WS_KEY = 'yuztoo-crm:active-workspace'

function toError(error: unknown): Error {
  if (error instanceof Error) return error
  return new Error('Une erreur est survenue')
}

function mapUser(user: { id: string; email?: string | null }): AuthUser {
  return { id: user.id, email: user.email ?? null }
}

async function loadMemberships(userId: string): Promise<WorkspaceMembership[]> {
  const { data, error } = await supabase
    .from('workspace_members')
    .select('workspace_id, role, workspaces(id, name)')
    .eq('user_id', userId)

  if (error) throw error

  return (data ?? []).flatMap((row) => {
    const workspace = row.workspaces as
      | { id: string; name: string }
      | { id: string; name: string }[]
      | null
    const ws = Array.isArray(workspace) ? workspace[0] : workspace
    if (!ws) return []
    return [
      {
        workspaceId: ws.id,
        workspaceName: ws.name,
        role: row.role as WorkspaceRole,
      },
    ]
  })
}

function readPreferredWorkspace(): string | null {
  try {
    return localStorage.getItem(ACTIVE_WS_KEY)
  } catch {
    return null
  }
}

export function persistActiveWorkspace(workspaceId: string | null): void {
  try {
    if (workspaceId) localStorage.setItem(ACTIVE_WS_KEY, workspaceId)
    else localStorage.removeItem(ACTIVE_WS_KEY)
  } catch {
    /* ignore quota */
  }
}

async function buildSession(user: AuthUser): Promise<AuthSession> {
  const memberships = await loadMemberships(user.id)
  const activeWorkspaceId = pickActiveWorkspace(
    memberships,
    readPreferredWorkspace(),
  )
  return { user, memberships, activeWorkspaceId }
}

export async function getSession(): Promise<Result<AuthSession | null>> {
  try {
    const { data, error } = await supabase.auth.getSession()
    if (error) throw error
    if (!data.session?.user) return { data: null, error: null }
    const session = await buildSession(mapUser(data.session.user))
    return { data: session, error: null }
  } catch (error) {
    return { data: null, error: toError(error) }
  }
}

export async function signInWithPassword(
  email: string,
  password: string,
): Promise<Result<AuthSession>> {
  try {
    const trimmed = email.trim()
    if (!trimmed || password.length < 6) {
      throw new Error('E-mail et mot de passe (6 caractères min.) requis')
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email: trimmed,
      password,
    })
    if (error) throw error
    if (!data.user) throw new Error('Connexion impossible')

    const session = await buildSession(mapUser(data.user))
    return { data: session, error: null }
  } catch (error) {
    return { data: null, error: toError(error) }
  }
}

export async function signUpWithPassword(
  email: string,
  password: string,
  fullName: string,
): Promise<Result<AuthSession | { needsEmailConfirmation: true }>> {
  try {
    const trimmed = email.trim()
    if (!trimmed || password.length < 6) {
      throw new Error('E-mail et mot de passe (6 caractères min.) requis')
    }

    const { data, error } = await supabase.auth.signUp({
      email: trimmed,
      password,
      options: {
        data: { full_name: fullName.trim() || undefined },
      },
    })
    if (error) throw error
    if (!data.user) throw new Error('Inscription impossible')

    // Confirm e-mail activé : pas de session tant que le lien n'est pas validé.
    if (!data.session) {
      return { data: { needsEmailConfirmation: true }, error: null }
    }

    const session = await buildSession(mapUser(data.user))
    return { data: session, error: null }
  } catch (error) {
    return { data: null, error: toError(error) }
  }
}

export async function signOut(): Promise<Result<null>> {
  try {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    persistActiveWorkspace(null)
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: toError(error) }
  }
}

export function onAuthStateChange(
  callback: (session: AuthSession | null) => void,
): () => void {
  const { data } = supabase.auth.onAuthStateChange((_event, next) => {
    void (async () => {
      if (!next?.user) {
        callback(null)
        return
      }
      try {
        callback(await buildSession(mapUser(next.user)))
      } catch {
        callback(null)
      }
    })()
  })
  return () => data.subscription.unsubscribe()
}

export async function setActiveWorkspace(
  workspaceId: string,
): Promise<Result<string>> {
  try {
    persistActiveWorkspace(workspaceId)
    return { data: workspaceId, error: null }
  } catch (error) {
    return { data: null, error: toError(error) }
  }
}
