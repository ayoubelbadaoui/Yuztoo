import type {
  WaConversation,
  WaMessage,
} from '@/features/whatsapp/domain/conversation'
import type { WaNumber } from '@/features/whatsapp/domain/number'
import type { WaTemplate } from '@/features/whatsapp/domain/template'

const MINUTE = 60 * 1000

function ago(minutes: number): string {
  return new Date(Date.now() - minutes * MINUTE).toISOString()
}

export const mockNumbers: WaNumber[] = [
  {
    id: 'WA-01',
    displayName: 'Yuztoo',
    phone: '+33756901234',
    verified: true,
    quality: 'high',
    tier: 1000,
    used24h: 318,
  },
  {
    id: 'WA-02',
    displayName: 'Yuztoo Support',
    phone: '+33756905678',
    verified: true,
    quality: 'medium',
    tier: 250,
    used24h: 96,
  },
]

export const mockTemplates: WaTemplate[] = [
  {
    id: 'TPL-01',
    name: 'relance_devis',
    category: 'utility',
    language: 'fr',
    status: 'approved',
    body: "Bonjour {{1}}, votre devis Yuztoo n°{{2}} est prêt. Vous pouvez le consulter et l'accepter depuis ce lien. Une question ? Répondez simplement à ce message.",
    buttons: ['Voir le devis', 'Être rappelé'],
    reviewNote: null,
    sent30d: 412,
  },
  {
    id: 'TPL-02',
    name: 'rappel_echeance',
    category: 'utility',
    language: 'fr',
    status: 'approved',
    body: 'Bonjour {{1}}, le prélèvement de votre abonnement Yuztoo ({{2}}) est prévu le {{3}}. Aucune action nécessaire de votre part.',
    buttons: ['Mettre à jour mon RIB'],
    reviewNote: null,
    sent30d: 806,
  },
  {
    id: 'TPL-03',
    name: 'impaye_relance',
    category: 'utility',
    language: 'fr',
    status: 'approved',
    body: "Bonjour {{1}}, le prélèvement de {{2}} a été rejeté. Vous pouvez régulariser en une minute depuis le lien ci-dessous, sans frais si c'est fait sous 7 jours.",
    buttons: ['Payer maintenant'],
    reviewNote: null,
    sent30d: 143,
  },
  {
    id: 'TPL-04',
    name: 'bienvenue_commercant',
    category: 'marketing',
    language: 'fr',
    status: 'approved',
    body: 'Bienvenue chez Yuztoo, {{1}} ! Votre plaque NFC arrive sous 48 h. En attendant, votre espace est déjà ouvert.',
    buttons: ['Ouvrir mon espace'],
    reviewNote: null,
    sent30d: 57,
  },
  {
    id: 'TPL-05',
    name: 'offre_black_friday',
    category: 'marketing',
    language: 'fr',
    status: 'pending',
    body: '{{1}}, profitez de deux mois offerts sur la formule Premium jusqu’au {{2}}.',
    buttons: ['J’en profite', 'Ne plus recevoir'],
    reviewNote: null,
    sent30d: 0,
  },
  {
    id: 'TPL-06',
    name: 'promo_flash_24h',
    category: 'marketing',
    language: 'fr',
    status: 'rejected',
    body: 'DERNIÈRE CHANCE {{1}} !!! -50% SEULEMENT AUJOURD’HUI, cliquez vite !!!',
    buttons: ['Cliquer'],
    reviewNote:
      'Contenu jugé trop insistant et promesse commerciale imprécise (politique Meta sur le marketing).',
    sent30d: 0,
  },
  {
    id: 'TPL-07',
    name: 'code_connexion',
    category: 'authentication',
    language: 'fr',
    status: 'approved',
    body: 'Votre code de connexion Yuztoo est {{1}}. Il expire dans 10 minutes.',
    buttons: [],
    reviewNote: null,
    sent30d: 1294,
  },
]

