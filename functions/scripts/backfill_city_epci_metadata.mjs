#!/usr/bin/env node
/**
 * Backfill city_metadata / cities_metadata (EPCI) for existing merchants + users.
 *
 * Usage:
 *   node functions/scripts/backfill_city_epci_metadata.mjs --project yuztoo --dry-run
 *   node functions/scripts/backfill_city_epci_metadata.mjs --project yuztoo
 *   node functions/scripts/backfill_city_epci_metadata.mjs --project yuztoo-dev
 *
 * Does NOT rewrite city display strings. Only adds official geo metadata.
 */
import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const args = process.argv.slice(2);
const projectId = argValue('--project') || 'yuztoo';
const dryRun = args.includes('--dry-run');
const limit = Number(argValue('--limit') || '0') || 0;
const sleepMs = Number(argValue('--sleep-ms') || '80');

function argValue(flag) {
  const i = args.indexOf(flag);
  return i >= 0 ? args[i + 1] : null;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function isPlaceholder(city) {
  const lower = (city || '').trim().toLowerCase();
  return !lower || lower === 'votre ville' || lower === 'à compléter' || lower === 'a completer';
}

async function fetchJson(url, { retries = 4 } = {}) {
  let lastErr;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url);
      if (!res.ok) {
        if (res.status >= 500 && attempt < retries) {
          await sleep(300 * (attempt + 1));
          continue;
        }
        return null;
      }
      return await res.json();
    } catch (err) {
      lastErr = err;
      if (attempt < retries) {
        await sleep(400 * (attempt + 1));
        continue;
      }
    }
  }
  throw lastErr;
}

async function resolveCommune(name) {
  const url = new URL('https://geo.api.gouv.fr/communes');
  url.searchParams.set('nom', name);
  url.searchParams.set('boost', 'population');
  url.searchParams.set('limit', '10');
  url.searchParams.set(
    'fields',
    'nom,code,codesPostaux,population,codeDepartement,codeRegion,codeEpci,centre',
  );
  const list = await fetchJson(url);
  if (!Array.isArray(list) || list.length === 0) return null;

  const exact =
    list.find((c) => (c.nom || '').toLowerCase() === name.toLowerCase()) ||
    list[0];

  let epciName;
  if (exact.codeEpci) {
    try {
      const epci = await fetchJson(
        `https://geo.api.gouv.fr/epcis/${exact.codeEpci}`,
      );
      if (epci?.nom) epciName = epci.nom;
    } catch {
      // non-fatal
    }
  }

  const centre = exact.centre?.coordinates;
  return {
    name: exact.nom || name,
    insee_code: exact.code || undefined,
    postal_codes: Array.isArray(exact.codesPostaux) ? exact.codesPostaux : [],
    population: typeof exact.population === 'number' ? exact.population : undefined,
    department_code: exact.codeDepartement || undefined,
    region_code: exact.codeRegion || undefined,
    epci_code: exact.codeEpci || undefined,
    epci_name: epciName,
    longitude: Array.isArray(centre) ? centre[0] : undefined,
    latitude: Array.isArray(centre) ? centre[1] : undefined,
    source: 'geo.api.gouv.fr',
  };
}

function needsMerchantBackfill(data) {
  const city = (data.city || '').trim();
  if (isPlaceholder(city)) return false;
  const meta = data.city_metadata;
  if (!meta || typeof meta !== 'object') return true;
  return !meta.epci_code;
}

function collectUserCities(data) {
  const out = [];
  const seen = new Set();
  const push = (c) => {
    const t = (c || '').trim();
    if (isPlaceholder(t)) return;
    const key = t.toLowerCase();
    if (seen.has(key)) return;
    seen.add(key);
    out.push(t);
  };
  if (Array.isArray(data.cities)) data.cities.forEach(push);
  push(data.city);
  return out;
}

