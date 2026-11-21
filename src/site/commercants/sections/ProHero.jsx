import { ArrowDown, ArrowRight, Check, Store } from 'lucide-react'
import Breadcrumb from '../../components/Breadcrumb.jsx'
import AppPhone from '../../components/AppPhone.jsx'
import NfcIcon from '../../components/NfcIcon.jsx'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import { APP_SCREENS } from '../../appScreensContent.js'
import { PRO_HERO } from '../commercantsContent.js'

export default function ProHero() {
  const { tag } = PRO_HERO

  return (
    <section className="yz-hero yz-prohero" aria-labelledby="yz-prohero-title">
      <SiteAmbient variant="grid" />

      <div className="yz-hero__inner">
        <div className="yz-hero__copy">
          <Breadcrumb current={PRO_HERO.crumb} />

          <p className="yz-badge">
            <Store size={14} strokeWidth={2.4} aria-hidden="true" />
            {PRO_HERO.badge}
          </p>

          <h1 id="yz-prohero-title" className="yz-hero__title">
            {PRO_HERO.titleLead} <span className="yz-accent">{PRO_HERO.titleAccent}</span>{' '}
            <span className="yz-hero__title-end">{PRO_HERO.titleEnd}</span>
          </h1>

          <p className="yz-hero__lead">{PRO_HERO.intro}</p>

          <div className="yz-hero__actions">
            <a className="yz-btn yz-btn--primary" href={PRO_HERO.primaryCta.href}>
              {PRO_HERO.primaryCta.label}
              <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
            </a>
            <a className="yz-link" href={PRO_HERO.secondaryCta.href}>
              <ArrowDown size={14} strokeWidth={2.6} aria-hidden="true" />
              {PRO_HERO.secondaryCta.label}
            </a>
          </div>

          <ul className="yz-prohero__checks">
            {PRO_HERO.checks.map((check) => (
              <li key={check}>
                <Check size={15} strokeWidth={3} aria-hidden="true" />
                {check}
              </li>
            ))}
          </ul>
        </div>

        <div className="yz-prohero__visual">
          <div className="yz-prohero__stage yz-prohero__stage--duo yz-frame">
            <div className="yz-hero__dots" aria-hidden="true" />
            <AppPhone screen={APP_SCREENS.fidelite} className="yz-device--back" sizes="(max-width: 640px) 46vw, 230px" />
            <AppPhone screen={APP_SCREENS.notification} className="yz-device--front" priority sizes="(max-width: 640px) 50vw, 250px" />
            <span className="yz-prohero__plaque" aria-hidden="true">
              <NfcIcon size={30} strokeWidth={1.7} />
            </span>
          </div>
          <div className="yz-hero__plate yz-prohero__tag">
            <strong>{tag.value}</strong>
            <span className="yz-mono">{tag.label}</span>
          </div>
        </div>
      </div>
    </section>
  )
}
