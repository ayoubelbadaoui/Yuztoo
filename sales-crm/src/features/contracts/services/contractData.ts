import type {
  Contract,
  ContractStatus,
} from '@/features/contracts/domain/contract'
import { signatureValidityDays } from '@/features/contracts/domain/contract'
import { contractPlainText } from '@/features/contracts/domain/contractTemplate'
import { documentHash } from '@/features/contracts/domain/signature'
import { mockLeads } from '@/features/leads/services/leadData'
import { loadOrSeed, persist } from '@/lib/mockStore'

type Row = [
  leadIndex: number,
  planName: string,
  monthlyAmount: number,
  engagementMonths: number,
  daysAgo: number,
  status: ContractStatus,
]

const rows: Row[] = [
  [4, 'Premium', 49, 24, 36, 'signed'],
  [11, 'Essentielle', 29, 12, 28, 'signed'],
  [18, 'Premium', 53.1, 12, 21, 'signed'],
  [0, 'Premium', 59, 24, 9, 'sent'],
  [8, 'Essentielle', 39.6, 12, 5, 'sent'],
  [21, 'Essentielle', 29, 12, 2, 'sent'],
  [15, 'Premium', 49, 12, 1, 'draft'],
  [6, 'Essentielle', 44, 12, 19, 'declined'],
  [2, 'Premium', 49, 24, 40, 'expired'],
]

const DAY = 24 * 60 * 60 * 1000

/** Tracé manuscrit de démonstration, encre sombre sur fond transparent. */
const demoStroke = `data:image/svg+xml;utf8,${encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 70">' +
    '<path d="M8 54 C 26 10 40 64 58 36 C 76 8 96 62 114 34 C 132 6 150 60 168 32 C 184 8 204 56 232 20"' +
    ' fill="none" stroke="#0b162c" stroke-width="2.5" stroke-linecap="round"/></svg>',
)}`

function emailFor(name: string): string {
  const slug = name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z]+/g, '.')
  return `${slug}@exemple.fr`
}

function seedContracts(): Contract[] {
  return rows.map((row, index) => {
    const [
      leadIndex,
      planName,
      monthlyAmount,
      engagementMonths,
      daysAgo,
      status,
    ] = row
    const lead = mockLeads[leadIndex]
    const createdAt = new Date(Date.now() - daysAgo * DAY)
    const sentAt =
      status === 'draft' ? null : new Date(createdAt.getTime() + DAY)

    const contract: Contract = {
      id: `CT-${210 + index}`,
      quoteId: null,
      leadId: lead.id,
      leadName: lead.name,
      company: lead.company,
      planName,
      monthlyAmount,
      engagementMonths,
      owner: lead.owner,
      status,
      createdAt: createdAt.toISOString(),
      sentAt: sentAt ? sentAt.toISOString() : null,
      expiresAt: new Date(
        (sentAt ?? createdAt).getTime() + signatureValidityDays * DAY,
      ).toISOString(),
      signature: null,
    }

    if (status === 'signed' && sentAt) {
      contract.signature = {
        signerName: lead.name,
        signerEmail: emailFor(lead.name),
        signedAt: new Date(sentAt.getTime() + 2 * DAY).toISOString(),
        strokeDataUrl: demoStroke,
        documentHash: documentHash(contractPlainText(contract)),
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X)',
      }
    }

    return contract
  })
}

export const mockContracts: Contract[] = loadOrSeed(
  'contracts',
  seedContracts,
)

/** À appeler après toute écriture pour que le lien survive au rechargement. */
export function saveContracts(): void {
  persist('contracts', mockContracts)
}
