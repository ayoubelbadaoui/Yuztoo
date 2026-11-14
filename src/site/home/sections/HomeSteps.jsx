import { BellRing, Repeat, ScanLine } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { HOME_STEPS } from '../homeContent.js'

const ICONS = { scan: ScanLine, bell: BellRing, repeat: Repeat }

export default function HomeSteps() {
  const { image, steps } = HOME_STEPS

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
          <figure className="yz-steps__media yz-frame" data-reveal>
            <img
              src={image.src}
              alt={image.alt}
              width={image.width}
              height={image.height}
              loading="lazy"
              decoding="async"
            />
            <figcaption className="yz-steps__caption yz-mono">{HOME_STEPS.imageCaption}</figcaption>
          </figure>

          <ol className="yz-grid yz-steps__list">
            {steps.map((step, i) => {
              const Icon = ICONS[step.icon]
              return (
                <li
                  key={step.id}
                  className="yz-cell yz-steps__item"
                  data-reveal
                  style={{ '--d': `${i * 0.08}s` }}
                >
                  <span className="yz-steps__num" aria-hidden="true">
                    {String(i + 1).padStart(2, '0')}
                  </span>
                  <div className="yz-steps__body">
                    <h3 className="yz-steps__title">{step.title}</h3>
                    <p className="yz-steps__text">{step.text}</p>
                    <span className="yz-steps__tag yz-mono">{step.tag}</span>
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
    </section>
  )
}
