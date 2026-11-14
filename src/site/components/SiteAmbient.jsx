/**
 * Flat section texture: 'grid' | 'dots' | 'rules' | 'plain'.
 * No two textured sections touch, and each light texture is used once per page.
 */
export default function SiteAmbient({ variant = 'grid' }) {
  if (variant === 'plain') return null

  return (
    <div className="yz-ambient" aria-hidden="true">
      <div className={`yz-ambient__pattern yz-ambient__pattern--${variant}`} />
      <div className="yz-ambient__edge" />
    </div>
  )
}
