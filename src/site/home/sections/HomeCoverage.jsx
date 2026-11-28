import { ArrowRight, MapPin } from 'lucide-react'
import { HOME_COVERAGE } from '../homeContent.js'
import { useNetworkCount } from '../../useNetworkCount.js'
import LiveBadge from '../../components/LiveBadge.jsx'
import { bt } from '../../components/Brand.jsx'
import DevNote from '../../components/DevNote.jsx'

function NetworkMeter({ meter }) {
  const lit = Math.max(1, Math.round((meter.current / meter.target) * meter.segments))

  return (
    <div className="yz-meter" data-reveal>
      <div className="yz-meter__head">
        <span className="yz-mono">{bt(meter.kicker)}</span>
        {meter.live ? (
          <LiveBadge label="En direct de l’app" className="yz-live--meter" />
        ) : (
          <span className="yz-meter__live yz-mono">
            <span aria-hidden="true" />
            En cours
          </span>
        )}
      </div>

      <p className="yz-meter__figure">
        <strong>{meter.current}</strong>
        <span className="yz-meter__of">/ {meter.target}</span>
      </p>

      <div
        className="yz-meter__bar"
        style={{ '--segments': meter.segments }}
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
  const { image, imageBadge, points, elsewhere } = HOME_COVERAGE
  const network = useNetworkCount()
  const meter = { ...HOME_COVERAGE.meter, current: network.count, live: network.live }

  return (
    <section id="belfort" className="yz-section yz-dark yz-coverage" aria-labelledby="yz-coverage-title">
      <div className="yz-container">
        <div className="yz-coverage__top">
          <div>
            <p className="yz-eyebrow">
              <em className="yz-eyebrow__idx">{HOME_COVERAGE.index}</em>
              {bt(HOME_COVERAGE.eyebrow)}
            </p>
            <h2 className="yz-coverage__title" id="yz-coverage-title">
              {bt(HOME_COVERAGE.title)}
            </h2>
          </div>
          <p className="yz-coverage__lead">{bt(HOME_COVERAGE.lead)}</p>
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
                <strong>{bt(imageBadge.value)}</strong>
                <span className="yz-mono">{bt(imageBadge.label)}</span>
              </span>
            </figcaption>
          </figure>

          <div className="yz-coverage__panel">
            <DevNote id="counter" place="inline" />
            <NetworkMeter meter={meter} />
            <dl className="yz-grid yz-coverage__points">
              {points.map((point, i) => (
                <div
                  key={point.id}
                  className="yz-cell yz-coverage__point"
                  data-reveal
                  style={{ '--d': `${0.08 + i * 0.06}s` }}
                >
                  <dt>{bt(point.label)}</dt>
                  <dd>{bt(point.value)}</dd>
                </div>
              ))}
            </dl>
            <p className="yz-coverage__elsewhere" data-reveal>
              <span>{bt(elsewhere.text)}</span>
              <a className="yz-btn yz-btn--ghost" href={elsewhere.cta.href}>
                {elsewhere.cta.label}
                <ArrowRight size={16} strokeWidth={2.4} aria-hidden="true" />
              </a>
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
