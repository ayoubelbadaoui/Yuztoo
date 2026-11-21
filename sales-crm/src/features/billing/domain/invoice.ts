export type InvoiceStatus = 'scheduled' | 'due' | 'paid' | 'late' | 'failed'

export type Invoice = {
  id: string
  subscriptionId: string
  leadName: string
  company: string
  /** Période couverte, par exemple « Mars 2026 ». */
  periodLabel: string
  dueDate: string
  amount: number
  status: InvoiceStatus
  paidAt: string | null
  /** Tentatives de prélèvement déjà présentées à la banque. */
  attempts: number
}

export const invoiceStatusLabels: Record<InvoiceStatus, string> = {
  scheduled: 'Planifiée',
  due: 'À échoir',
  paid: 'Payée',
  late: 'En retard',
  failed: 'Rejetée',
}

/** Une échéance rejetée ou en retard pèse sur le recouvrement. */
export function isOutstanding(invoice: Invoice): boolean {
  return invoice.status === 'late' || invoice.status === 'failed'
}

export function daysLate(invoice: Invoice, now = new Date()): number {
  if (!isOutstanding(invoice)) return 0
  const diff = now.getTime() - new Date(invoice.dueDate).getTime()
  return Math.max(0, Math.floor(diff / (1000 * 60 * 60 * 24)))
}
