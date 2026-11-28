import { useState } from 'react'
import { Play, Send } from 'lucide-react'
import VideoDrawer from '../../components/VideoDrawer.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_CLIENTS } from '../commercantsContent.js'
import { bt } from '../../components/Brand.jsx'

function ClientBoard({ board }) {
  return (
    <div className="yz-board" data-reveal>
      <div className="yz-board__bar">
        <strong>{bt(board.title)}</strong>
        <span className="yz-mono">{bt(board.note)}</span>
      </div>
      <table className="yz-board__table">
        <caption className="yz-sr-only">
          {bt(board.title)} — {bt(board.note)}
        </caption>
        <thead>
          <tr>
            {board.columns.map((column) => (
              <th key={column} scope="col" className="yz-mono">
                {column}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {board.rows.map((row) => (
            <tr key={row.id}>
              <th scope="row">
                <span className="yz-board__avatar" aria-hidden="true">
                  {row.name.charAt(0)}
                </span>
                {bt(row.name)}
              </th>
              <td className="yz-board__visits">{row.visits}</td>
              <td>
                <span className={`yz-board__status yz-board__status--${row.status}`}>
                  {row.statusLabel}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <span className="yz-board__action" aria-hidden="true">
        <Send size={15} strokeWidth={2.4} />
        {board.action}
      </span>
    </div>
  )
}

export default function ProClients() {
  const [playing, setPlaying] = useState(null)
  const { video } = PRO_CLIENTS
  return (
    <section className="yz-section yz-light--alt yz-section--ruled yz-clients" aria-labelledby="yz-clients-title">
      <div className="yz-container">
        <div className="yz-clients__layout">
          <div>
            <SectionHead
              index={PRO_CLIENTS.index}
              eyebrow={PRO_CLIENTS.eyebrow}
              title={PRO_CLIENTS.title}
              lead={PRO_CLIENTS.lead}
              titleId="yz-clients-title"
            />
            <ul className="yz-grid yz-clients__segments">
              {PRO_CLIENTS.segments.map((segment) => (
                <li key={segment.id} className="yz-cell yz-clients__segment">
                  <span className={`yz-board__status yz-board__status--${segment.id}`}>
                    {bt(segment.label)}
                  </span>
                  <p>{bt(segment.text)}</p>
                </li>
              ))}
            </ul>
          </div>

          <div className="yz-clients__board">
            <ClientBoard board={PRO_CLIENTS.board} />
            <button className="yz-network__video yz-clients__video" type="button" onClick={() => setPlaying(0)}>
              <img src={video.video.poster} width="54" height="96" alt="" loading="lazy" />
              <span>
                <span className="yz-mono">Vidéo</span>
                <strong>{video.cta}</strong>
              </span>
              <span className="yz-steps__play-icon" aria-hidden="true">
                <Play size={14} strokeWidth={2.6} />
              </span>
            </button>
          </div>
        </div>

        <div className="yz-clients__ideas">
          <h3 className="yz-clients__ideas-title yz-mono">{PRO_CLIENTS.ideasTitle}</h3>
          <ul>
            {PRO_CLIENTS.ideas.map((idea) => (
              <li key={idea}>« {idea} »</li>
            ))}
          </ul>
          <p className="yz-clients__punch">{bt(PRO_CLIENTS.punchline)}</p>
        </div>
      </div>

      <VideoDrawer items={[video]} index={playing} onChange={setPlaying} onClose={() => setPlaying(null)} kicker="Vidéo" />
    </section>
  )
}
