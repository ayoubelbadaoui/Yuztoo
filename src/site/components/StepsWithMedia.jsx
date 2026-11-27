import { useState } from 'react'
import AppPhone from './AppPhone.jsx'
import SectionHead from './SectionHead.jsx'
import { bt } from './Brand.jsx'
import { APP_SCREENS } from '../appScreensContent.js'

/** One step's visual: a photo, or a real app screen on a stage. */
function StepMedia({ media, active }) {
  return (
    <div className={`yz-setup__slide${active ? ' is-active' : ''}`} aria-hidden={active ? undefined : 'true'}>
      {media.type === 'screen' ? (
        <div className="yz-setup__stage">
          <AppPhone screen={APP_SCREENS[media.screen]} sizes="(max-width: 900px) 52vw, 240px" />
        </div>
      ) : (
        <img src={media.src} alt={media.alt} width={media.width} height={media.height} loading="lazy" decoding="async" />
      )}
    </div>
  )
}

/**
 * Photo + numbered steps on a dashed rail. `data`: { index, eyebrow, title,
 * steps[{ id, icon, title, text, media? }], quote?, image, imageCaption }.
 * When every step has `media`, the visual follows the step being hovered,
 * focused or tapped.
 */
export default function StepsWithMedia({ data, icons, id, className = 'yz-light' }) {
  const { image } = data
  const interactive = data.steps.every((step) => step.media)
  const [active, setActive] = useState(0)

  return (
    <section id={id} className={`yz-section ${className} yz-setup`} aria-labelledby={`${id}-title`}>
      <div className="yz-container yz-setup__layout">
        <figure className={`yz-setup__media yz-frame${interactive ? ' yz-setup__media--slides' : ''}`} data-reveal>
          {interactive ? (
            data.steps.map((step, i) => <StepMedia key={step.id} media={step.media} active={i === active} />)
          ) : (
            <img
              src={image.src}
              alt={image.alt}
              width={image.width}
              height={image.height}
              loading="lazy"
              decoding="async"
            />
          )}
          <figcaption className="yz-steps__caption yz-mono">
            {interactive ? bt(data.steps[active].title) : bt(data.imageCaption)}
          </figcaption>
        </figure>

        <div className="yz-setup__copy">
          <SectionHead
            index={data.index}
            eyebrow={data.eyebrow}
            title={data.title}
            titleId={`${id}-title`}
          />

          <ol className="yz-setup__steps">
            {data.steps.map((step, i) => {
              const Icon = icons[step.icon]
              return (
                <li
                  key={step.id}
                  className={`yz-setup__step${interactive ? ' is-pickable' : ''}${interactive && i === active ? ' is-active' : ''}`}
                  data-reveal
                  style={{ '--d': `${i * 0.1}s` }}
                  onMouseEnter={interactive ? () => setActive(i) : undefined}
                  onClick={interactive ? () => setActive(i) : undefined}
                  onFocus={interactive ? () => setActive(i) : undefined}
                  tabIndex={interactive ? 0 : undefined}
                >
                  <span className="yz-setup__marker" aria-hidden="true">
                    <Icon size={20} strokeWidth={2} />
                  </span>
                  <div>
                    <span className="yz-setup__num yz-mono" aria-hidden="true">
                      Étape {String(i + 1).padStart(2, '0')}
                    </span>
                    <h3 className="yz-setup__title">{bt(step.title)}</h3>
                    <p className="yz-setup__text">{bt(step.text)}</p>
                  </div>
                </li>
              )
            })}
          </ol>

          {data.quote ? <p className="yz-strip yz-strip__text yz-setup__quote">{bt(data.quote)}</p> : null}
        </div>
      </div>
    </section>
  )
}
