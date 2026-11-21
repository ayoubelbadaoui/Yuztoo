import { navBottomItems, navGroups } from '@/app/navigation'
import { NavItemRow } from '@/components/layout/NavItemRow'
import { WorkspaceSwitcher } from '@/components/layout/WorkspaceSwitcher'

type Props = {
  activeId: string
  onSelect: (id: string) => void
  workspace: string
  workspaces?: string[]
  onWorkspaceSelect: (workspace: string) => void
  badges?: Record<string, number>
}

export function SidebarNav({
  activeId,
  onSelect,
  workspace,
  workspaces = [],
  onWorkspaceSelect,
  badges,
}: Props) {
  return (
    <div className="flex h-full w-[260px] flex-col p-3">
      <WorkspaceSwitcher
        selected={workspace}
        workspaces={workspaces}
        onSelect={onWorkspaceSelect}
      />

      <nav className="scrollbar-none mt-2 flex flex-1 flex-col gap-4 overflow-y-auto">
        {navGroups.map((group, index) => (
          <div key={group.heading ?? index} className="flex flex-col gap-0.5">
            {group.heading && (
              <span className="mb-1 px-2.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                {group.heading}
              </span>
            )}
            {group.items.map((item) => (
              <NavItemRow
                key={item.id}
                item={item}
                activeId={activeId}
                onSelect={onSelect}
                badges={badges}
              />
            ))}
          </div>
        ))}
      </nav>

      <div className="mt-auto flex flex-col gap-0.5 border-t border-border pt-4">
        {navBottomItems.map((item) => (
          <NavItemRow
            key={item.id}
            item={item}
            activeId={activeId}
            onSelect={onSelect}
          />
        ))}
      </div>
    </div>
  )
}
