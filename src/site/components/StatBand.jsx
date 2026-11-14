/** Dark band of headline figures. `band.stats`: { id, value, label, note }. */
export default function StatBand({ band, id }) {
  return (
    <section className="yz-section yz-dark yz-impact" aria-labelledby={`${id}-title`}>
      <div className="yz-container">
        <div className="yz-impact__head">
          <p className="yz-eyebrow">{band.eyebrow}</p>
          <h2 className="yz-h2" id={`${id}-title`}>
            {band.title}
          </h2>
        </div>

        <dl className="yz-impact__stats">
          {band.stats.map((stat, i) => (
            <div key={stat.id} className="yz-impact__stat" data-reveal style={{ '--d': `${i * 0.1}s` }}>
              <dt className="yz-impact__label">
                <span className="yz-mono">{stat.label}</span>
                <span className="yz-impact__note">{stat.note}</span>
              </dt>
              <dd className="yz-impact__value">{stat.value}</dd>
            </div>
          ))}
        </dl>
      </div>
    </section>
  )
}
