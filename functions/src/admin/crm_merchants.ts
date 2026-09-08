import * as functions from "firebase-functions";
import {
  DocumentData,
  DocumentSnapshot,
  FieldValue,
  Firestore,
  Query,
  getFirestore,
} from "firebase-admin/firestore";
import {
  ADMIN_REGION,
  assertAdmin,
  assertFreshAdmin,
  optionalStringArg,
  pageLimitArg,
  pickAllowedFields,
  requireStringArg,
  writeAuditLog,
} from "./guard";
import { docToJson, docToSummary, toJsonValue } from "./serialize";

// ─── Admin CRM — stores (merchants) ──────────────────────────────────────────
//
// Mirrors the merchant document shape written by `merchant_dto.dart`. Fields
// the merchant owns through the app stay editable here; identity and
// server-maintained counters do not.

function db(): Firestore {
  return getFirestore();
}

/**
 * Fields an admin may edit directly.
 *
 * Deliberately excluded:
 *   - `owner_uid`      reassigning a store to another account is an identity
 *                      change; it would strand the previous owner's
 *                      `users/{uid}.merchant_id` pointer.
 *   - `status`         has its own endpoint so "mis en ligne / hors ligne"
 *                      reads as a distinct action in the audit trail.
 *   - `deleted_*`      owned by the soft-delete endpoints.
 *   - `rappels_*`      monthly counters maintained by client writes and CFs.
 *   - `loyalty_program`, `gratification_config`
 *                      nested config with invariants enforced by the app's
 *                      own editors; a blind overwrite here can corrupt a
 *                      running loyalty program.
 *   - `created_at`     immutable history.
 */
const MERCHANT_EDITABLE_FIELDS = [
  "name",
  "display_name",
  "email",
  "phone",
  "city",
  "address",
  "categories",
  "category_id",
  "subcategory_title",
  "description",
  "hours",
  "logo_url",
  "banner_url",
  "website_url",
  "news_image_urls",
  "loyalty_enabled",
  "messaging_enabled",
  "notifications_auto_enabled",
  "galerie_enabled",
  "merchant_type",
  "subscription_plan",
  "welcome_gift_description",
  "rappels_auto_client_validation",
  "rappels_auto_passage_validation",
  "passage_cooldown_enabled",
] as const;

/** Columns the list view renders — keeps payloads small on large pages. */
const MERCHANT_SUMMARY_FIELDS = [
  "name",
  "display_name",
  "email",
  "phone",
  "city",
  "status",
  "owner_uid",
  "logo_url",
  "merchant_type",
  "subscription_plan",
  "created_at",
  "updated_at",
  "deleted_at",
] as const;

const MERCHANT_STATUSES = ["active", "inactive"] as const;
type MerchantStatus = (typeof MERCHANT_STATUSES)[number];

/**
 * `listMode` semantics — chosen to work on documents written before
 * soft-delete existed, which have no `deleted_at` field at all.
 *
 * Firestore's `where("deleted_at", "==", null)` matches only documents where
 * the field is explicitly null; documents missing the field are excluded
 * entirely. Filtering that way would hide every pre-existing store. So the
 * "active" mode runs an unfiltered query and drops deleted rows in memory,
 * over-fetching to keep pages full. The "deleted" mode orders by `deleted_at`,
 * which implicitly selects only documents that carry the field.
 */
type ListMode = "active" | "deleted" | "all";

function parseListMode(data: unknown): ListMode {
  const raw = (data as Record<string, unknown> | undefined)?.listMode;
  if (raw === undefined || raw === null) return "active";
  if (raw === "active" || raw === "deleted" || raw === "all") return raw;
  throw new functions.https.HttpsError(
    "invalid-argument",
    "`listMode` must be one of: active, deleted, all."
  );
}

function parseMerchantStatus(data: unknown): MerchantStatus {
  const raw = requireStringArg(data, "status", 16);
  if (!(MERCHANT_STATUSES as readonly string[]).includes(raw)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "`status` must be 'active' or 'inactive'."
    );
  }
  return raw as MerchantStatus;
}

