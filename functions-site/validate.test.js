import { test } from 'node:test'
import assert from 'node:assert/strict'
import { validate } from './index.js'

const ok = { source: 'Site web / Commerçants', kind: 'commercant', name: 'Marie', email: 'Marie@Example.fr', consent: true, website: '' }

test('accepts a valid lead and normalises the email', () => {
  assert.equal(validate(ok).email, 'marie@example.fr')
})

test('rejects unknown fields, sources, kinds and missing consent', () => {
  assert.equal(validate({ ...ok, admin: true }), null)
  assert.equal(validate({ ...ok, source: 'Site web / <script>' }), null)
  assert.equal(validate({ ...ok, kind: 'other' }), null)
  assert.equal(validate({ ...ok, consent: 'yes' }), null)
})

test('rejects bad name, email and phone', () => {
  assert.equal(validate({ ...ok, name: 'M' }), null)
  assert.equal(validate({ ...ok, email: 'nope' }), null)
  assert.equal(validate({ ...ok, phone: 'call me maybe' }), null)
})
