import { useEffect, useState } from 'react'
import { DEV_NOTES, DEV_NOTES_LABEL } from '../devNotesContent.js'

const KEY = 'yz-dev-notes'

/** Whether dev notes are on: dev server, or ?notes on any build (remembered). */
function notesEnabled() {
  try {
    const param = new URLSearchParams(window.location.search).get('notes')
    if (param === 'off') window.localStorage.removeItem(KEY)
    else if (param !== null) window.localStorage.setItem(KEY, '1')
    if (param === 'off') return false
    return import.meta.env.DEV || param !== null || window.localStorage.getItem(KEY) === '1'
  } catch {
    return import.meta.env.DEV
  }
}

/**
 * Orange « note dev » label on a placeholder. Renders nothing during
 * prerender and for visitors; client-only after mount so hydration matches.
 * `id` is a key of DEV_NOTES; `place` = 'corner' (absolute, top-left of the
 * nearest positioned parent) or 'inline'.
 */
export default function DevNote({ id, place = 'corner' }) {
  const [on, setOn] = useState(false)
  useEffect(() => setOn(notesEnabled()), [])
  const note = DEV_NOTES[id]
  if (!on || !note) return null
  return (
    <aside className={`yz-devnote yz-devnote--${note.kind} yz-devnote--${place}`} role="note">
      <strong>Note dev · {DEV_NOTES_LABEL[note.kind]}</strong>
      <span>{note.text}</span>
    </aside>
  )
}