function needsUserBackfill(data) {
  const cities = collectUserCities(data);
  if (cities.length === 0) return false;
  const meta = data.cities_metadata;
  if (!meta || typeof meta !== 'object') return true;
  for (const city of cities) {
    const entry =
      meta[city] ||
      Object.entries(meta).find(
        ([k]) => k.toLowerCase() === city.toLowerCase(),
      )?.[1];
    if (!entry || typeof entry !== 'object' || !entry.epci_code) return true;
  }
  return false;
}

async function main() {
  if (!getApps().length) {
    initializeApp({
      credential: applicationDefault(),
      projectId,
    });
  }
  const db = getFirestore();
  console.log(`Project=${projectId} dryRun=${dryRun}`);

  const unresolved = new Set();
  let merchantsUpdated = 0;
  let merchantsSkipped = 0;
  let usersUpdated = 0;
  let usersSkipped = 0;

  // --- Merchants ---
  let merchantQuery = db.collection('merchants');
  if (limit > 0) merchantQuery = merchantQuery.limit(limit);
  const merchants = await merchantQuery.get();
  console.log(`Scanning ${merchants.size} merchants…`);

  for (const doc of merchants.docs) {
    const data = doc.data() || {};
    if (!needsMerchantBackfill(data)) {
      merchantsSkipped++;
      continue;
    }
    const city = (data.city || '').trim();
    let resolved;
    try {
      resolved = await resolveCommune(city);
    } catch (err) {
      console.warn(`[merchant ${doc.id}] resolve failed city="${city}": ${err.message}`);
      unresolved.add(city);
      await sleep(sleepMs);
      continue;
    }
    await sleep(sleepMs);
    if (!resolved?.epci_code) {
      unresolved.add(city);
      console.warn(`[merchant ${doc.id}] unresolved city="${city}"`);
      continue;
    }
    console.log(
      `[merchant ${doc.id}] ${city} → epci ${resolved.epci_code} (${resolved.epci_name || '?'})`,
    );
    if (!dryRun) {
      await doc.ref.set(
        {
          city_metadata: resolved,
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    merchantsUpdated++;
  }

  // --- Users ---
  let userQuery = db.collection('users');
  if (limit > 0) userQuery = userQuery.limit(limit);
  const users = await userQuery.get();
  console.log(`Scanning ${users.size} users…`);

  for (const doc of users.docs) {
    const data = doc.data() || {};
    if (!needsUserBackfill(data)) {
      usersSkipped++;
      continue;
    }
    const cities = collectUserCities(data);
    const citiesMetadata = {
      ...(typeof data.cities_metadata === 'object' && data.cities_metadata
        ? data.cities_metadata
        : {}),
    };
    let changed = false;
    for (const city of cities) {
      const existing = citiesMetadata[city];
      if (existing?.epci_code) continue;
      let resolved;
      try {
        resolved = await resolveCommune(city);
      } catch (err) {
        console.warn(`[user ${doc.id}] resolve failed city="${city}": ${err.message}`);
        unresolved.add(city);
        await sleep(sleepMs);
        continue;
      }
      await sleep(sleepMs);
      if (!resolved?.epci_code) {
        unresolved.add(city);
        console.warn(`[user ${doc.id}] unresolved city="${city}"`);
        continue;
      }
      citiesMetadata[city] = resolved;
      changed = true;
      console.log(
        `[user ${doc.id}] ${city} → epci ${resolved.epci_code}`,
      );
    }
    if (!changed) {
      usersSkipped++;
      continue;
    }
    const primary = cities[0];
    const patch = {
      cities_metadata: citiesMetadata,
      updated_at: FieldValue.serverTimestamp(),
    };
    if (primary && citiesMetadata[primary]) {
      patch.city_metadata = citiesMetadata[primary];
    }
    if (!dryRun) {
      await doc.ref.set(patch, { merge: true });
    }
    usersUpdated++;
  }

  console.log('--- summary ---');
  console.log({ merchantsUpdated, merchantsSkipped, usersUpdated, usersSkipped });
  if (unresolved.size) {
    console.log('Unresolved cities:', [...unresolved].sort().join(', '));
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
