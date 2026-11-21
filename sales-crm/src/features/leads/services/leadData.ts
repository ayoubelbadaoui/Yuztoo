import type { Lead } from '@/features/leads/domain/lead'
import prospection from '@/features/leads/services/prospectionLeads.json'

/**
 * Real prospection commerçants (Excel Yuztoo) — replaces the old dummy merchants.
 * Client segment is empty for now; new clients still arrive via inbox → createLead.
 */
export const mockLeads: Lead[] = (prospection as Lead[]).map((lead) => ({
  ...lead,
}))
