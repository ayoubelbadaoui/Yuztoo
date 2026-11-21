/**
 * Jeton de partage de démonstration, dérivé de l'identifiant pour qu'un lien
 * reste valable après un rechargement. En production le jeton doit être
 * aléatoire, généré côté serveur, stocké en base et protégé par une policy RLS
 * qui n'expose que le devis correspondant.
 */
export function shareTokenFor(quoteId: string): string {
  let hash = 0
  for (const character of quoteId) {
    hash = (hash * 31 + character.charCodeAt(0)) >>> 0
  }
  return `${quoteId.toLowerCase().replace(/-/g, '')}${hash.toString(36)}`
}

export const SHARE_PARAM = 'devis'

export function buildShareUrl(origin: string, quoteId: string): string {
  return `${origin}/?${SHARE_PARAM}=${shareTokenFor(quoteId)}`
}
