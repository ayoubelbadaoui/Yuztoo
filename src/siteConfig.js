/**
 * Single source of truth for anything that identifies YuzToo on the website.
 *
 * Brand values are duplicated from the Flutter app on purpose (this branch must
 * never import app code). Source of truth for colors: lib/theme.dart,
 * lib/core/shared/constants/merchant_colors.dart and
 * lib/feature/storefront/presentation/widgets/storefront_colors.dart on `develop`.
 */

export const SITE = {
  name: 'YuzToo',
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
 * Network figures shown in the header strip, the homepage and the pricing.
 * TODO(owner): keep `partners` in sync with the live count until the
 * automatic counter (src/data/networkCount.js) is deployed.
 */
export const NETWORK = {
  partners: 50,
  target: 300,
  city: 'Belfort',
  department: '90',
  /** Test phase: the three towns where YuzToo is deployed first. */
  pilotCities: ['Belfort', 'Héricourt', 'Montbéliard'],
  /** Pioneer offer: preferential pricing for the first N merchants. */
  pioneers: 300,
}

/**
 * App store listings. `available` per store: false shows « Bientôt
 * disponible » instead of a link.
 */
export const APP_STORES = {
  ios: { available: true, url: 'https://apps.apple.com/fr/app/yuztoo/id6762813533' },
  android: { available: true, url: 'https://play.google.com/store/apps/details?id=com.yuztoo.app' },
}

export const absoluteUrl = (path) => `${SITE.origin}${path === '/' ? '' : path}`
