import * as functions from "firebase-functions";
import { FieldValue, Firestore, getFirestore } from "firebase-admin/firestore";

// ─── Admin CRM — identity guard + audit trail ────────────────────────────────
//
// Every CRM operation runs here first. The rule the whole back-office rests on:
// the browser never gets database privileges. It holds a normal Firebase Auth
// session carrying an `admin: true` custom claim, and that claim only unlocks
// these callables — never Firestore rules. So the blast radius of a stolen
// admin session is exactly the set of operations implemented in `crm.ts`, and
// every one of them lands in `admin_audit_log`.
//
// The claim is set out-of-band by `tools/firebase/scripts/set_admin_claim.mjs`
// and can never be granted from inside the app: no document write, no callable,
// and no rule path can produce it. Custom claims live in the Auth token, which
// only the Admin SDK can mint.

/** Callables run in europe-west1, matching [purgeAccount] in `index.ts`. */
export const ADMIN_REGION = "europe-west1";

/** Server-only collection; `firestore.rules` denies every client read/write. */
export const AUDIT_LOG_COLLECTION = "admin_audit_log";

/**
 * Destructive actions require the admin to have authenticated recently, so a
 * forgotten open tab or an exfiltrated refresh token cannot delete accounts
 * hours later. The web app catches `failed-precondition` and re-prompts.
 */
const FRESH_AUTH_MAX_AGE_SECONDS = 60 * 60 * 2; // 2 hours

/**
 * App Check attestation binds calls to the real admin web app. Left off until
 * the admin site is registered with App Check (phase 5) — otherwise nothing
 * could call these functions. Flip by setting ADMIN_REQUIRE_APP_CHECK=true in
 * the function environment; no code change needed.
 */
function appCheckRequired(): boolean {
  return process.env.ADMIN_REQUIRE_APP_CHECK === "true";
}

/**
 * Lazy — `index.ts` owns `initializeApp()` and imports this module, so the
 * default app does not exist yet when this file is first evaluated.
 *
 * These modules import from `firebase-admin/firestore` rather than reaching
 * through the `admin.firestore` namespace. Under the Functions emulator the
 * `firebase-admin` module is proxied and the namespace statics
 * (`FieldValue`, `FieldPath`, …) come back `undefined`; the modular entry
 * points are untouched and behave identically in both environments.
 */
function db(): Firestore {
  return getFirestore();
}

export type AdminCaller = {
  uid: string;
  email: string | null;
};

/**
 * Reject anything that is not a signed-in admin. Returns the caller identity so
 * the calling function can stamp it onto the audit entry.
 */
export function assertAdmin(
  context: functions.https.CallableContext
): AdminCaller {
  if (appCheckRequired() && !context.app) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "App Check attestation required."
    );
  }

  const auth = context.auth;
  if (!auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign in required."
    );
  }

  if (auth.token.admin !== true) {
    // Logged at warn level: a non-admin reaching these endpoints at all is
    // worth alerting on, since the admin site is not linked from the app.
    functions.logger.warn("adminGuard: rejected non-admin caller", {
      uid: auth.uid,
      email: auth.token.email ?? null,
    });
    throw new functions.https.HttpsError(
      "permission-denied",
      "Administrator access required."
    );
  }

  return {
    uid: auth.uid,
    email: (auth.token.email as string | undefined) ?? null,
  };
}

/**
 * [assertAdmin] plus a recent-login check. Use for deletes, restores and any
 * other irreversible or high-impact operation.
 */
export function assertFreshAdmin(
  context: functions.https.CallableContext
): AdminCaller {
  const caller = assertAdmin(context);

  const authTime = context.auth?.token.auth_time as number | undefined;
  const ageSeconds = authTime
    ? Math.floor(Date.now() / 1000) - authTime
    : Number.POSITIVE_INFINITY;

  if (ageSeconds > FRESH_AUTH_MAX_AGE_SECONDS) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Please re-authenticate to perform this action."
    );
  }

  return caller;
}

export type AuditEntry = {
  actor: AdminCaller;
  /** Dotted verb, e.g. `merchant.status_changed`, `user.soft_deleted`. */
  action: string;
  targetType: "merchant" | "user" | "system";
  targetId: string;
  /** Prior values of the fields this action touched. */
  before?: Record<string, unknown>;
  /** New values of the fields this action touched. */
  after?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
};

/**
 * Append an immutable record of an admin action.
 *
 * Best-effort by design: the mutation has already been applied by the time we
 * get here, so a logging failure must not surface as a failed operation to the
 * caller — that would invite a retry and a double-apply. It is logged at error
 * level instead, which is what alerting should watch.
 */
export async function writeAuditLog(entry: AuditEntry): Promise<void> {
  try {
    await db()
      .collection(AUDIT_LOG_COLLECTION)
      .add({
        actor_uid: entry.actor.uid,
        actor_email: entry.actor.email,
        action: entry.action,
        target_type: entry.targetType,
        target_id: entry.targetId,
        before: entry.before ?? null,
        after: entry.after ?? null,
        metadata: entry.metadata ?? null,
        created_at: FieldValue.serverTimestamp(),
      });
  } catch (e) {
    functions.logger.error("adminGuard: audit log write failed", {
      action: entry.action,
      targetId: entry.targetId,
      actorUid: entry.actor.uid,
      error: e,
    });
  }
}

/**
 * Narrow an untrusted callable payload to an allowlisted set of fields.
 *
 * Anything not in [allowed] is dropped rather than rejected, so a future web
 * build sending an extra field cannot write it — and cannot fail either.
 * Returns the accepted subset plus the names it discarded (recorded in the
 * audit entry so silent drops stay visible).
 */
export function pickAllowedFields(
  patch: unknown,
  allowed: readonly string[]
): { accepted: Record<string, unknown>; rejected: string[] } {
  if (!patch || typeof patch !== "object" || Array.isArray(patch)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "`patch` must be an object."
    );
  }

  const accepted: Record<string, unknown> = {};
  const rejected: string[] = [];
  const allowedSet = new Set(allowed);

  for (const [key, value] of Object.entries(patch as Record<string, unknown>)) {
    if (value === undefined) continue;
    if (allowedSet.has(key)) {
      accepted[key] = value;
    } else {
      rejected.push(key);
    }
  }

  return { accepted, rejected };
}

/** Read a required non-empty string argument, or throw `invalid-argument`. */
export function requireStringArg(
  data: unknown,
  field: string,
  maxLength = 1500
): string {
  const raw = (data as Record<string, unknown> | undefined)?.[field];
  if (typeof raw !== "string" || raw.trim().length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` is required.`
    );
  }
  const value = raw.trim();
  if (value.length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` exceeds ${maxLength} characters.`
    );
  }
  return value;
}

/** Read an optional string argument, trimmed; empty string becomes null. */
export function optionalStringArg(
  data: unknown,
  field: string,
  maxLength = 1500
): string | null {
  const raw = (data as Record<string, unknown> | undefined)?.[field];
  if (raw === undefined || raw === null) return null;
  if (typeof raw !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` must be a string.`
    );
  }
  const value = raw.trim();
  if (!value) return null;
  if (value.length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `\`${field}\` exceeds ${maxLength} characters.`
    );
  }
  return value;
}

/** Clamp a page-size argument into a sane range. */
export function pageLimitArg(data: unknown, fallback = 25, max = 100): number {
  const raw = (data as Record<string, unknown> | undefined)?.limit;
  if (raw === undefined || raw === null) return fallback;
  const value = Number(raw);
  if (!Number.isFinite(value) || value < 1) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "`limit` must be a positive number."
    );
  }
  return Math.min(Math.floor(value), max);
}
