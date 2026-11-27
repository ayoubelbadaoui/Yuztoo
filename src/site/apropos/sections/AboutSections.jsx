import { Compass, Database, Link, Network, Users } from 'lucide-react'
import IconGrid from '../../components/IconGrid.jsx'
import PageHero from '../../components/PageHero.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { ABOUT_AMBITION, ABOUT_FOUNDER, ABOUT_HERO, ABOUT_MISSION, ABOUT_VISION } from '../aproposContent.js'
import { bt } from '../../components/Brand.jsx'

const AMBITION_ICONS = { link: Link, database: Database, network: Network, compass: Compass }

export function AboutHero() {
  const { image, tag } = ABOUT_HERO
  return (
    <PageHero hero={ABOUT_HERO} BadgeIcon={Users}>
      <div className="yz-prohero__stage yz-prohero__stage--photo yz-frame">
        <img src={image.src} alt={image.alt} width={image.width} height={image.height} fetchpriority="high" decoding="async" />
      </div>
      <div className="yz-hero__plate yz-prohero__tag">
        <strong>{bt(tag.value)}</strong>
        <span className="yz-mono">{bt(tag.label)}</span>
      </div>
    </PageHero>
  )
}

export function AboutMission() {
  return (
    <section className="yz-section yz-light--alt yz-mission" aria-labelledby="yz-mission-title">
      <div className="yz-container yz-answer__layout">
        <SectionHead
          index={ABOUT_MISSION.index}
          eyebrow={ABOUT_MISSION.eyebrow}
          title={ABOUT_MISSION.title}
          titleId="yz-mission-title"
        />
        <div className="yz-mission__body">
          {ABOUT_MISSION.paragraphs.map((text) => (
            <p key={text}>{bt(text)}</p>
          ))}
          <blockquote className="yz-mission__quote">
            <p>{bt(ABOUT_MISSION.quote)}</p>
          </blockquote>
        </div>
      </div>
    </section>
  )
}

export function AboutVision() {
  return (
    <section className="yz-section yz-light yz-vision" aria-labelledby="yz-vision-title">
      <div className="yz-container">
        <p className="yz-eyebrow">
          <em className="yz-eyebrow__idx">{ABOUT_VISION.index}</em>
          {bt(ABOUT_VISION.eyebrow)}
        </p>
        <h2 className="yz-vision__title" id="yz-vision-title">
          {bt(ABOUT_VISION.title)}
          {ABOUT_VISION.words.map((word, i) => (
            <span key={word} className="yz-vision__word" data-reveal style={{ '--d': `${i * 0.12}s` }}>
              {word}
            </span>
          ))}
        </h2>

        <div className="yz-vision__where">
          <h3 className="yz-mono">{ABOUT_VISION.whereTitle}</h3>
          <ol className="yz-grid yz-vision__grid">
            {ABOUT_VISION.where.map((item, i) => (
              <li key={item.id} className="yz-cell">
                <span className="yz-mono" aria-hidden="true">
                  {String(i + 1).padStart(2, '0')}
                </span>
                {bt(item.title)}
              </li>
            ))}
          </ol>
          <p className="yz-loyalty__punch">
            <span className="yz-accent">{ABOUT_VISION.punch}</span>
          </p>
        </div>
      </div>
    </section>
  )
}

export function AboutFounder() {
  const { image } = ABOUT_FOUNDER
  return (
    <section id="fondateur" className="yz-section yz-light--alt yz-section--ruled yz-bio" aria-labelledby="yz-bio-title">
      <div className="yz-container yz-bio__layout">
        <figure className="yz-bio__media yz-frame" data-reveal>
          <img src={image.src} alt={image.alt} width={image.width} height={image.height} loading="lazy" decoding="async" />
          <figcaption className="yz-steps__caption yz-mono">{bt(ABOUT_FOUNDER.role)}</figcaption>
        </figure>

        <div>
          <p className="yz-eyebrow">
            <em className="yz-eyebrow__idx">{ABOUT_FOUNDER.index}</em>
            {bt(ABOUT_FOUNDER.eyebrow)}
          </p>
          <h2 className="yz-h2" id="yz-bio-title">
            {bt(ABOUT_FOUNDER.name)}
          </h2>
          <div className="yz-bio__text">
            {ABOUT_FOUNDER.paragraphs.map((text) => (
              <p key={text}>{bt(text)}</p>
            ))}
          </div>
          <p className="yz-strip yz-strip__text yz-setup__quote">{ABOUT_FOUNDER.goal}</p>
          <dl className="yz-bio__facts">
            {ABOUT_FOUNDER.facts.map((fact) => (
              <div key={fact.id}>
                <dt className="yz-mono">{bt(fact.label)}</dt>
                <dd>{bt(fact.value)}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  )
}

export function AboutAmbition() {
  return (
    <section className="yz-section yz-light" aria-labelledby="yz-ambition-title">
      <div className="yz-container">
        <SectionHead eyebrow={ABOUT_AMBITION.eyebrow} title={ABOUT_AMBITION.title} titleId="yz-ambition-title" />
        <IconGrid items={ABOUT_AMBITION.items} icons={AMBITION_ICONS} columns={4} />
        <p className="yz-loyalty__punch">
          <span className="yz-accent">{ABOUT_AMBITION.punch}</span>
        </p>
      </div>
    </section>
  )
}
