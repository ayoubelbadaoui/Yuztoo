import * as functions from "firebase-functions";
import {
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {
  ADMIN_REGION,
  AdminCaller,
  assertAdmin,
  assertFreshAdmin,
  optionalStringArg,
  pageLimitArg,
  requireStringArg,
  writeAuditLog,
} from "./guard";
import { docToJson, toJsonValue } from "./serialize";
import {
  findNewsTestClientHandler,
  searchNewsMerchantsHandler,
} from "./crm_yuztoo_news_lookup";

// ─── Admin CRM — Actu YuzToo (`yuztoo_news/{id}`) ────────────────────────────
//
// Flutter dual-query (live + preview for test UID). Writers:
//   • onCall admin* (Firebase Auth admin claim)
//   • crmBridgeYuztooNews HTTPS (CRM_BRIDGE_SECRET from Supabase Edge)

const COLLECTION = "yuztoo_news";

type ReleaseStatus = "draft" | "preview" | "live";

function db() {
  return getFirestore();
}

function newsCol() {
  return db().collection(COLLECTION);
}

function normalizeReleaseStatus(raw: unknown): ReleaseStatus {
  if (raw === "draft" || raw === "preview" || raw === "live") return raw;
  return "live";
}

export type YuztooNewsInput = {
  title: string;
  body: string;
  publish_on: Timestamp;
  active: boolean;
  image_url: string | null;
  cta_label: string | null;
  cta_url: string | null;
  cta_merchant_id: string | null;
  /** Shop name shown in the CMS next to `cta_merchant_id` (app ignores it). */
  cta_merchant_label: string | null;
};

/** Pure helper — shared with unit tests. */
export function parseYuztooNewsInput(data: unknown): YuztooNewsInput {
  const title = requireStringArg(data, "title", 200);
  const body = requireStringArg(data, "body", 8000);
  const active = (data as Record<string, unknown> | undefined)?.active !== false;

  const publishRaw = (data as Record<string, unknown> | undefined)?.publish_on;
  let publishOn: Timestamp;
  if (
    publishRaw &&
    typeof publishRaw === "object" &&
    typeof (publishRaw as { toDate?: unknown }).toDate === "function"
  ) {
    publishOn = publishRaw as Timestamp;
  } else if (typeof publishRaw === "string" && publishRaw.trim()) {
    const d = new Date(publishRaw);
    if (Number.isNaN(d.getTime())) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "`publish_on` must be an ISO date string."
      );
    }
    publishOn = Timestamp.fromDate(d);
  } else if (
    publishRaw &&
    typeof publishRaw === "object" &&
    typeof (publishRaw as { seconds?: unknown }).seconds === "number"
  ) {
    publishOn = new Timestamp(
      (publishRaw as { seconds: number }).seconds,
      typeof (publishRaw as { nanoseconds?: unknown }).nanoseconds === "number"
        ? (publishRaw as { nanoseconds: number }).nanoseconds
        : 0
    );
  } else {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "`publish_on` is required (ISO string)."
    );
  }

  const imageUrl = optionalStringArg(data, "image_url", 2000);
  const ctaLabel = optionalStringArg(data, "cta_label", 80);
  const ctaUrl = optionalStringArg(data, "cta_url", 2000);
  const ctaMerchantId = optionalStringArg(data, "cta_merchant_id", 128);
  const ctaMerchantLabel = optionalStringArg(data, "cta_merchant_label", 120);

  if (ctaUrl && !/^https?:\/\//i.test(ctaUrl)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "`cta_url` must be an http(s) URL."
    );
  }
  if (imageUrl && !/^https?:\/\//i.test(imageUrl)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "`image_url` must be an http(s) URL."
    );
  }

  return {
    title,
    body,
    publish_on: publishOn,
    active,
    image_url: imageUrl,
    // No target → no button: a lone label would be a dead field.
    cta_label: ctaMerchantId || ctaUrl ? ctaLabel : null,
    cta_url: ctaUrl,
    cta_merchant_id: ctaMerchantId,
    cta_merchant_label: ctaMerchantId ? ctaMerchantLabel : null,
  };
}

