import { X } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import { YuztooNewsBannerPreview } from '@/features/cms-app/components/YuztooNewsBannerPreview'
import { YuztooNewsReleaseSection } from '@/features/cms-app/components/YuztooNewsReleaseSection'
import type { MediaTestAccount } from '@/features/cms-app/domain/mediaRelease'
import type {
  YuztooNews,
  YuztooNewsInput,
} from '@/features/cms-app/domain/yuztooNews'
import {
  YUZTOO_NEWS_BODY_MAX,
  YUZTOO_NEWS_CTA_LABEL_MAX,
  YUZTOO_NEWS_TITLE_MAX,
} from '@/features/cms-app/domain/yuztooNews'

type Props = {
  news: YuztooNews | null
  testAccounts: MediaTestAccount[]
  testSearch: string
  onTestSearch: (value: string) => void
  onClose: () => void
  onSave: (
    input: YuztooNewsInput,
  ) => Promise<{ error: string | null; news: YuztooNews | null }>
  onSelectTestAccount: (
    id: string,
    account: MediaTestAccount | null,
  ) => Promise<{ error: string | null; news: YuztooNews | null }>
  onActivatePreview: (
    id: string,
  ) => Promise<{ error: string | null; news: YuztooNews | null }>
  onPublishLive: (
    id: string,
  ) => Promise<{ error: string | null; news: YuztooNews | null }>
  onRevertToDraft: (
    id: string,
  ) => Promise<{ error: string | null; news: YuztooNews | null }>
  onNewsUpdated: (news: YuztooNews) => void
}

