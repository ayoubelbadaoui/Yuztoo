import { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { ArrowLeft, ArrowRight, X } from 'lucide-react'
import { bt } from './Brand.jsx'

/**
 * Side drawer that plays a short vertical video without leaving the page.
 * `items`: [{ id, title, video: { src, poster, label } }]; `index` null = closed.
 * Esc and the backdrop close it; arrows switch video; body scroll is locked
 * while open; focus moves to the close button and comes back on close.
 */
export default function VideoDrawer({ items, index, onChange, onClose, kicker }) {
  const open = index !== null && index !== undefined
  const closeRef = useRef(null)
  const lastFocus = useRef(null)
  const item = open ? items[index] : null
  // Portal into <body> so no section's stacking context traps the drawer
  // under the sticky header; mounted-only, so prerendered HTML is unchanged.
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])

  useEffect(() => {
    if (!open) return undefined
    lastFocus.current = document.activeElement
    closeRef.current?.focus()
    const root = document.documentElement
    const prevOverflow = root.style.overflow
    root.style.overflow = 'hidden'
    const onKey = (e) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowRight') onChange((index + 1) % items.length)
      if (e.key === 'ArrowLeft') onChange((index - 1 + items.length) % items.length)
    }
    window.addEventListener('keydown', onKey)
    return () => {
      root.style.overflow = prevOverflow
      window.removeEventListener('keydown', onKey)
    }
  }, [open, index, items.length, onChange, onClose])

  useEffect(() => {
    if (!open && lastFocus.current) {
      lastFocus.current.focus?.()
      lastFocus.current = null
    }
  }, [open])

  if (!mounted) return null

  return createPortal(
    <div className={`yz-vdrawer${open ? ' is-open' : ''}`} aria-hidden={open ? undefined : 'true'}>
      <button className="yz-vdrawer__backdrop" type="button" tabIndex={-1} aria-label="Fermer la vidéo" onClick={onClose} />
      <aside
        className="yz-vdrawer__panel"
        role="dialog"
        aria-modal="true"
        aria-label={item ? item.title : undefined}
      >
        {item ? (
          <>
            <header className="yz-vdrawer__head">
              <p className="yz-mono">
                {kicker} {String(index + 1).padStart(2, '0')} / {String(items.length).padStart(2, '0')}
              </p>
              <button ref={closeRef} className="yz-vdrawer__close" type="button" onClick={onClose} aria-label="Fermer la vidéo">
                <X size={20} strokeWidth={2.4} />
              </button>
            </header>

            <h3 className="yz-vdrawer__title">{bt(item.title)}</h3>

            <div className="yz-vdrawer__frame">
              <video
                key={item.id}
                src={item.video.src}
                poster={item.video.poster}
                controls
                autoPlay
                playsInline
                preload="metadata"
              />
            </div>

            <p className="yz-vdrawer__label">{bt(item.video.label)}</p>

            {items.length > 1 ? (
              <nav className="yz-vdrawer__nav" aria-label="Autres vidéos">
                <button type="button" onClick={() => onChange((index - 1 + items.length) % items.length)}>
                  <ArrowLeft size={16} strokeWidth={2.4} aria-hidden="true" />
                  Précédente
                </button>
                <button type="button" onClick={() => onChange((index + 1) % items.length)}>
                  Suivante
                  <ArrowRight size={16} strokeWidth={2.4} aria-hidden="true" />
                </button>
              </nav>
            ) : null}
          </>
        ) : null}
      </aside>
    </div>,
    document.body,
  )
}
