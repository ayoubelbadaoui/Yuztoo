/**
 * This branch is website-only. Fails the build if anything in src/ reaches into
 * the Flutter app or the CRM, or imports Firebase outside src/data.
 *
 * See docs/holy-books/DDD_HOLY_BOOK.md §1 and §6.
 */

import { readdirSync, readFileSync, statSync } from 'node:fs'
import { resolve, dirname, relative } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const srcDir = resolve(root, 'src')

const FORBIDDEN = [
  { pattern: /from\s+['"][^'"]*lib\/feature\//, label: 'Flutter app import' },
  { pattern: /from\s+['"][^'"]*\/crm\//, label: 'CRM import' },
  { pattern: /\.dart['"]/, label: 'Dart file import' },
]

const FIREBASE = /from\s+['"](firebase\/|[^'"]*lib\/firebase)/

function walk(dir) {
  const files = []
  for (const entry of readdirSync(dir)) {
    const full = resolve(dir, entry)
    if (statSync(full).isDirectory()) files.push(...walk(full))
    else if (/\.(js|jsx)$/.test(entry)) files.push(full)
  }
  return files
}

const violations = []

for (const file of walk(srcDir)) {
  const rel = relative(root, file)
  const source = readFileSync(file, 'utf8')

  for (const { pattern, label } of FORBIDDEN) {
    if (pattern.test(source)) violations.push(`${rel}: ${label}`)
  }

  const inDataLayer = rel.startsWith('src/data/') || rel.startsWith('src/lib/')
  if (!inDataLayer && FIREBASE.test(source)) {
    violations.push(`${rel}: Firebase import outside src/data`)
  }
}

if (violations.length > 0) {
  console.error('✗ Isolation check failed:')
  for (const violation of violations) console.error(`  - ${violation}`)
  process.exit(1)
}

console.log('✓ Isolation: no app/CRM code, no Firebase outside src/data')
