import { bt } from '../../components/Brand.jsx'

/** Renders « *word* » as the gold-underlined accent used in the videos. */
export function em(text) {
  return text.split(/(\*[^*]+\*)/).map((part, i) =>
    part.startsWith('*') && part.endsWith('*') ? (
      <em key={i} className="yz-tuto-em">
        {bt(part.slice(1, -1))}
      </em>
    ) : (
      <span key={i}>{bt(part)}</span>
    ),
  )
}

export const plain = (text) => text.replaceAll('*', '')

export const clock = (sec) => {
  const s = Math.round(sec)
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`
}
