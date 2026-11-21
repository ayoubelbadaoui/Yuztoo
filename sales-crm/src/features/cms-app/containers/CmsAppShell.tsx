import {
  BarChart3,
  Image,
  LayoutDashboard,
  Moon,
  ReceiptText,
  Settings,
  Store,
  Sun,
  Users,
} from 'lucide-react'
import { useState } from 'react'
import type { ElementType, ReactNode } from 'react'

import type { CmsViewId } from '@/features/cms-app/domain/cms'
import { useTheme } from '@/lib/useTheme'

type NavItem = {
  id: CmsViewId | 'stats' | 'audit' | 'settings'
  title: string
  icon: ElementType
  disabled?: boolean
  badge?: string
}

const navItems: NavItem[] = [
  { id: 'dashboard', title: 'Tableau de bord', icon: LayoutDashboard },
  { id: 'stores', title: 'Boutiques', icon: Store },
  { id: 'clients', title: 'Clients', icon: Users },
  { id: 'images', title: 'Images app', icon: Image },
  { id: 'stats', title: 'Statistiques', icon: BarChart3, disabled: true, badge: 'V2' },
  { id: 'audit', title: "Journal d'audit", icon: ReceiptText, disabled: true, badge: 'V2' },
  { id: 'settings', title: 'Paramètres', icon: Settings, disabled: true, badge: 'V2' },
]

const enabledViews: CmsViewId[] = ['dashboard', 'stores', 'clients', 'images']

type Props = {
  activeId: CmsViewId
  onSelect: (id: CmsViewId) => void
  children: ReactNode
}

export function CmsAppShell({ activeId, onSelect, children }: Props) {
  const { theme, toggleTheme } = useTheme()
  const [sidebarOpen, setSidebarOpen] = useState(true)

  const activeTitle =
    navItems.find((item) => item.id === activeId)?.title ?? 'CMS App Yuztoo'

  return (
    <div className="flex h-screen w-full overflow-hidden bg-background">
      <aside
        className={`flex h-full shrink-0 flex-col border-r border-border bg-card transition-[width] duration-300 ${
          sidebarOpen ? 'w-[248px]' : 'w-[72px]'
        }`}
      >
        <div className="flex items-center gap-3 border-b border-border px-3 py-4">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary text-[12px] font-bold text-primary-foreground">
            Y
          </span>
          {sidebarOpen && (
            <div className="min-w-0">
              <p className="truncate text-[13px] font-semibold text-card-foreground">
                CMS App Yuztoo
              </p>
              <p className="truncate text-[11px] text-muted-foreground">
                Administration produit
              </p>
            </div>
          )}
        </div>

        <nav className="flex flex-1 flex-col gap-0.5 overflow-y-auto p-2">
          {navItems.map((item) => {
            const Icon = item.icon
            const active = item.id === activeId
            return (
              <button
                key={item.id}
                type="button"
                disabled={item.disabled}
                title={item.title}
                onClick={() => {
                  if (
                    !item.disabled &&
                    enabledViews.includes(item.id as CmsViewId)
                  ) {
                    onSelect(item.id as CmsViewId)
                  }
                }}
                className={`flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-left text-[13px] transition-colors disabled:cursor-not-allowed disabled:opacity-40 ${
                  active
                    ? 'bg-accent font-medium text-accent-foreground'
                    : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                }`}
              >
                <Icon className="size-4 shrink-0" strokeWidth={1.5} />
                {sidebarOpen && (
                  <>
                    <span className="min-w-0 flex-1 truncate">{item.title}</span>
                    {item.badge && (
                      <span className="rounded-md bg-primary/15 px-1.5 text-[10px] font-semibold text-primary">
                        {item.badge}
                      </span>
                    )}
                  </>
                )}
              </button>
            )
          })}
        </nav>

        {sidebarOpen && (
          <p className="border-t border-border p-3 text-[11px] leading-relaxed text-muted-foreground">
            Données produit (boutiques & clients). Le pipeline commercial reste
            dans la fenêtre Sales CRM.
          </p>
        )}
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-14 shrink-0 items-center justify-between border-b border-border bg-card px-4">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setSidebarOpen((open) => !open)}
              className="rounded-md px-2 py-1 text-[12px] text-muted-foreground transition-colors hover:bg-muted"
            >
              Menu
            </button>
            <div className="text-sm text-muted-foreground">
              <span className="font-medium text-foreground">{activeTitle}</span>
            </div>
          </div>
          <button
            type="button"
            onClick={toggleTheme}
            aria-label="Basculer le thème"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent"
          >
            {theme === 'dark' ? (
              <Sun className="size-[18px]" strokeWidth={1.5} />
            ) : (
              <Moon className="size-[18px]" strokeWidth={1.5} />
            )}
          </button>
        </header>
        <main className="scrollbar-none flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
