import { Globe, Mail, Phone, PlayCircle } from 'lucide-react'
import type { ElementType } from 'react'

import type { MessageSource } from '@/features/inbox/domain/message'
import { messageSourceLabels } from '@/features/inbox/domain/message'

const icons: Record<MessageSource, ElementType> = {
  'website-form': Globe,
  'website-demo': PlayCircle,
  'website-callback': Phone,
  email: Mail,
}

type Props = {
  source: MessageSource
  /** Variante icône seule, pour les lignes de liste déjà denses. */
  iconOnly?: boolean
}

export function SourceBadge({ source, iconOnly = false }: Props) {
  const Icon = icons[source]
  const label = messageSourceLabels[source]

  if (iconOnly) {
    return (
      <span title={label} aria-label={label}>
        <Icon className="size-3.5 shrink-0 text-muted-foreground" />
      </span>
    )
  }

  return (
    <span className="inline-flex h-5 items-center gap-1 rounded-full bg-muted px-2 text-[11px] font-medium text-muted-foreground">
      <Icon className="size-3" />
      {label}
    </span>
  )
}
