import { supabase } from '@/lib/supabaseClient'

type EdgeResult<T> = { data: T | null; error: Error | null }

/**
 * Invoke a Supabase Edge Function with the signed-in user JWT.
 * Used from feature services only — never from components directly for Meta.
 */
export async function callEdgeFunction<T>(
  name: string,
  body?: Record<string, unknown>,
): Promise<EdgeResult<T>> {
  try {
    const { data, error } = await supabase.functions.invoke(name, {
      body: body ?? {},
    })
    if (error) {
      const fromBody =
        data &&
        typeof data === 'object' &&
        'error' in data &&
        typeof (data as { error?: unknown }).error === 'string'
          ? (data as { error: string }).error
          : null
      return { data: null, error: new Error(fromBody ?? error.message) }
    }
    return { data: data as T, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
