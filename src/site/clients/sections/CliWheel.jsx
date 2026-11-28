import { useRef, useState } from 'react'
import { Check, RotateCw } from 'lucide-react'
import { bt } from '../../components/Brand.jsx'
import { CLI_WHEEL } from '../clientsContent.js'
import DevNote from '../../components/DevNote.jsx'

const R = 170
const SEG_TONES = ['navy', 'gold', 'cream', 'gold-deep']

/** Point on the circle for an angle in degrees, 0 = top, clockwise. */
const at = (deg, r) => {
  const rad = (deg * Math.PI) / 180
  return [r * Math.sin(rad), -r * Math.cos(rad)]
}

function Wheel({ segments, rotation, onDone }) {
  const step = 360 / segments.length
  return (
    <svg
      className="yz-wheel__svg"
      viewBox="-180 -180 360 360"
      style={{ transform: `rotate(${rotation}deg)` }}
      onTransitionEnd={onDone}
      aria-hidden="true"
    >
      {segments.map((label, i) => {
        const [x0, y0] = at(i * step - step / 2, R)
        const [x1, y1] = at(i * step + step / 2, R)
        const tone = SEG_TONES[i % SEG_TONES.length]
        return (
          <g key={label} className={`yz-wheel__seg yz-wheel__seg--${tone}${label.length > 8 ? ' is-long' : ''}`}>
            <path d={`M0 0 L${x0} ${y0} A${R} ${R} 0 0 1 ${x1} ${y1} Z`} />
            <text transform={`rotate(${i * step})`} x="0" y={-R * 0.66} textAnchor="middle" dominantBaseline="middle">
              {label}
            </text>
          </g>
        )
      })}
      <circle className="yz-wheel__rim" r={R} />
    </svg>
  )
}

export default function CliWheel() {
  const { segments } = CLI_WHEEL
  const [rotation, setRotation] = useState(0)
  const [spinning, setSpinning] = useState(false)
  const [result, setResult] = useState(null)
  const target = useRef(0)

  const spin = () => {
    if (spinning) return
    const step = 360 / segments.length
    const pick = Math.floor(Math.random() * segments.length)
    target.current = pick
    // Land the picked segment's centre under the pointer (top), after 5 turns.
    const current = rotation % 360
    const delta = (360 - pick * step - current + 720) % 360
    const next = rotation + 1800 + delta
    setResult(null)
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setRotation(next)
      setResult(segments[pick])
      return
    }
    setSpinning(true)
    setRotation(next)
  }

  const done = () => {
    setSpinning(false)
    setResult(segments[target.current])
  }

  return (
    <section id="roue" className="yz-section yz-dark yz-wheel" aria-labelledby="yz-wheel-title">
      <div className="yz-container yz-wheel__grid">
        <div className="yz-wheel__copy">
          <p className="yz-eyebrow">{bt(CLI_WHEEL.eyebrow)}</p>
          <h2 className="yz-h2" id="yz-wheel-title">
            {bt(CLI_WHEEL.title)}
          </h2>
          <p className="yz-lead">{bt(CLI_WHEEL.lead)}</p>

          <ol className="yz-wheel__steps">
            {CLI_WHEEL.steps.map((text, i) => (
              <li key={text}>
                <span className="yz-mono">{String(i + 1).padStart(2, '0')}</span>
                {bt(text)}
              </li>
            ))}
          </ol>

          <p className="yz-wheel__note">
            <Check size={15} strokeWidth={2.6} aria-hidden="true" />
            {bt(CLI_WHEEL.note)}
          </p>
        </div>

        <div className="yz-wheel__stage">
          <DevNote id="wheel" />
          <span className="yz-wheel__badge yz-mono">{CLI_WHEEL.demo}</span>
          <div className={`yz-wheel__dial${spinning ? ' is-spinning' : ''}`}>
            <span className="yz-wheel__pointer" aria-hidden="true" />
            <Wheel segments={segments} rotation={rotation} onDone={done} />
            <span className="yz-wheel__hub" aria-hidden="true">
              <img src="/images/yuztoo/yuztoo-mascotte-logo.webp" width="84" height="96" alt="" />
            </span>
          </div>

          <button className="yz-btn yz-btn--primary yz-wheel__spin" type="button" onClick={spin} disabled={spinning}>
            <RotateCw size={18} strokeWidth={2.4} aria-hidden="true" />
            {spinning ? CLI_WHEEL.spinning : CLI_WHEEL.spin}
          </button>

          <p className="yz-wheel__result" aria-live="polite">
            {result ? (
              <>
                {CLI_WHEEL.resultLead} <strong>{result}</strong>. {CLI_WHEEL.resultEnd}
              </>
            ) : null}
          </p>
        </div>
      </div>
    </section>
  )
}
