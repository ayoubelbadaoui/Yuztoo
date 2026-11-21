import type { CSSProperties } from 'react'

export type NaturalSize = { w: number; h: number }

export type CropWindow = { sx: number; sy: number; sw: number; sh: number }

export function computeCropWindow(
  natural: NaturalSize,
  aspectRatio: number,
  zoom: number,
  offsetX: number,
  offsetY: number,
): CropWindow {
  const { w, h } = natural
  let cropW: number
  let cropH: number
  if (w / h > aspectRatio) {
    cropH = h / zoom
    cropW = cropH * aspectRatio
  } else {
    cropW = w / zoom
    cropH = cropW / aspectRatio
  }
  cropW = Math.min(cropW, w)
  cropH = Math.min(cropH, h)
  const maxX = w - cropW
  const maxY = h - cropH
  const sx = Math.max(0, Math.min(maxX, offsetX * maxX))
  const sy = Math.max(0, Math.min(maxY, offsetY * maxY))
  return { sx, sy, sw: cropW, sh: cropH }
}

export function coverPreviewStyle(
  natural: NaturalSize,
  aspect: number,
  zoom: number,
  offsetX: number,
  offsetY: number,
): CSSProperties {
  const { sx, sy, sw } = computeCropWindow(
    natural,
    aspect,
    zoom,
    offsetX,
    offsetY,
  )
  const scale = 100 / (sw / natural.w)
  return {
    width: `${scale}%`,
    height: 'auto',
    left: `${(-sx / sw) * 100}%`,
    top: `${(-sy / (sw / aspect)) * 100}%`,
  }
}
