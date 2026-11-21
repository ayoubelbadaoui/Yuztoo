export type MediaSlotId =
  | 'brand.logo'
  | 'onboarding.merchant.hero_personal'
  | 'onboarding.merchant.hero_commerce'
  | 'onboarding.merchant.hero_audience'
  | 'onboarding.merchant.hero_city'
  | 'onboarding.client.hero'
  | 'empty.loyalty'
  | 'empty.passages'
  | 'empty.promotions'
  | 'onboarding.category.bouche'
  | 'onboarding.category.commerce'
  | 'onboarding.category.beaute'
  | 'onboarding.category.sante'
  | 'onboarding.category.services_particuliers'
  | 'onboarding.category.loisirs'
  | 'onboarding.category.association'
  | 'onboarding.category.autre'
  | 'onboarding.category.artisan_btp'
  | 'onboarding.category.services_pro'
  | 'onboarding.category.grossiste'
  | 'onboarding.category.immobilier'
  | 'onboarding.category.finance_juridique'
  | 'onboarding.category.livraison'
  | 'onboarding.category.independants'
  | 'onboarding.category.autres_pro'

export type MediaSlotGroup =
  | 'branding'
  | 'onboarding'
  | 'categories'
  | 'empty'

/** Drives size / export constraints in CMS + Admin CF. */
export type MediaSlotProfile = 'brand' | 'hero' | 'icon' | 'illustration'

export type MediaObjectFit = 'contain' | 'cover'

export type MediaPreviewShape = 'square' | 'circle' | 'card43'

export type MediaDefaultIconKey =
  | 'user'
  | 'store'
  | 'users'
  | 'building'
  | 'gift'
  | 'tag'
  | 'usersRound'
  | 'utensils'
  | 'sparkles'
  | 'heartPulse'
  | 'wrench'
  | 'ferrisWheel'
  | 'layoutGrid'
  | 'hardHat'
  | 'briefcase'
  | 'warehouse'
  | 'landmark'
  | 'truck'
  | 'badgeCheck'

/** What Flutter shows today when no custom CMS image is published. */
export type MediaDefaultPreview =
  | { kind: 'image'; src: string; alt: string }
  | {
      kind: 'icon'
      icon: MediaDefaultIconKey
      tone: 'goldOnNavy' | 'goldOnCard'
    }

export type MediaSlotDefinition = {
  id: MediaSlotId
  group: MediaSlotGroup
  profile: MediaSlotProfile
  label: string
  description: string
  /** width / height */
  aspectRatio: number
  recommendedWidth: number
  recommendedHeight: number
  maxBytes: number
  allowedMime: readonly string[]
  objectFit: MediaObjectFit
  previewShape: MediaPreviewShape
  /** Flutter resolves this slot remotely when release allows */
  flutterWired: boolean
  defaultNote: string
  /** Visual of the current in-app default (shown in Aperçu when Défaut) */
  defaultPreview: MediaDefaultPreview
}

export type MediaSlotState = MediaSlotDefinition & {
  imageDataUrl: string | null
  updatedAt: string | null
  isCustom: boolean
}

export const MEDIA_MAX_BYTES_DEFAULT = 1_500_000
/** Category / small badge icons — hard cap for Storage + CMS. */
export const MEDIA_MAX_BYTES_ICON = 200_000

export const MEDIA_ALLOWED_MIME = [
  'image/png',
  'image/jpeg',
  'image/webp',
] as const

export const mediaGroupLabels: Record<MediaSlotGroup, string> = {
  branding: 'Branding',
  onboarding: 'Onboarding',
  categories: 'Catégories onboarding',
  empty: 'États vides',
}

export function formatMaxBytes(maxBytes: number): string {
  if (maxBytes < 1_000_000) {
    return `${Math.round(maxBytes / 1_000)} Ko`
  }
  return `${(maxBytes / 1_000_000).toFixed(1)} Mo`
}

export function formatSlotConstraints(slot: MediaSlotDefinition): string {
  return `${formatAspectLabel(slot.aspectRatio)} · ${formatRecommendedSize(slot)} · max ${formatMaxBytes(slot.maxBytes)}`
}

const onboardingIcon = (icon: MediaDefaultIconKey): MediaDefaultPreview => ({
  kind: 'icon',
  icon,
  tone: 'goldOnNavy',
})

const emptyIcon = (icon: MediaDefaultIconKey): MediaDefaultPreview => ({
  kind: 'icon',
  icon,
  tone: 'goldOnCard',
})

