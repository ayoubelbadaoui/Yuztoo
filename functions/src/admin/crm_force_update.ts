import * as functions from "firebase-functions";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import {
  ADMIN_REGION,
  assertAdmin,
  assertFreshAdmin,
  writeAuditLog,
} from "./guard";
import { toJsonValue } from "./serialize";

// ─── Admin CRM — force update gate (`app_config/force_update`) ───────────────
//
// Sales CMS publishes platform min build numbers after a store release is
// approved. Flutter compares PackageInfo.buildNumber automatically and hard-
// blocks when installed < min and `force === true`.

const DOC_PATH = { collection: "app_config", id: "force_update" } as const;

function db() {
  return getFirestore();
}

function forceUpdateRef() {
  return db().collection(DOC_PATH.collection).doc(DOC_PATH.id);
}

export type ForceUpdatePayload = {
  force: boolean;
  android_min_build: number;
  ios_min_build: number;
  message_fr: string | null;
  android_store_url: string | null;
  ios_store_url: string | null;
};

export const FORCE_UPDATE_DEFAULTS: ForceUpdatePayload = {
  force: false,
  android_min_build: 0,
  ios_min_build: 0,
  message_fr: null,
  android_store_url: null,
  ios_store_url: null,
};

/** Pure helper — shared with unit tests. */
export function normalizeForceUpdateInput(
  data: unknown
): ForceUpdatePayload {
  const raw = (data ?? {}) as Record<string, unknown>;

  const force = raw.force === true;

  const androidMin = asNonNegInt(raw.android_min_build, "android_min_build");
  const iosMin = asNonNegInt(raw.ios_min_build, "ios_min_build");

  return {
    force,
    android_min_build: androidMin,
    ios_min_build: iosMin,
    message_fr: optionalTrimmed(raw.message_fr, "message_fr", 800),
    android_store_url: optionalUrl(raw.android_store_url, "android_store_url"),
    ios_store_url: optionalUrl(raw.ios_store_url, "ios_store_url"),
  };
}

function asNonNegInt(raw: unknown, field: string): number {
  if (raw === undefined || raw === null) return 0;
  const n = typeof raw === "number" ? raw : Number(raw);
  if (!Number.isFinite(n) || n < 0 || !Number.isInteger(n)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` must be a non-negative integer.`
    );
  }
  return n;
}

function optionalTrimmed(
  raw: unknown,
  field: string,
  max: number
): string | null {
  if (raw === undefined || raw === null) return null;
  if (typeof raw !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` must be a string.`
    );
  }
  const v = raw.trim();
  if (!v) return null;
  if (v.length > max) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` exceeds ${max} characters.`
    );
  }
  return v;
}

function optionalUrl(raw: unknown, field: string): string | null {
  const v = optionalTrimmed(raw, field, 2000);
  if (!v) return null;
  if (!/^https?:\/\//i.test(v)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` must be an http(s) URL.`
    );
  }
  return v;
}

function docToPayload(
  data: Record<string, unknown> | undefined
): ForceUpdatePayload {
  if (!data) return { ...FORCE_UPDATE_DEFAULTS };
  return {
    force: data.force === true,
    android_min_build:
      typeof data.android_min_build === "number" ? data.android_min_build : 0,
    ios_min_build:
      typeof data.ios_min_build === "number" ? data.ios_min_build : 0,
    message_fr:
      typeof data.message_fr === "string" && data.message_fr.trim()
        ? data.message_fr.trim()
        : null,
    android_store_url:
      typeof data.android_store_url === "string" &&
      data.android_store_url.trim()
        ? data.android_store_url.trim()
        : null,
    ios_store_url:
      typeof data.ios_store_url === "string" && data.ios_store_url.trim()
        ? data.ios_store_url.trim()
        : null,
  };
}

export const adminGetForceUpdate = functions
  .region(ADMIN_REGION)
  .https.onCall(async (_data, context) => {
    assertAdmin(context);
    const snap = await forceUpdateRef().get();
    const raw = snap.data() as Record<string, unknown> | undefined;
    const payload = docToPayload(raw);
    return {
      id: DOC_PATH.id,
      exists: snap.exists,
      ...(toJsonValue(payload) as Record<string, unknown>),
      updated_at: toJsonValue(raw?.updated_at ?? null),
      updated_by: raw?.updated_by ?? null,
    };
  });

/**
 * Upsert the force-update gate. Requires a fresh admin session — flipping
 * this on locks every outdated install out of the product.
 */
export const adminSetForceUpdate = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);
    const next = normalizeForceUpdateInput(data);

    const ref = forceUpdateRef();
    const beforeSnap = await ref.get();
    const before = docToPayload(
      beforeSnap.data() as Record<string, unknown> | undefined
    );

    await ref.set(
      {
        ...next,
        updated_at: FieldValue.serverTimestamp(),
        updated_by: caller.uid,
      },
      { merge: true }
    );

    await writeAuditLog({
      actor: caller,
      action: "force_update.set",
      targetType: "system",
      targetId: DOC_PATH.id,
      before: before as unknown as Record<string, unknown>,
      after: next as unknown as Record<string, unknown>,
    });

    return {
      id: DOC_PATH.id,
      ...(toJsonValue(next) as Record<string, unknown>),
    };
  });