/** Pure helper — shared with unit tests. */
export function canPublishYuztooNewsLive(data: {
  release_status?: unknown;
  test_account_id?: unknown;
  preview_activated_at?: unknown;
}): boolean {
  return (
    normalizeReleaseStatus(data.release_status) === "preview" &&
    typeof data.test_account_id === "string" &&
    data.test_account_id.trim().length > 0 &&
    data.preview_activated_at != null
  );
}

// ─── Shared handlers (callable + HTTPS bridge) ───────────────────────────────

export async function listYuztooNewsHandler(data: unknown): Promise<{
  items: Record<string, unknown>[];
}> {
  const limit = pageLimitArg(data, 50, 100);
  const includeInactive =
    (data as Record<string, unknown> | undefined)?.includeInactive === true;

  let query = newsCol().orderBy("publish_on", "desc").limit(limit);
  if (!includeInactive) {
    query = newsCol()
      .where("active", "==", true)
      .orderBy("publish_on", "desc")
      .limit(limit);
  }

  const snap = await query.get();
  const backfill = snap.docs.filter(
    (d) => !("release_status" in (d.data() ?? {}))
  );
  if (backfill.length > 0) {
    const batch = db().batch();
    for (const doc of backfill) {
      batch.set(
        doc.ref,
        {
          release_status: "live",
          test_account_id: null,
          test_account_label: null,
          preview_activated_at: null,
          live_at: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
    await batch.commit();
  }

  const fresh = backfill.length > 0 ? await query.get() : snap;
  return { items: fresh.docs.map((d) => docToJson(d)) };
}

export async function upsertYuztooNewsHandler(
  data: unknown,
  caller: AdminCaller
): Promise<Record<string, unknown>> {
  const input = parseYuztooNewsInput(data);
  const idRaw = (data as Record<string, unknown> | undefined)?.id;
  const id =
    typeof idRaw === "string" && idRaw.trim() ? idRaw.trim() : null;

  const ref = id ? newsCol().doc(id) : newsCol().doc();
  const beforeSnap = id ? await ref.get() : null;
  const before = beforeSnap?.exists ? beforeSnap.data() ?? {} : null;
  const prevStatus = before
    ? normalizeReleaseStatus(before.release_status)
    : null;
  const wasLive = prevStatus === "live";
  const releaseFields = before
    ? {
        release_status: wasLive ? ("draft" as ReleaseStatus) : prevStatus!,
        preview_activated_at: wasLive
          ? null
          : before.preview_activated_at ?? null,
        live_at: wasLive ? null : before.live_at ?? null,
        test_account_id: before.test_account_id ?? null,
        test_account_label: before.test_account_label ?? null,
      }
    : {
        release_status: "draft" as ReleaseStatus,
        test_account_id: null,
        test_account_label: null,
        preview_activated_at: null,
        live_at: null,
      };

  const payload = {
    ...input,
    ...releaseFields,
    updated_at: FieldValue.serverTimestamp(),
    updated_by: caller.uid,
    ...(beforeSnap?.exists
      ? {}
      : {
          created_at: FieldValue.serverTimestamp(),
          created_by: caller.uid,
        }),
  };

  await ref.set(payload, { merge: true });

  await writeAuditLog({
    actor: caller,
    action: beforeSnap?.exists ? "yuztoo_news.updated" : "yuztoo_news.created",
    targetType: "system",
    targetId: ref.id,
    before: beforeSnap?.exists
      ? (toJsonValue(beforeSnap.data() ?? {}) as Record<string, unknown>)
      : undefined,
    after: toJsonValue({
      id: ref.id,
      ...input,
      release_status: releaseFields.release_status,
    }) as Record<string, unknown>,
  });

  const after = await ref.get();
  return docToJson(after);
}

export async function setYuztooNewsReleaseHandler(
  data: unknown,
  caller: AdminCaller
): Promise<Record<string, unknown>> {
  const id = requireStringArg(data, "id", 128);
  const payload = (data ?? {}) as Record<string, unknown>;
  const status = String(
    payload.release_status ?? payload.status ?? ""
  ).trim() as ReleaseStatus;
  if (!["draft", "preview", "live"].includes(status)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "release_status must be draft, preview, or live."
    );
  }

  const ref = newsCol().doc(id);
  const beforeSnap = await ref.get();
  if (!beforeSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Actu not found.");
  }
  const current = beforeSnap.data() ?? {};
  const currentStatus = normalizeReleaseStatus(current.release_status);

  let testAccountId =
    payload.test_account_id === undefined
      ? typeof current.test_account_id === "string"
        ? current.test_account_id
        : null
      : payload.test_account_id === null
        ? null
        : String(payload.test_account_id).trim() || null;
  let testAccountLabel =
    payload.test_account_label === undefined
      ? typeof current.test_account_label === "string"
        ? current.test_account_label
        : null
      : payload.test_account_label === null
        ? null
        : String(payload.test_account_label).trim() || null;

  // A test send must reach a real phone: the uid has to be a live client.
  if (testAccountId && testAccountId !== current.test_account_id) {
    const userSnap = await db().collection("users").doc(testAccountId).get();
    if (!userSnap.exists || userSnap.data()?.deleted_at) {
      throw new functions.https.HttpsError(
        "not-found",
        "Test account is not an existing Yuztoo client."
      );
    }
  }

  if (status === "preview") {
    if (!testAccountId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Select a test account before activating preview."
      );
    }
    if (currentStatus === "live") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Actu is already live. Revert to draft before a new preview."
      );
    }
  }

  if (status === "live") {
    const ready = canPublishYuztooNewsLive({
      release_status: currentStatus,
      test_account_id: current.test_account_id,
      preview_activated_at: current.preview_activated_at,
    });
    if (!ready) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Publish blocked: activate preview with a test account first."
      );
    }
    testAccountId =
      typeof current.test_account_id === "string"
        ? current.test_account_id
        : null;
    testAccountLabel =
      typeof current.test_account_label === "string"
        ? current.test_account_label
        : null;
  }

  const next: Record<string, unknown> = {
    release_status: status,
    test_account_id: testAccountId,
    test_account_label: testAccountLabel,
    updated_at: FieldValue.serverTimestamp(),
    updated_by: caller.uid,
    preview_activated_at:
      status === "preview"
        ? FieldValue.serverTimestamp()
        : status === "live"
          ? current.preview_activated_at ?? null
          : null,
    live_at: status === "live" ? FieldValue.serverTimestamp() : null,
    ...(status === "preview" || status === "live" ? { active: true } : {}),
  };

  await ref.set(next, { merge: true });

  await writeAuditLog({
    actor: caller,
    action: "yuztoo_news.release_set",
    targetType: "system",
    targetId: id,
    before: {
      release_status: currentStatus,
      test_account_id: current.test_account_id ?? null,
    },
    after: { release_status: status, test_account_id: testAccountId },
  });

  const after = await ref.get();
  return docToJson(after);
}

