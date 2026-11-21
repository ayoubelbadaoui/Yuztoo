/**
 * A real app screenshot in a phone frame. `screen` comes from
 * appScreensContent.js. `sizes` tells the browser how wide the phone renders
 * so it picks the 360 or 720 px file.
 */
export default function AppPhone({ screen, className = '', priority = false, sizes = '300px' }) {
  return (
    <figure className={`yz-device ${className}`}>
      <div className="yz-device__screen">
        <img
          src={screen.src}
          srcSet={screen.srcSet}
          sizes={sizes}
          width={screen.width}
          height={screen.height}
          alt={screen.alt}
          loading={priority ? 'eager' : 'lazy'}
          fetchpriority={priority ? 'high' : undefined}
          decoding="async"
        />
        <span className="yz-device__island" aria-hidden="true" />
      </div>
    </figure>
  )
}
