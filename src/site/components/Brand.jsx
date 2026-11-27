/**
 * Brand rendering: in titles and copy, the T of « YuzToo » is set in the brand
 * orange (owner request, Nov 2026). `bt(text)` returns the string untouched
 * when it has no « YuzToo », so it is safe on any text child — never use it on
 * attributes (alt, aria-label, title), which need plain strings.
 */
export function bt(text) {
  if (typeof text !== 'string' || !text.includes('YuzToo')) return text
  const parts = text.split('YuzToo')
  return parts.flatMap((part, i) =>
    i === 0
      ? [part]
      : [
          <span key={i} className="yz-brand">
            Yuz<span className="yz-brand__t">T</span>oo
          </span>,
          part,
        ],
  )
}
