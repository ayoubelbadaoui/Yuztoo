import { Play, RotateCcw } from 'lucide-react'
import { bt } from '../../components/Brand.jsx'
import { TUTO_UI } from '../tutorielsContent.js'
import { clock, em, plain } from './TutoText.jsx'
import { useTutoPlayer } from './useTutoPlayer.js'

/**
 * The lesson: the video (sticky on wide screens) beside the steps. Each step is
 * a chapter of the video — the playing one is highlighted, and « Revoir ce
 * passage » jumps the video to it.
 */
export default function TutoLesson({ tuto }) {
  const { videoRef, active, started, seek } = useTutoPlayer(tuto.steps)

  return (
    <section className="yz-section yz-light yz-lesson" id="etapes" aria-labelledby="yz-lesson-title">
      <div className="yz-container yz-lesson__grid">
        <div className="yz-lesson__player" id="video">
          <div className="yz-lesson__frame">
            <video
              ref={videoRef}
              src={tuto.video.src}
              poster={tuto.video.poster}
              width={tuto.video.width}
              height={tuto.video.height}
              controls
              playsInline
              preload="none"
              aria-label={`${TUTO_UI.videoLabel} : ${plain(tuto.question)}`}
            />
          </div>

          <nav className="yz-lesson__chapters" aria-label={TUTO_UI.chapters}>
            <p className="yz-mono">{TUTO_UI.chapters}</p>
            <ol>
              {tuto.steps.map((s, i) => (
                <li key={s.n}>
                  <button
                    type="button"
                    className={started && active === i ? 'is-on' : ''}
                    aria-current={started && active === i ? 'step' : undefined}
                    onClick={() => seek(i)}
                  >
                    <span className="yz-mono">{clock(s.at)}</span>
                    {plain(s.title)}
                  </button>
                </li>
              ))}
            </ol>
          </nav>

          {!tuto.voiced ? <p className="yz-lesson__note">{TUTO_UI.silentNote}</p> : null}
        </div>

        <div className="yz-lesson__steps">
          <header className="yz-lesson__head">
            <h2 className="yz-h2" id="yz-lesson-title">
              {TUTO_UI.stepsTitle}
            </h2>
            <p className="yz-lead">{TUTO_UI.stepsLead}</p>
          </header>

          <ol className="yz-steplist">
            {tuto.steps.map((s, i) => (
              <li
                key={s.n}
                id={`etape-${s.n}`}
                className={`yz-step${started && active === i ? ' is-on' : ''}`}
              >
                <div className="yz-step__text">
                  <p className="yz-step__n yz-mono">
                    {String(s.n).padStart(2, '0')}
                    <span>/ {String(tuto.steps.length).padStart(2, '0')}</span>
                  </p>
                  <h3 className="yz-step__title">{em(s.title)}</h3>
                  <ul className="yz-step__captions">
                    {s.captions.map((c) => (
                      <li key={c}>{em(c)}</li>
                    ))}
                  </ul>
                  <button type="button" className="yz-step__jump" onClick={() => seek(i)}>
                    {started && active === i ? (
                      <RotateCcw size={14} strokeWidth={2.6} aria-hidden="true" />
                    ) : (
                      <Play size={14} strokeWidth={2.6} aria-hidden="true" />
                    )}
                    {TUTO_UI.jump}
                    <span className="yz-mono">{clock(s.at)}</span>
                  </button>
                </div>

                <figure className="yz-device yz-step__shot">
                  <div className="yz-device__screen">
                    <img
                      src={s.shot.src}
                      srcSet={s.shot.srcSet}
                      sizes="(max-width: 680px) 46vw, 220px"
                      width={s.shot.width}
                      height={s.shot.height}
                      alt={s.shot.alt}
                      loading="lazy"
                      decoding="async"
                    />
                  </div>
                </figure>
              </li>
            ))}
          </ol>

          <details className="yz-transcript">
            <summary>{bt(TUTO_UI.transcriptTitle)}</summary>
            <ol>
              {tuto.transcript.map((line) => (
                <li key={line}>{bt(line)}</li>
              ))}
            </ol>
          </details>
        </div>
      </div>
    </section>
  )
}
