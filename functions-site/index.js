/**
 * websiteLead — the one door for every yuztoo.com form (SEO_HOLY_BOOK §11,
 * SECURITY_HOLY_BOOK §4). Public HTTPS endpoint: origin allowlist, honeypot,
 * schema validation, rate limit by hashed IP and by email, generic errors.
 *
 * Collections (closed to all clients by Firestore rules' default deny):
 *   websiteLeads/{auto}            the lead
 *   websiteLeadLimits/{hash_hour}  counters, deleted by TTL on `expiresAt`
 */

import { createHash } from 'node:crypto'
import { onRequest } from 'firebase-functions/v2/https'
import { defineSecret } from 'firebase-functions/params'
import { logger } from 'firebase-functions'
import { initializeApp } from 'firebase-admin/app'
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore'

initializeApp()
const db = getFirestore()
const HASH_SALT = defineSecret('LEAD_HASH_SALT')

const ORIGINS = new Set([
  'https://yuztoo.com',
  'https://www.yuztoo.com',
  'https://yuztoo.web.app',
  'https://yuztoo-dev.web.app',
  'http://localhost:3001',
  'http://localhost:5173',
  'http://localhost:5050',
])

/** Must match src/data/leadSources.js. */
const SOURCES = new Set([
  'Site web',
  'Site web / Accueil',
  'Site web / Commerçants',
  'Site web / Clients',
  'Site web / Collectivités',
  'Site web / A propos',
  'Site web / Autre page',
])

const KINDS = new Set(['commercant', 'client', 'collectivite', 'contact'])
const FIELDS = new Set(['source', 'kind', 'name', 'email', 'phone', 'organisation', 'message', 'consent', 'website'])
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/
const PHONE = /^[0-9+().\s-]{0,20}$/
const LIMITS = { ip: 5, email: 3 }

const text = (value, max) => (typeof value === 'string' ? value.trim().slice(0, max) : '')

export function validate(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null
  if (Object.keys(body).some((key) => !FIELDS.has(key))) return null
  if (!SOURCES.has(body.source) || !KINDS.has(body.kind) || body.consent !== true) return null

  const lead = {
    source: body.source,
    kind: body.kind,
    name: text(body.name, 80),
    email: text(body.email, 120).toLowerCase(),
    phone: text(body.phone, 20),
    organisation: text(body.organisation, 120),
    message: text(body.message, 1000),
  }
  if (lead.name.length < 2 || !EMAIL.test(lead.email) || !PHONE.test(lead.phone)) return null
  return lead
}

const hash = (value, salt) => createHash('sha256').update(`${salt}:${value}`).digest('hex').slice(0, 32)

async function overLimit(keys) {
  const hour = Math.floor(Date.now() / 3_600_000)
  const expiresAt = Timestamp.fromMillis((hour + 24) * 3_600_000)
  return db.runTransaction(async (tx) => {
    const refs = keys.map(({ id }) => db.collection('websiteLeadLimits').doc(`${id}_${hour}`))
    const snaps = await Promise.all(refs.map((ref) => tx.get(ref)))
    const blocked = snaps.some((snap, i) => (snap.get('count') ?? 0) >= keys[i].max)
    if (!blocked) {
      refs.forEach((ref) => tx.set(ref, { count: FieldValue.increment(1), expiresAt }, { merge: true }))
    }
    return blocked
  })
}

export const websiteLead = onRequest(
  { region: 'europe-west1', secrets: [HASH_SALT], maxInstances: 5, memory: '256MiB', timeoutSeconds: 15 },
  async (req, res) => {
    const origin = req.get('origin') ?? ''
    if (!ORIGINS.has(origin)) {
      res.status(403).json({ ok: false })
      return
    }
    res.set('Access-Control-Allow-Origin', origin)
    res.set('Vary', 'Origin')

    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST')
      res.set('Access-Control-Allow-Headers', 'Content-Type')
      res.set('Access-Control-Max-Age', '3600')
      res.status(204).send('')
      return
    }
    if (req.method !== 'POST') {
      res.status(405).json({ ok: false })
      return
    }

    // Honeypot filled: pretend success, store nothing.
    if (typeof req.body?.website === 'string' && req.body.website.length > 0) {
      res.status(200).json({ ok: true })
      return
    }

    const lead = validate(req.body)
    if (!lead) {
      res.status(400).json({ ok: false })
      return
    }

    try {
      const salt = HASH_SALT.value()
      const blocked = await overLimit([
        { id: `ip_${hash(req.ip ?? 'unknown', salt)}`, max: LIMITS.ip },
        { id: `em_${hash(lead.email, salt)}`, max: LIMITS.email },
      ])
      if (blocked) {
        res.status(429).json({ ok: false })
        return
      }

      await db.collection('websiteLeads').add({
        ...lead,
        consent: true,
        status: 'new',
        createdAt: FieldValue.serverTimestamp(),
      })
      logger.info('websiteLead stored', { source: lead.source, kind: lead.kind })
      res.status(200).json({ ok: true })
    } catch (error) {
      logger.error('websiteLead failed', { code: error?.code })
      res.status(500).json({ ok: false })
    }
  },
)
