import { useMemo } from 'react'

import { Combobox } from '@/components/ui/Combobox'
import type { ComboboxOption } from '@/components/ui/Combobox'
import type { Lead } from '@/features/leads/domain/lead'

type Props = {
  leads: Lead[]
  value: string
  onChange: (leadId: string) => void
}

function describe(lead: Lead): string {
  return lead.company === '—' ? lead.city : `${lead.company} · ${lead.city}`
}

export function LeadCombobox({ leads, value, onChange }: Props) {
  const options = useMemo<ComboboxOption[]>(
    () =>
      leads.map((lead) => ({
        id: lead.id,
        label: lead.name,
        hint: describe(lead),
        keywords: `${lead.name} ${lead.company} ${lead.city}`,
      })),
    [leads],
  )

  return (
    <Combobox
      options={options}
      value={value}
      onChange={onChange}
      placeholder="Rechercher un lead…"
      searchPlaceholder="Nom, commerce ou ville"
      emptyLabel="Aucun lead ne correspond."
    />
  )
}
