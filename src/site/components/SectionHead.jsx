import { bt } from './Brand.jsx'
export default function SectionHead({
  index,
  eyebrow,
  title,
  lead,
  align = 'left',
  titleId,
}) {
  return (
    <div className={`yz-head yz-head--${align}`}>
      <p className="yz-eyebrow">
        {index ? <em className="yz-eyebrow__idx">{index}</em> : null}
        {bt(eyebrow)}
      </p>
      <h2 className="yz-h2" id={titleId}>
        {bt(title)}
      </h2>
      {lead ? <p className="yz-lead">{bt(lead)}</p> : null}
    </div>
  )
}
