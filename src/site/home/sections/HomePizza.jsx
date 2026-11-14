import SiteAmbient from '../../components/SiteAmbient.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { HOME_PIZZA } from '../homeContent.js'

function Receipt({ receipt }) {
  return (
    <figure className="yz-receipt" data-reveal>
      <figcaption className="yz-sr-only">
        Détail d’une commande de 18 € passée via une plateforme de livraison
      </figcaption>
      <div className="yz-receipt__paper">
        <div className="yz-receipt__head">
          <span className="yz-receipt__brand">{receipt.header}</span>
          <span>{receipt.number}</span>
        </div>

        <div className="yz-receipt__item">
          <span>
            {receipt.item.label}
            <small>{receipt.item.note}</small>
          </span>
          <span>{receipt.item.amount}</span>
        </div>

        <dl className="yz-receipt__lines">
          {receipt.lines.map((line) => (
            <div key={line.id} className={line.tone ? `is-${line.tone}` : undefined}>
              <dt>{line.label}</dt>
              <dd>{line.amount}</dd>
            </div>
          ))}
        </dl>

        <div className="yz-receipt__total">
          <span>{receipt.total.label}</span>
          <strong>{receipt.total.amount}</strong>
        </div>

        <p className="yz-receipt__foot">{receipt.footer}</p>
        <div className="yz-receipt__barcode" aria-hidden="true" />
      </div>

      <div className="yz-receipt__stamp" aria-hidden="true">
        <span>{receipt.stamp.top}</span>
        <strong>{receipt.stamp.value}</strong>
        <span>{receipt.stamp.bottom}</span>
      </div>
    </figure>
  )
}

export default function HomePizza() {
  const { facts, receipt } = HOME_PIZZA

  return (
    <section className="yz-section yz-dark yz-pizza" aria-labelledby="yz-pizza-title">
      <SiteAmbient variant="rules" />
      <div className="yz-container yz-pizza__grid">
        <div className="yz-pizza__copy">
          <SectionHead
            index={HOME_PIZZA.index}
            eyebrow={HOME_PIZZA.eyebrow}
            title={HOME_PIZZA.title}
            lead={HOME_PIZZA.lead}
            titleId="yz-pizza-title"
          />

          <dl className="yz-pizza__facts">
            {facts.map((fact, i) => (
              <div key={fact.id} data-reveal style={{ '--d': `${i * 0.06}s` }}>
                <dt>{fact.label}</dt>
                <dd>{fact.value}</dd>
              </div>
            ))}
          </dl>

          <p className="yz-pizza__punch">
            {HOME_PIZZA.punchlineLead} <span className="yz-accent">{HOME_PIZZA.punchlineAccent}</span>
          </p>
        </div>

        <Receipt receipt={receipt} />
      </div>
    </section>
  )
}
