import { createAdminClient } from './supabase.ts'

const cache = new Map<string, string>()

/** Prefer Deno env; fall back to DB config via service-role RPC. */
export async function getConfig(key: string): Promise<string | null> {
  const fromEnv = Deno.env.get(key)
  if (fromEnv) return fromEnv
  if (cache.has(key)) return cache.get(key) ?? null

  const admin = createAdminClient()
  const { data, error } = await admin.rpc('get_edge_config', { p_key: key })
  if (error || data == null || data === '') return null
  const value = String(data)
  cache.set(key, value)
  return value
}