type ConversationSeed = [
  contactName: string,
  phone: string,
  company: string | null,
  leadId: string | null,
  assignedTo: string,
  unread: number,
  /** Minutes depuis le dernier message entrant, null si le contact n'a jamais répondu. */
  inboundMinutesAgo: number | null,
  messages: Array<[direction: 'in' | 'out', minutesAgo: number, body: string, templateName?: string]>,
]

const seeds: ConversationSeed[] = [
  [
    'Claire Fontaine',
    '+33612448790',
    'Fleurs & Co',
    'LD-1043',
    'Sara M.',
    2,
    12,
    [
      ['out', 180, 'Bonjour Claire, votre devis Yuztoo n°DV-321 est prêt. Vous pouvez le consulter et l’accepter depuis ce lien.', 'relance_devis'],
      ['in', 90, 'Merci ! Je regarde ça ce soir.'],
      ['in', 12, 'Petite question : les plaques NFC sont fournies avec un support ?'],
    ],
  ],
  [
    'Pierre Lemoine',
    '+33677210914',
    'Boucherie Lemoine',
    null,
    'Yasmine K.',
    0,
    200,
    [
      ['in', 260, 'Bonjour, on a demandé une démo via votre site.'],
      ['out', 240, 'Bonjour Pierre, avec plaisir. Jeudi 15 h vous conviendrait ?'],
      ['in', 200, 'Parfait pour jeudi 15 h.'],
      ['out', 190, 'Noté, je vous envoie l’invitation.'],
    ],
  ],
  [
    'Nadia Cherkaoui',
    '+33629147603',
    'Studio Coiffure Nadia',
    'LD-1041',
    'Ayoub T.',
    1,
    35,
    [
      ['out', 1500, 'Bonjour Nadia, le prélèvement de votre abonnement Yuztoo (29 €) est prévu le 05/12.', 'rappel_echeance'],
      ['in', 35, 'Bonjour, est-ce que je peux changer la date de prélèvement ?'],
    ],
  ],
  [
    'Mehdi Tazi',
    '+33655421860',
    'Garage Tazi Auto',
    'LD-1034',
    'Sara M.',
    0,
    null,
    [
      ['out', 2880, 'Bonjour Mehdi, le prélèvement de 50,15 € a été rejeté. Vous pouvez régulariser en une minute.', 'impaye_relance'],
    ],
  ],
  [
    'Leila Amrani',
    '+33603875541',
    'Pâtisserie Zohra',
    'LD-1035',
    'Yasmine K.',
    0,
    4320,
    [
      ['in', 4400, 'On est intéressés par la formule Premium.'],
      ['out', 4380, 'Super, je vous prépare une proposition.'],
      ['in', 4320, 'Merci beaucoup.'],
    ],
  ],
]

export const mockConversations: WaConversation[] = seeds.map(
  (
    [contactName, phone, company, leadId, assignedTo, unread, inboundMinutesAgo, messages],
    index,
  ) => ({
    id: `CV-${120 + index}`,
    contactName,
    phone,
    company,
    leadId,
    assignedTo,
    unread,
    lastInboundAt: inboundMinutesAgo === null ? null : ago(inboundMinutesAgo),
    lastMessageAt: ago(Math.min(...messages.map(([, minutes]) => minutes))),
  }),
)

export const mockMessages: WaMessage[] = seeds.flatMap(
  ([, , , , , , , messages], seedIndex) =>
    messages.map(([direction, minutesAgo, body, templateName], index) => {
      const template = templateName
        ? mockTemplates.find((candidate) => candidate.name === templateName)
        : undefined

      return {
        id: `MS-${seedIndex}-${index}`,
        conversationId: `CV-${120 + seedIndex}`,
        direction,
        kind: template ? 'template' : 'text',
        body,
        templateName: templateName ?? null,
        buttons: template?.buttons ?? [],
        sentAt: ago(minutesAgo),
        status:
          direction === 'in'
            ? 'read'
            : minutesAgo > 60
              ? 'read'
              : 'delivered',
        error: null,
      } satisfies WaMessage
    }),
)