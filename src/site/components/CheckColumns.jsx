import { Check } from 'lucide-react'

/** Numbered hairline columns of checked items. `columns`: { id, title, items[], note? }. */
export default function CheckColumns({ columns }) {
  return (
    <div className={`yz-grid yz-loyalty__cols yz-loyalty__cols--${columns.length}`}>
      {columns.map((column, i) => (
        <div key={column.id} className="yz-cell yz-loyalty__col">
          <h3 className="yz-loyalty__col-title">
            <span className="yz-mono" aria-hidden="true">
              {String(i + 1).padStart(2, '0')}
            </span>
            {column.title}
          </h3>
          <ul>
            {column.items.map((item) => (
              <li key={item}>
                <Check size={15} strokeWidth={3} aria-hidden="true" />
                {item}
              </li>
            ))}
          </ul>
          {column.note ? <p className="yz-loyalty__note">{column.note}</p> : null}
        </div>
      ))}
    </div>
  )
}
