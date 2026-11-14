import { Building2, Check, Eye, ShieldCheck, TrendingUp } from 'lucide-react'
import CheckColumns from '../../components/CheckColumns.jsx'
import IconGrid from '../../components/IconGrid.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { COL_ANSWER, COL_BENEFITS, COL_INVEST, COL_PROBLEM, COL_PROMISE } from '../collectivitesContent.js'

const INVEST_ICONS = { shield: ShieldCheck, trending: TrendingUp, building: Building2, eye: Eye }

export function ColProblem() {
  return (
    <section id="constat" className="yz-section yz-light--alt yz-pains" aria-labelledby="yz-col-problem-title">
      <div className="yz-container">
        <SectionHead
          index={COL_PROBLEM.index}
          eyebrow={COL_PROBLEM.eyebrow}
          title={COL_PROBLEM.title}
          lead={COL_PROBLEM.lead}
          titleId="yz-col-problem-title"
        />
        <ul className="yz-pains__chips yz-pains__chips--lead" aria-label="Plateformes internationales">
          {COL_PROBLEM.platforms.map((name) => (
            <li key={name} className="yz-mono">
              {name}
            </li>
          ))}
        </ul>
        <ul className="yz-grid yz-pains__grid yz-pains__grid--4">
          {COL_PROBLEM.items.map((item, i) => (
            <li key={item.id} className="yz-cell yz-pains__item" data-reveal style={{ '--d': `${i * 0.08}s` }}>
              <span className="yz-pains__kicker yz-mono">
                <span aria-hidden="true">{String(i + 1).padStart(2, '0')}</span>
                {item.kicker}
              </span>
              <h3 className="yz-pains__title">{item.title}</h3>
              <p className="yz-pains__text">{item.text}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}

export function ColAnswer() {
  return (
    <section className="yz-section yz-light yz-answer" aria-labelledby="yz-col-answer-title">
      <div className="yz-container yz-answer__layout">
        <div>
          <SectionHead
            index={COL_ANSWER.index}
            eyebrow={COL_ANSWER.eyebrow}
            title={COL_ANSWER.title}
            titleId="yz-col-answer-title"
          />
          <p className="yz-answer__highlight">{COL_ANSWER.highlight}</p>
        </div>
        <div>
          <ol className="yz-answer__list">
            {COL_ANSWER.points.map((point, i) => (
              <li key={point} data-reveal style={{ '--d': `${i * 0.06}s` }}>
                <span className="yz-mono" aria-hidden="true">
                  {String(i + 1).padStart(2, '0')}
                </span>
                {point}
                <Check size={16} strokeWidth={3} aria-hidden="true" />
              </li>
            ))}
          </ol>
          <p className="yz-strip yz-strip__text yz-setup__quote">{COL_ANSWER.quote}</p>
        </div>
      </div>
    </section>
  )
}

export function ColPromise() {
  return (
    <section className="yz-section yz-light--alt yz-section--ruled" aria-labelledby="yz-col-promise-title">
      <div className="yz-container">
        <SectionHead
          index={COL_PROMISE.index}
          eyebrow={COL_PROMISE.eyebrow}
          title={COL_PROMISE.title}
          titleId="yz-col-promise-title"
        />
        <CheckColumns columns={COL_PROMISE.columns} />
      </div>
    </section>
  )
}

export function ColBenefits() {
  return (
    <section className="yz-section yz-light" aria-labelledby="yz-col-benefits-title">
      <div className="yz-container">
        <SectionHead
          index={COL_BENEFITS.index}
          eyebrow={COL_BENEFITS.eyebrow}
          title={COL_BENEFITS.title}
          titleId="yz-col-benefits-title"
        />
        <CheckColumns columns={COL_BENEFITS.columns} />
      </div>
    </section>
  )
}

export function ColInvest() {
  return (
    <section className="yz-section yz-light--alt" aria-labelledby="yz-col-invest-title">
      <div className="yz-container">
        <SectionHead eyebrow={COL_INVEST.eyebrow} title={COL_INVEST.title} titleId="yz-col-invest-title" />
        <IconGrid items={COL_INVEST.items} icons={INVEST_ICONS} columns={4} />
      </div>
    </section>
  )
}
