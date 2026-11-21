import { Check, ChevronsUpDown, Search } from 'lucide-react'
import { useEffect, useMemo, useRef, useState } from 'react'

const MAX_RESULTS = 8

export type ComboboxOption = {
  id: string
  label: string
  /** Seconde ligne, affichée en gris sous le libellé. */
  hint?: string
  /** Texte réellement fouillé par la recherche, à défaut du libellé. */
  keywords?: string
}

type Props = {
  options: ComboboxOption[]
  value: string
  onChange: (id: string) => void
  placeholder: string
  searchPlaceholder: string
  emptyLabel: string
}

/** Sélecteur cherchable : au-delà de quelques entrées, une liste déroulante ne tient plus. */
export function Combobox({
  options,
  value,
  onChange,
  placeholder,
  searchPlaceholder,
  emptyLabel,
}: Props) {
  const [isOpen, setIsOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [highlighted, setHighlighted] = useState(0)
  const root = useRef<HTMLDivElement>(null)
  const input = useRef<HTMLInputElement>(null)

  const selected = options.find((option) => option.id === value) ?? null

  const matches = useMemo(() => {
    const needle = query.trim().toLowerCase()
    const pool = needle
      ? options.filter((option) =>
          (option.keywords ?? `${option.label} ${option.hint ?? ''}`)
            .toLowerCase()
            .includes(needle),
        )
      : options
    return { visible: pool.slice(0, MAX_RESULTS), total: pool.length }
  }, [options, query])

  useEffect(() => {
    if (!isOpen) return
    input.current?.focus()

    const onPointerDown = (event: PointerEvent) => {
      if (!root.current?.contains(event.target as Node)) setIsOpen(false)
    }
    document.addEventListener('pointerdown', onPointerDown)
    return () => document.removeEventListener('pointerdown', onPointerDown)
  }, [isOpen])

  const pick = (option: ComboboxOption) => {
    onChange(option.id)
    setIsOpen(false)
    setQuery('')
  }

  const onKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault()
      setHighlighted((current) => {
        const next = current + (event.key === 'ArrowDown' ? 1 : -1)
        return Math.max(0, Math.min(next, matches.visible.length - 1))
      })
      return
    }
    if (event.key === 'Enter') {
      event.preventDefault()
      const option = matches.visible[highlighted]
      if (option) pick(option)
      return
    }
    if (event.key === 'Escape') {
      event.preventDefault()
      setIsOpen(false)
    }
  }

  return (
    <div ref={root} className="relative">
      <button
        type="button"
        onClick={() => setIsOpen((current) => !current)}
        aria-haspopup="listbox"
        aria-expanded={isOpen}
        className="flex h-9 w-full items-center justify-between gap-2 rounded-lg border border-input bg-background px-2.5 text-left text-[13px] transition-colors hover:border-ring"
      >
        {selected ? (
          <span className="min-w-0 truncate text-foreground">
            {selected.label}
            {selected.hint && (
              <span className="text-muted-foreground">{` — ${selected.hint}`}</span>
            )}
          </span>
        ) : (
          <span className="text-muted-foreground">{placeholder}</span>
        )}
        <ChevronsUpDown className="size-3.5 shrink-0 text-muted-foreground" />
      </button>

      {isOpen && (
        <div className="absolute z-10 mt-1 w-full overflow-hidden rounded-lg border border-border bg-popover shadow-xl">
          <div className="flex items-center gap-2 border-b border-border px-2.5">
            <Search className="size-3.5 shrink-0 text-muted-foreground" />
            <input
              ref={input}
              value={query}
              onChange={(event) => {
                setQuery(event.target.value)
                setHighlighted(0)
              }}
              onKeyDown={onKeyDown}
              placeholder={searchPlaceholder}
              className="h-9 w-full bg-transparent text-[13px] text-popover-foreground outline-none placeholder:text-muted-foreground"
            />
          </div>

          <ul role="listbox" className="max-h-64 overflow-y-auto p-1">
            {matches.visible.map((option, index) => (
              <li key={option.id}>
                <button
                  type="button"
                  role="option"
                  aria-selected={option.id === value}
                  onPointerEnter={() => setHighlighted(index)}
                  onClick={() => pick(option)}
                  className={`flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left transition-colors ${
                    index === highlighted ? 'bg-accent' : ''
                  }`}
                >
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-[13px] text-popover-foreground">
                      {option.label}
                    </span>
                    {option.hint && (
                      <span className="block truncate text-[11px] text-muted-foreground">
                        {option.hint}
                      </span>
                    )}
                  </span>
                  {option.id === value && (
                    <Check className="size-3.5 shrink-0 text-primary" />
                  )}
                </button>
              </li>
            ))}

            {matches.total === 0 && (
              <li className="px-2 py-3 text-center text-[12px] text-muted-foreground">
                {emptyLabel}
              </li>
            )}
          </ul>

          {matches.total > MAX_RESULTS && (
            <p className="border-t border-border px-2.5 py-1.5 text-[11px] text-muted-foreground">
              {`${matches.total} résultats — affinez la recherche.`}
            </p>
          )}
        </div>
      )}
    </div>
  )
}
