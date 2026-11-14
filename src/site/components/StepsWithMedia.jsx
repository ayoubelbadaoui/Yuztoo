import SectionHead from './SectionHead.jsx'

/**
 * Photo + numbered steps on a dashed rail. `data`: { index, eyebrow, title,
 * steps[{ id, icon, title, text }], quote?, image, imageCaption }.
 */
export default function StepsWithMedia({ data, icons, id, className = 'yz-light' }) {
  const { image } = data

  return (
    <section id={id} className={`yz-section ${className} yz-setup`} aria-labelledby={`${id}-title`}>
      <div className="yz-container yz-setup__layout">
        <figure className="yz-setup__media yz-frame" data-reveal>
          <img
            src={image.src}
            alt={image.alt}
            width={image.width}
            height={image.height}
            loading="lazy"
            decoding="async"
          />
          <figcaption className="yz-steps__caption yz-mono">{data.imageCaption}</figcaption>
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
                <li key={step.id} className="yz-setup__step" data-reveal style={{ '--d': `${i * 0.1}s` }}>
                  <span className="yz-setup__marker" aria-hidden="true">
                    <Icon size={20} strokeWidth={2} />
                  </span>
                  <div>
                    <span className="yz-setup__num yz-mono" aria-hidden="true">
                      Étape {String(i + 1).padStart(2, '0')}
                    </span>
                    <h3 className="yz-setup__title">{step.title}</h3>
                    <p className="yz-setup__text">{step.text}</p>
                  </div>
                </li>
              )
            })}
          </ol>

          {data.quote ? <p className="yz-strip yz-strip__text yz-setup__quote">{data.quote}</p> : null}
        </div>
      </div>
    </section>
  )
}
