import { useEffect, useState } from 'react'
import { fetchPartnerCount } from '../data/networkCount.js'
import { NETWORK } from '../siteConfig.js'

let pending = null

/**
 * Partner count shown on the site: { count, live }. Prerendered HTML and
 * first paint use NETWORK.partners with live = false; when NETWORK.liveCount
 * is on and the app answers, count is the live number and live = true, so
 * « En direct » is only ever shown on data that really came from the app.
 */
export function useNetworkCount() {
  const [state, setState] = useState({ count: NETWORK.partners, live: false })

  useEffect(() => {
    if (!NETWORK.liveCount) return undefined
    let alive = true
    pending ??= fetchPartnerCount()
    pending.then(({ data }) => {
      if (alive && data !== null && data > 0) setState({ count: data, live: true })
    })
    return () => {
      alive = false
    }
  }, [])

  return state
}
