import type { CmsClient, CmsMerchant, ClientStatus, MerchantStatus } from '@/features/cms-app/domain/cms'

const day = 24 * 60 * 60 * 1000

function ago(days: number): string {
  return new Date(Date.now() - days * day).toISOString()
}

const seedMerchants: CmsMerchant[] = [
  {
    id: 'm_boulangerie_marche',
    displayName: 'Boulangerie du Marché',
    city: 'Paris',
    email: 'contact@boulangeriedumarche.fr',
    phone: '+33612440011',
    status: 'published',
    updatedAt: ago(1),
    salesCrmLeadId: null,
  },
  {
    id: 'm_studio_nadia',
    displayName: 'Studio Coiffure Nadia',
    city: 'Lyon',
    email: 'nadia@studio-coiffure.fr',
    phone: '+33629147603',
    status: 'published',
    updatedAt: ago(2),
    salesCrmLeadId: 'LD-1041',
  },
  {
    id: 'm_patisserie_zohra',
    displayName: 'Pâtisserie Zohra',
    city: 'Lille',
    email: 'zohra@patisserie.fr',
    phone: '+33603875541',
    status: 'unpublished',
    updatedAt: ago(5),
    salesCrmLeadId: 'LD-1035',
  },
  {
    id: 'm_garage_tazi',
    displayName: 'Garage Tazi Auto',
    city: 'Paris',
    email: 'mehdi@tazi-auto.fr',
    phone: '+33655421860',
    status: 'draft',
    updatedAt: ago(3),
    salesCrmLeadId: 'LD-1034',
  },
  {
    id: 'm_fleurs_co',
    displayName: 'Fleurs & Co',
    city: 'Belfort',
    email: 'claire@fleursco.fr',
    phone: '+33612448790',
    status: 'published',
    updatedAt: ago(0),
    salesCrmLeadId: 'LD-1043',
  },
  {
    id: 'm_anthracite',
    displayName: 'Anthracite Tattoo',
    city: 'Belfort',
    email: 'piercingbysankaflex@gmail.com',
    phone: '+33753884943',
    status: 'published',
    updatedAt: ago(4),
    salesCrmLeadId: null,
  },
  {
    id: 'm_levain',
    displayName: 'Au Levain Doré',
    city: 'Montbéliard',
    email: 'aulevaindore@outlook.fr',
    phone: '+33673253991',
    status: 'draft',
    updatedAt: ago(8),
    salesCrmLeadId: null,
  },
  {
    id: 'm_deleted_demo',
    displayName: 'Ancienne Boutique Demo',
    city: 'Nantes',
    email: null,
    phone: null,
    status: 'deleted',
    updatedAt: ago(20),
    salesCrmLeadId: null,
  },
]

const seedClients: CmsClient[] = [
  {
    id: 'u_karim',
    displayName: 'Karim Belhaj',
    email: 'karim.belhaj@email.fr',
    phone: '+33611112222',
    city: 'Paris',
    status: 'active',
    createdAt: ago(40),
    salesCrmLeadId: null,
  },
  {
    id: 'u_nadia',
    displayName: 'Nadia Cherkaoui',
    email: 'nadia@studio-coiffure.fr',
    phone: '+33629147603',
    city: 'Lyon',
    status: 'active',
    createdAt: ago(60),
    salesCrmLeadId: 'LD-1041',
  },
  {
    id: 'u_fatima',
    displayName: 'Fatima Zahra El Khattabi',
    email: 'fz.elkhattabi@email.fr',
    phone: '+33633334444',
    city: 'Marseille',
    status: 'active',
    createdAt: ago(12),
    salesCrmLeadId: null,
  },
  {
    id: 'u_blocked',
    displayName: 'Compte test bloqué',
    email: 'blocked@yuztoo.com',
    phone: null,
    city: '—',
    status: 'blocked',
    createdAt: ago(90),
    salesCrmLeadId: null,
  },
  {
    id: 'u_deleted',
    displayName: 'Ancien client',
    email: 'ancien@email.fr',
    phone: null,
    city: 'Toulouse',
    status: 'deleted',
    createdAt: ago(200),
    salesCrmLeadId: null,
  },
  {
    id: 'u_rania',
    displayName: 'Rania Soussi',
    email: 'rania.soussi@email.fr',
    phone: '+33655556666',
    city: 'Nantes',
    status: 'active',
    createdAt: ago(7),
    salesCrmLeadId: null,
  },
]

const merchantCities = [
  'Paris',
  'Lyon',
  'Marseille',
  'Lille',
  'Nantes',
  'Bordeaux',
  'Toulouse',
  'Strasbourg',
]
const merchantStatuses: MerchantStatus[] = [
  'published',
  'published',
  'draft',
  'unpublished',
  'published',
]

const extraMerchants: CmsMerchant[] = Array.from({ length: 28 }, (_, i) => {
  const n = i + 1
  return {
    id: `m_extra_${String(n).padStart(2, '0')}`,
    displayName: `Boutique démo ${n}`,
    city: merchantCities[i % merchantCities.length]!,
    email: `boutique${n}@yuztoo.com`,
    phone: `+336${String(10000000 + n).slice(0, 8)}`,
    status: merchantStatuses[i % merchantStatuses.length]!,
    updatedAt: ago(n),
    salesCrmLeadId: n % 5 === 0 ? `LD-9${String(n).padStart(3, '0')}` : null,
  }
})

const clientCities = ['Paris', 'Lyon', 'Nice', 'Rennes', 'Dijon', 'Reims']
const clientStatuses: ClientStatus[] = ['active', 'active', 'active', 'blocked']

const extraClients: CmsClient[] = Array.from({ length: 30 }, (_, i) => {
  const n = i + 1
  return {
    id: `u_extra_${String(n).padStart(2, '0')}`,
    displayName: `Client démo ${n}`,
    email: `client${n}@yuztoo.com`,
    phone: n % 3 === 0 ? null : `+336${String(20000000 + n).slice(0, 8)}`,
    city: clientCities[i % clientCities.length]!,
    status: clientStatuses[i % clientStatuses.length]!,
    createdAt: ago(n + 3),
    salesCrmLeadId: n % 7 === 0 ? `LD-8${String(n).padStart(3, '0')}` : null,
  }
})

/**
 * Phase-1 mocks shaped like admin callables. Replace via Edge → Firebase
 * (`adminListMerchants`, `adminListUsers`, …) without changing UI contracts.
 */
export const mockMerchants: CmsMerchant[] = [...seedMerchants, ...extraMerchants]

export const mockClients: CmsClient[] = [...seedClients, ...extraClients]
