import { ChevronRight } from 'lucide-react'
import { useState } from 'react'

import type { NavItem } from '@/app/navigation'

type Props = {
  item: NavItem
  activeId: string
  onSelect: (id: string) => void
  /** Compteurs vivants, qui priment sur la valeur déclarée dans la navigation. */
  badges?: Record<string, number>
  level?: number
}

export function NavItemRow({
  item,
  activeId,
  onSelect,
  badges,
  level = 0,
}: Props) {
  const badge = badges?.[item.id] ?? item.badge
  const hasChildren = Boolean(item.children?.length)
  const isActive = activeId === item.id
  const [isOpen, setIsOpen] = useState(
    () => item.children?.some((child) => child.id === activeId) ?? false,
  )

  const handleClick = () => {
    if (hasChildren) {
      setIsOpen(!isOpen)
      return
    }
    onSelect(item.id)
  }

  return (
    <div className="flex w-full flex-col">
      <button
        type="button"
        onClick={handleClick}
        style={{ paddingLeft: `${level * 12 + 10}px` }}
        className={`group flex items-center justify-between rounded-md py-[7px] pr-2.5 text-left transition-colors ${
          isActive
            ? 'bg-accent font-medium text-accent-foreground'
            : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
        }`}
      >
        <span className="flex items-center gap-2.5">
          <item.icon className="size-4 shrink-0" strokeWidth={1.5} />
          <span className="truncate text-[13px] tracking-wide">
            {item.title}
          </span>
        </span>

        <span className="flex items-center gap-2">
          {item.shortcut && (
            <kbd className="hidden h-5 items-center justify-center rounded border border-border bg-muted px-1.5 font-mono text-[10px] text-muted-foreground group-hover:inline-flex">
              {item.shortcut}
            </kbd>
          )}
          {badge !== undefined && badge !== 0 && (
            <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-primary/10 px-1.5 text-[10px] font-medium text-primary">
              {badge}
            </span>
          )}
          {hasChildren && (
            <ChevronRight
              className={`size-3.5 transition-transform ${isOpen ? 'rotate-90' : ''}`}
              strokeWidth={2}
            />
          )}
        </span>
      </button>

      {hasChildren && (
        <div
          className={`grid transition-[grid-template-rows,opacity] duration-200 ${
            isOpen ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0'
          }`}
        >
          <div className="relative mt-0.5 flex min-h-0 flex-col gap-0.5 overflow-hidden">
            <span
              className="absolute bottom-0 top-0 border-l border-border"
              style={{ left: `${level * 12 + 18}px` }}
            />
            {item.children?.map((child) => (
              <NavItemRow
                key={child.id}
                item={child}
                activeId={activeId}
                onSelect={onSelect}
                badges={badges}
                level={level + 1}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
