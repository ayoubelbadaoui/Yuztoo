import type { Channel, ChannelKind } from '@/features/marketing/domain/channel'
import { isPublishable } from '@/features/marketing/domain/channel'

/**
 * Ciblage en masse : le marketeur ne coche pas quarante comptes à la main, il
 * décrit la population voulue et le CRM résout la liste.
 */
export type AudienceFilter = {
  kinds: ChannelKind[]
  cities: string[]
  plans: string[]
  /** Comptes Yuztoo, comptes commerçants, ou les deux. */
  includeYuztoo: boolean
  includeMerchants: boolean
}

export const emptyAudience: AudienceFilter = {
  kinds: [],
  cities: [],
  plans: [],
  includeYuztoo: true,
  includeMerchants: false,
}

export function selectChannels(
  channels: Channel[],
  filter: AudienceFilter,
): Channel[] {
  return channels.filter((channel) => {
    if (!isPublishable(channel)) return false
    if (channel.owner === 'yuztoo' && !filter.includeYuztoo) return false
    if (channel.owner === 'merchant' && !filter.includeMerchants) return false
    if (filter.kinds.length > 0 && !filter.kinds.includes(channel.kind)) {
      return false
    }
    if (filter.cities.length > 0) {
      if (!channel.city || !filter.cities.includes(channel.city)) return false
    }
    if (filter.plans.length > 0) {
      if (!channel.planName || !filter.plans.includes(channel.planName)) {
        return false
      }
    }
    return true
  })
}

export function totalReach(channels: Channel[]): number {
  return channels.reduce((sum, channel) => sum + channel.followers, 0)
}

/** Bascule une valeur dans une liste de filtre, sans muter l'original. */
export function toggle<T>(values: T[], value: T): T[] {
  return values.includes(value)
    ? values.filter((current) => current !== value)
    : [...values, value]
}
