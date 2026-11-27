import { useEffect, useState } from 'react'
import { ArrowRight, ArrowUpRight, Mail, MapPin, Menu, Phone, X } from 'lucide-react'
import { CONTACT } from '../../siteConfig.js'
import ThemeToggle from '../components/ThemeToggle.jsx'
import { LOGO, NAV_CTA, NAV_LINKS, UTILITY } from './navContent.js'
import { bt } from '../components/Brand.jsx'

// Two thresholds so the bar does not flicker when the page rests near one.
const CONDENSE_AT = 24
const RELEASE_AT = 8

function useCondensed() {
  const [condensed, setCondensed] = useState(false)

  useEffect(() => {
    let frame = 0
    const update = () => {
      frame = 0
      const y = window.scrollY
      setCondensed((current) => (current ? y > RELEASE_AT : y > CONDENSE_AT))
    }
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(update)
    }
    update()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => {
      window.removeEventListener('scroll', onScroll)
      if (frame) cancelAnimationFrame(frame)
    }
  }, [])

  return condensed
}

function useDrawer() {
  const [open, setOpen] = useState(false)

  useEffect(() => {
    if (!open) return undefined
    const root = document.documentElement
    const onKey = (event) => {
      if (event.key === 'Escape') setOpen(false)
    }
    const desktop = window.matchMedia('(min-width: 901px)')
    const onDesktop = (event) => {
      if (event.matches) setOpen(false)
    }
    root.classList.add('yz-menu-open')
    document.addEventListener('keydown', onKey)
    desktop.addEventListener('change', onDesktop)
    return () => {
      root.classList.remove('yz-menu-open')
      document.removeEventListener('keydown', onKey)
      desktop.removeEventListener('change', onDesktop)
    }
  }, [open])

  return [open, setOpen]
}

function Logo() {
  return (
    <a className="yz-logo" href="/" aria-label="YuzToo, accueil">
      <img src={LOGO.src} width={LOGO.width} height={LOGO.height} alt="" />
      <span className="yz-logo__word" aria-hidden="true">
        Yuz<span>Too</span>
      </span>
    </a>
  )
}

function UtilityStrip() {
  return (
    <div className="yz-utility">
      <div className="yz-utility__inner">
        <a className="yz-utility__item" href={`mailto:${CONTACT.email}`}>
          <Mail size={13} strokeWidth={2.2} aria-hidden="true" />
          {CONTACT.email}
        </a>
        <span className="yz-utility__sep" aria-hidden="true" />
        <span className="yz-utility__item">
          <MapPin size={13} strokeWidth={2.2} aria-hidden="true" />
          {UTILITY.location}
        </span>
        <span className="yz-utility__sep yz-utility__sep--promise" aria-hidden="true" />
        <span className="yz-utility__item yz-utility__item--promise">{UTILITY.promise}</span>
        <span className="yz-utility__status">
          <span className="yz-utility__pulse" aria-hidden="true" />
          {UTILITY.network}
        </span>
      </div>
    </div>
  )
}

export default function SiteHeader({ currentPath = '/' }) {
  const condensed = useCondensed()
  const [open, setOpen] = useDrawer()
  const close = () => setOpen(false)

  const headerClass = [
    'yz-header',
    condensed ? 'is-condensed' : '',
    open ? 'is-menu-open' : '',
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <>
      <UtilityStrip />
      <header className={headerClass}>
        <div className="yz-bar">
          <Logo />

          <nav className="yz-nav" aria-label="Navigation principale">
            {NAV_LINKS.map((link) => {
              const active = link.href === currentPath
              return (
                <a
                  key={link.href}
                  className={`yz-nav__link${active ? ' is-active' : ''}`}
                  href={link.href}
                  aria-current={active ? 'page' : undefined}
                >
                  {bt(link.label)}
                </a>
              )
            })}
          </nav>

          <div className="yz-actions">
            <ThemeToggle />
            <a className="yz-cta" href={NAV_CTA.href}>
              {bt(NAV_CTA.label)}
              <span className="yz-cta__arrow" aria-hidden="true">
                <ArrowUpRight size={16} strokeWidth={2.4} />
              </span>
            </a>
            <button
              type="button"
              className="yz-burger"
              aria-expanded={open}
              aria-controls="yz-drawer"
              onClick={() => setOpen((value) => !value)}
            >
              {open ? <X size={22} aria-hidden="true" /> : <Menu size={22} aria-hidden="true" />}
              <span className="yz-sr-only">{open ? 'Fermer le menu' : 'Ouvrir le menu'}</span>
            </button>
          </div>
        </div>

        <div className={`yz-drawer${open ? ' is-open' : ''}`} id="yz-drawer">
          <nav className="yz-drawer__nav" aria-label="Navigation mobile">
            {NAV_LINKS.map((link, i) => {
              const active = link.href === currentPath
              return (
                <a
                  key={link.href}
                  className={`yz-drawer__link${active ? ' is-active' : ''}`}
                  href={link.href}
                  aria-current={active ? 'page' : undefined}
                  style={{ '--i': i }}
                  onClick={close}
                >
                  <span>
                    <em className="yz-drawer__idx">{String(i + 1).padStart(2, '0')}</em>
                    {bt(link.label)}
                  </span>
                  <ArrowRight size={18} aria-hidden="true" />
                </a>
              )
            })}
          </nav>
          <div className="yz-drawer__quick">
            <a className="yz-drawer__chip" href={`mailto:${CONTACT.email}`}>
              <Mail size={16} aria-hidden="true" />
              E-mail
            </a>
            <a className="yz-drawer__chip" href={`tel:${CONTACT.phone}`}>
              <Phone size={16} aria-hidden="true" />
              Appeler
            </a>
          </div>
          <a className="yz-cta yz-cta--block" href={NAV_CTA.href} onClick={close}>
            {bt(NAV_CTA.label)}
            <span className="yz-cta__arrow" aria-hidden="true">
              <ArrowUpRight size={18} strokeWidth={2.4} />
            </span>
          </a>
          <p className="yz-drawer__meta">
            <MapPin size={13} aria-hidden="true" />
            {UTILITY.location}
          </p>
        </div>
      </header>
    </>
  )
}
