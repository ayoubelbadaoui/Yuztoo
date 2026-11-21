import { Users, X } from 'lucide-react'

import { ChannelIcon } from '@/features/marketing/components/ChannelBadge'
import type { AudienceFilter } from '@/features/marketing/domain/audience'
import { toggle, totalReach } from '@/features/marketing/domain/audience'
import type { Channel, ChannelKind } from '@/features/marketing/domain/channel'
import {
  channelKindLabels,
  formatFollowers,
  groupChannelPairs,
  networkMixLabel,
} from '@/features/marketing/domain/channel'

type Props = {
  channels: Channel[]
  audience: AudienceFilter
  onAudience: (audience: AudienceFilter) => void
  matched: Channel[]
  selected: Channel[]
  excluded: string[]
  onToggleExcluded: (channelId: string) => void
}

const chip = (isOn: boolean) =>
  `h-7 rounded-full px-2.5 text-[12px] transition-colors ${
    isOn
      ? 'bg-primary text-primary-foreground'
      : 'border border-border text-muted-foreground hover:bg-muted'
  }`

const BOTH_KINDS: ChannelKind[] = ['facebook-page', 'instagram']

function bothKindsOn(kinds: ChannelKind[]) {
  return BOTH_KINDS.every((kind) => kinds.includes(kind))
}

