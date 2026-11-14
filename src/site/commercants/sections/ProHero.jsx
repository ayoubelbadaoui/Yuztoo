import { ArrowDown, ArrowRight, Check, ChevronRight, Store } from 'lucide-react'
import NfcIcon from '../../components/NfcIcon.jsx'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import { PRO_HERO } from '../commercantsContent.js'

function Breadcrumb({ crumbs }) {
  return (
    <nav className="yz-crumbs yz-mono" aria-label="Fil d’Ariane">
      <ol>
        {crumbs.map((crumb, i) => (
          <li key={crumb.label}>
            {i > 0 ? <ChevronRight size={12} strokeWidth={2.4} aria-hidden="true" /> : null}
            {crumb.href ? (
              <a href={crumb.href}>{crumb.label}</a>
            ) : (
              <span aria-current="page">{crumb.label}</span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  )
}

function PhoneMock({ phone }) {
  return (
    <div className="yz-phone" role="img" aria-label={phone.label}>
      <div className="yz-phone__screen">
        <div className="yz-phone__status" aria-hidden="true">
          <span>{phone.time}</span>
          <span className="yz-phone__island" />
          <span className="yz-phone__bars" />
        </div>
        <p className="yz-phone__label yz-mono" aria-hidden="true">
          {phone.label}
        </p>
        <ul className="yz-phone__stack" aria-hidden="true">
          {phone.notifications.map((note, i) => (
            <li key={note.id} className="yz-notif" style={{ '--i': i }}>
              <span className="yz-notif__icon">
                <img src="/images/yuztoo/yuztoo-mascotte-logo.webp" width="84" height="96" alt="" />
              </span>
              <span className="yz-notif__body">
                <span className="yz-notif__head">
                  <strong>{phone.shop}</strong>
                  <span>{note.when}</span>
                </span>
                <span className="yz-notif__text">
                  {note.emoji} {note.text}
                </span>
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}

export default function ProHero() {
  const { phone, tag } = PRO_HERO

  return (
    <section className="yz-hero yz-prohero" aria-labelledby="yz-prohero-title">
      <SiteAmbient variant="grid" />

      <div className="yz-hero__inner">
        <div className="yz-hero__copy">
          <Breadcrumb crumbs={PRO_HERO.crumbs} />

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
          <div className="yz-prohero__stage yz-frame">
            <div className="yz-hero__dots" aria-hidden="true" />
            <PhoneMock phone={phone} />
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
