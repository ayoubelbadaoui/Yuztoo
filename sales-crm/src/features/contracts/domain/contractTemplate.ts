import type { Contract } from '@/features/contracts/domain/contract'
import { formatContractDate } from '@/features/contracts/domain/contract'
import { formatEuro } from '@/lib/money'

export type ContractArticle = {
  number: number
  title: string
  body: string
}

/** Le texte est un remplissage de maquette, il n'a aucune valeur juridique. */
export const templateNotice =
  'Modèle de démonstration. Le texte doit être remplacé par la version validée par le conseil juridique avant toute mise en production.'

export function buildArticles(contract: Contract): ContractArticle[] {
  const client = contract.company === '—' ? contract.leadName : contract.company
  const yearly = contract.monthlyAmount * 12

  return [
    {
      number: 1,
      title: 'Objet du contrat',
      body: `Le présent contrat définit les conditions dans lesquelles Yuztoo met à disposition de ${client} la formule ${contract.planName}, comprenant la plateforme de fidélité, la vitrine commerçant et les supports NFC associés. Le client dispose d'un accès nominatif à l'espace d'administration dès la signature.`,
    },
    {
      number: 2,
      title: 'Durée et engagement',
      body: `Le contrat est conclu pour une durée de ${contract.engagementMonths} mois à compter de la mise en service. Il se renouvelle ensuite par tacite reconduction par périodes de douze mois, sauf dénonciation adressée par écrit au moins trente jours avant l'échéance.`,
    },
    {
      number: 3,
      title: 'Conditions financières',
      body: `L'abonnement est facturé ${formatEuro(contract.monthlyAmount)} par mois, soit ${formatEuro(yearly)} par an, prélevé à la date convenue au contrat. Les prix s'entendent hors taxes. Yuztoo ne prélève aucune commission sur le chiffre d'affaires réalisé par le client.`,
    },
    {
      number: 4,
      title: 'Matériel NFC',
      body: `Les plaques et porte-clés NFC compris dans la formule sont fournis en prêt d'usage et restent la propriété de Yuztoo. Tout support supplémentaire est facturé au tarif en vigueur. Le matériel est restitué dans le mois suivant la fin du contrat.`,
    },
    {
      number: 5,
      title: 'Données personnelles',
      body: `Chaque partie agit en responsable de traitement pour les données qu'elle collecte. Le client reste propriétaire de sa base de clientèle et peut l'exporter à tout moment. Yuztoo s'interdit toute réutilisation commerciale de ces données et les héberge sur une infrastructure située dans l'Union européenne.`,
    },
    {
      number: 6,
      title: 'Résiliation',
      body: `En cas de manquement grave, et notamment de défaut de paiement persistant après mise en demeure restée sans effet pendant quinze jours, Yuztoo peut suspendre le service puis résilier le contrat de plein droit. Les sommes dues au titre de la période engagée restent exigibles.`,
    },
    {
      number: 7,
      title: 'Droit applicable',
      body: `Le contrat est soumis au droit français. À défaut d'accord amiable, tout litige relève de la compétence exclusive des tribunaux du ressort du siège social de Yuztoo.`,
    },
  ]
}

/** Texte intégral signé, support de l'empreinte conservée avec la signature. */
export function contractPlainText(contract: Contract): string {
  const header = `Contrat ${contract.id} — ${contract.leadName} — ${contract.planName} — ${formatContractDate(contract.createdAt)}`
  const body = buildArticles(contract)
    .map((article) => `${article.number}. ${article.title}\n${article.body}`)
    .join('\n\n')
  return `${header}\n\n${body}`
}
