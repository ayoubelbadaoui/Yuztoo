import { ChevronDown, LayoutGrid } from 'lucide-react'
import { useState } from 'react'

import { openCmsAppWindow } from '@/features/cms-app/domain/cms'

type Props = {
  selected: string
  workspaces: string[]
  onSelect: (workspace: string) => void
}

export function WorkspaceSwitcher({
  selected,
  workspaces,
  onSelect,
}: Props) {
  const [isOpen, setIsOpen] = useState(false)
  const options = workspaces.length > 0 ? workspaces : [selected]

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="group mb-4 flex w-full items-center justify-between rounded-lg px-2 py-2 transition-colors hover:bg-accent"
      >
        <span className="flex items-center gap-3">
          <span className="flex size-8 items-center justify-center rounded-md bg-primary text-[13px] font-semibold text-primary-foreground">
            {selected.charAt(0)}
          </span>
          <span className="flex flex-col items-start overflow-hidden">
            <span className="max-w-[130px] truncate text-[13px] font-medium leading-none text-foreground">
              {selected}
            </span>
            <span className="mt-1 text-[11px] leading-none text-muted-foreground">
              Équipe commerciale
            </span>
          </span>
        </span>
        <ChevronDown
          className="size-4 shrink-0 text-muted-foreground"
          strokeWidth={1.5}
        />
      </button>

      {isOpen && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setIsOpen(false)} />
          <div className="pop-in absolute left-0 top-[52px] z-50 flex w-full flex-col gap-0.5 rounded-lg border border-border bg-popover py-1 shadow-xl">
            {options.map((workspace) => (
              <button
                key={workspace}
                type="button"
                onClick={() => {
                  onSelect(workspace)
                  setIsOpen(false)
                }}
                className={`mx-1 rounded-md px-3 py-2 text-left text-[13px] transition-colors ${
                  workspace === selected
                    ? 'bg-primary/10 font-medium text-primary'
                    : 'text-popover-foreground hover:bg-accent'
                }`}
              >
                {workspace}
              </button>
            ))}
            <div className="mx-1 my-1 border-t border-border" />
            <button
              type="button"
              onClick={() => {
                openCmsAppWindow()
                setIsOpen(false)
              }}
              className="mx-1 flex items-center gap-2 rounded-md px-3 py-2 text-left text-[13px] text-popover-foreground transition-colors hover:bg-accent"
            >
              <LayoutGrid className="size-3.5 shrink-0 text-primary" strokeWidth={1.5} />
              <span className="min-w-0">
                <span className="block font-medium">CMS App Yuztoo</span>
                <span className="block text-[11px] text-muted-foreground">
                  Boutiques & clients · nouvelle fenêtre
                </span>
              </span>
            </button>
          </div>
        </>
      )}
    </div>
  )
}
