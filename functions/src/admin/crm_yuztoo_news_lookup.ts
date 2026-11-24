import { DocumentSnapshot, getFirestore } from "firebase-admin/firestore";
import { optionalStringArg } from "./guard";

// ─── Admin CRM — Actu YuzToo lookups (read-only) ─────────────────────────────
//
// Feeds the CMS editor through `crmBridgeYuztooNews`:
//   • findClient      — pick ONE real client to receive the test preview
//   • searchMerchants — pick the shop an actu button opens (cta_merchant_id)
//
// Results are deliberately minimal (no full email / phone) — the operator
// already typed the identity they are looking for; the CRM only needs enough
// to confirm it is the right account.

const MAX_RESULTS = 10;

export type NewsTestClient = {
  id: string;
  displayName: string;
  contactHint: string | null;
  city: string | null;
};

export type NewsMerchantOption = {
  id: string;
  name: string;
  city: string | null;
  logoUrl: string | null;
  status: string | null;
};

function str(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

/** `ayoub@gmail.com` → `ay***@gmail.com`. Pure — unit tested. */
export function maskEmail(email: string | null): string | null {
  if (!email) return null;
  const at = email.indexOf("@");
  if (at <= 0) return null;
  const local = email.slice(0, at);
  return `${local.slice(0, Math.min(2, local.length))}***${email.slice(at)}`;
}

/** `+33612345678` → `+33 ••• •• 78`. Pure — unit tested. */
export function maskPhone(phone: string | null): string | null {
  if (!phone) return null;
  const digits = phone.replace(/\s+/g, "");
  if (digits.length < 4) return null;
  const prefix =
    ["+212", "+33"].find((code) => digits.startsWith(code)) ?? "";
  return `${prefix} ••• •• ${digits.slice(-2)}`.trim();
}

/**
 * Phone forms an operator may type → stored E.164 candidates.
 * `06 12 34 56 78` tries +33 and +212; `0033…` becomes `+33…`. Pure.
 */
export function phoneCandidates(raw: string): string[] {
  const compact = raw.replace(/[\s.\-()]/g, "");
  if (!/^\+?\d{6,15}$/.test(compact) && !/^00\d{6,15}$/.test(compact)) {
    return [];
  }
  const out = new Set<string>();
  if (compact.startsWith("+")) out.add(compact);
  else if (compact.startsWith("00")) out.add(`+${compact.slice(2)}`);
  else if (compact.startsWith("0")) {
    out.add(`+33${compact.slice(1)}`);
    out.add(`+212${compact.slice(1)}`);
  } else {
    out.add(`+${compact}`);
  }
  out.add(compact);
  return [...out];
}

function capitalize(word: string): string {
  return word ? word.charAt(0).toUpperCase() + word.slice(1).toLowerCase() : word;
}

/**
 * "pascal guyomar" → first-name variants ["pascal","Pascal","PASCAL"],
 * full-name variants for `displayName`, and the last name used for ranking.
 * Pure — unit tested.
 */
export function nameCandidates(raw: string): {
  first: string[];
  full: string[];
  last: string | null;
} {
  const words = raw.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0 || words.some((w) => w.length > 60)) {
    return { first: [], full: [], last: null };
  }
  const variants = (w: string) => [w, w.toLowerCase(), capitalize(w), w.toUpperCase()];
  const fullRaw = words.join(" ");
  return {
    first: [...new Set(variants(words[0]))],
    full: [...new Set([fullRaw, fullRaw.toLowerCase(), words.map(capitalize).join(" ")])],
    last: words.length > 1 ? words.slice(1).join(" ").toLowerCase() : null,
  };
}

/** Matching last names first, then the rest (dedup happens in the caller). */
function rankByLastName(docs: DocumentSnapshot[], last: string | null): DocumentSnapshot[] {
  if (!last) return docs;
  const score = (doc: DocumentSnapshot) => {
    const data = (doc.data() ?? {}) as Record<string, unknown>;
    const name = `${str(data.lastName) ?? ""} ${str(data.displayName) ?? ""}`.toLowerCase();
    return name.includes(last) ? 0 : 1;
  };
  return [...docs].sort((a, b) => score(a) - score(b));
}

