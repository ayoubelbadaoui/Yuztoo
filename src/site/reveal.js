/**
 * Arms the wipe reveal on [data-reveal]. Content is visible without JS; the
 * hidden state only applies once `html.yz-reveal` is set here, and anything
 * already on screen is marked in before the class lands so the fold never
 * blinks.
 */
export function armReveal() {
  if (typeof window === 'undefined' || !('IntersectionObserver' in window)) return
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

  const nodes = Array.from(document.querySelectorAll('[data-reveal]'))
  const fold = window.innerHeight

  nodes.forEach((node) => {
    if (node.getBoundingClientRect().top < fold) node.classList.add('is-in')
  })

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.add('is-in')
        observer.unobserve(entry.target)
      })
    },
    { rootMargin: '0px 0px -8% 0px', threshold: 0.12 },
  )

  nodes.filter((node) => !node.classList.contains('is-in')).forEach((node) => observer.observe(node))
  document.documentElement.classList.add('yz-reveal')
}
