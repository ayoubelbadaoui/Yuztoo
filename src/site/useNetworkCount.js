import { useEffect, useState } from 'react'
import { fetchPartnerCount } from '../data/networkCount.js'
import { NETWORK } from '../siteConfig.js'

let pending = null

/**
 * Partner count shown on the site. Prerendered HTML and first paint use
 * NETWORK.partners; when NETWORK.liveCount is on, the live number from the
 * app replaces it after load (one request per page view, shared).
 */
export function useNetworkCount() {
  const [count, setCount] = useState(NETWORK.partners)

  useEffect(() => {
    if (!NETWORK.liveCount) return undefined
    let alive = true
    pending ??= fetchPartnerCount()
    pending.then(({ data }) => {
      if (alive && data !== null && data > 0) setCount(data)
    })
    return () => {
      alive = false
    }
  }, [])

  return count
}
