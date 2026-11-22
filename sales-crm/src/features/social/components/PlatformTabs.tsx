import type {
  PlatformFilter,
  SocialConversation,
} from '@/features/social/domain/conversation'
import {
  countByPlatform,
  platformFilterLabels,
  platformFilters,
} from '@/features/social/domain/conversation'

type Props = {
  conversations: SocialConversation[]
  value: PlatformFilter
  onChange: (value: PlatformFilter) => void
}

/** Tous / Instagram / Facebook — counts and unread per network. */
export function PlatformTabs({ conversations, value, onChange }: Props) {
  const counts = countByPlatform(conversations)
  return (
    <div
      role="tablist"
      aria-label="Réseau"
      className="grid shrink-0 grid-cols-3 gap-1 border-b border-border p-2"
    >
      {platformFilters.map((filter) => {
        const { total, unread } = counts[filter]
        const active = value === filter
        return (
          <button
            key={filter}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onChange(filter)}
            className={`flex items-center justify-center gap-1.5 rounded-md px-2 py-1.5 text-[12px] font-medium transition-colors ${
              active
                ? 'bg-accent text-foreground'
                : 'text-muted-foreground hover:bg-muted/60'
            }`}
          >
            {filter !== 'all' && <PlatformDot platform={filter} />}
            {platformFilterLabels[filter]}
            <span className="tabular-nums text-muted-foreground">{total}</span>
            {unread > 0 && (
              <span className="rounded-full bg-primary px-1.5 text-[10px] font-semibold text-primary-foreground tabular-nums">
                {unread}
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}

export function PlatformDot({
  platform,
}: {
  platform: 'instagram' | 'messenger'
}) {
  return (
    <span
      aria-hidden
      className={`inline-flex size-4 shrink-0 items-center justify-center rounded text-[8px] font-bold text-white ${
        platform === 'instagram'
          ? 'bg-gradient-to-br from-[#F58529] via-[#DD2A7B] to-[#8134AF]'
          : 'bg-[#1877F2]'
      }`}
    >
      {platform === 'instagram' ? 'IG' : 'FB'}
    </span>
  )
}
