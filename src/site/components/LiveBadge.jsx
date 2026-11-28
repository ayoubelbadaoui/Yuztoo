/** « En direct » marker for figures read live from the app. */
export default function LiveBadge({ label = 'En direct', className = '' }) {
  return (
    <span
      className={`yz-live ${className}`}
      title="Nombre de vitrines actives dans l’application YuzToo, mis à jour en direct"
    >
      <span className="yz-live__dot" aria-hidden="true" />
      {label}
    </span>
  )
}
