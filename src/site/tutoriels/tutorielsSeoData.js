import { buildPageSeo } from '../../seo/buildPageSeo.js'
import { SITE, absoluteUrl } from '../../siteConfig.js'
import { TUTORIALS, TUTO_HUB, TUTO_UI, tutoPath } from './tutorielsContent.js'

const UPLOADED = '2026-11-28'
const plain = (text) => text.replaceAll('*', '')
const isoDuration = (sec) => `PT${Math.round(sec)}S`

const videoNode = (t, url) => ({
  '@type': 'VideoObject',
  '@id': `${url}/#video`,
  name: `Tuto ${t.number} — ${t.title}`,
  description: t.lead,
  thumbnailUrl: absoluteUrl(t.video.poster),
  contentUrl: absoluteUrl(t.video.src),
  uploadDate: UPLOADED,
  duration: isoDuration(t.durationSec),
  inLanguage: SITE.lang,
  publisher: { '@id': `${SITE.origin}/#organization` },
})

const howToNode = (t, url) => ({
  '@type': 'HowTo',
  '@id': `${url}/#howto`,
  name: plain(t.question),
  description: t.lead,
  totalTime: isoDuration(t.durationSec),
  inLanguage: SITE.lang,
  video: { '@id': `${url}/#video` },
  step: t.steps.map((s) => ({
    '@type': 'HowToStep',
    position: s.n,
    name: plain(s.title),
    text: s.captions.map(plain).join(' · '),
    image: absoluteUrl(s.shot.src.replace('-360.webp', '-720.webp')),
    url: `${url}#etape-${s.n}`,
  })),
})

export const TUTORIELS_SEO = buildPageSeo({
  path: '/tutoriels',
  title: 'Tutoriels vidéo YuzToo — l’app commerçant en 30 s',
  description:
    'Tous les tutoriels vidéo de l’application commerçant YuzToo : vitrine, plaque NFC, fidélité, notifications, promotions. Étapes illustrées, 30 s chacun.',
  crumb: TUTO_HUB.crumb,
  graph: [
    {
      '@type': 'ItemList',
      name: 'Tutoriels YuzToo en 30 secondes',
      itemListElement: TUTORIALS.map((t, i) => ({
        '@type': 'ListItem',
        position: i + 1,
        name: `Tuto ${t.number} — ${t.title}`,
        url: absoluteUrl(tutoPath(t.slug)),
      })),
    },
  ],
})

export const tutorielSeo = (t) => {
  const path = tutoPath(t.slug)
  const url = absoluteUrl(path)
  return buildPageSeo({
    path,
    title: `${TUTO_UI.kicker} ${t.number} — ${t.title} · YuzToo en 30 s`,
    description: t.seoDescription,
    crumb: `Tuto ${t.number}`,
    parents: [{ name: TUTO_HUB.crumb, path: '/tutoriels' }],
    graph: [videoNode(t, url), howToNode(t, url)],
  })
}
