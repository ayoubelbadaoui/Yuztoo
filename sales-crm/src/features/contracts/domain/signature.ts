/**
 * Jeton de signature de démonstration, dérivé de l'identifiant pour qu'un lien
 * reste valable après un rechargement. En production le jeton doit être
 * aléatoire, généré côté serveur, à usage unique, daté, et protégé par une
 * policy RLS qui n'expose que le contrat correspondant.
 */
export function signingTokenFor(contractId: string): string {
  let hash = 0
  for (const character of `sign:${contractId}`) {
    hash = (hash * 31 + character.charCodeAt(0)) >>> 0
  }
  return `${contractId.toLowerCase().replace(/-/g, '')}${hash.toString(36)}`
}

export const CONTRACT_PARAM = 'contrat'

export function buildSigningUrl(origin: string, contractId: string): string {
  return `${origin}/?${CONTRACT_PARAM}=${signingTokenFor(contractId)}`
}

/**
 * Empreinte du texte signé. Démonstration uniquement : une vraie preuve
 * demande un SHA-256 calculé côté serveur sur le PDF scellé.
 */
export function documentHash(text: string): string {
  let hash = 0x811c9dc5
  for (const character of text) {
    hash = ((hash ^ character.charCodeAt(0)) * 0x01000193) >>> 0
  }
  return hash.toString(16).padStart(8, '0').toUpperCase()
}
