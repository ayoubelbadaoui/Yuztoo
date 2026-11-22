import type { YuztooNews } from '@/features/cms-app/domain/yuztooNews'
import { normalizeReleaseStatus } from '@/features/cms-app/domain/yuztooNews'

const STORAGE_KEY = 'cms-app-yuztoo-news'

const day = 24 * 60 * 60 * 1000

function isoDaysFromNow(days: number): string {
  return new Date(Date.now() + days * day).toISOString()
}

const seedNews: YuztooNews[] = [
  {
    id: 'news_welcome',
    title: 'Bienvenue sur Yuztoo',
    body: 'Découvrez les nouveautés de l’app : fidélité, passages et promotions près de chez vous.',
    publish_on: isoDaysFromNow(-2),
    active: true,
    image_url: null,
    cta_label: 'En savoir plus',
    cta_url: 'https://yuztoo.com',
    cta_merchant_id: null,
    cta_merchant_label: null,
    release_status: 'draft',
    test_account_id: null,
    test_account_label: null,
    preview_activated_at: null,
    live_at: null,
    created_at: isoDaysFromNow(-3),
    updated_at: isoDaysFromNow(-2),
  },
  {
    id: 'news_draft_future',
    title: 'Prochaine fonctionnalité',
    body: 'Une nouveauté arrive bientôt — cette actu est programmée et inactive pour la démo CMS.',
    publish_on: isoDaysFromNow(7),
    active: false,
    image_url: null,
    cta_label: null,
    cta_url: null,
    cta_merchant_id: null,
    cta_merchant_label: null,
    release_status: 'draft',
    test_account_id: null,
    test_account_label: null,
    preview_activated_at: null,
    live_at: null,
    created_at: isoDaysFromNow(-1),
    updated_at: isoDaysFromNow(-1),
  },
]

function coerce(item: YuztooNews): YuztooNews {
  return {
    ...item,
    release_status: normalizeReleaseStatus(item.release_status),
    cta_merchant_label: item.cta_merchant_label ?? null,
    test_account_id: item.test_account_id ?? null,
    test_account_label: item.test_account_label ?? null,
    preview_activated_at: item.preview_activated_at ?? null,
    live_at: item.live_at ?? null,
  }
}

export function loadYuztooNews(): YuztooNews[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) {
      saveYuztooNews(seedNews)
      return seedNews.map(coerce)
    }
    const parsed = JSON.parse(raw) as YuztooNews[]
    if (!Array.isArray(parsed)) {
      saveYuztooNews(seedNews)
      return seedNews.map(coerce)
    }
    return parsed.map(coerce)
  } catch {
    return seedNews.map(coerce)
  }
}

export function saveYuztooNews(items: YuztooNews[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(items))
}
