import { Check, ExternalLink, Link2 } from 'lucide-react'
import { useState } from 'react'

import { buildSigningUrl } from '@/features/contracts/domain/signature'

const iconButton =
  'rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground'

export function SigningLinkButtons({ contractId }: { contractId: string }) {
  const [isCopied, setIsCopied] = useState(false)
  const url = buildSigningUrl(window.location.origin, contractId)

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url)
      setIsCopied(true)
      window.setTimeout(() => setIsCopied(false), 1600)
    } catch {
      window.prompt('Copiez le lien de signature', url)
    }
  }

  return (
    <div
      className="flex items-center justify-end gap-0.5"
      onClick={(event) => event.stopPropagation()}
      onKeyDown={(event) => event.stopPropagation()}
      role="presentation"
    >
      <button
        type="button"
        onClick={() => void copy()}
        aria-label="Copier le lien de signature"
        title="Copier le lien"
        className={iconButton}
      >
        {isCopied ? (
          <Check className="size-4 text-success" />
        ) : (
          <Link2 className="size-4" />
        )}
      </button>

      <a
        href={url}
        target="_blank"
        rel="noreferrer"
        aria-label="Ouvrir la page de signature"
        title="Ouvrir la vue client"
        className={iconButton}
      >
        <ExternalLink className="size-4" />
      </a>
    </div>
  )
}
