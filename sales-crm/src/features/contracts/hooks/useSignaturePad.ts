import { useCallback, useEffect, useRef, useState } from 'react'

/** Encre fixe : l'affichage inverse l'image en thème sombre. */
const INK = '#0b162c'

/**
 * Tracé manuscrit au pointeur, donc valable à la souris, au trackpad et au
 * doigt. Le canvas est dimensionné en pixels physiques pour rester net sur
 * un écran à forte densité.
 */
export function useSignaturePad() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const isDrawing = useRef(false)
  const [isEmpty, setIsEmpty] = useState(true)

  const context = useCallback(() => {
    const canvas = canvasRef.current
    return canvas ? canvas.getContext('2d') : null
  }, [])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ratio = window.devicePixelRatio || 1
    const rect = canvas.getBoundingClientRect()
    canvas.width = rect.width * ratio
    canvas.height = rect.height * ratio

    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.scale(ratio, ratio)
    ctx.lineWidth = 2.2
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.strokeStyle = INK
  }, [])

  const pointOf = (event: React.PointerEvent<HTMLCanvasElement>) => {
    const rect = event.currentTarget.getBoundingClientRect()
    return { x: event.clientX - rect.left, y: event.clientY - rect.top }
  }

  const onPointerDown = (event: React.PointerEvent<HTMLCanvasElement>) => {
    const ctx = context()
    if (!ctx) return
    event.currentTarget.setPointerCapture(event.pointerId)
    isDrawing.current = true

    const { x, y } = pointOf(event)
    ctx.beginPath()
    ctx.moveTo(x, y)
  }

  const onPointerMove = (event: React.PointerEvent<HTMLCanvasElement>) => {
    if (!isDrawing.current) return
    const ctx = context()
    if (!ctx) return

    const { x, y } = pointOf(event)
    ctx.lineTo(x, y)
    ctx.stroke()
    if (isEmpty) setIsEmpty(false)
  }

  const onPointerUp = () => {
    isDrawing.current = false
  }

  const clear = useCallback(() => {
    const canvas = canvasRef.current
    const ctx = context()
    if (!canvas || !ctx) return
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    setIsEmpty(true)
  }, [context])

  const toDataUrl = useCallback(() => {
    const canvas = canvasRef.current
    return canvas && !isEmpty ? canvas.toDataURL('image/png') : ''
  }, [isEmpty])

  return {
    canvasRef,
    isEmpty,
    clear,
    toDataUrl,
    handlers: { onPointerDown, onPointerMove, onPointerUp, onPointerLeave: onPointerUp },
  }
}
