import { Camera, Globe } from 'lucide-react'

import { Badge } from '@/components/ui/Badge'
import type { BadgeTone } from '@/components/ui/Badge'
import type { Channel, ConnectionStatus } from '@/features/marketing/domain/channel'
import {
  channelKindLabels,
  connectionStatusLabels,
} from '@/features/marketing/domain/channel'

const tones: Record<ConnectionStatus, BadgeTone> = {
  connected: 'success',
  expiring: 'warning',
  disconnected: 'danger',
}

/** lucide ne fournit plus les logos de marque : on garde une icône générique. */
export function ChannelIcon({ channel }: { channel: Channel }) {
  const Icon = channel.kind === 'instagram' ? Camera : Globe
  return (
    <Icon
      className="size-3.5 shrink-0 text-muted-foreground"
      aria-label={channelKindLabels[channel.kind]}
    />
  )
}

export function ConnectionBadge({ status }: { status: ConnectionStatus }) {
  return <Badge tone={tones[status]}>{connectionStatusLabels[status]}</Badge>
}
