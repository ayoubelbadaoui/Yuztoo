import { ArrowRight } from 'lucide-react'
import SiteAmbient from './components/SiteAmbient.jsx'
import SiteHeader from './sections/SiteHeader.jsx'
import SiteFooter from './sections/SiteFooter.jsx'

export default function NotFoundPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/404" />
      <main id="contenu" className="yz-section yz-light yz-notfound">
        <SiteAmbient variant="grid" />
        <div className="yz-container yz-notfound__inner">
          <p className="yz-eyebrow">Erreur 404</p>
          <h1 className="yz-notfound__title">Cette page n’existe pas</h1>
          <p className="yz-lead">Le lien est peut-être ancien, ou la page a été déplacée.</p>
          <a className="yz-btn yz-btn--primary" href="/">
            Retour à l’accueil
            <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
          </a>
        </div>
      </main>
      <SiteFooter />
    </div>
  )
}
