import { MapPin } from 'lucide-react'
import { HOME_COVERAGE } from '../homeContent.js'

function NetworkMeter({ meter }) {
  const lit = Math.max(1, Math.round((meter.current / meter.target) * meter.segments))

  return (
    <div className="yz-meter" data-reveal>
      <div className="yz-meter__head">
        <span className="yz-mono">{meter.kicker}</span>
        <span className="yz-meter__live yz-mono">
          <span aria-hidden="true" />
          En cours
        </span>
      </div>

      <p className="yz-meter__figure">
        <strong>{meter.current}</strong>
        <span className="yz-meter__of">/ {meter.target}</span>
      </p>

      <div
        className="yz-meter__bar"
        role="img"
        aria-label={`${meter.current} commerces partenaires sur un objectif de ${meter.target}`}
      >
        {Array.from({ length: meter.segments }, (_, i) => (
          <span key={i} className={i < lit ? 'is-lit' : undefined} />
        ))}
      </div>

      <dl className="yz-meter__legend">
        <div>
          <dt className="yz-mono">Aujourd’hui</dt>
          <dd>
            {meter.current} {meter.currentLabel}
          </dd>
        </div>
        <div>
          <dt className="yz-mono">Objectif</dt>
          <dd>
            {meter.target} {meter.targetLabel}
          </dd>
        </div>
      </dl>
    </div>
  )
}

export default function HomeCoverage() {
  const { image, imageBadge, meter, points } = HOME_COVERAGE

  return (
    <section id="belfort" className="yz-section yz-dark yz-coverage" aria-labelledby="yz-coverage-title">
      <div className="yz-container">
        <div className="yz-coverage__top">
          <div>
            <p className="yz-eyebrow">
              <em className="yz-eyebrow__idx">{HOME_COVERAGE.index}</em>
              {HOME_COVERAGE.eyebrow}
            </p>
            <h2 className="yz-coverage__title" id="yz-coverage-title">
              {HOME_COVERAGE.title}
            </h2>
          </div>
          <p className="yz-coverage__lead">{HOME_COVERAGE.lead}</p>
        </div>

        <div className="yz-coverage__body">
          <figure className="yz-coverage__visual yz-frame" data-reveal>
            <img
              src={image.src}
              alt={image.alt}
              width={image.width}
              height={image.height}
              loading="lazy"
              decoding="async"
            />
            <figcaption className="yz-coverage__badge">
              <MapPin size={16} strokeWidth={2.4} aria-hidden="true" />
              <span>
                <strong>{imageBadge.value}</strong>
                <span className="yz-mono">{imageBadge.label}</span>
              </span>
            </figcaption>
          </figure>

          <div className="yz-coverage__panel">
            <NetworkMeter meter={meter} />
            <dl className="yz-grid yz-coverage__points">
              {points.map((point, i) => (
                <div
                  key={point.id}
                  className="yz-cell yz-coverage__point"
                  data-reveal
                  style={{ '--d': `${0.08 + i * 0.06}s` }}
                >
                  <dt>{point.label}</dt>
                  <dd>{point.value}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </div>
    </section>
  )
}
