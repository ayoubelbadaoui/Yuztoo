import { ArrowUpRight, GraduationCap, Users } from 'lucide-react'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import SectionStrip from '../../components/SectionStrip.jsx'
import { HOME_BENEFITS } from '../homeContent.js'

const ICONS = { users: Users, graduation: GraduationCap }

export default function HomeBenefits() {
  const { featured, photo, items, strip } = HOME_BENEFITS

  return (
    <section
      className="yz-section yz-light yz-light--alt yz-section--ruled"
      aria-labelledby="yz-benefits-title"
    >
      <SiteAmbient variant="dots" />
      <div className="yz-container">
        <SectionHead
          index={HOME_BENEFITS.index}
          eyebrow={HOME_BENEFITS.eyebrow}
          title={HOME_BENEFITS.title}
          lead={HOME_BENEFITS.lead}
          align="center"
          titleId="yz-benefits-title"
        />

        <div className="yz-grid yz-bento">
          <article className="yz-bento__feature" data-reveal>
            <span className="yz-bento__kicker yz-mono">{featured.kicker}</span>
            <span className="yz-bento__figure">{featured.figure}</span>
            <h3 className="yz-bento__label">{featured.label}</h3>
            <p className="yz-bento__note">{featured.note}</p>
            <dl className="yz-bento__facts">
              {featured.facts.map((fact) => (
                <div key={fact.label}>
                  <dt className="yz-mono">{fact.label}</dt>
                  <dd>{fact.value}</dd>
                </div>
              ))}
            </dl>
          </article>

          <figure className="yz-bento__photo" data-reveal style={{ '--d': '0.06s' }}>
            <img
              src={photo.src}
              alt={photo.alt}
              width={photo.width}
              height={photo.height}
              loading="lazy"
              decoding="async"
            />
            <figcaption className="yz-bento__caption yz-mono">{photo.caption}</figcaption>
          </figure>

          {items.map((item, i) => {
            const Icon = ICONS[item.icon]
            return (
              <article
                key={item.id}
                className={`yz-cell yz-bento__item yz-bento__item--${i + 1}`}
                data-reveal
                style={{ '--d': `${0.12 + i * 0.06}s` }}
              >
                <span className="yz-bento__num yz-mono" aria-hidden="true">
                  {String(i + 1).padStart(2, '0')}
                </span>
                <span className="yz-tile" aria-hidden="true">
                  <Icon size={21} strokeWidth={2.1} />
                </span>
                <h3 className="yz-bento__title">{item.title}</h3>
                <p className="yz-bento__copy">{item.text}</p>
                <span className="yz-bento__metric yz-mono">
                  <ArrowUpRight size={13} strokeWidth={2.6} aria-hidden="true" />
                  {item.metric}
                </span>
              </article>
            )
          })}
        </div>

        <SectionStrip {...strip} />
      </div>
    </section>
  )
}
