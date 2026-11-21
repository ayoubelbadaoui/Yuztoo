import { Send, X } from 'lucide-react'
import { useEffect } from 'react'

import { Field, controlClass } from '@/components/ui/Field'
import { AudiencePicker } from '@/features/marketing/components/AudiencePicker'
import { MediaDropzone } from '@/features/marketing/components/MediaDropzone'
import { PostPreview } from '@/features/marketing/components/PostPreview'
import type { Channel } from '@/features/marketing/domain/channel'
import {
  networkMixLabel,
  requiresMediaForChannels,
} from '@/features/marketing/domain/channel'
import type { PostFormat } from '@/features/marketing/domain/post'
import { postFormatLabels } from '@/features/marketing/domain/post'
import type { RecurrenceFreq } from '@/features/marketing/domain/recurrence'
import { recurrenceFreqLabels } from '@/features/marketing/domain/recurrence'
import { usePostComposer } from '@/features/marketing/hooks/usePostComposer'

type Props = {
  channels: Channel[]
  onClose: () => void
  onPublished: () => void
}

const formats: PostFormat[] = ['post', 'story', 'reel']
const freqs: RecurrenceFreq[] = ['once', 'daily', 'every_n_days', 'weekly']
const weekdays = [
  { value: 1, label: 'Lun' },
  { value: 2, label: 'Mar' },
  { value: 3, label: 'Mer' },
  { value: 4, label: 'Jeu' },
  { value: 5, label: 'Ven' },
  { value: 6, label: 'Sam' },
  { value: 0, label: 'Dim' },
]

