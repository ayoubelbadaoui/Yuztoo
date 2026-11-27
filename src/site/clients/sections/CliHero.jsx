import { MapPin } from 'lucide-react'
import AppPhone from '../../components/AppPhone.jsx'
import NfcIcon from '../../components/NfcIcon.jsx'
import PageHero from '../../components/PageHero.jsx'
import { APP_SCREENS } from '../../appScreensContent.js'
import { CLI_HERO } from '../clientsContent.js'
import { bt } from '../../components/Brand.jsx'

export default function CliHero() {
  return (
    <PageHero hero={CLI_HERO} BadgeIcon={MapPin}>
      <div className="yz-prohero__stage yz-prohero__stage--duo yz-frame">
        <div className="yz-hero__dots" aria-hidden="true" />
        <AppPhone screen={APP_SCREENS.promotions} className="yz-device--back" sizes="(max-width: 640px) 46vw, 230px" />
        <AppPhone screen={APP_SCREENS.vitrine} className="yz-device--front" priority sizes="(max-width: 640px) 50vw, 250px" />
        <span className="yz-prohero__plaque" aria-hidden="true">
          <NfcIcon size={30} strokeWidth={1.7} />
        </span>
      </div>
      <div className="yz-hero__plate yz-prohero__tag">
        <strong>{bt(CLI_HERO.tag.value)}</strong>
        <span className="yz-mono">{bt(CLI_HERO.tag.label)}</span>
      </div>
    </PageHero>
  )
}
