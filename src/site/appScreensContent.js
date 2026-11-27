/**
 * Real screenshots of the YuzToo merchant app (iOS, demo shop « pyuztoo »).
 * Source: Yuztoo-Presentation/shots, exported to WebP at 360 and 720 px wide
 * in public/images/app. To replace a screen, overwrite both files with the
 * same names. No JSX.
 */

const screen = (id, alt) => ({
  id,
  src: `/images/app/yuztoo-app-${id}-360.webp`,
  srcSet: `/images/app/yuztoo-app-${id}-360.webp 360w, /images/app/yuztoo-app-${id}-720.webp 720w`,
  width: 360,
  height: 779,
  alt,
})

export const APP_SCREENS = {
  vitrine: screen('vitrine', 'Écran « Ma vitrine » de l’application YuzToo : horaires, adresse et actualité du commerce'),
  badge: screen('badge', 'Écran « Badge NFC » : programmer la plaque que les clients approchent avec leur téléphone'),
  fidelite: screen('fidelite', 'Écran « Fidélité » : carte de 10 passages, 8 tampons validés, un café offert en récompense'),
  promotions: screen('promotions', 'Écran « Promotions » : offre du jour à −20 % sur les viennoiseries, en ligne'),
  partenaires: screen('partenaires', 'Écran « Vos partenaires » : les commerces du quartier liés entre eux'),
  notification: screen('notification', 'Écran « Envoyer » : une notification rédigée pour 48 clients, avec son aperçu'),
  profil: screen('profil', 'Écran de profil commerçant : nom, catégorie, ville et présentation du commerce'),
}