export function AudiencePicker({
  channels,
  audience,
  onAudience,
  matched,
  selected,
  excluded,
  onToggleExcluded,
}: Props) {
  const cities = [
    ...new Set(
      channels
        .map((channel) => channel.city)
        .filter((city): city is string => Boolean(city)),
    ),
  ].sort()
  const plans = [
    ...new Set(
      channels
        .map((channel) => channel.planName)
        .filter((plan): plan is string => Boolean(plan)),
    ),
  ].sort()

  const pairs = groupChannelPairs(matched)
  const allKinds = audience.kinds.length === 0

  const setKinds = (kinds: ChannelKind[]) =>
    onAudience({ ...audience, kinds })

  const togglePair = (ids: string[]) => {
    const allSelected = ids.every(
      (id) => !excluded.includes(id) && matched.some((c) => c.id === id),
    )
    for (const id of ids) {
      const isExcluded = excluded.includes(id)
      if (allSelected && !isExcluded) onToggleExcluded(id)
      if (!allSelected && isExcluded) onToggleExcluded(id)
    }
  }

  return (
    <div className="flex flex-col gap-3 rounded-xl border border-border bg-muted/40 p-3">
      <div className="flex flex-wrap items-center gap-1.5">
        <span className="text-[12px] text-muted-foreground">Comptes</span>
        <button
          type="button"
          onClick={() =>
            onAudience({ ...audience, includeYuztoo: !audience.includeYuztoo })
          }
          className={chip(audience.includeYuztoo)}
        >
          Yuztoo
        </button>
        <button
          type="button"
          onClick={() =>
            onAudience({
              ...audience,
              includeMerchants: !audience.includeMerchants,
            })
          }
          className={chip(audience.includeMerchants)}
        >
          Commerçants partenaires
        </button>
      </div>

      <div className="flex flex-col gap-1.5">
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="text-[12px] text-muted-foreground">Réseau</span>
          <button
            type="button"
            title="Publier sur Facebook et Instagram en même temps"
            onClick={() =>
              setKinds(
                bothKindsOn(audience.kinds) || allKinds ? [] : [...BOTH_KINDS],
              )
            }
            className={chip(allKinds || bothKindsOn(audience.kinds))}
          >
            FB + IG
          </button>
          {BOTH_KINDS.map((kind) => (
            <button
              key={kind}
              type="button"
              onClick={() => setKinds(toggle(audience.kinds, kind))}
              className={chip(!allKinds && audience.kinds.includes(kind))}
            >
              {channelKindLabels[kind]}
            </button>
          ))}
        </div>
        <p className="text-[11px] text-muted-foreground">
          Cochez FB + IG (ou les deux chips) pour envoyer la même publication
          sur les deux réseaux d’un coup.
        </p>
      </div>

      {(cities.length > 0 || plans.length > 0) && (
        <>
          {cities.length > 0 && (
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-[12px] text-muted-foreground">Ville</span>
              {cities.map((city) => (
                <button
                  key={city}
                  type="button"
                  onClick={() =>
                    onAudience({
                      ...audience,
                      cities: toggle(audience.cities, city),
                    })
                  }
                  className={chip(audience.cities.includes(city))}
                >
                  {city}
                </button>
              ))}
            </div>
          )}

          {plans.length > 0 && (
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-[12px] text-muted-foreground">Formule</span>
              {plans.map((plan) => (
                <button
                  key={plan}
                  type="button"
                  onClick={() =>
                    onAudience({
                      ...audience,
                      plans: toggle(audience.plans, plan),
                    })
                  }
                  className={chip(audience.plans.includes(plan))}
                >
                  {plan}
                </button>
              ))}
            </div>
          )}
        </>
      )}

      <div className="flex items-center gap-2 border-t border-border pt-2.5">
        <Users className="size-3.5 shrink-0 text-primary" />
        <p className="text-[12px] text-foreground">
          {selected.length === 0
            ? 'Aucun compte sélectionné'
            : `${selected.length} compte${selected.length > 1 ? 's' : ''} · ${networkMixLabel(selected)} · ${formatFollowers(totalReach(selected))} abonnés`}
        </p>
      </div>

      {pairs.length > 0 && (
        <ul className="scrollbar-none flex max-h-40 flex-col gap-1.5 overflow-y-auto">
          {pairs.map((pair) => {
            const members = [pair.facebook, pair.instagram].filter(
              (channel): channel is Channel => Boolean(channel),
            )
            const ids = members.map((channel) => channel.id)
            const allOn = ids.every((id) => !excluded.includes(id))
            const label =
              pair.facebook?.name ??
              pair.instagram?.name ??
              'Compte connecté'

            return (
              <li
                key={pair.pageMetaId}
                className="rounded-lg border border-border/70 bg-background/50"
              >
                <div className="flex items-center gap-2 px-2 py-1.5">
                  <div className="flex min-w-0 flex-1 items-center gap-1.5">
                    {members.map((channel) => (
                      <ChannelIcon key={channel.id} channel={channel} />
                    ))}
                    <span className="min-w-0 truncate text-[12px] text-foreground">
                      {label}
                    </span>
                  </div>
                  {members.length === 2 && (
                    <button
                      type="button"
                      onClick={() => togglePair(ids)}
                      className={`h-6 shrink-0 rounded-full px-2 text-[11px] ${
                        allOn
                          ? 'bg-primary/15 text-primary'
                          : 'border border-border text-muted-foreground'
                      }`}
                    >
                      Les deux
                    </button>
                  )}
                </div>
                <ul className="flex flex-col border-t border-border/60">
                  {members.map((channel) => {
                    const isExcluded = excluded.includes(channel.id)
                    return (
                      <li key={channel.id}>
                        <button
                          type="button"
                          onClick={() => onToggleExcluded(channel.id)}
                          title={
                            isExcluded
                              ? 'Remettre dans le lot'
                              : 'Retirer du lot'
                          }
                          className={`flex w-full items-center gap-2 px-2 py-1 text-left transition-colors hover:bg-muted ${
                            isExcluded ? 'opacity-40' : ''
                          }`}
                        >
                          <ChannelIcon channel={channel} />
                          <span className="min-w-0 flex-1 truncate text-[12px] text-foreground">
                            {channelKindLabels[channel.kind]}
                            {channel.kind === 'instagram'
                              ? ` · @${channel.handle}`
                              : ''}
                          </span>
                          <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
                            {formatFollowers(channel.followers)}
                          </span>
                          <X className="size-3 shrink-0 text-muted-foreground" />
                        </button>
                      </li>
                    )
                  })}
                </ul>
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