function isDeleted(data: DocumentData | undefined): boolean {
  return Boolean(data?.deleted_at);
}

/** Load a merchant or throw `not-found`. */
async function getMerchantOrThrow(
  merchantId: string
): Promise<DocumentSnapshot> {
  const doc = await db().collection("merchants").doc(merchantId).get();
  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Store not found.");
  }
  return doc;
}

// ─── list ────────────────────────────────────────────────────────────────────

/**
 * Paginated store list with optional name prefix search and status filter.
 *
 * Search uses the `name_lowercase` field the app already maintains, as a
 * prefix range query — Firestore has no substring search, so "bou" finds
 * "Boulangerie" but "langerie" does not.
 */
export const adminListMerchants = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    assertAdmin(context);

    const limit = pageLimitArg(data);
    const listMode = parseListMode(data);
    const search = optionalStringArg(data, "search", 120)?.toLowerCase() ?? null;
    const statusFilter = optionalStringArg(data, "status", 16);
    const cursor = optionalStringArg(data, "cursor", 1500);

    if (
      statusFilter &&
      !(MERCHANT_STATUSES as readonly string[]).includes(statusFilter)
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "`status` must be 'active' or 'inactive'."
      );
    }

    let query: Query = db().collection("merchants");

    if (statusFilter) {
      query = query.where("status", "==", statusFilter);
    }

    if (search) {
      // Prefix range: [search, search + \uf8ff) over the lowercase name.
      query = query
        .where("name_lowercase", ">=", search)
        .where("name_lowercase", "<", `${search}\uf8ff`)
        .orderBy("name_lowercase");
    } else if (listMode === "deleted") {
      query = query.orderBy("deleted_at", "desc");
    } else {
      // `updated_at` is written on every merchant save by `merchant_dto.dart`,
      // so ordering by it does not hide documents the way `created_at` could.
      query = query.orderBy("updated_at", "desc");
    }

    if (cursor) {
      const cursorDoc = await db().collection("merchants").doc(cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    // A "deleted" list ordered by `deleted_at` needs no in-memory filtering —
    // only documents carrying the field can match. Every other filtered mode
    // does, so over-fetch to keep pages from coming back sparse.
    const filtersInMemory =
      listMode === "active" || (listMode === "deleted" && Boolean(search));
    const fetchSize = filtersInMemory ? Math.min(limit * 2, 200) : limit;
    const snap = await query.limit(fetchSize).get();

    const items: Record<string, unknown>[] = [];
    let lastExaminedId: string | null = null;

    for (const doc of snap.docs) {
      lastExaminedId = doc.id;
      const deleted = isDeleted(doc.data());
      if (listMode === "active" && deleted) continue;
      if (listMode === "deleted" && !deleted) continue;
      items.push(docToSummary(doc, MERCHANT_SUMMARY_FIELDS));
      if (items.length >= limit) break;
    }

    return {
      items,
      // Null signals the end of the collection; a non-null cursor with a short
      // page just means deleted rows were filtered out of this batch.
      nextCursor: snap.size < fetchSize ? null : lastExaminedId,
    };
  });

// ─── read ────────────────────────────────────────────────────────────────────

/** Full store document plus its owner's user document, for the detail view. */
export const adminGetMerchant = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    assertAdmin(context);

    const merchantId = requireStringArg(data, "merchantId", 128);
    const doc = await getMerchantOrThrow(merchantId);

    const ownerUid = doc.data()?.owner_uid as string | undefined;
    let owner: Record<string, unknown> | null = null;
    if (ownerUid) {
      const ownerDoc = await db().collection("users").doc(ownerUid).get();
      if (ownerDoc.exists) owner = docToJson(ownerDoc);
    }

    return { merchant: docToJson(doc), owner };
  });

// ─── create ──────────────────────────────────────────────────────────────────

/**
 * Create a store for an existing account and link the two.
 *
 * Mirrors `firestore_merchant_repository.writes.part.dart`: the store document
 * carries `owner_uid`, and the owner's user document gains `merchant_id`, the
 * merchant/provider roles, and a completed merchant onboarding flag. Both
 * writes go in one batch so a store can never exist unlinked.
 *
 * New stores start `inactive` — same as `complete_merchant_onboarding.dart` —
 * so nothing appears in Découvrir until an admin explicitly publishes it.
 */