function toLocalInputValue(iso: string): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export function YuztooNewsEditPanel({
  news,
  testAccounts,
  testSearch,
  onTestSearch,
  onClose,
  onSave,
  onSelectTestAccount,
  onActivatePreview,
  onPublishLive,
  onRevertToDraft,
  onNewsUpdated,
}: Props) {
  const [current, setCurrent] = useState<YuztooNews | null>(news)
  const isCreate = current == null
  const [title, setTitle] = useState(news?.title ?? '')
  const [body, setBody] = useState(news?.body ?? '')
  const [publishLocal, setPublishLocal] = useState(
    toLocalInputValue(news?.publish_on ?? new Date().toISOString()),
  )
  const [active, setActive] = useState(news?.active ?? true)
  const [imageUrl, setImageUrl] = useState(news?.image_url ?? '')
  const [ctaLabel, setCtaLabel] = useState(news?.cta_label ?? '')
  const [ctaUrl, setCtaUrl] = useState(news?.cta_url ?? '')
  const [ctaMerchantId, setCtaMerchantId] = useState(
    news?.cta_merchant_id ?? '',
  )
  const [isSaving, setIsSaving] = useState(false)
  const [isBusyRelease, setIsBusyRelease] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const preview = useMemo(
    () => ({
      title,
      body,
      image_url: imageUrl.trim() || null,
      cta_label: ctaLabel.trim() || null,
      cta_url: ctaUrl.trim() || null,
      cta_merchant_id: ctaMerchantId.trim() || null,
    }),
    [title, body, imageUrl, ctaLabel, ctaUrl, ctaMerchantId],
  )

  const applySaved = (saved: YuztooNews) => {
    setCurrent(saved)
    onNewsUpdated(saved)
  }

  const submit = async () => {
    setIsSaving(true)
    setError(null)
    const publishDate = new Date(publishLocal)
    if (Number.isNaN(publishDate.getTime())) {
      setIsSaving(false)
      setError('Date de publication invalide.')
      return
    }
    const input: YuztooNewsInput = {
      id: current?.id ?? null,
      title,
      body,
      publish_on: publishDate.toISOString(),
      active,
      image_url: imageUrl,
      cta_label: ctaLabel,
      cta_url: ctaUrl,
      cta_merchant_id: ctaMerchantId,
    }
    const { error: message, news: saved } = await onSave(input)
    setIsSaving(false)
    if (message || !saved) {
      setError(message ?? 'Enregistrement impossible')
      return
    }
    applySaved(saved)
  }

  const runRelease = async (
    action: () => Promise<{ error: string | null; news: YuztooNews | null }>,
  ): Promise<string | null> => {
    if (!current) return 'Enregistrez l’actu d’abord.'
    setIsBusyRelease(true)
    setError(null)
    const { error: message, news: updated } = await action()
    setIsBusyRelease(false)
    if (message) {
      setError(message)
      return message
    }
    if (updated) applySaved(updated)
    return null
  }

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        aria-label="Fermer le panneau"
        onClick={onClose}
        className="absolute inset-0 bg-foreground/20"
      />
      <aside
        role="dialog"
        aria-modal="true"
        aria-label={isCreate ? 'Nouvelle actu' : `Modifier ${current!.title}`}
        className="pop-in relative flex h-full w-full max-w-md flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div className="min-w-0">
            <h2 className="truncate text-[15px] font-semibold text-card-foreground">
              {isCreate ? 'Nouvelle actu' : 'Modifier l’actu'}
            </h2>
            <p className="text-[12px] text-muted-foreground">
              {isCreate
                ? 'Enregistrez en brouillon, puis aperçu test → tous'
                : current!.id}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent"
          >
            <X className="size-4" />
          </button>
        </header>

        <form
          onSubmit={(event) => {
            event.preventDefault()
            void submit()
          }}
          className="flex min-h-0 flex-1 flex-col"
        >
          <div className="scrollbar-none flex min-h-0 flex-1 flex-col gap-3.5 overflow-y-auto p-4">
            <YuztooNewsBannerPreview news={preview} />

            <Field label="Titre" htmlFor="actu-title">
              <input
                id="actu-title"
                value={title}
                maxLength={YUZTOO_NEWS_TITLE_MAX}
                onChange={(event) => setTitle(event.target.value)}
                className={controlClass}
                required
              />
            </Field>

            <Field label="Texte" htmlFor="actu-body">
              <textarea
                id="actu-body"
                value={body}
                maxLength={YUZTOO_NEWS_BODY_MAX}
                onChange={(event) => setBody(event.target.value)}
                rows={5}
                className={`${controlClass} min-h-[100px] resize-y py-2`}
                required
              />
            </Field>

            <Field label="Publier le" htmlFor="actu-publish">
              <input
                id="actu-publish"
                type="datetime-local"
                value={publishLocal}
                onChange={(event) => setPublishLocal(event.target.value)}
                className={controlClass}
                required
              />
            </Field>

            <label className="flex items-center gap-2 text-[13px] text-foreground">
              <input
                type="checkbox"
                checked={active}
                onChange={(event) => setActive(event.target.checked)}
              />
              Active (soft hide — la publication reste draft/preview/live)
            </label>

            <Field label="Image URL (optionnel)" htmlFor="actu-image">
              <input
                id="actu-image"
                type="url"
                value={imageUrl}
                onChange={(event) => setImageUrl(event.target.value)}
                placeholder="https://…"
                className={controlClass}
              />
              <p className="mt-1 text-[11px] text-muted-foreground">
                HTTPS uniquement. Bannière app ≈ 46×46 ; détail pleine largeur
                (idéalement 16:9). Upload crop intégré prévu ensuite.
              </p>
            </Field>

            <Field label="Libellé CTA" htmlFor="actu-cta-label">
              <input
                id="actu-cta-label"
                value={ctaLabel}
                maxLength={YUZTOO_NEWS_CTA_LABEL_MAX}
                onChange={(event) => setCtaLabel(event.target.value)}
                placeholder="En savoir plus"
                className={controlClass}
              />
            </Field>

            <Field
              label="CTA boutique id (reste dans l’app — recommandé)"
              htmlFor="actu-cta-merchant"
            >
              <input
                id="actu-cta-merchant"
                value={ctaMerchantId}
                onChange={(event) => setCtaMerchantId(event.target.value)}
                placeholder="merchantId Firebase"
                className={controlClass}
              />
            </Field>

            <Field label="CTA URL externe (http/https)" htmlFor="actu-cta-url">
              <input
                id="actu-cta-url"
                type="url"
                value={ctaUrl}
                onChange={(event) => setCtaUrl(event.target.value)}
                placeholder="https://…"
                className={controlClass}
              />
              {ctaUrl.trim() && !ctaMerchantId.trim() ? (
                <p className="mt-1 text-[11px] font-medium text-amber-700 dark:text-amber-400">
                  Attention : cette URL ouvre le navigateur externe et quitte
                  l’app. Préférez un id boutique, ou laissez vide pour rester
                  sur la page Actu.
                </p>
              ) : (
                <p className="mt-1 text-[11px] text-muted-foreground">
                  Laisser vide = pas de bouton (lecture in-app seulement). L’id
                  boutique prime sur l’URL.
                </p>
              )}
            </Field>

            {current ? (
              <YuztooNewsReleaseSection
                news={current}
                accounts={testAccounts}
                search={testSearch}
                onSearch={onTestSearch}
                isBusy={isBusyRelease}
                onSelectAccount={async (account) => {
                  const message = await runRelease(() =>
                    onSelectTestAccount(current.id, account),
                  )
                  if (!message) {
                    // Parent reload updates list; sync local from callback via reload in page
                  }
                  return message
                }}
                onActivatePreview={() =>
                  runRelease(() => onActivatePreview(current.id))
                }
                onPublishLive={() => runRelease(() => onPublishLive(current.id))}
                onRevertToDraft={() =>
                  runRelease(() => onRevertToDraft(current.id))
                }
              />
            ) : (
              <p className="rounded-lg border border-border bg-muted/40 px-3 py-2 text-[12px] text-muted-foreground">
                Enregistrez le contenu (brouillon) pour choisir un compte test et
                publier.
              </p>
            )}

            {error && (
              <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
                {error}
              </p>
            )}
          </div>

          <footer className="flex shrink-0 gap-2 border-t border-border p-4">
            <button
              type="button"
              onClick={onClose}
              className="h-9 flex-1 rounded-lg border border-border text-[13px] font-medium hover:bg-muted"
            >
              Fermer
            </button>
            <button
              type="submit"
              disabled={isSaving}
              className="h-9 flex-1 rounded-lg bg-primary text-[13px] font-medium text-primary-foreground disabled:opacity-50"
            >
              {isSaving ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </footer>
        </form>
      </aside>
    </div>
  )
}
