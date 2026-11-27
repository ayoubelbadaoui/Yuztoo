import { useEffect, useRef, useState } from 'react'
import AppPhone from '../../components/AppPhone.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { APP_SCREENS } from '../../appScreensContent.js'
import { HOME_SHOWCASE } from '../homeContent.js'
import { bt } from '../../components/Brand.jsx'

/**
 * Desktop: a sticky phone whose screen follows the chapter being read.
 * Mobile: each chapter carries its own phone in a swipeable row.
 */
export default function HomeShowcase() {
  const { chapters } = HOME_SHOWCASE
  const [active, setActive] = useState(0)
  const listRef = useRef(null)

  useEffect(() => {
    const items = listRef.current?.querySelectorAll('[data-chapter]')
    if (!items?.length || !('IntersectionObserver' in window)) return undefined
    // A chapter becomes active when it crosses the middle band of the viewport.
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) setActive(Number(entry.target.dataset.chapter))
        }
      },
      { rootMargin: '-45% 0px -45% 0px' },
    )
    items.forEach((item) => observer.observe(item))
    return () => observer.disconnect()
  }, [])

  return (
    <section className="yz-section yz-dark yz-show" aria-labelledby="yz-show-title">
      <div className="yz-container">
        <SectionHead
          index={HOME_SHOWCASE.index}
          eyebrow={HOME_SHOWCASE.eyebrow}
          title={HOME_SHOWCASE.title}
          lead={HOME_SHOWCASE.lead}
          titleId="yz-show-title"
        />

        <div className="yz-show__layout">
          <div className="yz-show__stage">
            <div className="yz-show__device">
              {chapters.map((chapter, i) => (
                <div
                  key={chapter.id}
                  className={`yz-show__screen${i === active ? ' is-active' : ''}`}
                  aria-hidden={i === active ? undefined : 'true'}
                >
                  <AppPhone screen={APP_SCREENS[chapter.id]} sizes="320px" />
                </div>
              ))}
            </div>
            <div className="yz-show__meta" aria-hidden="true">
              <p className="yz-mono">
                <em>{String(active + 1).padStart(2, '0')}</em> / {String(chapters.length).padStart(2, '0')}
                <span>{chapters[active].kicker}</span>
              </p>
              <ol className="yz-show__rail">
                {chapters.map((chapter, i) => (
                  <li key={chapter.id} className={i <= active ? 'is-on' : ''} />
                ))}
              </ol>
            </div>
          </div>

          <ol className="yz-show__list" ref={listRef}>
            {chapters.map((chapter, i) => (
              <li
                key={chapter.id}
                data-chapter={i}
                className={`yz-show__chapter${i === active ? ' is-active' : ''}`}
              >
                <AppPhone screen={APP_SCREENS[chapter.id]} className="yz-show__mini" sizes="62vw" />
                <p className="yz-show__kicker yz-mono">
                  <em>{String(i + 1).padStart(2, '0')}</em>
                  {bt(chapter.kicker)}
                </p>
                <h3 className="yz-show__title">{bt(chapter.title)}</h3>
                <p className="yz-show__text">{bt(chapter.text)}</p>
              </li>
            ))}
          </ol>
        </div>
      </div>
    </section>
  )
}
