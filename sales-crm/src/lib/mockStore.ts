/**
 * Persistance de la donnée de démonstration dans le navigateur.
 *
 * Les services continuent de travailler sur des tableaux en mémoire : ce cache
 * sert uniquement à ce qu'un devis ou un contrat créé pendant une démo survive
 * à un rechargement, et donc à ce qu'un lien partagé reste ouvrable. Il
 * disparaîtra au branchement de Supabase, où la donnée vivra en base derrière
 * une policy RLS.
 */
const PREFIX = 'yuztoo-crm:'

/** À incrémenter dès que la forme des données de démonstration change. */
const VERSION = 1

type Payload<T> = { version: number; items: T[] }

function keyOf(name: string): string {
  return `${PREFIX}${name}`
}

export function loadOrSeed<T>(name: string, seed: () => T[]): T[] {
  try {
    const raw = window.localStorage.getItem(keyOf(name))
    if (raw) {
      const payload = JSON.parse(raw) as Payload<T>
      if (payload.version === VERSION && Array.isArray(payload.items)) {
        return payload.items
      }
    }
  } catch {
    // Stockage indisponible ou contenu illisible : on repart du jeu de départ.
  }

  const items = seed()
  persist(name, items)
  return items
}

export function persist<T>(name: string, items: T[]): void {
  try {
    const payload: Payload<T> = { version: VERSION, items }
    window.localStorage.setItem(keyOf(name), JSON.stringify(payload))
  } catch {
    // Mode privé ou quota atteint : la démo reste utilisable sans persistance.
  }
}
