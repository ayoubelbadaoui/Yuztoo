/**
 * Hairline grid of icon cells. `items`: { id, icon, title, text }.
 * `icons` maps the content's icon keys to components, so content stays JSX-free.
 */
export default function IconGrid({ items, icons, columns = 3 }) {
  return (
    <ul className={`yz-grid yz-tools__grid yz-tools__grid--${columns}`}>
      {items.map((item, i) => {
        const Icon = icons[item.icon]
        return (
          <li
            key={item.id}
            className="yz-cell yz-tools__item"
            data-reveal
            style={{ '--d': `${(i % columns) * 0.08}s` }}
          >
            <span className="yz-tile" aria-hidden="true">
              <Icon size={20} strokeWidth={2.1} />
            </span>
            <h3 className="yz-tools__title">{item.title}</h3>
            <p className="yz-tools__text">{item.text}</p>
          </li>
        )
      })}
    </ul>
  )
}
