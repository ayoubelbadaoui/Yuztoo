import { X } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import { YuztooNewsBannerPreview } from '@/features/cms-app/components/YuztooNewsBannerPreview'
import type { ButtonShop } from '@/features/cms-app/components/YuztooNewsButtonFields'
import { YuztooNewsButtonFields } from '@/features/cms-app/components/YuztooNewsButtonFields'
import { YuztooNewsReleaseSection } from '@/features/cms-app/components/YuztooNewsReleaseSection'
import type {
  NewsTestClient,
  YuztooNews,
  YuztooNewsCtaKind,
  YuztooNewsInput,
} from '@/features/cms-app/domain/yuztooNews'
import {
  ctaKindOf,
  YUZTOO_NEWS_BODY_MAX,
  YUZTOO_NEWS_TITLE_MAX,
} from '@/features/cms-app/domain/yuztooNews'

type Props = {
  news: YuztooNews | null
  onClose: () => void
  onSave: (
    input: YuztooNewsInput,
  ) => Promise<{ error: string | null; news: YuztooNews | null }>
  onSelectTestAccount: (
    id: string,
    account: NewsTestClient | null,
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
  const [ctaKind, setCtaKind] = useState<YuztooNewsCtaKind>(ctaKindOf(news))
  const [ctaLabel, setCtaLabel] = useState(news?.cta_label ?? '')
  const [ctaUrl, setCtaUrl] = useState(news?.cta_url ?? '')
  const [ctaShop, setCtaShop] = useState<ButtonShop | null>(
    news?.cta_merchant_id
      ? { id: news.cta_merchant_id, label: news.cta_merchant_label }
      : null,
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

  // Only the chosen button kind is sent: switching to "Sans bouton" really
  // removes the button instead of leaving hidden fields behind.
  const button = useMemo(
    () => ({
      cta_label: ctaKind === 'none' ? null : ctaLabel.trim() || null,
      cta_url: ctaKind === 'url' ? ctaUrl.trim() || null : null,
      cta_merchant_id: ctaKind === 'merchant' ? (ctaShop?.id ?? null) : null,
      cta_merchant_label:
        ctaKind === 'merchant' ? (ctaShop?.label ?? null) : null,
    }),
    [ctaKind, ctaLabel, ctaUrl, ctaShop],
  )

  const preview = useMemo(
    () => ({ title, body, image_url: imageUrl.trim() || null, ...button }),
    [title, body, imageUrl, button],
  )

  const isDirty =
    current != null &&
    (title.trim() !== current.title ||
      body.trim() !== current.body ||
      (imageUrl.trim() || null) !== current.image_url ||
      active !== current.active ||
      publishLocal !== toLocalInputValue(current.publish_on) ||
      button.cta_url !== current.cta_url ||
      button.cta_merchant_id !== current.cta_merchant_id ||
      (button.cta_merchant_id || button.cta_url ? button.cta_label : null) !==
        current.cta_label)

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
    if (ctaKind === 'merchant' && !ctaShop) {
      setIsSaving(false)
      setError('Choisissez la boutique que le bouton ouvre.')
      return
    }
    const input: YuztooNewsInput = {
      id: current?.id ?? null,
      title,
      body,
      publish_on: publishDate.toISOString(),
      active,
      image_url: imageUrl,
      ...button,
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
                ? 'Brouillon → test sur 1 client → tous les clients'
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

            <Field label="Image (optionnel)" htmlFor="actu-image">
              <input
                id="actu-image"
                type="url"
                value={imageUrl}
                onChange={(event) => setImageUrl(event.target.value)}
                placeholder="https://… — laisser vide pour une actu sans image"
                className={controlClass}
              />
              <p className="mt-1 text-[11px] text-muted-foreground">
                HTTPS uniquement. Vignette 46×46 dans Alertes, pleine largeur
                (16:9) sur la page détail.
              </p>
            </Field>

            <YuztooNewsButtonFields
              kind={ctaKind}
              onKind={setCtaKind}
              label={ctaLabel}
              onLabel={setCtaLabel}
              url={ctaUrl}
              onUrl={setCtaUrl}
              shop={ctaShop}
              onShop={setCtaShop}
            />

            <Field label="Visible à partir du" htmlFor="actu-publish">
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
              Active (décochez pour masquer sans dépublier)
            </label>

            {current ? (
              <YuztooNewsReleaseSection
                news={current}
                isBusy={isBusyRelease}
                isDirty={isDirty}
                onSelectAccount={(account) =>
                  runRelease(() => onSelectTestAccount(current.id, account))
                }
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
                Enregistrez le brouillon pour choisir le client test, puis
                publier pour tous les clients.
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
