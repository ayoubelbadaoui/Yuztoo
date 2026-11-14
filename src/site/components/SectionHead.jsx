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
        {eyebrow}
      </p>
      <h2 className="yz-h2" id={titleId}>
        {title}
      </h2>
      {lead ? <p className="yz-lead">{lead}</p> : null}
    </div>
  )
}
