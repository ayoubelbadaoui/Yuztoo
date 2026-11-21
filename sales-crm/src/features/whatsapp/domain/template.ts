export type TemplateCategory = 'marketing' | 'utility' | 'authentication'

export const templateCategoryLabels: Record<TemplateCategory, string> = {
  marketing: 'Marketing',
  utility: 'Service',
  authentication: 'Authentification',
}

export type TemplateStatus = 'approved' | 'pending' | 'rejected' | 'paused'

export const templateStatusLabels: Record<TemplateStatus, string> = {
  approved: 'Approuvé',
  pending: 'En revue',
  rejected: 'Refusé',
  paused: 'Suspendu',
}

export type WaTemplate = {
  id: string
  /** Nom technique déclaré chez Meta, en minuscules avec des tirets bas. */
  name: string
  category: TemplateCategory
  language: string
  status: TemplateStatus
  /** Corps avec des variables numérotées, convention Meta : {{1}}, {{2}}. */
  body: string
  buttons: string[]
  /** Motif renvoyé par la revue Meta en cas de refus. */
  reviewNote: string | null
  sent30d: number
}

export function variableCount(body: string): number {
  const matches = body.match(/\{\{\d+\}\}/g)
  return matches ? new Set(matches).size : 0
}

export function renderTemplate(body: string, values: string[]): string {
  return body.replace(/\{\{(\d+)\}\}/g, (match, index: string) => {
    const value = values[Number(index) - 1]
    return value && value.trim() ? value : match
  })
}

export function isSendable(template: WaTemplate): boolean {
  return template.status === 'approved'
}
