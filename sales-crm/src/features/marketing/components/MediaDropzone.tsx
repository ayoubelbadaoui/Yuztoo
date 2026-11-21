import { AlertCircle, ImageIcon, Upload, X } from 'lucide-react'
import { useRef, useState } from 'react'

type Props = {
  mediaUrl: string | null
  mediaLabel: string | null
  isUploading: boolean
  onFile: (file: File) => void
  onClear: () => void
}

/** Inspired by 21st.dev File Dropzone — adapted to CRM tokens. */
export function MediaDropzone({
  mediaUrl,
  mediaLabel,
  isUploading,
  onFile,
  onClear,
}: Props) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragging, setDragging] = useState(false)
  const [localError, setLocalError] = useState<string | null>(null)

  const pick = (file: File | undefined) => {
    if (!file) return
    if (file.size > 50 * 1024 * 1024) {
      setLocalError('Max 50 Mo')
      return
    }
    setLocalError(null)
    onFile(file)
  }

  return (
    <div className="flex flex-col gap-2">
      <div
        data-dragging={dragging || undefined}
        onDragEnter={(event) => {
          event.preventDefault()
          setDragging(true)
        }}
        onDragLeave={(event) => {
          event.preventDefault()
          setDragging(false)
        }}
        onDragOver={(event) => event.preventDefault()}
        onDrop={(event) => {
          event.preventDefault()
          setDragging(false)
          pick(event.dataTransfer.files?.[0])
        }}
        className="relative flex min-h-40 flex-col items-center justify-center overflow-hidden rounded-xl border border-dashed border-border p-4 transition-colors data-[dragging=true]:bg-accent/50"
      >
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp,video/mp4,video/quicktime"
          className="sr-only"
          onChange={(event) => pick(event.target.files?.[0])}
        />

        {mediaUrl ? (
          <div className="absolute inset-0 flex items-center justify-center p-4">
            {mediaUrl.match(/\.(mp4|mov)(\?|$)/i) ? (
              <video
                src={mediaUrl}
                className="mx-auto max-h-full rounded object-contain"
                controls
              />
            ) : (
              <img
                src={mediaUrl}
                alt={mediaLabel ?? 'Média'}
                className="mx-auto max-h-full rounded object-contain"
              />
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center px-4 py-3 text-center">
            <div className="mb-2 flex size-11 items-center justify-center rounded-full border border-border bg-background">
              <ImageIcon className="size-4 opacity-60" />
            </div>
            <p className="mb-1 text-[13px] font-medium text-foreground">
              {isUploading ? 'Upload…' : 'Déposez un visuel ici'}
            </p>
            <p className="text-[12px] text-muted-foreground">
              JPEG, PNG, WebP ou MP4 · max 50 Mo
            </p>
            <button
              type="button"
              disabled={isUploading}
              onClick={() => inputRef.current?.click()}
              className="mt-3 flex h-8 items-center gap-1.5 rounded-lg border border-border px-3 text-[12px] text-foreground transition-colors hover:bg-muted disabled:opacity-40"
            >
              <Upload className="size-3.5 opacity-60" />
              Choisir un fichier
            </button>
          </div>
        )}
      </div>

      {mediaUrl && (
        <div className="flex items-center justify-between gap-2 rounded-lg border border-border bg-muted/40 px-3 py-2">
          <p className="truncate text-[12px] text-foreground">{mediaLabel}</p>
          <button
            type="button"
            aria-label="Retirer le média"
            onClick={onClear}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
          >
            <X className="size-3.5" />
          </button>
        </div>
      )}

      {localError && (
        <p className="flex items-center gap-1 text-[12px] text-destructive" role="alert">
          <AlertCircle className="size-3 shrink-0" />
          {localError}
        </p>
      )}
    </div>
  )
}