function categorySlot(
  id: Extract<MediaSlotId, `onboarding.category.${string}`>,
  label: string,
  description: string,
  icon: MediaDefaultIconKey,
  materialNote: string,
): MediaSlotDefinition {
  return {
    id,
    group: 'categories',
    profile: 'icon',
    label,
    description:
      description ||
      'Remplit le bandeau placeholder de la carte catégorie (pas seulement l’icône).',
    aspectRatio: 1,
    recommendedWidth: 256,
    recommendedHeight: 256,
    maxBytes: MEDIA_MAX_BYTES_ICON,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    // Square frame ≈ banner placeholder; Flutter covers the full top banner.
    previewShape: 'square',
    flutterWired: true,
    defaultNote: `Sans image : icône Material (${materialNote}) dans le bandeau`,
    defaultPreview: onboardingIcon(icon),
  }
}

export const MEDIA_SLOT_CATALOG: MediaSlotDefinition[] = [
  {
    id: 'brand.logo',
    group: 'branding',
    profile: 'brand',
    label: 'Logo app',
    description: 'AppLogo — sélection de rôle et accueil client.',
    aspectRatio: 1,
    recommendedWidth: 1024,
    recommendedHeight: 1024,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'contain',
    previewShape: 'square',
    flutterWired: true,
    defaultNote: 'assets/branding/logo.png (bundle Flutter)',
    defaultPreview: {
      kind: 'image',
      src: '/cms-defaults/logo.png',
      alt: 'Logo Yuztoo actuel',
    },
  },
  {
    id: 'onboarding.merchant.hero_personal',
    group: 'onboarding',
    profile: 'hero',
    label: 'Onboarding — infos perso',
    description: 'Remplace l’avatar icône de l’étape identité commerçant.',
    aspectRatio: 1,
    recommendedWidth: 512,
    recommendedHeight: 512,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'circle',
    flutterWired: true,
    defaultNote: 'Icône Material (person) — bundle actuel',
    defaultPreview: onboardingIcon('user'),
  },
  {
    id: 'onboarding.merchant.hero_commerce',
    group: 'onboarding',
    profile: 'hero',
    label: 'Onboarding — commerce',
    description: 'Étape nom / commerce.',
    aspectRatio: 1,
    recommendedWidth: 512,
    recommendedHeight: 512,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'circle',
    flutterWired: true,
    defaultNote: 'Icône Material (storefront) — bundle actuel',
    defaultPreview: onboardingIcon('store'),
  },
  {
    id: 'onboarding.merchant.hero_audience',
    group: 'onboarding',
    profile: 'hero',
    label: 'Onboarding — audience',
    description: 'Étape audience / catégorie.',
    aspectRatio: 1,
    recommendedWidth: 512,
    recommendedHeight: 512,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'circle',
    flutterWired: true,
    defaultNote: 'Icône Material (groups) — bundle actuel',
    defaultPreview: onboardingIcon('users'),
  },
  {
    id: 'onboarding.merchant.hero_city',
    group: 'onboarding',
    profile: 'hero',
    label: 'Onboarding — ville',
    description: 'Étape ville.',
    aspectRatio: 1,
    recommendedWidth: 512,
    recommendedHeight: 512,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'circle',
    flutterWired: true,
    defaultNote: 'Icône Material (location_city) — bundle actuel',
    defaultPreview: onboardingIcon('building'),
  },
  {
    id: 'onboarding.client.hero',
    group: 'onboarding',
    profile: 'hero',
    label: 'Onboarding client',
    description: 'Visuel étape profil client (hors photo utilisateur).',
    aspectRatio: 1,
    recommendedWidth: 512,
    recommendedHeight: 512,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'circle',
    flutterWired: true,
    defaultNote: 'Icône Material (person) — bundle actuel',
    defaultPreview: onboardingIcon('user'),
  },

  // ── Catégories onboarding (16) — icon profile 200 Ko / 256×256 ─────────
  categorySlot(
    'onboarding.category.bouche',
    'Catégorie — Métiers de bouche',
    'Bandeau placeholder carte grille (B2C).',
    'utensils',
    'restaurant',
  ),
  categorySlot(
    'onboarding.category.commerce',
    'Catégorie — Commerce',
    'Bandeau placeholder carte grille (B2C).',
    'store',
    'storefront',
  ),
  categorySlot(
    'onboarding.category.beaute',
    'Catégorie — Beauté & Bien-être',
    'Bandeau placeholder carte grille (B2C).',
    'sparkles',
    'spa',
  ),
  categorySlot(
    'onboarding.category.sante',
    'Catégorie — Santé & Accompagnement',
    'Bandeau placeholder carte grille (B2C).',
    'heartPulse',
    'medical_services',
  ),
  categorySlot(
    'onboarding.category.services_particuliers',
    'Catégorie — Services aux particuliers',
    'Bandeau placeholder carte grille (B2C).',
    'wrench',
    'home_repair_service',
  ),
  categorySlot(
    'onboarding.category.loisirs',
    'Catégorie — Loisirs & Expérience',
    'Bandeau placeholder carte grille (B2C).',
    'ferrisWheel',
    'attractions',
  ),
  categorySlot(
    'onboarding.category.association',
    'Catégorie — Association & Collectivité',
    'Bandeau placeholder carte grille (B2C).',
    'users',
    'groups',
  ),
  categorySlot(
    'onboarding.category.autre',
    'Catégorie — Autre (B2C)',
    'Bandeau placeholder carte grille (B2C).',
    'layoutGrid',
    'apps',
  ),
  categorySlot(
    'onboarding.category.artisan_btp',
    'Catégorie — Artisan BTP',
    'Bandeau placeholder carte grille (B2B).',
    'hardHat',
    'construction',
  ),
  categorySlot(
    'onboarding.category.services_pro',
    'Catégorie — Services aux professionnels',
    'Bandeau placeholder carte grille (B2B).',
    'briefcase',
    'business_center',
  ),
  categorySlot(
    'onboarding.category.grossiste',
    'Catégorie — Grossiste spécialisé',
    'Bandeau placeholder carte grille (B2B).',
    'warehouse',
    'warehouse',
  ),
  categorySlot(
    'onboarding.category.immobilier',
    'Catégorie — Immobilier & Foncier',
    'Bandeau placeholder carte grille (B2B).',
    'building',
    'apartment',
  ),
  categorySlot(
    'onboarding.category.finance_juridique',
    'Catégorie — Finance & Juridique',
    'Bandeau placeholder carte grille (B2B).',
    'landmark',
    'account_balance',
  ),
  categorySlot(
    'onboarding.category.livraison',
    'Catégorie — Service de livraison',
    'Bandeau placeholder carte grille (B2B).',
    'truck',
    'local_shipping',
  ),
  categorySlot(
    'onboarding.category.independants',
    'Catégorie — Indépendants',
    'Bandeau placeholder carte grille (B2B).',
    'badgeCheck',
    'badge',
  ),
  categorySlot(
    'onboarding.category.autres_pro',
    'Catégorie — Autre (B2B)',
    'Bandeau placeholder carte grille (B2B).',
    'layoutGrid',
    'apps',
  ),

  {
    id: 'empty.loyalty',
    group: 'empty',
    profile: 'illustration',
    label: 'État vide — fidélité',
    description: 'Illustration carte vide fidélité.',
    aspectRatio: 4 / 3,
    recommendedWidth: 800,
    recommendedHeight: 600,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'card43',
    flutterWired: true,
    defaultNote: 'Icône gift (empty state fidélité)',
    defaultPreview: emptyIcon('gift'),
  },
  {
    id: 'empty.passages',
    group: 'empty',
    profile: 'illustration',
    label: 'État vide — passages',
    description: 'Illustration liste passages vide.',
    aspectRatio: 4 / 3,
    recommendedWidth: 800,
    recommendedHeight: 600,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'card43',
    flutterWired: true,
    defaultNote: 'Icône groupe (liste clients / passages vide)',
    defaultPreview: emptyIcon('usersRound'),
  },
  {
    id: 'empty.promotions',
    group: 'empty',
    profile: 'illustration',
    label: 'État vide — promos',
    description: 'Illustration promotions vide.',
    aspectRatio: 4 / 3,
    recommendedWidth: 800,
    recommendedHeight: 600,
    maxBytes: MEDIA_MAX_BYTES_DEFAULT,
    allowedMime: MEDIA_ALLOWED_MIME,
    objectFit: 'cover',
    previewShape: 'card43',
    flutterWired: true,
    defaultNote: 'Icône offre (empty state promotions)',
    defaultPreview: emptyIcon('tag'),
  },
]

export function formatAspectLabel(aspectRatio: number): string {
  if (Math.abs(aspectRatio - 1) < 0.01) return '1:1'
  if (Math.abs(aspectRatio - 4 / 3) < 0.01) return '4:3'
  return aspectRatio.toFixed(2)
}

export function formatRecommendedSize(slot: MediaSlotDefinition): string {
  return `${slot.recommendedWidth}×${slot.recommendedHeight}`
}
