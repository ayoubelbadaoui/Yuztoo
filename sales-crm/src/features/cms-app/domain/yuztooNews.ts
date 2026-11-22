/** Mirrors Flutter `yuztoo_news` + Admin callable JSON (ISO dates). */
export type YuztooNewsReleaseStatus = 'draft' | 'preview' | 'live'

export type YuztooNews = {
  id: string
  title: string
  body: string
  /** ISO timestamp — app shows only when ≤ now */
  publish_on: string
  active: boolean
  image_url: string | null
  cta_label: string | null
  cta_url: string | null
  /** Opens shop in app; wins over `cta_url` */
  cta_merchant_id: string | null
  /** Shop name for the CMS only (the app reads `cta_merchant_id`). */
  cta_merchant_label: string | null
  /** draft → preview (test UID) → live (everyone) */
  release_status: YuztooNewsReleaseStatus
  test_account_id: string | null
  test_account_label: string | null
  preview_activated_at: string | null
  live_at: string | null
  created_at?: string
  updated_at?: string
}

export type YuztooNewsInput = {
  id?: string | null
  title: string
  body: string
  publish_on: string
  active: boolean
  image_url?: string | null
  cta_label?: string | null
  cta_url?: string | null
  cta_merchant_id?: string | null
  cta_merchant_label?: string | null
}

/** What the actu's button does — derived from the cta_* fields. */
export type YuztooNewsCtaKind = 'none' | 'merchant' | 'url'

export const yuztooNewsCtaKindLabels: Record<YuztooNewsCtaKind, string> = {
  none: 'Sans bouton',
  merchant: 'Ouvrir une boutique',
  url: 'Ouvrir un lien',
}

export const YUZTOO_NEWS_DEFAULT_CTA_LABEL = 'En savoir plus'

export function ctaKindOf(
  news: Pick<YuztooNews, 'cta_merchant_id' | 'cta_url'> | null,
): YuztooNewsCtaKind {
  if (news?.cta_merchant_id) return 'merchant'
  if (news?.cta_url) return 'url'
  return 'none'
}

/** One real client picked to receive the test preview (masked contact). */
export type NewsTestClient = {
  id: string
  displayName: string
  contactHint: string | null
  city: string | null
}

/** A shop an actu button can open. */
export type NewsMerchantOption = {
  id: string
  name: string
  city: string | null
  logoUrl: string | null
  status: string | null
}

export type YuztooNewsActiveFilter = 'all' | 'active' | 'inactive'

export const YUZTOO_NEWS_TITLE_MAX = 200
export const YUZTOO_NEWS_BODY_MAX = 8000
export const YUZTOO_NEWS_CTA_LABEL_MAX = 80

export const yuztooNewsReleaseLabels: Record<YuztooNewsReleaseStatus, string> =
  {
    draft: 'Brouillon',
    preview: 'Test · 1 client',
    live: 'En ligne · tous les clients',
  }

export function normalizeReleaseStatus(
  raw: string | null | undefined,
): YuztooNewsReleaseStatus {
  if (raw === 'draft' || raw === 'preview' || raw === 'live') return raw
  // Legacy docs without the field behave as live.
  return 'live'
}

export function canActivateNewsPreview(news: YuztooNews): boolean {
  return Boolean(news.test_account_id)
}

export function canPublishNewsLive(news: YuztooNews): boolean {
  return (
    news.release_status === 'preview' &&
    Boolean(news.test_account_id) &&
    Boolean(news.preview_activated_at)
  )
}

export function isNewsVisibleNow(news: YuztooNews, now = new Date()): boolean {
  if (!news.active) return false
  if (news.release_status === 'draft') return false
  const publishAt = new Date(news.publish_on)
  if (Number.isNaN(publishAt.getTime())) return false
  return publishAt.getTime() <= now.getTime()
}

export function newsStatusLabel(news: YuztooNews, now = new Date()): string {
  if (!news.active) return 'Inactive'
  if (news.release_status === 'draft') return yuztooNewsReleaseLabels.draft
  if (news.release_status === 'preview') {
    return yuztooNewsReleaseLabels.preview
  }
  const publishAt = new Date(news.publish_on)
  if (Number.isNaN(publishAt.getTime())) return 'Date invalide'
  if (publishAt.getTime() > now.getTime()) return 'Programmée'
  return yuztooNewsReleaseLabels.live
}