/** Display name from the mixed-convention user document. Pure. */
export function clientDisplayName(data: Record<string, unknown>): string {
  const display = str(data.displayName);
  if (display) return display;
  const first = str(data.firstName);
  const last = str(data.lastName);
  const full = [first, last ? `${last.charAt(0)}.` : null]
    .filter(Boolean)
    .join(" ");
  return full || "Client sans nom";
}

function toTestClient(doc: DocumentSnapshot): NewsTestClient | null {
  const data = (doc.data() ?? {}) as Record<string, unknown>;
  if (data.deleted_at) return null;
  return {
    id: doc.id,
    displayName: clientDisplayName(data),
    contactHint: maskEmail(str(data.email)) ?? maskPhone(str(data.phone)),
    city: str(data.city),
  };
}

/** Exact lookup by uid, email or phone — Firestore has no name search. */
export async function findNewsTestClientHandler(
  data: unknown
): Promise<{ items: NewsTestClient[] }> {
  const search = optionalStringArg(data, "search", 320);
  if (!search) return { items: [] };

  const users = getFirestore().collection("users");
  const found = new Map<string, NewsTestClient>();
  const add = (doc: DocumentSnapshot) => {
    const client = toTestClient(doc);
    if (client) found.set(client.id, client);
  };

  if (!search.includes("@") && /^[A-Za-z0-9]{20,128}$/.test(search)) {
    const byId = await users.doc(search).get();
    if (byId.exists) add(byId);
  }

  if (search.includes("@")) {
    const variants = [...new Set([search, search.toLowerCase()])];
    const snaps = await Promise.all(
      variants.map((email) =>
        users.where("email", "==", email).limit(MAX_RESULTS).get()
      )
    );
    snaps.forEach((snap) => snap.docs.forEach(add));
  } else {
    const phones = phoneCandidates(search);
    if (phones.length > 0) {
      const snap = await users
        .where("phone", "in", phones.slice(0, 10))
        .limit(MAX_RESULTS)
        .get();
      snap.docs.forEach(add);
    } else {
      // Exact first name / full display name (no substring search exists).
      const names = nameCandidates(search);
      if (names.first.length > 0) {
        const snaps = await Promise.all([
          users.where("firstName", "in", names.first).limit(30).get(),
          users.where("displayName", "in", names.full).limit(30).get(),
        ]);
        const docs = snaps.flatMap((snap) => snap.docs);
        rankByLastName(docs, names.last).forEach(add);
      }
    }
  }

  return { items: [...found.values()].slice(0, MAX_RESULTS) };
}

/** Shop name prefix search on `name_lowercase` (same as adminListMerchants). */
export async function searchNewsMerchantsHandler(
  data: unknown
): Promise<{ items: NewsMerchantOption[] }> {
  const merchants = getFirestore().collection("merchants");
  const search = optionalStringArg(data, "search", 120)?.toLowerCase() ?? null;
  const id = optionalStringArg(data, "id", 128);

  if (id) {
    const doc = await merchants.doc(id).get();
    const one = doc.exists ? toMerchantOption(doc) : null;
    return { items: one ? [one] : [] };
  }
  if (!search) return { items: [] };

  const snap = await merchants
    .where("name_lowercase", ">=", search)
    .where("name_lowercase", "<", `${search}`)
    .orderBy("name_lowercase")
    .limit(MAX_RESULTS * 2)
    .get();

  const items = snap.docs
    .map(toMerchantOption)
    .filter((m): m is NewsMerchantOption => m !== null)
    .slice(0, MAX_RESULTS);
  return { items };
}

function toMerchantOption(doc: DocumentSnapshot): NewsMerchantOption | null {
  const data = (doc.data() ?? {}) as Record<string, unknown>;
  if (data.deleted_at) return null;
  return {
    id: doc.id,
    name: str(data.display_name) ?? str(data.name) ?? doc.id,
    city: str(data.city),
    logoUrl: str(data.logo_url),
    status: str(data.status),
  };
}