export async function setYuztooNewsActiveHandler(
  data: unknown,
  caller: AdminCaller
): Promise<Record<string, unknown>> {
  const id = requireStringArg(data, "id", 128);
  const active = (data as Record<string, unknown>).active === true;

  const ref = newsCol().doc(id);
  const before = await ref.get();
  if (!before.exists) {
    throw new functions.https.HttpsError("not-found", "Actu not found.");
  }

  const patch: Record<string, unknown> = {
    active,
    updated_at: FieldValue.serverTimestamp(),
    updated_by: caller.uid,
  };
  if (!("release_status" in (before.data() ?? {}))) {
    patch.release_status = "live";
    patch.test_account_id = null;
    patch.test_account_label = null;
    patch.preview_activated_at = null;
    patch.live_at = FieldValue.serverTimestamp();
  }

  await ref.update(patch);

  await writeAuditLog({
    actor: caller,
    action: "yuztoo_news.active_set",
    targetType: "system",
    targetId: id,
    before: { active: before.data()?.active === true },
    after: { active },
  });

  const after = await ref.get();
  return docToJson(after);
}

export async function deleteYuztooNewsHandler(
  data: unknown,
  caller: AdminCaller
): Promise<{ id: string; deleted: true }> {
  const id = requireStringArg(data, "id", 128);
  const ref = newsCol().doc(id);
  const before = await ref.get();
  if (!before.exists) {
    throw new functions.https.HttpsError("not-found", "Actu not found.");
  }

  await ref.delete();

  await writeAuditLog({
    actor: caller,
    action: "yuztoo_news.deleted",
    targetType: "system",
    targetId: id,
    before: toJsonValue(before.data() ?? {}) as Record<string, unknown>,
  });

  return { id, deleted: true };
}

