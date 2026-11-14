import { ScanLine, Store } from 'lucide-react'
import NfcIcon from '../../components/NfcIcon.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_SETUP } from '../commercantsContent.js'

const ICONS = { store: Store, nfc: NfcIcon, scan: ScanLine }

export default function ProSetup() {
  const { image } = PRO_SETUP

  return (
    <section className="yz-section yz-light yz-setup" aria-labelledby="yz-setup-title">
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
          <figcaption className="yz-steps__caption yz-mono">{PRO_SETUP.imageCaption}</figcaption>
        </figure>

        <div className="yz-setup__copy">
          <SectionHead
            index={PRO_SETUP.index}
            eyebrow={PRO_SETUP.eyebrow}
            title={PRO_SETUP.title}
            titleId="yz-setup-title"
          />

          <ol className="yz-setup__steps">
            {PRO_SETUP.steps.map((step, i) => {
              const Icon = ICONS[step.icon]
              return (
                <li
                  key={step.id}
                  className="yz-setup__step"
                  data-reveal
                  style={{ '--d': `${i * 0.1}s` }}
                >
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

          <p className="yz-strip yz-strip__text yz-setup__quote">{PRO_SETUP.quote}</p>
        </div>
      </div>
    </section>
  )
}
