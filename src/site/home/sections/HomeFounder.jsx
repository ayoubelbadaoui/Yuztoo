import { HOME_FOUNDER } from '../homeContent.js'

export default function HomeFounder() {
  const { image, imageBadge } = HOME_FOUNDER

  return (
    <section className="yz-section yz-dark yz-dark--deep yz-founder" aria-labelledby="yz-founder-title">
      <div className="yz-container yz-founder__grid">
        <figure className="yz-founder__visual yz-frame" data-reveal>
          <img
            src={image.src}
            alt={image.alt}
            width={image.width}
            height={image.height}
            loading="lazy"
            decoding="async"
          />
          <figcaption className="yz-founder__badge">
            <strong>{imageBadge.value}</strong>
            <span className="yz-mono">{imageBadge.label}</span>
          </figcaption>
        </figure>

        <div className="yz-founder__copy">
          <h2 className="yz-eyebrow" id="yz-founder-title">
            <em className="yz-eyebrow__idx">{HOME_FOUNDER.index}</em>
            {HOME_FOUNDER.eyebrow}
          </h2>
          <blockquote className="yz-founder__quote" data-reveal>
            <span className="yz-founder__mark" aria-hidden="true">
              «
            </span>
            <p>{HOME_FOUNDER.quote}</p>
          </blockquote>
          <p className="yz-founder__sign">
            <span className="yz-founder__rule" aria-hidden="true" />
            <strong>{HOME_FOUNDER.author}</strong>
            <span className="yz-mono">{HOME_FOUNDER.role}</span>
          </p>
        </div>
      </div>
    </section>
  )
}
