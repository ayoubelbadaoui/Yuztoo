/**
 * Arms the wipe reveal on [data-reveal]. Content is visible without JS; the
 * hidden state only applies once `html.yz-reveal` is set here, and anything
 * already on screen is marked in before the class lands so the fold never
 * blinks.
 *
 * Every check queries the live DOM instead of a list captured at arm time:
 * React can render or replace nodes after arming (dev client render, hydration
 * recovery), and a stale list left those sections hidden until reload.
 * Anything at or above the reveal line is shown, so content you scrolled past
 * can never stay hidden.
 */
export function armReveal() {
  if (typeof window === 'undefined') return
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

  let frame = 0
  let timer = 0

  const check = () => {
    cancelAnimationFrame(frame)
    clearTimeout(timer)
    frame = 0
    timer = 0
    const line = window.innerHeight * 0.92
    for (const node of document.querySelectorAll('[data-reveal]:not(.is-in)')) {
      if (node.getBoundingClientRect().top < line) node.classList.add('is-in')
    }
  }

  // The timer covers webviews and throttled tabs where rAF stalls while the
  // page is still scrolled and visible.
  const schedule = () => {
    if (frame || timer) return
    frame = requestAnimationFrame(check)
    timer = setTimeout(check, 120)
  }

  check()
  window.addEventListener('scroll', schedule, { passive: true })
  window.addEventListener('resize', schedule, { passive: true })
  window.addEventListener('load', schedule)
  document.documentElement.classList.add('yz-reveal')
}
