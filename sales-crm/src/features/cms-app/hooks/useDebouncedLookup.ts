import { useEffect, useState } from 'react'

type Lookup<T> = (query: string) => Promise<{ data: T[] | null; error: Error | null }>

type Answer<T> = { query: string; results: T[]; error: string | null }

/**
 * Debounced search-as-you-type over a service lookup. Each answer remembers
 * the query it belongs to, so a slow early response never shows up next to a
 * newer query, and "searching" is derived instead of stored.
 */
export function useDebouncedLookup<T>(lookup: Lookup<T>, delayMs = 300) {
  const [query, setQuery] = useState('')
  const [answer, setAnswer] = useState<Answer<T> | null>(null)
  const needle = query.trim()

  useEffect(() => {
    if (!needle) return
    let cancelled = false
    const handle = window.setTimeout(() => {
      void lookup(needle).then(({ data, error }) => {
        if (cancelled) return
        setAnswer({
          query: needle,
          results: data ?? [],
          error: error ? error.message : null,
        })
      })
    }, delayMs)
    return () => {
      cancelled = true
      window.clearTimeout(handle)
    }
  }, [needle, lookup, delayMs])

  const current = answer && answer.query === needle ? answer : null
  return {
    query,
    setQuery,
    results: current?.results ?? [],
    error: current?.error ?? null,
    isSearching: Boolean(needle) && current == null,
  }
}
