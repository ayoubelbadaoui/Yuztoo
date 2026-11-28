import { hydrateRoot, createRoot } from 'react-dom/client'
import '@fontsource/montserrat/latin-400.css'
import '@fontsource/montserrat/latin-500.css'
import '@fontsource/montserrat/latin-600.css'
import '@fontsource/montserrat/latin-700.css'
import '@fontsource/montserrat/latin-800.css'
import '@fontsource/jetbrains-mono/latin-500.css'
import '@fontsource/jetbrains-mono/latin-700.css'
import './global.css'
import './site/styles/header.css'
import './site/styles/hero.css'
import './site/styles/sections-a.css'
import './site/styles/sections-b.css'
import './site/styles/commercants-a.css'
import './site/styles/commercants-b.css'
import './site/styles/pages.css'
import './site/styles/forms.css'
import './site/styles/app.css'
import './site/styles/launch.css'
import './site/styles/tutoriels.css'
import './site/styles/footer.css'
import './site/styles/responsive.css'
import './site/styles/theme-dark.css'
import { findRoute } from './routes.js'
import NotFoundPage from './site/NotFoundPage.jsx'
import { armReveal } from './site/reveal.js'

const container = document.getElementById('root')
const route = findRoute(window.location.pathname)
const Page = route ? route.Component : NotFoundPage

// The prerenderer marks server-rendered markup so we hydrate it instead of
// throwing it away. Without this the first paint flashes.
if (container.dataset.ssr === 'true') {
  hydrateRoot(container, <Page />)
} else {
  createRoot(container).render(<Page />)
}

requestAnimationFrame(armReveal)
