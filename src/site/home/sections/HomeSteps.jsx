import { useState } from 'react'
import { BellRing, Play, Repeat, SmartphoneNfc } from 'lucide-react'
import AppPhone from '../../components/AppPhone.jsx'
import VideoDrawer from '../../components/VideoDrawer.jsx'
import { APP_SCREENS } from '../../appScreensContent.js'
import SectionHead from '../../components/SectionHead.jsx'
import { HOME_STEPS } from '../homeContent.js'
import { bt } from '../../components/Brand.jsx'

const ICONS = { scan: SmartphoneNfc, bell: BellRing, repeat: Repeat }

export default function HomeSteps() {
  const { steps } = HOME_STEPS
  const [playing, setPlaying] = useState(null)
  const [active, setActive] = useState(0)

  return (
    <section
      id="fonctionnement"
      className="yz-section yz-light yz-steps"
      aria-labelledby="yz-steps-title"
    >
      <div className="yz-container">
        <SectionHead
          index={HOME_STEPS.index}
          eyebrow={HOME_STEPS.eyebrow}
          title={HOME_STEPS.title}
          lead={HOME_STEPS.lead}
          titleId="yz-steps-title"
        />

        <div className="yz-steps__layout">
          <figure className="yz-steps__media yz-steps__media--screens yz-frame" data-reveal>
            {steps.map((step, i) => (
              <div key={step.id} className={`yz-setup__slide${i === active ? ' is-active' : ''}`} aria-hidden={i === active ? undefined : 'true'}>
                <div className="yz-setup__stage">
                  <AppPhone screen={APP_SCREENS[step.screen]} sizes="(max-width: 900px) 46vw, 250px" />
                </div>
              </div>
            ))}
            <figcaption className="yz-steps__caption yz-mono">{bt(steps[active].tag)}</figcaption>
          </figure>

          <ol className="yz-grid yz-steps__list">
            {steps.map((step, i) => {
              const Icon = ICONS[step.icon]
              return (
                <li
                  key={step.id}
                  className={`yz-cell yz-steps__item${i === active ? ' is-active' : ''}`}
                  data-reveal
                  style={{ '--d': `${i * 0.08}s` }}
                  onMouseEnter={() => setActive(i)}
                  onFocus={() => setActive(i)}
                >
                  <span className="yz-steps__num" aria-hidden="true">
                    {String(i + 1).padStart(2, '0')}
                  </span>
                  <div className="yz-steps__body">
                    <h3 className="yz-steps__title">{bt(step.title)}</h3>
                    <p className="yz-steps__text">{bt(step.text)}</p>
                    <span className="yz-steps__tag yz-mono">{bt(step.tag)}</span>
                    <button className="yz-steps__play" type="button" onClick={() => {
                        setActive(i)
                        setPlaying(i)
                      }}>
                      <span className="yz-steps__play-icon" aria-hidden="true">
                        <Play size={14} strokeWidth={2.6} />
                      </span>
                      {HOME_STEPS.videoCta}
                      <span className="yz-sr-only"> : {step.title}</span>
                    </button>
                  </div>
                  <span className="yz-tile" aria-hidden="true">
                    <Icon size={21} strokeWidth={2.1} />
                  </span>
                </li>
              )
            })}
          </ol>
        </div>
      </div>

      <VideoDrawer
        items={steps}
        index={playing}
        onChange={setPlaying}
        onClose={() => setPlaying(null)}
        kicker={HOME_STEPS.videoKicker}
      />
    </section>
  )
}