export function PostComposer({ channels, onClose, onPublished }: Props) {
  const composer = usePostComposer(channels, onPublished)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  const needsMedia =
    composer.format !== 'post' ||
    requiresMediaForChannels(composer.selected)
  const canSend =
    composer.selected.length > 0 &&
    composer.caption.trim() !== '' &&
    (!needsMedia || Boolean(composer.mediaId))
  const canSchedule =
    canSend &&
    (Boolean(composer.scheduledAt) || composer.recurrence.freq !== 'once')

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        aria-label="Fermer le composeur"
        onClick={onClose}
        className="absolute inset-0 bg-foreground/20"
      />

      <aside
        role="dialog"
        aria-modal="true"
        aria-label="Nouvelle publication"
        className="pop-in relative flex h-full w-full max-w-2xl flex-col border-l border-border bg-card shadow-2xl"
      >
        <header className="flex shrink-0 items-start justify-between gap-3 border-b border-border p-4">
          <div>
            <h2 className="text-[15px] font-semibold text-card-foreground">
              Nouvelle publication
            </h2>
            <p className="text-[12px] text-muted-foreground">
              Média réel, comptes Meta connectés, récurrence optionnelle
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            <X className="size-4" />
          </button>
        </header>

        <div className="scrollbar-none flex min-h-0 flex-1 gap-4 overflow-y-auto p-4">
          <div className="flex min-w-0 flex-1 flex-col gap-4">
            <div className="flex gap-1 rounded-lg border border-border p-0.5">
              {formats.map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => composer.setFormat(option)}
                  className={`h-8 flex-1 rounded-[6px] text-[13px] transition-colors ${
                    composer.format === option
                      ? 'bg-primary text-primary-foreground'
                      : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  {postFormatLabels[option]}
                </button>
              ))}
            </div>

            <Field
              label="Texte"
              htmlFor="post-caption"
              hint={`${composer.remaining} caractère${Math.abs(composer.remaining) > 1 ? 's' : ''} restant${Math.abs(composer.remaining) > 1 ? 's' : ''} sur ${composer.limit}`}
            >
              <textarea
                id="post-caption"
                value={composer.caption}
                onChange={(event) => composer.setCaption(event.target.value)}
                rows={5}
                placeholder="Ce que vos clients vont lire…"
                className="w-full resize-none rounded-lg border border-input bg-background p-2.5 text-[13px] leading-relaxed text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-ring focus:ring-1 focus:ring-ring"
              />
            </Field>

            <Field label="Visuel" htmlFor="post-media">
              <MediaDropzone
                mediaUrl={composer.mediaUrl}
                mediaLabel={composer.mediaLabel}
                isUploading={composer.isUploading}
                onFile={(file) => void composer.uploadFile(file)}
                onClear={composer.clearMedia}
              />
            </Field>

            <AudiencePicker
              channels={channels}
              audience={composer.audience}
              onAudience={composer.setAudience}
              matched={composer.matched}
              selected={composer.selected}
              excluded={composer.excluded}
              onToggleExcluded={composer.toggleExcluded}
            />

            <Field
              label="Programmation"
              htmlFor="post-schedule"
              hint="Laissez vide pour publier immédiatement (si une seule fois)."
            >
              <input
                id="post-schedule"
                type="datetime-local"
                value={composer.scheduledAt}
                onChange={(event) =>
                  composer.setScheduledAt(event.target.value)
                }
                className={controlClass}
              />
            </Field>

            <Field label="Répéter" htmlFor="post-recurrence">
              <div className="flex flex-col gap-2">
                <div className="flex flex-wrap gap-1.5">
                  {freqs.map((freq) => (
                    <button
                      key={freq}
                      type="button"
                      onClick={() =>
                        composer.setRecurrence({
                          ...composer.recurrence,
                          freq,
                          interval:
                            freq === 'every_n_days'
                              ? Math.max(2, composer.recurrence.interval)
                              : 1,
                        })
                      }
                      className={`h-7 rounded-full px-2.5 text-[12px] transition-colors ${
                        composer.recurrence.freq === freq
                          ? 'bg-primary text-primary-foreground'
                          : 'border border-border text-muted-foreground hover:bg-muted'
                      }`}
                    >
                      {recurrenceFreqLabels[freq]}
                    </button>
                  ))}
                </div>

                {composer.recurrence.freq === 'every_n_days' && (
                  <label className="flex items-center gap-2 text-[12px] text-muted-foreground">
                    Tous les
                    <input
                      type="number"
                      min={2}
                      max={30}
                      value={composer.recurrence.interval}
                      onChange={(event) =>
                        composer.setRecurrence({
                          ...composer.recurrence,
                          interval: Number(event.target.value) || 2,
                        })
                      }
                      className="h-8 w-16 rounded-lg border border-input bg-background px-2 text-foreground"
                    />
                    jours
                  </label>
                )}

                {composer.recurrence.freq === 'weekly' && (
                  <div className="flex flex-wrap gap-1">
                    {weekdays.map((day) => {
                      const on = composer.recurrence.byWeekday.includes(day.value)
                      return (
                        <button
                          key={day.value}
                          type="button"
                          onClick={() => {
                            const byWeekday = on
                              ? composer.recurrence.byWeekday.filter(
                                  (value) => value !== day.value,
                                )
                              : [...composer.recurrence.byWeekday, day.value]
                            composer.setRecurrence({
                              ...composer.recurrence,
                              byWeekday,
                            })
                          }}
                          className={`h-7 rounded-full px-2.5 text-[12px] ${
                            on
                              ? 'bg-primary text-primary-foreground'
                              : 'border border-border text-muted-foreground'
                          }`}
                        >
                          {day.label}
                        </button>
                      )
                    })}
                  </div>
                )}

                {composer.recurrence.freq !== 'once' && (
                  <label className="flex items-center gap-2 text-[12px] text-muted-foreground">
                    Max occurrences
                    <input
                      type="number"
                      min={1}
                      max={52}
                      value={composer.recurrence.maxOccurrences ?? 8}
                      onChange={(event) =>
                        composer.setRecurrence({
                          ...composer.recurrence,
                          maxOccurrences: Number(event.target.value) || 8,
                        })
                      }
                      className="h-8 w-16 rounded-lg border border-input bg-background px-2 text-foreground"
                    />
                  </label>
                )}
              </div>
            </Field>

            {composer.error && (
              <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
                {composer.error}
              </p>
            )}
          </div>

          <div className="hidden w-52 shrink-0 flex-col gap-2 lg:flex">
            <p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
              Aperçu
            </p>
            <PostPreview
              format={composer.format}
              caption={composer.caption}
              mediaLabel={composer.mediaLabel}
              mediaUrl={composer.mediaUrl}
              channels={composer.selected}
            />
            {needsMedia && !composer.mediaId && (
              <p className="text-[11px] text-muted-foreground">
                Instagram (ou story/reel) exige un visuel avant l’envoi.
              </p>
            )}
          </div>
        </div>

        <footer className="flex shrink-0 flex-col gap-2 border-t border-border p-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-[11px] text-muted-foreground">
            {composer.selected.length === 0
              ? 'Choisissez Facebook, Instagram, ou les deux'
              : networkMixLabel(composer.selected)}
          </p>
          <div className="flex items-center justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="h-9 rounded-lg border border-border px-3 text-[13px] text-foreground transition-colors hover:bg-muted"
            >
              Annuler
            </button>
            <button
              type="button"
              disabled={!canSchedule || composer.isBusy}
              onClick={() => void composer.submit('schedule')}
              className="h-9 rounded-lg border border-border px-3 text-[13px] text-foreground transition-colors hover:bg-muted disabled:opacity-40"
            >
              Programmer
            </button>
            <button
              type="button"
              disabled={!canSend || composer.isBusy || composer.isUploading}
              onClick={() => void composer.submit('now')}
              className="flex h-9 items-center gap-1.5 rounded-lg bg-primary px-3.5 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-40"
            >
              <Send className="size-4" />
              {composer.isBusy
                ? 'Envoi…'
                : `Publier sur ${composer.selected.length} compte${composer.selected.length > 1 ? 's' : ''}`}
            </button>
          </div>
        </footer>
      </aside>
    </div>
  )
}
