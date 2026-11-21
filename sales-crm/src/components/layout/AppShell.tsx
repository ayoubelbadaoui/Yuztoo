import {
  Moon,
  PanelLeftClose,
  PanelLeftOpen,
  Search,
  Sun,
} from 'lucide-react'
import { useEffect, useState } from 'react'
import type { ReactNode } from 'react'

import { findNavItem } from '@/app/navigation'
import { CommandPalette } from '@/components/layout/CommandPalette'
import { SidebarNav } from '@/components/layout/SidebarNav'
import { useTheme } from '@/lib/useTheme'

type Props = {
  activeId: string
  onSelect: (id: string) => void
  badges?: Record<string, number>
  workspace: string
  workspaces?: string[]
  onWorkspaceSelect?: (workspace: string) => void
  children: ReactNode
}

export function AppShell({
  activeId,
  onSelect,
  badges,
  workspace,
  workspaces = [],
  onWorkspaceSelect,
  children,
}: Props) {
  const { theme, toggleTheme } = useTheme()
  const [isSidebarOpen, setIsSidebarOpen] = useState(true)
  const [isPaletteOpen, setIsPaletteOpen] = useState(false)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'k' && (event.metaKey || event.ctrlKey)) {
        event.preventDefault()
        setIsPaletteOpen(true)
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])

  const handleSelect = (id: string) => {
    if (id === 'search') {
      setIsPaletteOpen(true)
      return
    }
    onSelect(id)
  }

  const activeTitle = findNavItem(activeId)?.title ?? 'Tableau de bord'

  return (
    <div className="flex h-screen w-full overflow-hidden bg-background">
      <aside
        className={`h-full shrink-0 overflow-hidden border-r border-border bg-card transition-[width,opacity] duration-300 ${
          isSidebarOpen ? 'w-[260px] opacity-100' : 'w-0 border-none opacity-0'
        }`}
      >
        <SidebarNav
          activeId={activeId}
          onSelect={handleSelect}
          workspace={workspace}
          workspaces={workspaces}
          onWorkspaceSelect={onWorkspaceSelect ?? (() => undefined)}
          badges={badges}
        />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-14 shrink-0 items-center justify-between border-b border-border bg-card px-4">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              aria-label="Afficher ou masquer la navigation"
              className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
            >
              {isSidebarOpen ? (
                <PanelLeftClose className="size-[18px]" strokeWidth={1.5} />
              ) : (
                <PanelLeftOpen className="size-[18px]" strokeWidth={1.5} />
              )}
            </button>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span className="truncate">{workspace}</span>
              <span>/</span>
              <span className="truncate font-medium text-foreground">
                {activeTitle}
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setIsPaletteOpen(true)}
              className="hidden h-8 items-center gap-2 rounded-md border border-border bg-muted px-2.5 text-[13px] text-muted-foreground transition-colors hover:text-foreground md:flex"
            >
              <Search className="size-4" strokeWidth={1.5} />
              Rechercher
              <kbd className="ml-6 font-mono text-[10px]">⌘K</kbd>
            </button>
            <button
              type="button"
              onClick={toggleTheme}
              aria-label="Basculer le thème clair ou sombre"
              className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
            >
              {theme === 'dark' ? (
                <Sun className="size-[18px]" strokeWidth={1.5} />
              ) : (
                <Moon className="size-[18px]" strokeWidth={1.5} />
              )}
            </button>
            <span className="size-8 rounded-full border border-primary/20 bg-primary/10" />
          </div>
        </header>

        <main className="scrollbar-none flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>

      {isPaletteOpen && (
        <CommandPalette
          onClose={() => setIsPaletteOpen(false)}
          onSelect={onSelect}
        />
      )}
    </div>
  )
}
