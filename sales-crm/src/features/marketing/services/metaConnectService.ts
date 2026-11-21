import { callEdgeFunction } from '@/lib/callEdgeFunction'

type StartResult = { authorizeUrl: string }

/**
 * Starts Meta OAuth for the active workspace. Tokens stay on Edge;
 * the browser only receives the authorize URL.
 */
export async function startMetaConnect(input: {
  workspaceId: string
  returnTo?: string
}): Promise<{ data: StartResult | null; error: Error | null }> {
  return callEdgeFunction<StartResult>('meta-oauth-start', {
    workspaceId: input.workspaceId,
    returnTo: input.returnTo ?? '/?page=channels',
  })
}
