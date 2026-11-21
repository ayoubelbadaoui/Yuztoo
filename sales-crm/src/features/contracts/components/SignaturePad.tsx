import { Eraser } from 'lucide-react'
import type { RefObject } from 'react'
import type { PointerEventHandler } from 'react'

type Props = {
  canvasRef: RefObject<HTMLCanvasElement | null>
  isEmpty: boolean
  onClear: () => void
  handlers: {
    onPointerDown: PointerEventHandler<HTMLCanvasElement>
    onPointerMove: PointerEventHandler<HTMLCanvasElement>
    onPointerUp: PointerEventHandler<HTMLCanvasElement>
    onPointerLeave: PointerEventHandler<HTMLCanvasElement>
  }
}

export function SignaturePad({
  canvasRef,
  isEmpty,
  onClear,
  handlers,
}: Props) {
  return (
    <div className="flex flex-col gap-2">
      <div className="relative overflow-hidden rounded-xl border border-dashed border-input bg-card">
        <canvas
          ref={canvasRef}
          {...handlers}
          aria-label="Zone de signature"
          className="h-36 w-full touch-none dark:invert"
        />

        {isEmpty && (
          <p className="pointer-events-none absolute inset-0 flex items-center justify-center text-[13px] text-muted-foreground">
            Signez ici avec le doigt ou la souris
          </p>
        )}

        <span className="pointer-events-none absolute inset-x-6 bottom-6 border-b border-border" />
      </div>

      <button
        type="button"
        onClick={onClear}
        disabled={isEmpty}
        className="flex h-8 w-fit items-center gap-1.5 rounded-lg border border-border px-2.5 text-[12px] text-muted-foreground transition-colors hover:bg-muted disabled:opacity-40"
      >
        <Eraser className="size-3.5" />
        Effacer
      </button>
    </div>
  )
}
