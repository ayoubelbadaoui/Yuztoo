/**
 * Dev notes: orange labels on placeholders that still wait for real content.
 * Shown in dev (localhost) and on any build opened with ?notes (remembered in
 * this browser; ?notes=off hides them). Never shown to normal visitors.
 * Delete an entry once its content has arrived.
 */
export const DEV_NOTES = {
  plaque: {
    kind: 'missing',
    text: 'À fournir (client) : photo de la vraie plaque NFC. Remplace cette plaque dessinée — mettre le chemin dans homeContent.js › HOME_HERO.plate.photo.',
  },
  counter: {
    kind: 'info',
    text: 'Compteur live : 46 vitrines actives dans l’app (le brief dit 50). Choix du client à confirmer. Le live ne marche sur Hostinger/localhost qu’après redéploiement de networkCount.',
  },
  carousel: {
    kind: 'missing',
    text: 'À fournir (client) : publications et vidéos réalisées pour les commerçants (images 4:5, vidéos 9:16) + accord des commerçants. Chaque carte accepte un « media ».',
  },
  pricing: {
    kind: 'missing',
    text: 'À confirmer (client) : contenu de chaque offre (brouillon : docs/demande-client/tarifs-brouillon.md) et durée de validité des prix pionniers.',
  },
  wheel: {
    kind: 'todo',
    text: 'Démo uniquement. À valider (client) : règles de participation, récompenses, qui les finance, règlement. La roue reste à développer dans l’app.',
  },
  clientsBoard: {
    kind: 'info',
    text: 'Tableau illustratif (noms fictifs). La vidéo à côté montre le vrai écran de l’app.',
  },
  report: {
    kind: 'info',
    text: 'Illustration : l’app n’a pas d’écran « rapport mensuel » pour les mairies.',
  },
}

export const DEV_NOTES_LABEL = { missing: 'Manquant', todo: 'À faire', info: 'Info' }
