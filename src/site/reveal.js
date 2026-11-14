/**
 * Arms the wipe reveal on [data-reveal]. Content is visible without JS; the
 * hidden state only applies once `html.yz-reveal` is set here, and anything
 * already on screen is marked in before the class lands so the fold never
 * blinks.
 *
 * A rAF-throttled scroll check, not an IntersectionObserver: an observer held
 * only by a closure can be collected mid-page, and anchor jumps skip targets,
 * which left sections hidden until reload. Anything at or above the reveal
 * line is shown, so content you scrolled past can never stay hidden.
 */
export function armReveal() {
  if (typeof window === 'undefined') return
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

  let pending = Array.from(document.querySelectorAll('[data-reveal]'))
  let frame = 0

  const check = () => {
    frame = 0
    const line = window.innerHeight * 0.92
    pending = pending.filter((node) => {
      if (node.getBoundingClientRect().top < line) {
        node.classList.add('is-in')
        return false
      }
      return true
    })
    if (!pending.length) {
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }

  const onScroll = () => {
    if (!frame) frame = requestAnimationFrame(check)
  }

  check()
  if (!pending.length) return
  window.addEventListener('scroll', onScroll, { passive: true })
  window.addEventListener('resize', onScroll, { passive: true })
  document.documentElement.classList.add('yz-reveal')
}
