import {
  BadgeCheck,
  Briefcase,
  Building2,
  FerrisWheel,
  Gift,
  HardHat,
  HeartPulse,
  Landmark,
  LayoutGrid,
  Sparkles,
  Store,
  Tag,
  Truck,
  User,
  Users,
  UsersRound,
  UtensilsCrossed,
  Warehouse,
  Wrench,
  type LucideIcon,
} from 'lucide-react'

import type {
  MediaDefaultIconKey,
  MediaDefaultPreview,
  MediaObjectFit,
  MediaPreviewShape,
} from '@/features/cms-app/domain/mediaSlot'

type Props = {
  imageUrl: string | null
  previewShape: MediaPreviewShape
  objectFit: MediaObjectFit
  defaultPreview: MediaDefaultPreview
  /** When true, frame shows the in-app default (Défaut) */
  isDefault: boolean
  label?: string
}

const ICON_MAP: Record<MediaDefaultIconKey, LucideIcon> = {
  user: User,
  store: Store,
  users: Users,
  building: Building2,
  gift: Gift,
  tag: Tag,
  usersRound: UsersRound,
  utensils: UtensilsCrossed,
  sparkles: Sparkles,
  heartPulse: HeartPulse,
  wrench: Wrench,
  ferrisWheel: FerrisWheel,
  layoutGrid: LayoutGrid,
  hardHat: HardHat,
  briefcase: Briefcase,
  warehouse: Warehouse,
  landmark: Landmark,
  truck: Truck,
  badgeCheck: BadgeCheck,
}

export function MediaCropPreview({
  imageUrl,
  previewShape,
  objectFit,
  defaultPreview,
  isDefault,
  label = 'Aperçu',
}: Props) {
  const frameClass =
    previewShape === 'circle'
      ? 'size-20 rounded-full'
      : previewShape === 'card43'
        ? 'aspect-[4/3] w-48 rounded-xl'
        : 'size-24 rounded-xl'

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center gap-2">
        <p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
          {label}
        </p>
        {isDefault && (
          <span className="rounded bg-muted px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-muted-foreground">
            Actuel app
          </span>
        )}
      </div>
      <div
        className={`relative overflow-hidden border border-border ${frameClass} ${
          imageUrl ? 'bg-muted' : ''
        }`}
      >
        {imageUrl ? (
          <img
            src={imageUrl}
            alt=""
            className={`size-full ${objectFit === 'contain' ? 'object-contain' : 'object-cover'}`}
          />
        ) : (
          <DefaultSlotVisual preview={defaultPreview} shape={previewShape} />
        )}
      </div>
    </div>
  )
}

function DefaultSlotVisual({
  preview,
  shape,
}: {
  preview: MediaDefaultPreview
  shape: MediaPreviewShape
}) {
  if (preview.kind === 'image') {
    return (
      <img
        src={preview.src}
        alt={preview.alt}
        className="size-full object-contain bg-[#0E2A44] p-2"
      />
    )
  }

  const Icon = ICON_MAP[preview.icon]
  const navy = preview.tone === 'goldOnNavy'
  return (
    <div
      className={`flex size-full flex-col items-center justify-center gap-1 ${
        navy ? 'bg-[#0E2A44]' : 'bg-[#152A40]'
      }`}
    >
      <div
        className={`flex items-center justify-center border border-[#D4A017]/70 ${
          shape === 'circle'
            ? 'size-[72%] rounded-full bg-[#D4A017]/15'
            : 'rounded-lg bg-[#D4A017]/10 p-3'
        }`}
      >
        <Icon
          className={shape === 'circle' ? 'size-7' : 'size-8'}
          strokeWidth={1.75}
          color="#D4A017"
        />
      </div>
    </div>
  )
}