export const adminCreateMerchant = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);

    const ownerUid = requireStringArg(data, "ownerUid", 128);
    const name = requireStringArg(data, "name", 200);
    const city = requireStringArg(data, "city", 120);
    const email = optionalStringArg(data, "email", 320);
    const phone = optionalStringArg(data, "phone", 32);

    const ownerRef = db().collection("users").doc(ownerUid);
    const ownerDoc = await ownerRef.get();
    if (!ownerDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Owner account not found."
      );
    }

    const ownerData = ownerDoc.data() ?? {};
    const existingMerchantId = ownerData.merchant_id as string | undefined;
    if (existingMerchantId) {
      throw new functions.https.HttpsError(
        "already-exists",
        "This account already owns a store."
      );
    }

    const { accepted: optionalFields } = pickAllowedFields(
      (data as Record<string, unknown>)?.patch ?? {},
      MERCHANT_EDITABLE_FIELDS
    );

    // The store document ID *is* the owner's UID. `firestore_merchant_repository`
    // reads `merchants/{ownerUid}` directly instead of querying `owner_uid`, and
    // Storage paths are `merchants/{ownerUid}/…`, so an auto-generated ID would
    // produce a store the app can never find. Every existing store follows this.
    const merchantRef = db().collection("merchants").doc(ownerUid);
    if ((await merchantRef.get()).exists) {
      throw new functions.https.HttpsError(
        "already-exists",
        "A store document already exists for this account."
      );
    }

    const now = FieldValue.serverTimestamp();

    const roles = {
      ...((ownerData.roles as Record<string, boolean> | undefined) ?? {
        client: false,
        provider: false,
      }),
      merchant: true,
      provider: true,
    };
    const onboarding = {
      ...((ownerData.onboarding as Record<string, string> | undefined) ?? {
        client: "not_started",
      }),
      merchant: "completed",
    };

    const batch = db().batch();
    batch.set(merchantRef, {
      ...optionalFields,
      owner_uid: ownerUid,
      name,
      name_lowercase: name.toLowerCase(),
      // Mirrors what merchant onboarding writes; the storefront reads
      // `display_name` in preference to `name`.
      display_name: (optionalFields.display_name as string | undefined) ?? name,
      merchant_type: (optionalFields.merchant_type as string | undefined) ?? "b2c",
      city,
      email: email ?? (ownerData.email as string | undefined) ?? "",
      phone: phone ?? (ownerData.phone as string | undefined) ?? "",
      status: "inactive",
      deleted_at: null,
      created_at: now,
      updated_at: now,
    });
    batch.set(
      ownerRef,
      {
        merchant_id: merchantRef.id,
        roles,
        onboarding,
        updated_at: now,
      },
      { merge: true }
    );
    await batch.commit();

    await writeAuditLog({
      actor: caller,
      action: "merchant.created",
      targetType: "merchant",
      targetId: merchantRef.id,
      after: { name, city, owner_uid: ownerUid, status: "inactive" },
    });

    return { merchantId: merchantRef.id };
  });

// ─── update ──────────────────────────────────────────────────────────────────

/** Patch allowlisted store fields; records before/after in the audit log. */
export const adminUpdateMerchant = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);

    const merchantId = requireStringArg(data, "merchantId", 128);
    const { accepted, rejected } = pickAllowedFields(
      (data as Record<string, unknown>)?.patch,
      MERCHANT_EDITABLE_FIELDS
    );

    if (Object.keys(accepted).length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "No editable fields supplied."
      );
    }

    const doc = await getMerchantOrThrow(merchantId);
    const previous = doc.data() ?? {};

    // Keep the search key in sync — discovery and admin search both read it.
    if (typeof accepted.name === "string") {
      accepted.name_lowercase = accepted.name.toLowerCase();
    }
    accepted.updated_at = FieldValue.serverTimestamp();

    await doc.ref.update(accepted);

    const before: Record<string, unknown> = {};
    for (const key of Object.keys(accepted)) {
      before[key] = toJsonValue(previous[key]);
    }

    await writeAuditLog({
      actor: caller,
      action: "merchant.updated",
      targetType: "merchant",
      targetId: merchantId,
      before,
      after: toJsonValue(accepted) as Record<string, unknown>,
      metadata: rejected.length ? { rejected_fields: rejected } : undefined,
    });

    return { ok: true, rejectedFields: rejected };
  });

