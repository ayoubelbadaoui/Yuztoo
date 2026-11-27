import { useState } from 'react'
import { CalendarDays, Gift, Megaphone, Play, ThumbsUp, Users } from 'lucide-react'
import AppPhone from '../../components/AppPhone.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import VideoDrawer from '../../components/VideoDrawer.jsx'
import { bt } from '../../components/Brand.jsx'
import { APP_SCREENS } from '../../appScreensContent.js'
import { PRO_NETWORK } from '../commercantsContent.js'

const ICONS = { thumbs: ThumbsUp, megaphone: Megaphone, users: Users, gift: Gift, calendar: CalendarDays }

export default function ProNetwork() {
  const [playing, setPlaying] = useState(null)

  return (
    <section id="reseau" className="yz-section yz-dark yz-network" aria-labelledby="yz-network-title">
      <div className="yz-container">
        <div className="yz-network__layout">
          <div>
            <SectionHead
              index={PRO_NETWORK.index}
              eyebrow={PRO_NETWORK.eyebrow}
              title={PRO_NETWORK.title}
              lead={PRO_NETWORK.lead}
              titleId="yz-network-title"
            />

            <ol className="yz-network__list">
              {PRO_NETWORK.features.map((feature, i) => {
                const Icon = ICONS[feature.icon]
                return (
                  <li key={feature.id} className="yz-network__item" data-reveal style={{ '--d': `${i * 0.06}s` }}>
                    <span className="yz-network__icon" aria-hidden="true">
                      <Icon size={20} strokeWidth={2.1} />
                    </span>
                    <span>
                      <strong>{bt(feature.title)}</strong>
                      <span>{bt(feature.text)}</span>
                    </span>
                  </li>
                )
              })}
            </ol>
          </div>

          <div className="yz-network__visual">
            <AppPhone screen={APP_SCREENS.partenaires} className="yz-network__phone" sizes="(max-width: 900px) 60vw, 280px" />
            <div className="yz-network__videos">
              {PRO_NETWORK.videos.map((item, i) => (
                <button key={item.id} type="button" className="yz-network__video" onClick={() => setPlaying(i)}>
                  <img src={item.video.poster} width="54" height="96" alt="" loading="lazy" />
                  <span>
                    <span className="yz-mono">{PRO_NETWORK.videoKicker}</span>
                    <strong>{item.title}</strong>
                  </span>
                  <span className="yz-steps__play-icon" aria-hidden="true">
                    <Play size={14} strokeWidth={2.6} />
                  </span>
                </button>
              ))}
            </div>
          </div>
        </div>

        <p className="yz-network__punch">{bt(PRO_NETWORK.punchline)}</p>
      </div>

      <VideoDrawer
        items={PRO_NETWORK.videos}
        index={playing}
        onChange={setPlaying}
        onClose={() => setPlaying(null)}
        kicker={PRO_NETWORK.videoKicker}
      />
    </section>
  )
}
