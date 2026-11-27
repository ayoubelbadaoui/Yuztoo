import {
  Bell,
  BookOpen,
  Check,
  Gift,
  Heart,
  Info,
  MapPin,
  ScanLine,
  ShieldCheck,
  Smartphone,
} from 'lucide-react'
import IconGrid from '../../components/IconGrid.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import StepsWithMedia from '../../components/StepsWithMedia.jsx'
import { CLI_LOCAL, CLI_MESSAGES, CLI_STEPS, CLI_WHY } from '../clientsContent.js'
import { bt } from '../../components/Brand.jsx'

const WHY_ICONS = {
  shield: ShieldCheck,
  heart: Heart,
  bell: Bell,
  smartphone: Smartphone,
  gift: Gift,
  map: MapPin,
}

const STEP_ICONS = { scan: ScanLine, book: BookOpen, info: Info }

function CheckList({ items }) {
  return (
    <ul className="yz-checklist">
      {items.map((item) => (
        <li key={item}>
          <Check size={15} strokeWidth={3} aria-hidden="true" />
          {bt(item)}
        </li>
      ))}
    </ul>
  )
}

export function CliWhy() {
  return (
    <section className="yz-section yz-light--alt" aria-labelledby="yz-why-title">
      <div className="yz-container">
        <SectionHead index={CLI_WHY.index} eyebrow={CLI_WHY.eyebrow} title={CLI_WHY.title} titleId="yz-why-title" />
        <IconGrid items={CLI_WHY.items} icons={WHY_ICONS} />
      </div>
    </section>
  )
}

export function CliSteps() {
  return <StepsWithMedia data={CLI_STEPS} icons={STEP_ICONS} id="carnet" />
}

export function CliMessages() {
  return (
    <section className="yz-section yz-light--alt yz-section--ruled" aria-labelledby="yz-msg-title">
      <div className="yz-container">
        <SectionHead
          index={CLI_MESSAGES.index}
          eyebrow={CLI_MESSAGES.eyebrow}
          title={CLI_MESSAGES.title}
          lead={CLI_MESSAGES.lead}
          titleId="yz-msg-title"
        />
        <div className="yz-grid yz-duo">
          {CLI_MESSAGES.columns.map((column) => (
            <div key={column.id} className="yz-cell yz-duo__cell">
              <h3 className="yz-duo__title">{bt(column.title)}</h3>
              <CheckList items={column.points} />
              <ul className="yz-duo__notifs">
                {column.examples.map((example, i) => (
                  <li key={example.id} className="yz-notif yz-notif--flat" style={{ '--i': i }}>
                    <span className="yz-notif__icon">
                      <img src="/images/yuztoo/yuztoo-mascotte-logo.webp" width="84" height="96" alt="" />
                    </span>
                    <span className="yz-notif__body">
                      <span className="yz-notif__head">
                        <strong>{CLI_MESSAGES.shop}</strong>
                      </span>
                      <span className="yz-notif__text">
                        {example.emoji} {bt(example.text)}
                      </span>
                    </span>
                  </li>
                ))}
              </ul>
              <p className="yz-duo__punch">{column.punch}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export function CliLocal() {
  const { recommend, chat } = CLI_LOCAL
  return (
    <section className="yz-section yz-light" aria-labelledby="yz-local-title">
      <div className="yz-container">
        <SectionHead index={CLI_LOCAL.index} eyebrow={CLI_LOCAL.eyebrow} title={CLI_LOCAL.title} titleId="yz-local-title" />
        <div className="yz-grid yz-duo">
          <div className="yz-cell yz-duo__cell">
            <h3 className="yz-duo__title">{bt(recommend.title)}</h3>
            <p className="yz-duo__text">{bt(recommend.text)}</p>
            <CheckList items={recommend.points} />
          </div>
          <div className="yz-cell yz-duo__cell">
            <h3 className="yz-duo__title">{bt(chat.title)}</h3>
            <p className="yz-duo__text">{bt(chat.text)}</p>
            <div className="yz-chat" role="img" aria-label={chat.label}>
              <span className="yz-chat__label yz-mono" aria-hidden="true">
                {bt(chat.label)}
              </span>
              {chat.bubbles.map((bubble) => (
                <p key={bubble.id} className={`yz-chat__bubble yz-chat__bubble--${bubble.from}`} aria-hidden="true">
                  {bt(bubble.text)}
                </p>
              ))}
            </div>
            <p className="yz-duo__punch">{chat.punch}</p>
          </div>
        </div>
      </div>
    </section>
  )
}
