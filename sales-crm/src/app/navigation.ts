import {
  AlertTriangle,
  CalendarDays,
  CalendarRange,
  FileSignature,
  FileText,
  Inbox,
  KanbanSquare,
  LayoutDashboard,
  LayoutTemplate,
  LogOut,
  Megaphone,
  MessagesSquare,
  RefreshCw,
  Search,
  Settings,
  Share2,
  Users,
  Wallet,
} from 'lucide-react'
import type { ElementType } from 'react'

export type NavItem = {
  id: string
  title: string
  icon: ElementType
  badge?: number | string
  shortcut?: string
  children?: NavItem[]
}

export type NavGroup = {
  heading?: string
  items: NavItem[]
}

/** Navigation map for the first Sales CRM scope. Pages are placeholders for now. */
export const navGroups: NavGroup[] = [
  {
    items: [
      { id: 'search', title: 'Recherche', icon: Search, shortcut: '⌘K' },
      { id: 'dashboard', title: 'Tableau de bord', icon: LayoutDashboard },
      { id: 'inbox', title: 'Inbox', icon: Inbox, badge: 0 },
    ],
  },
  {
    heading: 'Pipeline',
    items: [
      {
        id: 'leads',
        title: 'Leads',
        icon: Users,
        children: [
          { id: 'leads-all', title: 'Tous', icon: Users },
          { id: 'leads-merchants', title: 'Commerçants', icon: Users },
          { id: 'leads-clients', title: 'Clients', icon: Users },
        ],
      },
      { id: 'pipeline', title: 'Pipeline', icon: KanbanSquare },
    ],
  },
  {
    heading: 'Commercial',
    items: [
      { id: 'quotes', title: 'Devis', icon: FileText },
      { id: 'contracts', title: 'Contrats', icon: FileSignature },
    ],
  },
  {
    heading: 'Facturation',
    items: [
      { id: 'subscriptions', title: 'Abonnements', icon: RefreshCw },
      { id: 'dunning', title: 'Recouvrement', icon: AlertTriangle },
      { id: 'schedule', title: 'Échéancier', icon: Wallet },
    ],
  },
  {
    heading: 'Marketing',
    items: [
      { id: 'publications', title: 'Publications', icon: Megaphone },
      { id: 'content-calendar', title: 'Calendrier éditorial', icon: CalendarRange },
      { id: 'social-inbox', title: 'Messages Meta', icon: MessagesSquare },
      { id: 'whatsapp', title: 'WhatsApp', icon: MessagesSquare },
      { id: 'whatsapp-templates', title: 'Modèles WhatsApp', icon: LayoutTemplate },
      { id: 'channels', title: 'Comptes connectés', icon: Share2 },
    ],
  },
  {
    heading: 'Agenda',
    items: [{ id: 'calendar', title: 'Calendrier', icon: CalendarDays }],
  },
]

export const navBottomItems: NavItem[] = [
  { id: 'settings', title: 'Configuration', icon: Settings, shortcut: '⌘,' },
  { id: 'logout', title: 'Déconnexion', icon: LogOut },
]

function flatten(items: NavItem[]): NavItem[] {
  return items.flatMap((item) =>
    item.children ? [item, ...flatten(item.children)] : [item],
  )
}

export const allNavItems: NavItem[] = flatten([
  ...navGroups.flatMap((group) => group.items),
  ...navBottomItems,
])

export function findNavItem(id: string): NavItem | undefined {
  return allNavItems.find((item) => item.id === id)
}
