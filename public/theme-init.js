// Blocking, same-origin (CSP script-src 'self'): sets the theme before first paint.
;(function () {
  try {
    var theme = localStorage.getItem('yz-theme')
    if (theme !== 'light' && theme !== 'dark') {
      theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    }
    document.documentElement.setAttribute('data-theme', theme)
  } catch (e) {
    document.documentElement.setAttribute('data-theme', 'light')
  }
})()
