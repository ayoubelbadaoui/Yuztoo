import { Landmark, MapPinned, Repeat, Store, Users } from 'lucide-react'
import PageHero from '../../components/PageHero.jsx'
import { COL_HERO } from '../collectivitesContent.js'

const KPI_ICONS = { store: Store, users: Users, repeat: Repeat, map: MapPinned }

function ReportMock({ report }) {
  const max = Math.max(...report.bars)
  return (
    <div className="yz-report" role="img" aria-label={`${report.title} — ${report.period}`}>
      <div className="yz-board__bar" aria-hidden="true">
        <strong>{report.title}</strong>
        <span className="yz-mono">{report.period}</span>
      </div>
      <ul className="yz-report__kpis" aria-hidden="true">
        {report.kpis.map((kpi) => {
          const Icon = KPI_ICONS[kpi.icon]
          return (
            <li key={kpi.id}>
              <Icon size={16} strokeWidth={2.2} />
              <span>{kpi.label}</span>
              <span className="yz-report__trend" />
            </li>
          )
        })}
      </ul>
      <div className="yz-report__chart" aria-hidden="true">
        <span className="yz-report__chart-label yz-mono">{report.chartLabel}</span>
        <div className="yz-report__bars">
          {report.bars.map((value, i) => (
            <span key={i} style={{ height: `${(value / max) * 100}%`, '--i': i }} />
          ))}
        </div>
      </div>
    </div>
  )
}

export default function ColHero() {
  return (
    <PageHero hero={COL_HERO} BadgeIcon={Landmark}>
      <div className="yz-prohero__stage yz-prohero__stage--board yz-frame">
        <div className="yz-hero__dots" aria-hidden="true" />
        <ReportMock report={COL_HERO.report} />
      </div>
      <div className="yz-hero__plate yz-prohero__tag">
        <strong>{COL_HERO.tag.value}</strong>
        <span className="yz-mono">{COL_HERO.tag.label}</span>
      </div>
    </PageHero>
  )
}
