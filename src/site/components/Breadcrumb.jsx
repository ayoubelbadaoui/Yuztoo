import { ChevronRight } from 'lucide-react'

export default function Breadcrumb({ current }) {
  return (
    <nav className="yz-crumbs yz-mono" aria-label="Fil d’Ariane">
      <ol>
        <li>
          <a href="/">Accueil</a>
        </li>
        <li>
          <ChevronRight size={12} strokeWidth={2.4} aria-hidden="true" />
          <span aria-current="page">{current}</span>
        </li>
      </ol>
    </nav>
  )
}
