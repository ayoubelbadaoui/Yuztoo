import { useEffect, useRef, useState } from 'react'
import { ArrowLeft, ArrowRight, Coffee, Play, ShoppingBasket, Waves } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import VideoDrawer from '../../components/VideoDrawer.jsx'
import { HOME_TESTIMONIALS } from '../homeContent.js'
import { bt } from '../../components/Brand.jsx'
import DevNote from '../../components/DevNote.jsx'

const TRADE_ICONS = { coffee: Coffee, waves: Waves, basket: ShoppingBasket }

/**
 * Merchant carousel: a scroll-snap row (swipe on touch, arrows on desktop).
 * Each merchant can carry `media` — { type: 'image', src } for a post made
 * for them, or { type: 'video', src, poster } for a reel — shown above the
 * quote; a video opens in the shared drawer.
 */
export default function HomeTestimonials() {
  const { quotes, question } = HOME_TESTIMONIALS
  const total = String(quotes.length).padStart(2, '0')
  const trackRef = useRef(null)
  const [edge, setEdge] = useState({ start: true, end: false })
  const [playing, setPlaying] = useState(null)
  const videos = quotes.filter((q) => q.media?.type === 'video').map((q) => ({ id: q.id, title: q.author, video: { ...q.media, label: q.quote } }))

  useEffect(() => {
    const track = trackRef.current
    if (!track) return undefined
    const update = () =>
      setEdge({
        start: track.scrollLeft <= 4,
        end: track.scrollLeft + track.clientWidth >= track.scrollWidth - 4,
      })
    update()
    track.addEventListener('scroll', update, { passive: true })
    window.addEventListener('resize', update)
    return () => {
      track.removeEventListener('scroll', update)
      window.removeEventListener('resize', update)
    }
  }, [])

  const scrollBy = (dir) => {
    const track = trackRef.current
    const card = track?.querySelector('.yz-voice')
    if (!card) return
    track.scrollBy({ left: dir * (card.getBoundingClientRect().width + 16), behavior: 'smooth' })
  }

  return (
    <section className="yz-section yz-light yz-voices" aria-labelledby="yz-voices-title">
      <div className="yz-container">
        <div className="yz-voices__head">
          <SectionHead
            index={HOME_TESTIMONIALS.index}
            eyebrow={HOME_TESTIMONIALS.eyebrow}
            title={HOME_TESTIMONIALS.title}
            lead={HOME_TESTIMONIALS.lead}
            titleId="yz-voices-title"
          />
          <div className="yz-voices__arrows">
            <button type="button" onClick={() => scrollBy(-1)} disabled={edge.start} aria-label="Commerçant précédent">
              <ArrowLeft size={18} strokeWidth={2.4} />
            </button>
            <button type="button" onClick={() => scrollBy(1)} disabled={edge.end} aria-label="Commerçant suivant">
              <ArrowRight size={18} strokeWidth={2.4} />
            </button>
          </div>
        </div>

        <DevNote id="carousel" place="inline" />

        <ul className="yz-voices__track" ref={trackRef} aria-label="Témoignages de commerçants">
          {quotes.map((item, i) => {
            const Icon = TRADE_ICONS[item.icon]
            const videoIndex = videos.findIndex((v) => v.id === item.id)
            return (
              <li key={item.id} className="yz-cell yz-voice" data-reveal style={{ '--d': `${i * 0.08}s` }}>
                <figure>
                  {item.media?.type === 'image' ? (
                    <img className="yz-voice__media" src={item.media.src} alt={item.media.alt || ''} loading="lazy" />
                  ) : null}
                  {item.media?.type === 'video' ? (
                    <button className="yz-voice__media yz-voice__media--video" type="button" onClick={() => setPlaying(videoIndex)}>
                      <img src={item.media.poster} alt="" loading="lazy" />
                      <span className="yz-steps__play-icon" aria-hidden="true">
                        <Play size={16} strokeWidth={2.6} />
                      </span>
                      <span className="yz-sr-only">Voir la vidéo de {item.author}</span>
                    </button>
                  ) : null}
                  <p className="yz-voice__q yz-mono" aria-hidden="true">
                    <span>Q.</span>
                    {question}
                    <em>
                      {String(i + 1).padStart(2, '0')}/{total}
                    </em>
                  </p>
                  <blockquote className="yz-voice__quote">
                    <p>{bt(item.quote)}</p>
                  </blockquote>
                  <figcaption className="yz-voice__who">
                    <span className="yz-voice__r" aria-hidden="true">
                      <Icon size={18} strokeWidth={2} />
                    </span>
                    <span>
                      <strong>{bt(item.author)}</strong>
                      <span className="yz-mono">{bt(item.role)}</span>
                    </span>
                  </figcaption>
                </figure>
              </li>
            )
          })}
        </ul>
      </div>

      {videos.length ? (
        <VideoDrawer items={videos} index={playing} onChange={setPlaying} onClose={() => setPlaying(null)} kicker="Vidéo" />
      ) : null}
    </section>
  )
}
