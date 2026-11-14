import { MapPin } from 'lucide-react'
import NfcIcon from '../../components/NfcIcon.jsx'
import PageHero from '../../components/PageHero.jsx'
import { CLI_HERO } from '../clientsContent.js'

function CarnetMock({ phone }) {
  return (
    <div className="yz-phone" role="img" aria-label={`${phone.title} — ${phone.label}`}>
      <div className="yz-phone__screen yz-phone__screen--light">
        <div className="yz-phone__status" aria-hidden="true">
          <span>{phone.time}</span>
          <span className="yz-phone__island" />
          <span className="yz-phone__bars" />
        </div>
        <div className="yz-carnet" aria-hidden="true">
          <p className="yz-carnet__title">{phone.title}</p>
          <p className="yz-carnet__label yz-mono">{phone.label}</p>
          <ul className="yz-carnet__list">
            {phone.shops.map((shop, i) => (
              <li key={shop.id} className="yz-carnet__shop" style={{ '--i': i }}>
                <span className="yz-carnet__avatar">{shop.name.charAt(0)}</span>
                <span className="yz-carnet__body">
                  <strong>{shop.name}</strong>
                  <span>{shop.kind}</span>
                  <span className="yz-carnet__bar">
                    <span style={{ width: `${(shop.stamps / shop.total) * 100}%` }} />
                  </span>
                </span>
                <span className="yz-carnet__count">
                  {shop.stamps}/{shop.total}
                </span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )
}

export default function CliHero() {
  return (
    <PageHero hero={CLI_HERO} BadgeIcon={MapPin}>
      <div className="yz-prohero__stage yz-frame">
        <div className="yz-hero__dots" aria-hidden="true" />
        <CarnetMock phone={CLI_HERO.phone} />
        <span className="yz-prohero__plaque" aria-hidden="true">
          <NfcIcon size={30} strokeWidth={1.7} />
        </span>
      </div>
      <div className="yz-hero__plate yz-prohero__tag">
        <strong>{CLI_HERO.tag.value}</strong>
        <span className="yz-mono">{CLI_HERO.tag.label}</span>
      </div>
    </PageHero>
  )
}
