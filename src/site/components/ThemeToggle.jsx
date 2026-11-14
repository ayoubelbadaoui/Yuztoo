import { useEffect, useState } from 'react'
import { Moon, Sun } from 'lucide-react'
import { THEME } from '../sections/navContent.js'

const STORAGE_KEY = 'yz-theme'

/** Both icons are rendered; CSS on html[data-theme] picks one, so SSR markup never mismatches. */
export default function ThemeToggle({ className = '' }) {
  const [dark, setDark] = useState(false)

  useEffect(() => {
    setDark(document.documentElement.getAttribute('data-theme') === 'dark')
  }, [])

  const toggle = () => {
    const next = !dark
    const theme = next ? 'dark' : 'light'
    document.documentElement.setAttribute('data-theme', theme)
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch {
      // Private mode: the choice lasts for this page only.
    }
    setDark(next)
  }

  return (
    <button
      type="button"
      className={`yz-theme-toggle ${className}`}
      aria-pressed={dark}
      onClick={toggle}
    >
      <Moon className="yz-theme-toggle__moon" size={19} strokeWidth={2.2} aria-hidden="true" />
      <Sun className="yz-theme-toggle__sun" size={19} strokeWidth={2.2} aria-hidden="true" />
      <span className="yz-sr-only">{THEME.label}</span>
    </button>
  )
}
