import { ArrowDown, ArrowRight, Megaphone, Percent, Store } from 'lucide-react'
import NfcIcon from '../../components/NfcIcon.jsx'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import { HOME_HERO } from '../homeContent.js'

const PROOF_ICONS = { percent: Percent, megaphone: Megaphone, store: Store }

export default function HomeHero() {
  const { image, plate, commission } = HOME_HERO

  return (
    <section className="yz-hero" aria-labelledby="yz-hero-title">
      <SiteAmbient variant="grid" />

      <div className="yz-hero__inner">
        <div className="yz-hero__copy">
          <p className="yz-badge">
            <Store size={14} strokeWidth={2.4} aria-hidden="true" />
            {HOME_HERO.badge}
          </p>

          <h1 id="yz-hero-title" className="yz-hero__title">
            {HOME_HERO.titleLead} <span className="yz-accent">{HOME_HERO.titleAccent}</span>{' '}
            <span className="yz-hero__title-end">{HOME_HERO.titleEnd}</span>
          </h1>

          <p className="yz-hero__lead">{HOME_HERO.intro}</p>

          <div className="yz-hero__actions">
            <a className="yz-btn yz-btn--primary" href={HOME_HERO.primaryCta.href}>
              {HOME_HERO.primaryCta.label}
              <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
            </a>
            <a className="yz-link" href={HOME_HERO.secondaryCta.href}>
              <ArrowDown size={14} strokeWidth={2.6} aria-hidden="true" />
              {HOME_HERO.secondaryCta.label}
            </a>
          </div>

          <dl className="yz-hero__proof">
            {HOME_HERO.proof.map((item) => {
              const Icon = PROOF_ICONS[item.icon]
              return (
                <div key={item.id} className="yz-hero__stat">
                  <dt className="yz-hero__stat-label">
                    <Icon size={13} strokeWidth={2.2} aria-hidden="true" />
                    {item.label}
                  </dt>
                  <dd className="yz-hero__stat-val">{item.value}</dd>
                </div>
              )
            })}
          </dl>
        </div>

        <div className="yz-hero__visual">
          <div className="yz-hero__frame yz-frame">
            <div className="yz-hero__dots" aria-hidden="true" />
            <img
              className="yz-hero__mascot"
              src={image.src}
              alt={image.alt}
              width={image.width}
              height={image.height}
              fetchpriority="high"
              decoding="async"
            />
            <span className="yz-hero__beam" aria-hidden="true" />
            <span className="yz-hero__scan yz-mono" aria-hidden="true">
              <span className="yz-hero__scan-dot" />
              {HOME_HERO.scanLabel}
            </span>
          </div>

          <div className="yz-hero__plate yz-hero__plate--commission">
            <strong>{commission.value}</strong>
            <span className="yz-mono">{commission.label}</span>
          </div>

          <div className="yz-hero__plate yz-hero__plate--nfc">
            <span className="yz-hero__nfc" aria-hidden="true">
              <NfcIcon size={24} strokeWidth={1.9} />
            </span>
            <span className="yz-hero__plate-text">
              <span className="yz-mono">{plate.kicker}</span>
              <strong>{plate.name}</strong>
              <span>{plate.hint}</span>
            </span>
          </div>
        </div>
      </div>
    </section>
  )
}
