import { useEffect, useState } from 'react'

import { callEdgeFunction } from '@/lib/callEdgeFunction'

type CompleteResult = { ok: boolean; returnTo?: string; error?: string }

/**
 * Meta redirects here after OAuth (localhost / CRM origin).
 * We finish the token exchange on Edge, then send the user back to Channels.
 */
export function MetaOAuthPage() {
  const [message, setMessage] = useState('Connexion Meta en cours…')

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const code = params.get('code')
    const state = params.get('state')
    const oauthError = params.get('error')

    if (oauthError) {
      setMessage('Autorisation Meta annulée.')
      return
    }
    if (!code || !state) {
      setMessage('Lien OAuth invalide.')
      return
    }

    void (async () => {
      const { data, error } = await callEdgeFunction<CompleteResult>(
        'meta-oauth-complete',
        { code, state },
      )
      if (error || !data?.ok) {
        setMessage(data?.error ?? error?.message ?? 'Échec de la connexion Meta')
        return
      }
      const dest = data.returnTo?.startsWith('/')
        ? data.returnTo
        : '/?page=channels'
      const url = new URL(dest, window.location.origin)
      url.searchParams.set('meta_connected', '1')
      window.location.replace(url.pathname + url.search)
    })()
  }, [])

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 text-center text-[13px] text-muted-foreground">
      {message}
    </div>
  )
}
