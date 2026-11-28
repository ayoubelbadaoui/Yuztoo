import { ChevronRight } from 'lucide-react'

/** `parents`: [{ href, label }] shown between Accueil and the current page. */
export default function Breadcrumb({ current, parents = [] }) {
  return (
    <nav className="yz-crumbs yz-mono" aria-label="Fil d’Ariane">
      <ol>
        <li>
          <a href="/">Accueil</a>
        </li>
        {parents.map((p) => (
          <li key={p.href}>
            <ChevronRight size={12} strokeWidth={2.4} aria-hidden="true" />
            <a href={p.href}>{p.label}</a>
          </li>
        ))}
        <li>
          <ChevronRight size={12} strokeWidth={2.4} aria-hidden="true" />
          <span aria-current="page">{current}</span>
        </li>
      </ol>
    </nav>
  )
}
