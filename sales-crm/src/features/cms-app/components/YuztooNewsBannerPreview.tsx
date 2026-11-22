import type { YuztooNews } from '@/features/cms-app/domain/yuztooNews'

type Props = {
  news: Pick<
    YuztooNews,
    'title' | 'body' | 'image_url' | 'cta_label' | 'cta_url' | 'cta_merchant_id'
  >
}

/** Preview matching in-app Alertes banner + detail hero strip. */
export function YuztooNewsBannerPreview({ news }: Props) {
  const cta =
    news.cta_label?.trim() ||
    (news.cta_merchant_id || news.cta_url ? 'En savoir plus' : null)

  return (
    <div className="space-y-3">
      <div className="rounded-2xl border border-[#D4A017]/40 bg-[#152A40] p-3.5 text-white">
        <div className="flex gap-3">
          {/* App banner thumb is 46×46, radius 12 */}
          <div className="flex size-[46px] shrink-0 items-center justify-center overflow-hidden rounded-xl bg-[#0E2A44]">
            {news.image_url ? (
              <img
                src={news.image_url}
                alt=""
                className="size-full object-cover"
              />
            ) : (
              <span className="text-[11px] font-bold text-[#D4A017]">📣</span>
            )}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-[10px] font-extrabold tracking-[0.12em] text-[#D4A017]">
              ACTU YUZTOO
            </p>
            <p className="mt-1 line-clamp-2 text-[14.5px] font-bold leading-tight">
              {news.title || 'Titre'}
            </p>
            <p className="mt-1 line-clamp-2 text-[12.5px] leading-snug text-white/70">
              {news.body || 'Corps de l’actu…'}
            </p>
            {cta && (
              <p className="mt-2 text-[12px] font-semibold text-[#D4A017]">
                {cta} →
              </p>
            )}
          </div>
        </div>
      </div>

      {news.image_url ? (
        <div className="overflow-hidden rounded-2xl border border-border bg-muted">
          <p className="px-3 pt-2 text-[11px] font-medium text-muted-foreground">
            Aperçu image (page détail — pleine largeur)
          </p>
          <img
            src={news.image_url}
            alt=""
            className="mt-2 aspect-[16/9] w-full object-cover"
          />
        </div>
      ) : null}
    </div>
  )
}
