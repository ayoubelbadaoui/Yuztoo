export type ContractStatus =
  | 'draft'
  | 'sent'
  | 'signed'
  | 'declined'
  | 'expired'

export const contractStatusLabels: Record<ContractStatus, string> = {
  draft: 'Brouillon',
  sent: 'À signer',
  signed: 'Signé',
  declined: 'Refusé',
  expired: 'Expiré',
}

/**
 * Preuve de signature conservée avec le contrat. En démonstration elle est
 * produite dans le navigateur : en production le tracé, l'horodatage et
 * l'empreinte du document doivent être scellés côté serveur, dans une table
 * protégée par RLS et jamais modifiable depuis le client.
 */
export type ContractSignature = {
  signerName: string
  signerEmail: string
  signedAt: string
  /** Tracé manuscrit, PNG transparent en data URL. */
  strokeDataUrl: string
  /** Empreinte du texte accepté, pour détecter une modification après coup. */
  documentHash: string
  userAgent: string
}

export type Contract = {
  id: string
  quoteId: string | null
  leadId: string
  leadName: string
  company: string
  /** Conditions figées à la génération : le contrat ne suit pas la grille tarifaire. */
  planName: string
  monthlyAmount: number
  engagementMonths: number
  owner: string
  status: ContractStatus
  createdAt: string
  sentAt: string | null
  /** Un lien de signature a une durée de vie : au-delà il faut le régénérer. */
  expiresAt: string
  signature: ContractSignature | null
}

export const signatureValidityDays = 14

export function isExpired(contract: Contract, now = new Date()): boolean {
  return contract.status === 'sent' && new Date(contract.expiresAt) < now
}

/** Un contrat n'est signable qu'une fois envoyé et tant que le lien est valide. */
export function isSignable(contract: Contract, now = new Date()): boolean {
  return contract.status === 'sent' && !isExpired(contract, now)
}

export function formatContractDate(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(iso))
}

export function formatContractDateTime(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}
