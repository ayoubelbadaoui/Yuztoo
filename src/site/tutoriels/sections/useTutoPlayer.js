import { useCallback, useEffect, useRef, useState } from 'react'

/**
 * Shared state between the video and the step list: which chapter is playing,
 * and `seek(i)` to jump to a step (scrolls the player into view when needed).
 */
export function useTutoPlayer(steps) {
  const videoRef = useRef(null)
  const [active, setActive] = useState(0)
  const [started, setStarted] = useState(false)

  useEffect(() => {
    const v = videoRef.current
    if (!v) return undefined
    const onTime = () => {
      let i = 0
      for (let k = 0; k < steps.length; k++) if (v.currentTime + 0.05 >= steps[k].at) i = k
      setActive(i)
    }
    const onPlay = () => setStarted(true)
    v.addEventListener('timeupdate', onTime)
    v.addEventListener('play', onPlay)
    return () => {
      v.removeEventListener('timeupdate', onTime)
      v.removeEventListener('play', onPlay)
    }
  }, [steps])

  const seek = useCallback(
    (i) => {
      const v = videoRef.current
      if (!v) return
      setActive(i)
      setStarted(true)
      const go = () => {
        v.currentTime = steps[i].at
        v.play().catch(() => {})
      }
      if (v.readyState >= 1) go()
      else {
        v.preload = 'auto'
        v.addEventListener('loadedmetadata', go, { once: true })
        v.load()
      }
      const box = v.getBoundingClientRect()
      if (box.top < 0 || box.bottom > window.innerHeight) {
        v.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
    },
    [steps],
  )

  return { videoRef, active, started, seek }
}
