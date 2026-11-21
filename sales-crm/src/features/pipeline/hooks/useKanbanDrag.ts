import { useCallback, useEffect, useRef, useState } from 'react'

import type { Lead, LeadStage } from '@/features/leads/domain/lead'

export type DropTarget = { stage: LeadStage; index: number }

export type DragState = {
  lead: Lead
  fromStage: LeadStage
  width: number
  height: number
  offsetX: number
  offsetY: number
  pointerX: number
  pointerY: number
  target: DropTarget | null
}

const DRAG_THRESHOLD = 4

type Options = {
  onDrop: (lead: Lead, target: DropTarget) => void
}

/**
 * Pointer-based drag so the gesture works with a trackpad and on touch.
 * The insert index is computed from card midpoints, ignoring the dragged
 * card so the placeholder cannot push the decision back and forth.
 */
export function useKanbanDrag({ onDrop }: Options) {
  const [drag, setDrag] = useState<DragState | null>(null)
  const columns = useRef(new Map<LeadStage, HTMLElement>())
  const pending = useRef<{ lead: Lead; stage: LeadStage; x: number; y: number; el: HTMLElement } | null>(null)
  /** Written synchronously by the pointer handlers so a drop never reads a stale target. */
  const dragRef = useRef<DragState | null>(null)

  /** Set on drop so the click that follows the gesture does not open the card. */
  const justDragged = useRef(false)

  const commit = useCallback((next: DragState | null) => {
    dragRef.current = next
    setDrag(next)
  }, [])

  const registerColumn = useCallback(
    (stage: LeadStage, element: HTMLElement | null) => {
      if (element) columns.current.set(stage, element)
      else columns.current.delete(stage)
    },
    [],
  )

  const resolveTarget = useCallback(
    (x: number, y: number, draggedId: string): DropTarget | null => {
      for (const [stage, element] of columns.current) {
        const rect = element.getBoundingClientRect()
        if (x < rect.left || x > rect.right) continue

        const cards = Array.from(
          element.querySelectorAll<HTMLElement>('[data-lead-id]'),
        ).filter((card) => card.dataset.leadId !== draggedId)

        let index = cards.length
        for (let position = 0; position < cards.length; position += 1) {
          const cardRect = cards[position].getBoundingClientRect()
          if (y < cardRect.top + cardRect.height / 2) {
            index = position
            break
          }
        }
        return { stage, index }
      }
      return null
    },
    [],
  )

  const startDrag = useCallback(
    (event: React.PointerEvent, lead: Lead) => {
      if (event.button !== 0) return
      pending.current = {
        lead,
        stage: lead.stage,
        x: event.clientX,
        y: event.clientY,
        el: event.currentTarget as HTMLElement,
      }
    },
    [],
  )

  useEffect(() => {
    const onMove = (event: PointerEvent) => {
      const start = pending.current

      if (start && !dragRef.current) {
        const moved =
          Math.abs(event.clientX - start.x) + Math.abs(event.clientY - start.y)
        if (moved < DRAG_THRESHOLD) return

        const rect = start.el.getBoundingClientRect()
        commit({
          lead: start.lead,
          fromStage: start.stage,
          width: rect.width,
          height: rect.height,
          offsetX: start.x - rect.left,
          offsetY: start.y - rect.top,
          pointerX: event.clientX,
          pointerY: event.clientY,
          target: { stage: start.stage, index: 0 },
        })
        return
      }

      const current = dragRef.current
      if (!current) return
      event.preventDefault()

      commit({
        ...current,
        pointerX: event.clientX,
        pointerY: event.clientY,
        target:
          resolveTarget(event.clientX, event.clientY, current.lead.id) ??
          current.target,
      })
    }

    const onUp = () => {
      const current = dragRef.current
      pending.current = null
      if (!current) return

      justDragged.current = true
      if (current.target) onDrop(current.lead, current.target)
      commit(null)
    }

    window.addEventListener('pointermove', onMove, { passive: false })
    window.addEventListener('pointerup', onUp)
    window.addEventListener('pointercancel', onUp)
    return () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', onUp)
      window.removeEventListener('pointercancel', onUp)
    }
  }, [commit, onDrop, resolveTarget])

  const wasDragged = useCallback(() => {
    const dragged = justDragged.current
    justDragged.current = false
    return dragged
  }, [])

  return { drag, startDrag, registerColumn, wasDragged }
}
