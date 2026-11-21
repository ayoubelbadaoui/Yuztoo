import { useEffect, useRef, useState } from 'react'
import { ArrowRight } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_CALC } from '../commercantsContent.js'

const euros = new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 })

/** Eases the displayed number toward `target` so the figure visibly climbs. */
function useTween(target) {
  const [shown, setShown] = useState(target)
  const from = useRef(target)

  useEffect(() => {
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (reduce) {
      from.current = target
      setShown(target)
      return undefined
    }
    const start = performance.now()
    const origin = from.current
    let frame = 0
    const step = (now) => {
      const t = Math.min(1, (now - start) / 420)
      const value = origin + (target - origin) * (1 - (1 - t) ** 3)
      from.current = value
      setShown(value)
      if (t < 1) frame = requestAnimationFrame(step)
    }
    frame = requestAnimationFrame(step)
    return () => cancelAnimationFrame(frame)
  }, [target])

  return shown
}

function Slider({ field, value, onChange }) {
  const pct = ((value - field.min) / (field.max - field.min)) * 100
  return (
    <div className="yz-calc__field">
      <label htmlFor={`yz-calc-${field.id}`}>
        <span>{field.label}</span>
        <output htmlFor={`yz-calc-${field.id}`}>
          {value}
          {field.unit ? ` ${field.unit}` : ''}
        </output>
      </label>
      <input
        id={`yz-calc-${field.id}`}
        type="range"
        min={field.min}
        max={field.max}
        step={field.step}
        value={value}
        onChange={(e) => onChange(field.id, Number(e.target.value))}
        style={{ '--pct': `${pct}%` }}
      />
    </div>
  )
}

export default function ProCalculator() {
  const [values, setValues] = useState(() =>
    Object.fromEntries(PRO_CALC.fields.map((field) => [field.id, field.value])),
  )
  const onChange = (id, value) => setValues((prev) => ({ ...prev, [id]: value }))

  const yearly = values.basket * values.orders * 12 * (values.rate / 100)
  const shown = useTween(yearly)

  return (
    <section className="yz-section yz-light yz-calc" aria-labelledby="yz-calc-title">
      <div className="yz-container">
        <SectionHead
          eyebrow={PRO_CALC.eyebrow}
          title={PRO_CALC.title}
          lead={PRO_CALC.lead}
          titleId="yz-calc-title"
        />

        <div className="yz-calc__panel" data-reveal>
          <div className="yz-calc__inputs">
            {PRO_CALC.fields.map((field) => (
              <Slider key={field.id} field={field} value={values[field.id]} onChange={onChange} />
            ))}
            <p className="yz-calc__note">{PRO_CALC.disclaimer}</p>
          </div>

          <div className="yz-calc__result" aria-live="polite">
            <p className="yz-mono">{PRO_CALC.resultKicker}</p>
            <p className="yz-calc__big">
              <span className="yz-sr-only">{euros.format(yearly)}</span>
              <span aria-hidden="true">{euros.format(Math.round(shown))}</span>
            </p>
            <p className="yz-calc__monthly">
              {PRO_CALC.monthly.replace('{value}', euros.format(Math.round(yearly / 12)))}
            </p>

            <div className="yz-calc__vs">
              <p className="yz-mono">{PRO_CALC.yuztooKicker}</p>
              <p className="yz-calc__zero">{PRO_CALC.yuztooValue}</p>
              <p>{PRO_CALC.yuztooNote}</p>
            </div>

            <a className="yz-btn yz-btn--primary yz-calc__cta" href={PRO_CALC.cta.href}>
              {PRO_CALC.cta.label}
              <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
