import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { execSync } from 'child_process';
import { writeFileSync } from 'fs';

if (!getApps().length) {
  initializeApp({ credential: applicationDefault(), projectId: 'yuztoo' });
}
const db = getFirestore();
const uid = 'NcelF0a6d7h7rzTymMbjT1kVVaf2';
const ref = db.collection('users').doc(uid);

const adb = (cmd) =>
  execSync(`adb ${cmd}`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
const sleep = (ms) => execSync(`sleep ${Math.max(0.1, ms / 1000)}`);

async function setCities(cities, existingMeta) {
  const meta = { ...existingMeta };
  if (cities.includes('Montbéliard') && !meta['Montbéliard']) {
    meta['Montbéliard'] = {
      name: 'Montbéliard',
      department_code: '25',
      epci_code: '200065647',
      insee_code: '25388',
      source: 'geo.api.gouv.fr',
      size: 'city',
    };
  }
  await ref.update({ cities, city: cities[0], cities_metadata: meta });
}

function openDiscoverProche() {
  adb('shell am force-stop com.yuztoo.app');
  sleep(1000);
  adb('logcat -c');
  adb('shell am start -n com.yuztoo.app/.MainActivity >/dev/null');
  sleep(5000);
  // bottom Découverte
  adb('shell input tap 326 2105');
  sleep(2000);
  // Proche de moi chip
  adb('shell input tap 609 292');
  sleep(5000);
  // pull to refresh
  adb('shell input swipe 540 700 540 1500 400');
  sleep(5000);
}

function parseLogs() {
  const pid = adb('shell pidof -s com.yuztoo.app').trim();
  const log = execSync(`adb logcat -d --pid=${pid}`, { encoding: 'utf8' });
  const lines = log.split('\n');
  const hits = [];
  for (let i = 0; i < lines.length; i++) {
    if (/List merchants by city keys/i.test(lines[i])) {
      // context often on nearby lines
      const ctx = lines.slice(i, i + 6).join(' ');
      const count = ctx.match(/count[:\s]+(\d+)/i);
      const keys = ctx.match(/keys[:\s]+(\d+)/i);
      hits.push({
        count: count ? Number(count[1]) : null,
        keys: keys ? Number(keys[1]) : null,
        raw: ctx.slice(0, 240),
      });
    }
    if (/List merchants for client home/i.test(lines[i])) {
      const ctx = lines.slice(i, i + 6).join(' ');
      const count = ctx.match(/count[:\s]+(\d+)/i);
      const cityFilter = ctx.match(/cityFilter[:\s]+([^,}]+)/i);
      hits.push({
        type: 'legacy',
        count: count ? Number(count[1]) : null,
        cityFilter: cityFilter ? cityFilter[1].trim() : null,
        raw: ctx.slice(0, 240),
      });
    }
  }
  return hits;
}

function screenshot(tag) {
  execSync(
    `adb exec-out screencap -p > /tmp/yuztoo-phone/verify_${tag}.png`,
  );
  adb('shell uiautomator dump /sdcard/uidump.xml >/dev/null');
  const xml = execSync('adb exec-out cat /sdcard/uidump.xml', {
    encoding: 'utf8',
  });
  writeFileSync(`/tmp/yuztoo-phone/verify_${tag}.xml`, xml);
  const names = [];
  const re = /content-desc="([^"]+)"/g;
  let m;
  while ((m = re.exec(xml))) {
    const t = m[1]
      .replace(/&#10;/g, ' | ')
      .replace(/&amp;/g, '&');
    if (/Découvrir|Proche|Dans votre région|MN Coiffure|Coifferie|PIGUET|Zouzou|Eau Vive|happy dog|Aucun commerce|Associ/i.test(t)) {
      names.push(t.slice(0, 120));
    }
  }
  return names;
}

const existing = (await ref.get()).data().cities_metadata || {};

const scenarios = [
  { name: 'hericourt', cities: ['Héricourt'], expectCount: 1 },
  { name: 'petit_croix', cities: ['Petit-Croix'], expectCount: 39 }, // includes association in city catalogue before proche filter
  { name: 'belfort', cities: ['Belfort'], expectCount: 39 },
  { name: 'montbeliard', cities: ['Montbéliard'], expectCount: 5 },
  { name: 'heri_petit', cities: ['Héricourt', 'Petit-Croix'], expectCount: 40 },
];

const report = [];
for (const s of scenarios) {
  console.log('\n====', s.name, s.cities.join('+'), '====');
  await setCities(s.cities, existing);
  sleep(800);
  openDiscoverProche();
  const hits = parseLogs();
  const ui = screenshot(s.name);
  const cityKeyHits = hits.filter((h) => h.count != null && !h.type);
  const last = cityKeyHits.at(-1) || hits.filter((h) => h.count != null).at(-1);
  const loaded = last?.count ?? null;
  const ok = loaded === s.expectCount;
  const row = {
    scenario: s.name,
    cities: s.cities,
    expectCount: s.expectCount,
    loadedCount: loaded,
    ok,
    logHits: hits.slice(-5),
    uiHints: ui.slice(0, 15),
  };
  console.log(JSON.stringify(row, null, 2));
  report.push(row);
}

writeFileSync('/tmp/yuztoo-basin-log-report.json', JSON.stringify(report, null, 2));
const pass = report.filter((r) => r.ok).length;
console.log(`\nSUMMARY ${pass}/${report.length} count-match OK`);
process.exit(pass === report.length ? 0 : 2);
