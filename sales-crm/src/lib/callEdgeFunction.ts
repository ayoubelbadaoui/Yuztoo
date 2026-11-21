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
    if (error) return { data: null, error: new Error(error.message) }
    return { data: data as T, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
