import {
  ChartColumn,
  Coffee,
  Croissant,
  Dumbbell,
  Leaf,
  Link,
  MessageCircle,
  Sparkles,
  Star,
  Store,
  Wallet,
  Wrench,
} from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_TOOLS } from '../commercantsContent.js'

const FEATURE_ICONS = {
  message: MessageCircle,
  chart: ChartColumn,
  leaf: Leaf,
  star: Star,
  link: Link,
  wallet: Wallet,
}

const TRADE_ICONS = {
  croissant: Croissant,
  sparkles: Sparkles,
  coffee: Coffee,
  store: Store,
  wrench: Wrench,
  dumbbell: Dumbbell,
}

export default function ProTools() {
  return (
    <section className="yz-section yz-light--alt yz-tools" aria-labelledby="yz-tools-title">
      <div className="yz-container">
        <SectionHead
          index={PRO_TOOLS.index}
          eyebrow={PRO_TOOLS.eyebrow}
          title={PRO_TOOLS.title}
          titleId="yz-tools-title"
        />

        <ul className="yz-grid yz-tools__grid">
          {PRO_TOOLS.features.map((feature, i) => {
            const Icon = FEATURE_ICONS[feature.icon]
            return (
              <li
                key={feature.id}
                className="yz-cell yz-tools__item"
                data-reveal
                style={{ '--d': `${(i % 3) * 0.08}s` }}
              >
                <span className="yz-tile" aria-hidden="true">
                  <Icon size={20} strokeWidth={2.1} />
                </span>
                <h3 className="yz-tools__title">{feature.title}</h3>
                <p className="yz-tools__text">{feature.text}</p>
              </li>
            )
          })}
        </ul>

        <div className="yz-trades">
          <h3 className="yz-trades__title yz-mono">{PRO_TOOLS.tradesTitle}</h3>
          <ul className="yz-trades__list">
            {PRO_TOOLS.trades.map((trade) => {
              const Icon = TRADE_ICONS[trade.icon]
              return (
                <li key={trade.id}>
                  <Icon size={18} strokeWidth={2} aria-hidden="true" />
                  {trade.label}
                </li>
              )
            })}
          </ul>
        </div>
      </div>
    </section>
  )
}
