import AppPhone from '../../components/AppPhone.jsx'
import CheckColumns from '../../components/CheckColumns.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { APP_SCREENS } from '../../appScreensContent.js'
import { PRO_LOYALTY } from '../commercantsContent.js'
import { bt } from '../../components/Brand.jsx'

export default function ProLoyalty() {
  return (
    <section className="yz-section yz-light yz-loyalty" aria-labelledby="yz-loyalty-title">
      <div className="yz-container">
        <div className="yz-loyalty__top">
          <SectionHead
            index={PRO_LOYALTY.index}
            eyebrow={PRO_LOYALTY.eyebrow}
            title={PRO_LOYALTY.title}
            titleId="yz-loyalty-title"
          />
          <div className="yz-loyalty__phones" data-reveal>
            <AppPhone screen={APP_SCREENS.partenaires} className="yz-device--back" sizes="(max-width: 640px) 44vw, 220px" />
            <AppPhone screen={APP_SCREENS.fidelite} className="yz-device--front" sizes="(max-width: 640px) 48vw, 240px" />
          </div>
        </div>

        <CheckColumns columns={PRO_LOYALTY.columns} />

        <p className="yz-loyalty__punch">
          <span className="yz-accent">{bt(PRO_LOYALTY.punchline)}</span>
        </p>
      </div>
    </section>
  )
}
