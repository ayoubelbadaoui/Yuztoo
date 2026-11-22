import { Store, X } from 'lucide-react'
import { useCallback } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import type {
  NewsMerchantOption,
  YuztooNewsCtaKind,
} from '@/features/cms-app/domain/yuztooNews'
import {
  YUZTOO_NEWS_CTA_LABEL_MAX,
  YUZTOO_NEWS_DEFAULT_CTA_LABEL,
  yuztooNewsCtaKindLabels,
} from '@/features/cms-app/domain/yuztooNews'
import { useDebouncedLookup } from '@/features/cms-app/hooks/useDebouncedLookup'
import { searchActuMerchants } from '@/features/cms-app/services/yuztooNewsLookupService'

export type ButtonShop = { id: string; label: string | null }

type Props = {
  kind: YuztooNewsCtaKind
  onKind: (kind: YuztooNewsCtaKind) => void
  label: string
  onLabel: (value: string) => void
  url: string
  onUrl: (value: string) => void
  shop: ButtonShop | null
  onShop: (shop: ButtonShop | null) => void
}

const kinds: YuztooNewsCtaKind[] = ['none', 'merchant', 'url']

/** "Sans bouton / boutique / lien" — one clear choice instead of raw fields. */
export function YuztooNewsButtonFields({
  kind,
  onKind,
  label,
  onLabel,
  url,
  onUrl,
  shop,
  onShop,
}: Props) {
  return (
    <section className="flex flex-col gap-2.5">
      <p className="text-[13px] font-semibold text-card-foreground">Bouton</p>
      <div
        role="radiogroup"
        aria-label="Type de bouton"
        className="grid grid-cols-3 gap-1 rounded-lg bg-muted p-1"
      >
        {kinds.map((value) => (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={kind === value}
            onClick={() => onKind(value)}
            className={`rounded-md px-2 py-1.5 text-[12px] font-medium transition-colors ${
              kind === value
                ? 'bg-card text-card-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {yuztooNewsCtaKindLabels[value]}
          </button>
        ))}
      </div>

      {kind === 'none' && (
        <p className="text-[11px] text-muted-foreground">
          Texte seul : le client lit l’actu, sans action.
        </p>
      )}

      {kind === 'merchant' && <ShopPicker shop={shop} onShop={onShop} />}

      {kind === 'url' && (
        <Field label="Lien (http/https)" htmlFor="actu-cta-url">
          <input
            id="actu-cta-url"
            type="url"
            value={url}
            onChange={(event) => onUrl(event.target.value)}
            placeholder="https://…"
            className={controlClass}
            required
          />
          <p className="mt-1 text-[11px] font-medium text-amber-700 dark:text-amber-400">
            Ouvre le navigateur et quitte l’app. Préférez une boutique quand
            c’est possible.
          </p>
        </Field>
      )}

      {kind !== 'none' && (
        <Field label="Texte du bouton" htmlFor="actu-cta-label">
          <input
            id="actu-cta-label"
            value={label}
            maxLength={YUZTOO_NEWS_CTA_LABEL_MAX}
            onChange={(event) => onLabel(event.target.value)}
            placeholder={YUZTOO_NEWS_DEFAULT_CTA_LABEL}
            className={controlClass}
          />
        </Field>
      )}
    </section>
  )
}

function ShopPicker({
  shop,
  onShop,
}: {
  shop: ButtonShop | null
  onShop: (shop: ButtonShop | null) => void
}) {
  const lookup = useCallback(
    (search: string) => searchActuMerchants({ search }),
    [],
  )
  const { query, setQuery, results, isSearching, error } =
    useDebouncedLookup<NewsMerchantOption>(lookup)

  if (shop) {
    return (
      <div className="flex items-center gap-2 rounded-lg border border-border bg-background px-3 py-2">
        <Store className="size-4 shrink-0 text-muted-foreground" />
        <div className="min-w-0 flex-1">
          <p className="truncate text-[13px] font-medium">
            {shop.label ?? 'Boutique'}
          </p>
          <p className="truncate text-[11px] text-muted-foreground">{shop.id}</p>
        </div>
        <button
          type="button"
          onClick={() => onShop(null)}
          aria-label="Changer de boutique"
          className="rounded-md p-1 text-muted-foreground hover:bg-accent"
        >
          <X className="size-4" />
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-1.5">
      <input
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Nom de la boutique (ex. « boul »)…"
        aria-label="Rechercher une boutique"
        className={controlClass}
      />
      {query.trim().length >= 2 && (
        <div className="max-h-40 overflow-y-auto rounded-lg border border-border bg-background">
          {isSearching ? (
            <p className="p-3 text-[12px] text-muted-foreground">Recherche…</p>
          ) : error ? (
            <p className="p-3 text-[12px] text-destructive">{error}</p>
          ) : results.length === 0 ? (
            <p className="p-3 text-[12px] text-muted-foreground">
              Aucune boutique ne commence par « {query.trim()} ».
            </p>
          ) : (
            results.map((merchant) => (
              <button
                key={merchant.id}
                type="button"
                onClick={() => onShop({ id: merchant.id, label: merchant.name })}
                className="flex w-full flex-col border-b border-border px-3 py-2 text-left last:border-0 hover:bg-muted/60"
              >
                <span className="text-[13px] font-medium">{merchant.name}</span>
                <span className="text-[11px] text-muted-foreground">
                  {[merchant.city, merchant.status === 'inactive' ? 'hors ligne' : null]
                    .filter(Boolean)
                    .join(' · ') || merchant.id}
                </span>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  )
}
