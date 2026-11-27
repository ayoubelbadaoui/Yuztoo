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
import IconGrid from '../../components/IconGrid.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_TOOLS } from '../commercantsContent.js'
import { bt } from '../../components/Brand.jsx'

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

        <IconGrid items={PRO_TOOLS.features} icons={FEATURE_ICONS} />

        <div className="yz-trades">
          <h3 className="yz-trades__title yz-mono">{PRO_TOOLS.tradesTitle}</h3>
          <ul className="yz-trades__list">
            {PRO_TOOLS.trades.map((trade) => {
              const Icon = TRADE_ICONS[trade.icon]
              return (
                <li key={trade.id}>
                  <Icon size={18} strokeWidth={2} aria-hidden="true" />
                  {bt(trade.label)}
                </li>
              )
            })}
          </ul>
        </div>
      </div>
    </section>
  )
}
