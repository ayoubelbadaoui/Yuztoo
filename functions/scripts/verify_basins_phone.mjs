import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { execSync } from 'child_process';
import { writeFileSync, readFileSync } from 'fs';

if (!getApps().length) {
  initializeApp({ credential: applicationDefault(), projectId: 'yuztoo' });
}
const db = getFirestore();
const uid = 'NcelF0a6d7h7rzTymMbjT1kVVaf2';
const ref = db.collection('users').doc(uid);

function adb(cmd) {
  return execSync(`adb ${cmd}`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}
function sleep(ms) {
  execSync(`sleep ${Math.max(0.1, ms / 1000)}`);
}

function scrapeNames() {
  adb('shell uiautomator dump /sdcard/uidump.xml >/dev/null');
  const xml = execSync('adb exec-out cat /sdcard/uidump.xml', { encoding: 'utf8' });
  const names = new Set();
  const re = /content-desc="([^"]+)"/g;
  let m;
  while ((m = re.exec(xml))) {
    let t = m[1]
      .replace(/&#10;/g, '\n')
      .replace(/&amp;/g, '&')
      .replace(/&#39;/g, "'");
    if (
      /ACCUEIL|DÉCOUV|FIDÉL|ALERT|PROFIL|Découvrir|Recommand|Proche|Associ|Dans votre|Invite|Rechercher|Fond|Informations|Villes|Profil complété|Modifier|Carte Fidélité|Présentez|Tél :|imigo|y y/i.test(
        t,
      )
    ) {
      continue;
    }
    if (!t.trim()) continue;
    const lines = t
      .split('\n')
      .map((s) => s.trim())
      .filter(Boolean);
    const name = lines.length > 1 ? lines[lines.length - 1] : lines[0];
    if (name && name.length > 2 && !/^\d+%$/.test(name)) names.add(name);
  }
  return names;
}

function scrapeAllByScrolling() {
  const all = new Set();
  // scroll up first
  adb('shell input swipe 540 800 540 1600 300');
  sleep(500);
  for (let i = 0; i < 12; i++) {
    for (const n of scrapeNames()) all.add(n);
    adb('shell input swipe 540 1750 540 650 350');
    sleep(700);
  }
  return [...all].sort((a, b) => a.localeCompare(b));
}

async function setCities(cities, existingMeta) {
  const meta = { ...existingMeta };
  for (const c of cities) {
    if (!meta[c] && c === 'Montbéliard') {
      meta[c] = {
        name: 'Montbéliard',
        department_code: '25',
        epci_code: '200065647',
        insee_code: '25388',
        source: 'geo.api.gouv.fr',
        size: 'city',
      };
    }
  }
  await ref.update({ cities, city: cities[0], cities_metadata: meta });
}

function openDiscover(tab) {
  adb('shell am force-stop com.yuztoo.app');
  sleep(800);
  adb('logcat -c');
  adb('shell am start -n com.yuztoo.app/.MainActivity >/dev/null');
  sleep(4000);
  // Découverte tab
  adb('shell input tap 326 2105');
  sleep(2500);
  if (tab === 'proche') adb('shell input tap 609 292');
  if (tab === 'associations') adb('shell input tap 915 292');
  sleep(2500);
}

function readCityKeyLog() {
  const log = execSync(
    'adb logcat -d --pid=$(adb shell pidof -s com.yuztoo.app) 2>/dev/null | rg -i "List merchants by city keys|List merchants for client home|Context:" | tail -40',
    { encoding: 'utf8', shell: '/bin/zsh' },
  );
  return log;
}

const existing = (await ref.get()).data().cities_metadata || {};

const scenarios = [
  {
    name: 'Héricourt only',
    cities: ['Héricourt'],
    expectProcheMin: 1,
    expectProcheExact: ['MN Coiffure'],
    expectAssoc: 0,
  },
  {
    name: 'Petit-Croix (bassin 90)',
    cities: ['Petit-Croix'],
    expectProcheMin: 35,
    expectMustInclude: ['La Coifferie', 'Eau Vive Magasin Bio', 'happy dog'],
    expectMustNotInclude: ['MN Coiffure', 'PIGUET GASTRONOMIE'],
    expectAssocMin: 1,
  },
  {
    name: 'Belfort (bassin 90)',
    cities: ['Belfort'],
    expectProcheMin: 35,
    expectMustInclude: ['La Coifferie', 'Dietplus Belfort'],
    expectMustNotInclude: ['MN Coiffure'],
    expectAssocMin: 1,
  },
  {
    name: 'Montbéliard (EPCI)',
    cities: ['Montbéliard'],
    expectProcheMin: 5,
    expectMustInclude: ['PIGUET GASTRONOMIE', 'Chez Zouzou'],
    expectMustNotInclude: ['La Coifferie', 'MN Coiffure'],
    expectAssoc: 0,
  },
  {
    name: 'Héricourt + Petit-Croix',
    cities: ['Héricourt', 'Petit-Croix'],
    expectProcheMin: 36,
    expectMustInclude: ['MN Coiffure', 'La Coifferie'],
    expectAssocMin: 1,
  },
];

const report = [];

for (const s of scenarios) {
  console.log('\n====', s.name, '====');
  await setCities(s.cities, existing);
  sleep(500);
  openDiscover('proche');
  const proche = scrapeAllByScrolling();
  const logs = readCityKeyLog();
  openDiscover('associations');
  const assoc = scrapeAllByScrolling();

  const row = {
    scenario: s.name,
    cities: s.cities,
    procheCount: proche.length,
    proche,
    assocCount: assoc.length,
    assoc,
    logs: logs.trim().split('\n').slice(-8),
    ok: true,
    failures: [],
  };

  if (s.expectProcheMin && proche.length < s.expectProcheMin) {
    row.ok = false;
    row.failures.push(`proche count ${proche.length} < ${s.expectProcheMin}`);
  }
  if (s.expectProcheExact) {
    for (const n of s.expectProcheExact) {
      if (!proche.some((p) => p.includes(n) || n.includes(p))) {
        row.ok = false;
        row.failures.push(`missing proche: ${n}`);
      }
    }
  }
  if (s.expectMustInclude) {
    for (const n of s.expectMustInclude) {
      if (!proche.some((p) => p.includes(n) || n.includes(p))) {
        row.ok = false;
        row.failures.push(`missing proche: ${n}`);
      }
    }
  }
  if (s.expectMustNotInclude) {
    for (const n of s.expectMustNotInclude) {
      if (proche.some((p) => p.includes(n) || n.includes(p))) {
        row.ok = false;
        row.failures.push(`should NOT show in proche: ${n}`);
      }
    }
  }
  if (s.expectAssoc === 0 && assoc.length > 0) {
    // Associations tab may show empty-state text scraped as noise; filter known empties
    const real = assoc.filter(
      (a) => !/Aucune|association|ville|moment/i.test(a),
    );
    if (real.length > 0) {
      row.ok = false;
      row.failures.push(`assoc expected 0 got ${real.join(', ')}`);
    }
    row.assocCount = real.length;
    row.assoc = real;
  }
  if (s.expectAssocMin && assoc.filter((a) => !/Aucune|moment/i.test(a)).length < s.expectAssocMin) {
    row.ok = false;
    row.failures.push(`assoc count too low: ${assoc.join(' | ')}`);
  }

  console.log(
    JSON.stringify(
      {
        ok: row.ok,
        failures: row.failures,
        procheCount: row.procheCount,
        assocCount: row.assocCount,
        procheSample: row.proche.slice(0, 12),
        assoc: row.assoc,
      },
      null,
      2,
    ),
  );
  report.push(row);
}

writeFileSync('/tmp/yuztoo-basin-report.json', JSON.stringify(report, null, 2));
const passed = report.filter((r) => r.ok).length;
console.log(`\nSUMMARY ${passed}/${report.length} scenarios OK`);
process.exit(passed === report.length ? 0 : 1);