// ─── onCall (Firebase Auth admin) ────────────────────────────────────────────

export const adminListYuztooNews = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    assertAdmin(context);
    return listYuztooNewsHandler(data);
  });

export const adminUpsertYuztooNews = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);
    return upsertYuztooNewsHandler(data, caller);
  });

export const adminSetYuztooNewsRelease = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);
    return setYuztooNewsReleaseHandler(data, caller);
  });

export const adminSetYuztooNewsActive = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);
    return setYuztooNewsActiveHandler(data, caller);
  });

export const adminDeleteYuztooNews = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);
    return deleteYuztooNewsHandler(data, caller);
  });

// ─── HTTPS bridge (Supabase Edge → shared secret) ────────────────────────────

function bridgeSecretExpected(): string {
  const fromEnv = process.env.CRM_BRIDGE_SECRET?.trim();
  if (fromEnv) return fromEnv;
  try {
    const fromConfig = functions.config()?.crm?.bridge_secret;
    if (typeof fromConfig === "string" && fromConfig.trim()) {
      return fromConfig.trim();
    }
  } catch {
    // functions.config() unavailable in some test / emulator setups
  }
  return "";
}

function bridgeSecretOk(req: functions.https.Request): boolean {
  const expected = bridgeSecretExpected();
  if (!expected) return false;
  const header = String(req.get("x-crm-bridge-secret") ?? "").trim();
  return header.length > 0 && header === expected;
}

function bridgeCaller(body: Record<string, unknown>): AdminCaller {
  const email =
    typeof body.actor_email === "string" && body.actor_email.trim()
      ? body.actor_email.trim().slice(0, 200)
      : null;
  const uid =
    typeof body.actor_uid === "string" && body.actor_uid.trim()
      ? body.actor_uid.trim().slice(0, 128)
      : "crm-bridge";
  return { uid, email };
}

function httpsErrorToStatus(err: unknown): {
  status: number;
  code: string;
  message: string;
} {
  if (err instanceof functions.https.HttpsError) {
    const map: Record<string, number> = {
      "invalid-argument": 400,
      "failed-precondition": 409,
      "not-found": 404,
      unauthenticated: 401,
      "permission-denied": 403,
    };
    return {
      status: map[err.code] ?? 400,
      code: err.code,
      message: err.message,
    };
  }
  functions.logger.error("crmBridgeYuztooNews unexpected error", err);
  return { status: 500, code: "internal", message: "Request failed" };
}

/**
 * Sales CRM Edge calls this with header `X-CRM-Bridge-Secret`.
 * Body: `{ action, actor_email?, actor_uid?, ...payload }`
 * actions: list | upsert | setActive | setRelease | delete
 *          | findClient | searchMerchants (read-only lookups)
 */
export const crmBridgeYuztooNews = functions
  .region(ADMIN_REGION)
  .runWith({ memory: "256MB", timeoutSeconds: 60 })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "null");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set(
      "Access-Control-Allow-Headers",
      "content-type, x-crm-bridge-secret"
    );
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }
    if (!bridgeSecretOk(req)) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const body = (req.body ?? {}) as Record<string, unknown>;
    const action = String(body.action ?? "").trim();
    const caller = bridgeCaller(body);

    try {
      let result: unknown;
      switch (action) {
        case "list":
          result = await listYuztooNewsHandler(body);
          break;
        case "upsert":
          result = await upsertYuztooNewsHandler(body, caller);
          break;
        case "setActive":
          result = await setYuztooNewsActiveHandler(body, caller);
          break;
        case "setRelease":
          result = await setYuztooNewsReleaseHandler(body, caller);
          break;
        case "delete":
          result = await deleteYuztooNewsHandler(body, caller);
          break;
        case "findClient":
          result = await findNewsTestClientHandler(body);
          break;
        case "searchMerchants":
          result = await searchNewsMerchantsHandler(body);
          break;
        default:
          res.status(400).json({ error: "Unknown action" });
          return;
      }
      res.status(200).json({ data: result });
    } catch (err) {
      const { status, code, message } = httpsErrorToStatus(err);
      res.status(status).json({ error: message, code });
    }
  });
