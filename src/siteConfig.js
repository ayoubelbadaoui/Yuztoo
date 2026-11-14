/**
 * Single source of truth for anything that identifies Yuztoo on the website.
 *
 * Brand values are duplicated from the Flutter app on purpose (this branch must
 * never import app code). Source of truth for colors: lib/theme.dart,
 * lib/core/shared/constants/merchant_colors.dart and
 * lib/feature/storefront/presentation/widgets/storefront_colors.dart on `develop`.
 */

export const SITE = {
  name: 'Yuztoo',
  origin: 'https://www.yuztoo.com',
  locale: 'fr_FR',
  lang: 'fr-FR',
  themeColor: '#0B1F33',
  tagline: 'Le lien direct entre vous et vos commerces de proximité',
}

export const CONTACT = {
  email: 'contact@yuztoo.com',
  phone: '+33609526511',
  phoneDisplay: '06 09 52 65 11',
  city: 'Belfort',
  country: 'FR',
}

/**
 * Network figures shown in the header strip and on the homepage.
 * TODO(owner): re-confirm the partner count each quarter.
 */
export const NETWORK = {
  partners: 10,
  target: 250,
  city: 'Belfort',
  department: '90',
}

/**
 * App store listings.
 *
 * TODO(owner): replace with the real listing URLs. Until they are provided,
 * `available: false` makes every download CTA fall back to the contact route
 * instead of shipping a dead link.
 */
export const APP_STORES = {
  available: false,
  ios: null,
  android: null,
}

export const absoluteUrl = (path) => `${SITE.origin}${path === '/' ? '' : path}`
