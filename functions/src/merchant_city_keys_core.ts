/**
 * Server-side twin of the app's `CityMatch` (lib/core/utils/city_match.dart).
 *
 * Merchants carry `city_keys`: the normalised keys of their city label, so
 * Découvrir can ask Firestore for "active shops whose city is one of these
 * communes" (`array-contains-any`) instead of scanning the newest N shops of
 * the whole base and filtering on the phone. The two normalisers MUST stay
 * identical, or a shop's stored key will not match the client's key.
 */

const ACCENTS: Record<string, string> = {
  "à": "a", "á": "a", "â": "a", "ä": "a", "ã": "a", "å": "a",
  "ç": "c",
  "è": "e", "é": "e", "ê": "e", "ë": "e",
  "ì": "i", "í": "i", "î": "i", "ï": "i",
  "ñ": "n",
  "ò": "o", "ó": "o", "ô": "o", "ö": "o", "õ": "o",
  "ù": "u", "ú": "u", "û": "u", "ü": "u",
  "ý": "y", "ÿ": "y",
  "œ": "oe", "æ": "ae",
};

const SEPARATORS = /[-'’‘`_.]+/g;
const SPACES = /\s+/;
const LIST_SEPARATORS = /[/,;&+|]/;

/** Same rules as `CityMatch.key`. */
export function cityKey(raw: string): string {
  const lower = raw.trim().toLowerCase();
  if (!lower) return "";
  let out = "";
  for (const ch of lower) out += ACCENTS[ch] ?? ch;
  return out
    .replace(SEPARATORS, " ")
    .trim()
    .split(SPACES)
    .filter((w) => w.length > 0)
    .map((w) => (w === "st" ? "saint" : w === "ste" ? "sainte" : w))
    .join(" ");
}

/** Same rules as `CityMatch.candidateKeys`. */
export function cityCandidateKeys(raw: string): string[] {
  const out = new Set<string>();
  const whole = cityKey(raw);
  if (whole) out.add(whole);
  if (LIST_SEPARATORS.test(raw)) {
    for (const part of raw.split(LIST_SEPARATORS)) {
      const k = cityKey(part);
      if (k) out.add(k);
    }
  }
  return [...out];
}

/**
 * Keys for a merchant document: its free-text `city` plus the official
 * commune name in `city_metadata.name` when present. Sorted for stable
 * comparison (the sync trigger only writes when the set changes).
 */
export function merchantCityKeys(data: Record<string, unknown>): string[] {
  const keys = new Set<string>();
  const city = data.city;
  if (typeof city === "string") {
    for (const k of cityCandidateKeys(city)) keys.add(k);
  }
  const meta = data.city_metadata;
  if (meta && typeof meta === "object") {
    const name = (meta as Record<string, unknown>).name;
    if (typeof name === "string") {
      for (const k of cityCandidateKeys(name)) keys.add(k);
    }
  }
  return [...keys].sort();
}

export function sameKeys(a: unknown, b: string[]): boolean {
  if (!Array.isArray(a) || a.length !== b.length) return false;
  const sorted = [...a].map(String).sort();
  return sorted.every((v, i) => v === b[i]);
}
