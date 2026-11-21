export type WorkspaceRole = 'owner' | 'admin' | 'seller' | 'viewer'

export type WorkspaceMembership = {
  workspaceId: string
  workspaceName: string
  role: WorkspaceRole
}

export type AuthUser = {
  id: string
  email: string | null
}

export type AuthSession = {
  user: AuthUser
  memberships: WorkspaceMembership[]
  /** Active workspace for UX; RLS still checks membership. */
  activeWorkspaceId: string | null
}

export function pickActiveWorkspace(
  memberships: WorkspaceMembership[],
  preferredId: string | null,
): string | null {
  if (preferredId && memberships.some((m) => m.workspaceId === preferredId)) {
    return preferredId
  }
  return memberships[0]?.workspaceId ?? null
}
