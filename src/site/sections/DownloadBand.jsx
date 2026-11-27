import { Check } from 'lucide-react'
import AppPhone from '../components/AppPhone.jsx'
import { StoreButton, STORES } from '../components/StoreButtons.jsx'
import { bt } from '../components/Brand.jsx'
import { APP_SCREENS } from '../appScreensContent.js'
import { DOWNLOAD } from './navContent.js'

/**
 * Download band above the footer on every page — the target of every
 * « Tester gratuitement » button (#telecharger). Phones get the store buttons;
 * desktop also gets a QR code per store.
 */
export default function DownloadBand() {
  return (
    <section id={DOWNLOAD.id} className="yz-section yz-light--alt yz-dl" aria-labelledby="yz-dl-title">
      <div className="yz-container yz-dl__grid">
        <div className="yz-dl__copy">
          <p className="yz-eyebrow">{DOWNLOAD.eyebrow}</p>
          <h2 className="yz-h2" id="yz-dl-title">
            {bt(DOWNLOAD.title)}
          </h2>
          <p className="yz-lead">{bt(DOWNLOAD.lead)}</p>

          <ul className="yz-dl__aud">
            {DOWNLOAD.audiences.map((aud) => (
              <li key={aud.id}>
                <Check size={16} strokeWidth={3} aria-hidden="true" />
                <strong>{aud.title}</strong>
                <span>{aud.text}</span>
              </li>
            ))}
          </ul>

          <div className="yz-dl__stores">
            {STORES.map((store) => (
              <div key={store.id} className="yz-dl__store">
                <StoreButton store={store} size="lg" />
                <figure className="yz-dl__qr">
                  <img src={store.qr} width="96" height="96" alt={`QR code ${store.name}`} loading="lazy" />
                  <figcaption className="yz-mono">{DOWNLOAD.qrHint}</figcaption>
                </figure>
              </div>
            ))}
          </div>

          <p className="yz-dl__note">{DOWNLOAD.footnote}</p>
        </div>

        <div className="yz-dl__visual" aria-hidden="true">
          <AppPhone screen={APP_SCREENS.vitrine} className="yz-dl__phone" sizes="(max-width: 900px) 52vw, 280px" />
        </div>
      </div>
    </section>
  )
}