// ─── publish / unpublish ─────────────────────────────────────────────────────

/**
 * Mettre un store en ligne ou hors ligne.
 *
 * `active` / `inactive` is the same switch the merchant flips from their own
 * vitrine (`storefront_screen.dart`), and Découvrir filters on it both in the
 * Firestore query and again in memory — so this genuinely removes the store
 * from discovery. Note the merchant document itself stays publicly readable by
 * id; taking a store offline hides it from browsing, it does not make it
 * secret.
 */
export const adminSetMerchantStatus = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);

    const merchantId = requireStringArg(data, "merchantId", 128);
    const status = parseMerchantStatus(data);

    const doc = await getMerchantOrThrow(merchantId);
    const previous = doc.data() ?? {};

    if (isDeleted(previous) && status === "active") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Restore the store before putting it back online."
      );
    }

    await doc.ref.update({
      status,
      updated_at: FieldValue.serverTimestamp(),
    });

    await writeAuditLog({
      actor: caller,
      action: "merchant.status_changed",
      targetType: "merchant",
      targetId: merchantId,
      before: { status: previous.status ?? null },
      after: { status },
    });

    return { ok: true, status };
  });

// ─── soft delete / restore ───────────────────────────────────────────────────

/**
 * Soft-delete a store: flag it and force it offline.
 *
 * Nothing is destroyed here. `deleted_at` marks it for the retention sweep in
 * `index.ts`, which performs the real cascade once the window elapses. Setting
 * `status` to `inactive` is what actually removes it from Découvrir today;
 * `status_before_delete` remembers the previous value so a restore is faithful.
 */
export const adminSoftDeleteMerchant = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);

    const merchantId = requireStringArg(data, "merchantId", 128);
    const reason = optionalStringArg(data, "reason", 500);

    const doc = await getMerchantOrThrow(merchantId);
    const previous = doc.data() ?? {};

    if (isDeleted(previous)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Store is already deleted."
      );
    }

    await doc.ref.update({
      deleted_at: FieldValue.serverTimestamp(),
      deleted_by: caller.uid,
      deleted_reason: reason,
      status_before_delete: previous.status ?? "inactive",
      status: "inactive",
      updated_at: FieldValue.serverTimestamp(),
    });

    await writeAuditLog({
      actor: caller,
      action: "merchant.soft_deleted",
      targetType: "merchant",
      targetId: merchantId,
      before: { status: previous.status ?? null, deleted_at: null },
      after: { status: "inactive", deleted_by: caller.uid },
      metadata: reason ? { reason } : undefined,
    });

    return { ok: true };
  });

/** Undo a soft delete, putting `status` back where it was. */
export const adminRestoreMerchant = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);

    const merchantId = requireStringArg(data, "merchantId", 128);
    const doc = await getMerchantOrThrow(merchantId);
    const previous = doc.data() ?? {};

    if (!isDeleted(previous)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Store is not deleted."
      );
    }

    const restoredStatus =
      (previous.status_before_delete as string | undefined) ?? "inactive";

    await doc.ref.update({
      deleted_at: null,
      deleted_by: FieldValue.delete(),
      deleted_reason: FieldValue.delete(),
      status_before_delete: FieldValue.delete(),
      status: restoredStatus,
      updated_at: FieldValue.serverTimestamp(),
    });

    await writeAuditLog({
      actor: caller,
      action: "merchant.restored",
      targetType: "merchant",
      targetId: merchantId,
      after: { status: restoredStatus },
    });

    return { ok: true, status: restoredStatus };
  });
