import { supabase } from '@/lib/supabaseClient'

type EdgeResult<T> = { data: T | null; error: Error | null }

/**
 * Invoke a Supabase Edge Function with the signed-in user JWT.
 * Used from feature services only — never from components directly for Meta.
 */
async function errorMessageFrom(context: unknown): Promise<string | null> {
  if (!(context instanceof Response)) return null
  try {
    const payload = (await context.clone().json()) as { error?: unknown }
    return typeof payload?.error === 'string' ? payload.error : null
  } catch {
    return null
  }
}

export async function callEdgeFunction<T>(
  name: string,
  body?: Record<string, unknown>,
): Promise<EdgeResult<T>> {
  try {
    const { data, error } = await supabase.functions.invoke(name, {
      body: body ?? {},
    })
    if (error) {
      // On a non-2xx, supabase-js leaves `data` null and keeps the raw
      // Response in `error.context` — read the function's own message there.
      const fromBody = await errorMessageFrom(
        (error as { context?: unknown }).context,
      )
      return { data: null, error: new Error(fromBody ?? error.message) }
    }
    return { data: data as T, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
