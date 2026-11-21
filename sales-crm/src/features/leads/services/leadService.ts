import type { Lead, LeadStage, LeadType } from '@/features/leads/domain/lead'
import { LEAD_PAGE_SIZE, leadStageOrder } from '@/features/leads/domain/lead'
import { mockLeads } from '@/features/leads/services/leadData'

type Result<T> = { data: T | null; error: Error | null }

export type LeadSortKey = 'updatedAt' | 'name' | 'amount' | 'stage'

export type LeadQuery = {
  type?: LeadType | 'all'
  search?: string
  sortKey?: LeadSortKey
  sortAsc?: boolean
  /** 1-based page index. */
  page?: number
  pageSize?: number
}

export type LeadPage = {
  items: Lead[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

function matchesSearch(lead: Lead, search: string): boolean {
  const haystack = [
    lead.name,
    lead.company,
    lead.city,
    lead.owner,
    lead.id,
    lead.instagram,
    lead.email,
    lead.phone,
    lead.trade,
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase()
  return haystack.includes(search)
}

function compare(a: Lead, b: Lead, key: LeadSortKey): number {
  switch (key) {
    case 'name':
      return a.name.localeCompare(b.name, 'fr')
    case 'amount':
      return a.amount - b.amount
    case 'stage':
      return leadStageOrder.indexOf(a.stage) - leadStageOrder.indexOf(b.stage)
    case 'updatedAt':
    default:
      return a.updatedAt.localeCompare(b.updatedAt)
  }
}

/**
 * Paginated lead list. Always prefer this for tables — never ship the full
 * catalogue to the browser when the CRM grows to thousands of rows.
 * Supabase later: `.range(from, to)` + `{ count: 'exact', head: false }`.
 */
export async function getLeads(
  query: LeadQuery = {},
): Promise<Result<LeadPage>> {
  try {
    const {
      type = 'all',
      search = '',
      sortKey = 'updatedAt',
      sortAsc = false,
      page: rawPage = 1,
      pageSize: rawSize = LEAD_PAGE_SIZE,
    } = query
    const pageSize = Math.min(100, Math.max(1, rawSize))
    const normalized = search.trim().toLowerCase()

    const filtered = mockLeads
      .filter((lead) => (type === 'all' ? true : lead.type === type))
      .filter((lead) => (normalized ? matchesSearch(lead, normalized) : true))
      .sort((a, b) =>
        sortAsc ? compare(a, b, sortKey) : compare(b, a, sortKey),
      )

    const total = filtered.length
    const totalPages = Math.max(1, Math.ceil(total / pageSize))
    const page = Math.min(Math.max(1, rawPage), totalPages)
    const start = (page - 1) * pageSize

    return {
      data: {
        items: filtered.slice(start, start + pageSize),
        total,
        page,
        pageSize,
        totalPages,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/**
 * Bounded search for pickers (devis, contrats…). Caps results so a combobox
 * never materialises thousands of leads in memory.
 */
export async function searchLeads(
  search = '',
  limit = 50,
): Promise<Result<Lead[]>> {
  try {
    const cap = Math.min(100, Math.max(1, limit))
    const normalized = search.trim().toLowerCase()
    const data = mockLeads
      .filter((lead) =>
        normalized ? matchesSearch(lead, normalized) : true,
      )
      .sort((a, b) => a.name.localeCompare(b.name, 'fr'))
      .slice(0, cap)
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getLeadById(id: string): Promise<Result<Lead>> {
  try {
    const lead = mockLeads.find((candidate) => candidate.id === id)
    if (!lead) throw new Error(`Lead ${id} introuvable`)
    return { data: { ...lead }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getLeadCounts(): Promise<
  Result<{ all: number; merchant: number; client: number }>
> {
  try {
    return {
      data: {
        all: mockLeads.length,
        merchant: mockLeads.filter((lead) => lead.type === 'merchant').length,
        client: mockLeads.filter((lead) => lead.type === 'client').length,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getLeadsByStage(): Promise<
  Result<Record<LeadStage, Lead[]>>
> {
  try {
    const grouped = {} as Record<LeadStage, Lead[]>
    for (const stage of leadStageOrder) {
      grouped[stage] = mockLeads
        .filter((lead) => lead.stage === stage)
        .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
    }
    grouped.lost = mockLeads.filter((lead) => lead.stage === 'lost')
    return { data: grouped, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type LeadPatch = Partial<
  Pick<Lead, 'name' | 'company' | 'city' | 'type' | 'stage' | 'amount' | 'owner'>
>

/** Last line of defence before the data layer; the form validates for UX only. */
export async function updateLead(
  id: string,
  patch: LeadPatch,
): Promise<Result<Lead>> {
  try {
    const lead = mockLeads.find((candidate) => candidate.id === id)
    if (!lead) throw new Error(`Lead ${id} introuvable`)
    if (patch.name !== undefined && patch.name.trim() === '') {
      throw new Error('Le nom est obligatoire')
    }
    if (patch.amount !== undefined && patch.amount < 0) {
      throw new Error('Le montant ne peut pas être négatif')
    }

    Object.assign(lead, patch)
    lead.updatedAt = new Date().toISOString()
    return { data: { ...lead }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Moves a lead to another stage. Mutates the mock store until Supabase lands. */
export async function updateLeadStage(
  id: string,
  stage: LeadStage,
): Promise<Result<Lead>> {
  try {
    const lead = mockLeads.find((candidate) => candidate.id === id)
    if (!lead) throw new Error(`Lead ${id} introuvable`)

    lead.stage = stage
    lead.updatedAt = new Date().toISOString()
    return { data: { ...lead }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type NewLead = {
  name: string
  company?: string
  city?: string
  type?: LeadType
  owner?: string
}

/** Reprend après le dernier identifiant connu. */
let sequence = mockLeads.reduce(
  (max, lead) => Math.max(max, Number(lead.id.slice(3)) || 0),
  2000,
)

/** Entrée d'un lead venu d'ailleurs, typiquement une demande reçue sur le site. */
export async function createLead(input: NewLead): Promise<Result<Lead>> {
  try {
    if (!input.name.trim()) throw new Error('Le nom est obligatoire')

    const lead: Lead = {
      id: `LD-${(sequence += 1)}`,
      name: input.name.trim(),
      company: input.company?.trim() || '—',
      city: input.city?.trim() || '—',
      type: input.type ?? 'merchant',
      stage: 'new',
      amount: 0,
      owner: input.owner ?? 'Non assigné',
      updatedAt: new Date().toISOString(),
      instagram: null,
      email: null,
      phone: null,
      trade: null,
      priority: null,
      yuztooStorefront: null,
      storefrontStatus: null,
    }

    mockLeads.unshift(lead)
    return { data: { ...lead }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getRecentLeads(limit = 5): Promise<Result<Lead[]>> {
  try {
    const data = [...mockLeads]
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
      .slice(0, limit)
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type PipelineSummary = {
  stage: LeadStage
  count: number
  amount: number
}

export async function getPipelineSummary(): Promise<Result<PipelineSummary[]>> {
  try {
    const data = leadStageOrder.map((stage) => {
      const leads = mockLeads.filter((lead) => lead.stage === stage)
      return {
        stage,
        count: leads.length,
        amount: leads.reduce((total, lead) => total + lead.amount, 0),
      }
    })
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
