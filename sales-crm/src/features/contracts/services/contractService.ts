import type {
  Contract,
  ContractStatus,
} from '@/features/contracts/domain/contract'
import {
  isExpired,
  isSignable,
  signatureValidityDays,
} from '@/features/contracts/domain/contract'
import { contractPlainText } from '@/features/contracts/domain/contractTemplate'
import {
  documentHash,
  signingTokenFor,
} from '@/features/contracts/domain/signature'
import {
  mockContracts,
  saveContracts,
} from '@/features/contracts/services/contractData'
import { plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'
import type { Quote } from '@/features/quotes/domain/quote'
import { getQuotes } from '@/features/quotes/services/quoteService'

type Result<T> = { data: T | null; error: Error | null }

const DAY = 24 * 60 * 60 * 1000

/** Reprend après le dernier identifiant connu, y compris restauré du cache. */
let sequence = mockContracts.reduce(
  (max, contract) => Math.max(max, Number(contract.id.slice(3)) || 0),
  219,
)

function find(id: string): Contract {
  const contract = mockContracts.find((candidate) => candidate.id === id)
  if (!contract) throw new Error(`Contrat ${id} introuvable`)
  return contract
}

/** Un lien périmé bascule le contrat avant toute lecture. */
function refreshExpiry(contract: Contract): Contract {
  if (isExpired(contract)) contract.status = 'expired'
  return contract
}

export async function getContracts(
  status: ContractStatus | 'all' = 'all',
): Promise<Result<Contract[]>> {
  try {
    const data = mockContracts
      .map(refreshExpiry)
      .filter((contract) => status === 'all' || contract.status === status)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getContractCounts(): Promise<
  Result<Record<ContractStatus | 'all', number>>
> {
  try {
    const count = (status: ContractStatus) =>
      mockContracts.filter((contract) => contract.status === status).length

    return {
      data: {
        all: mockContracts.length,
        draft: count('draft'),
        sent: count('sent'),
        signed: count('signed'),
        declined: count('declined'),
        expired: count('expired'),
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Devis acceptés n'ayant pas encore de contrat. */
export async function getContractableQuotes(): Promise<Result<Quote[]>> {
  try {
    const { data, error } = await getQuotes('accepted')
    if (error || !data) throw error ?? new Error('Devis indisponibles')

    const used = new Set(
      mockContracts.map((contract) => contract.quoteId).filter(Boolean),
    )
    return { data: data.filter((quote) => !used.has(quote.id)), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createContractFromQuote(
  quoteId: string,
): Promise<Result<Contract>> {
  try {
    const { data: available } = await getContractableQuotes()
    const quote = available?.find((candidate) => candidate.id === quoteId)
    if (!quote) throw new Error('Ce devis a déjà un contrat')

    const now = new Date()
    const contract: Contract = {
      id: `CT-${(sequence += 1)}`,
      quoteId: quote.id,
      leadId: quote.leadId,
      leadName: quote.leadName,
      company: quote.company,
      planName: plans[quote.planId].name,
      monthlyAmount: computeTotals(quote).monthlyTotal,
      engagementMonths: quote.engagementMonths,
      owner: quote.owner,
      status: 'draft',
      createdAt: now.toISOString(),
      sentAt: null,
      expiresAt: new Date(
        now.getTime() + signatureValidityDays * DAY,
      ).toISOString(),
      signature: null,
    }

    mockContracts.unshift(contract)
    saveContracts()
    return { data: { ...contract }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Ouvre la signature et repart sur un lien neuf, y compris après expiration. */
export async function sendContract(id: string): Promise<Result<Contract>> {
  try {
    const contract = find(id)
    if (contract.status === 'signed') {
      throw new Error('Ce contrat est déjà signé')
    }

    const now = new Date()
    contract.status = 'sent'
    contract.sentAt = now.toISOString()
    contract.expiresAt = new Date(
      now.getTime() + signatureValidityDays * DAY,
    ).toISOString()
    saveContracts()
    return { data: { ...contract }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function declineContract(id: string): Promise<Result<Contract>> {
  try {
    const contract = find(id)
    if (contract.status === 'signed') {
      throw new Error('Un contrat signé ne peut pas être refusé')
    }

    contract.status = 'declined'
    saveContracts()
    return { data: { ...contract }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getContractBySigningToken(
  token: string,
): Promise<Result<Contract>> {
  try {
    const contract = mockContracts.find(
      (candidate) => signingTokenFor(candidate.id) === token,
    )
    if (!contract) throw new Error('Contrat introuvable')
    return { data: { ...refreshExpiry(contract) }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type SignatureInput = {
  signerName: string
  signerEmail: string
  strokeDataUrl: string
}

/**
 * Dernière barrière avant la donnée : la page de signature ne valide que pour
 * le confort. Côté production, cette vérification appartient à une fonction
 * Edge, seule habilitée à écrire la preuve.
 */
export async function signContract(
  token: string,
  input: SignatureInput,
): Promise<Result<Contract>> {
  try {
    const contract = mockContracts.find(
      (candidate) => signingTokenFor(candidate.id) === token,
    )
    if (!contract) throw new Error('Contrat introuvable')
    if (!isSignable(refreshExpiry(contract))) {
      throw new Error('Ce contrat n’est plus ouvert à la signature')
    }
    if (input.signerName.trim().length < 3) {
      throw new Error('Indiquez le nom complet du signataire')
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.signerEmail)) {
      throw new Error('Adresse e-mail invalide')
    }
    if (!input.strokeDataUrl) throw new Error('Le tracé de signature manque')

    contract.status = 'signed'
    contract.signature = {
      signerName: input.signerName.trim(),
      signerEmail: input.signerEmail.trim(),
      signedAt: new Date().toISOString(),
      strokeDataUrl: input.strokeDataUrl,
      documentHash: documentHash(contractPlainText(contract)),
      userAgent: navigator.userAgent,
    }
    saveContracts()
    return { data: { ...contract }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
