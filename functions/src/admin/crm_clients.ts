import * as functions from "firebase-functions";
import { getAuth } from "firebase-admin/auth";
import {
  DocumentData,
  DocumentSnapshot,
  FieldPath,
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

// ─── Admin CRM — clients (users) ─────────────────────────────────────────────
//
// Mirrors the user document written by
// `firebase_user_repository.create.part.dart`. Note that document mixes
// conventions: profile names are camelCase (`firstName`, `photoUrl`) while
// everything else is snake_case (`merchant_id`, `created_at`). The field lists
// below follow the data as it actually exists, not as it ought to look.

function db(): Firestore {
  return getFirestore();
}

/**
 * Fields an admin may edit directly.
 *
 * Deliberately excluded:
 *   - `email`, `phone`  identity keys mirrored into `email_index` /
 *                       `phone_index` and into Firebase Auth. Changing them
 *                       means a three-way migration, not a field write.
 *   - `roles`, `onboarding`, `merchant_id`, `force_merchant_next_login`
 *                       these drive routing and the merchant link; editing
 *                       them by hand strands accounts in broken states.
 *   - `status`          has its own endpoint (block / unblock).
 *   - `deleted_*`       owned by the soft-delete endpoints.
 *   - `uid`, `created_at`
 *                       immutable.
 */
const USER_EDITABLE_FIELDS = [
  "firstName",
  "lastName",
  "displayName",
  "photoUrl",
  "city",
  "birth_date",
] as const;

const USER_SUMMARY_FIELDS = [
  "firstName",
  "lastName",
  "displayName",
  "email",
  "phone",
  "city",
  "status",
  "primary_role",
  "merchant_id",
  "photoUrl",
  "created_at",
  "deleted_at",
] as const;

const USER_STATUSES = ["active", "blocked"] as const;
type UserStatus = (typeof USER_STATUSES)[number];

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

function isDeleted(data: DocumentData | undefined): boolean {
  return Boolean(data?.deleted_at);
}

async function getUserOrThrow(
  uid: string
): Promise<DocumentSnapshot> {
  const doc = await db().collection("users").doc(uid).get();
  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Client not found.");
  }
  return doc;
}

/** Enable or disable the Auth account, tolerating an already-missing user. */
async function setAuthDisabled(uid: string, disabled: boolean): Promise<void> {
  try {
    await getAuth().updateUser(uid, { disabled });
  } catch (e: unknown) {
    const code = (e as { code?: string })?.code;
    if (code === "auth/user-not-found") {
      // Firestore document outlived the Auth account — the Firestore state is
      // what the CRM displays, so this is not fatal.
      functions.logger.warn("adminCrm: auth account missing", { uid });
      return;
    }
    throw e;
  }
}

// ─── list ────────────────────────────────────────────────────────────────────

/**
 * Paginated client list.
 *
 * Firestore has no substring search and the user document has no lowercase
 * name field to range-query, so `search` resolves exact identity keys only: a
 * uid, a full email address, or a full phone number. Browsing is ordered by
 * document id by default — unlike `created_at`, every document has one, so no
 * account can be invisible to the CRM. Pass `sort: "recent"` for
 * newest-first when completeness matters less than recency.
 */
export const adminListUsers = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    assertAdmin(context);

    const limit = pageLimitArg(data);
    const listMode = parseListMode(data);
    const search = optionalStringArg(data, "search", 320);
    const cursor = optionalStringArg(data, "cursor", 1500);
    const sort = optionalStringArg(data, "sort", 16) ?? "id";

    // Exact-match search short-circuits pagination entirely.
    if (search) {
      const byId = await db().collection("users").doc(search).get();
      if (byId.exists) {
        return {
          items: [docToSummary(byId, USER_SUMMARY_FIELDS)],
          nextCursor: null,
        };
      }

      const field = search.includes("@") ? "email" : "phone";
      const needle = field === "email" ? search.toLowerCase() : search;
      const snap = await db()
        .collection("users")
        .where(field, "==", needle)
        .limit(limit)
        .get();

      return {
        items: snap.docs.map((d) => docToSummary(d, USER_SUMMARY_FIELDS)),
        nextCursor: null,
      };
    }

    let query: Query = db().collection("users");
    if (listMode === "deleted") {
      query = query.orderBy("deleted_at", "desc");
    } else if (sort === "recent") {
      query = query.orderBy("created_at", "desc");
    } else {
      query = query.orderBy(FieldPath.documentId());
    }

    if (cursor) {
      const cursorDoc = await db().collection("users").doc(cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    // Ordering by `deleted_at` already selects only deleted documents, so only
    // the "active" mode filters in memory and needs the over-fetch.
    const fetchSize = listMode === "active" ? Math.min(limit * 2, 200) : limit;
    const snap = await query.limit(fetchSize).get();

    const items: Record<string, unknown>[] = [];
    let lastExaminedId: string | null = null;
    let examined = 0;

    for (const doc of snap.docs) {
      lastExaminedId = doc.id;
      examined += 1;
      const deleted = isDeleted(doc.data());
      if (listMode === "active" && deleted) continue;
      if (listMode === "deleted" && !deleted) continue;
      items.push(docToSummary(doc, USER_SUMMARY_FIELDS));
      if (items.length >= limit) break;
    }

    // See the same guard in `adminListMerchants`: a page that fills before the
    // batch is consumed still has documents behind it, even when the batch came
    // back short of `fetchSize`.
    const exhausted = snap.size < fetchSize && examined === snap.size;

    return {
      items,
      nextCursor: exhausted ? null : lastExaminedId,
    };
  });

// ─── read ────────────────────────────────────────────────────────────────────

/** Full client document, their Auth record, and their store if they own one. */
export const adminGetUser = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    assertAdmin(context);

    const uid = requireStringArg(data, "uid", 128);
    const doc = await getUserOrThrow(uid);
    const userData = doc.data() ?? {};

    let authRecord: Record<string, unknown> | null = null;
    try {
      const record = await getAuth().getUser(uid);
      authRecord = {
        disabled: record.disabled,
        emailVerified: record.emailVerified,
        lastSignInTime: record.metadata.lastSignInTime,
        creationTime: record.metadata.creationTime,
        providers: record.providerData.map((p) => p.providerId),
      };
    } catch (e: unknown) {
      if ((e as { code?: string })?.code !== "auth/user-not-found") throw e;
    }

    let merchant: Record<string, unknown> | null = null;
    const merchantId = userData.merchant_id as string | undefined;
    if (merchantId) {
      const merchantDoc = await db()
        .collection("merchants")
        .doc(merchantId)
        .get();
      if (merchantDoc.exists) merchant = docToJson(merchantDoc);
    }

    return { user: docToJson(doc), auth: authRecord, merchant };
  });

// ─── create ──────────────────────────────────────────────────────────────────

/**
 * Create a client account: Auth user, `users/{uid}` document, and the
 * duplicate-guard index entries the signup flow relies on.
 *
 * The index documents matter — `email_index` and `phone_index` are what stop
 * the app from letting the same person sign up twice. An account created here
 * without them would be invisible to that check.
 *
 * No password is accepted. The account is created with an unguessable random
 * one and the response carries a password-reset link for the admin to hand to
 * the client, so no admin ever knows a client's credentials.
 */
export const adminCreateClient = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);

    const email = requireStringArg(data, "email", 320).toLowerCase();
    const phone = optionalStringArg(data, "phone", 32);
    const firstName = optionalStringArg(data, "firstName", 120);
    const lastName = optionalStringArg(data, "lastName", 120);
    const city = optionalStringArg(data, "city", 120);

    const emailIndexRef = db().collection("email_index").doc(email);
    if ((await emailIndexRef.get()).exists) {
      throw new functions.https.HttpsError(
        "already-exists",
        "This email is already registered."
      );
    }
    const phoneIndexRef = phone
      ? db().collection("phone_index").doc(phone)
      : null;
    if (phoneIndexRef && (await phoneIndexRef.get()).exists) {
      throw new functions.https.HttpsError(
        "already-exists",
        "This phone number is already registered."
      );
    }

    const displayName =
      [firstName, lastName].filter(Boolean).join(" ").trim() || null;

    let uid: string;
    try {
      const record = await getAuth().createUser({
        email,
        phoneNumber: phone ?? undefined,
        displayName: displayName ?? undefined,
        password: `${Date.now()}-${Math.random().toString(36).slice(2)}-Aa1!`,
      });
      uid = record.uid;
    } catch (e: unknown) {
      const code = (e as { code?: string })?.code ?? "";
      if (code.startsWith("auth/")) {
        throw new functions.https.HttpsError(
          "already-exists",
          `Could not create the account: ${code}`
        );
      }
      throw e;
    }

    const now = FieldValue.serverTimestamp();
    const batch = db().batch();
    batch.set(db().collection("users").doc(uid), {
      uid,
      email,
      ...(phone ? { phone } : {}),
      roles: { client: true, merchant: false, provider: false },
      primary_role: "client",
      ...(city ? { city } : {}),
      ...(firstName ? { firstName } : {}),
      ...(lastName ? { lastName } : {}),
      ...(displayName ? { displayName } : {}),
      merchant_id: null,
      onboarding: { merchant: "not_started", client: "not_started" },
      status: "active",
      deleted_at: null,
      created_at: now,
      updated_at: now,
      last_login_at: null,
      force_merchant_next_login: false,
      created_by_admin: caller.uid,
    });
    batch.set(emailIndexRef, { uid });
    if (phoneIndexRef) batch.set(phoneIndexRef, { uid });
    await batch.commit();

    let passwordResetLink: string | null = null;
    try {
      passwordResetLink = await getAuth().generatePasswordResetLink(email);
    } catch (e) {
      // Non-fatal: the account exists, the admin can trigger a reset later.
      functions.logger.warn("adminCreateClient: reset link failed", {
        uid,
        error: e,
      });
    }

    await writeAuditLog({
      actor: caller,
      action: "user.created",
      targetType: "user",
      targetId: uid,
      after: { email, phone, city, displayName },
    });

    return { uid, passwordResetLink };
  });

// ─── update ──────────────────────────────────────────────────────────────────

/** Patch allowlisted client profile fields. */
export const adminUpdateUser = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);

    const uid = requireStringArg(data, "uid", 128);
    const { accepted, rejected } = pickAllowedFields(
      (data as Record<string, unknown>)?.patch,
      USER_EDITABLE_FIELDS
    );

    if (Object.keys(accepted).length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "No editable fields supplied."
      );
    }

    const doc = await getUserOrThrow(uid);
    const previous = doc.data() ?? {};

    accepted.updated_at = FieldValue.serverTimestamp();
    await doc.ref.update(accepted);

    const before: Record<string, unknown> = {};
    for (const key of Object.keys(accepted)) {
      before[key] = toJsonValue(previous[key]);
    }

    await writeAuditLog({
      actor: caller,
      action: "user.updated",
      targetType: "user",
      targetId: uid,
      before,
      after: toJsonValue(accepted) as Record<string, unknown>,
      metadata: rejected.length ? { rejected_fields: rejected } : undefined,
    });

    return { ok: true, rejectedFields: rejected };
  });

// ─── block / unblock ─────────────────────────────────────────────────────────

/**
 * Block or unblock a client.
 *
 * Two layers, because the Firestore flag alone is only advisory: `status` is
 * what the app reads (and `firestore.rules` already forbids a client from
 * changing their own once set), while disabling the Auth account is what
 * actually stops them signing in and invalidates their refresh tokens.
 */
export const adminSetUserStatus = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);

    const uid = requireStringArg(data, "uid", 128);
    const status = requireStringArg(data, "status", 16);
    if (!(USER_STATUSES as readonly string[]).includes(status)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "`status` must be 'active' or 'blocked'."
      );
    }

    const doc = await getUserOrThrow(uid);
    const previous = doc.data() ?? {};

    await setAuthDisabled(uid, status === "blocked");
    await doc.ref.update({
      status,
      updated_at: FieldValue.serverTimestamp(),
    });

    await writeAuditLog({
      actor: caller,
      action: "user.status_changed",
      targetType: "user",
      targetId: uid,
      before: { status: previous.status ?? null },
      after: { status },
    });

    return { ok: true, status: status as UserStatus };
  });

// ─── soft delete / restore ───────────────────────────────────────────────────

/**
 * Soft-delete a client and immediately revoke their access.
 *
 * Data is untouched — the retention sweep in `index.ts` performs the real
 * cascade later. What happens now is that the Auth account is disabled, so the
 * person is signed out and cannot come back during the grace period.
 *
 * If the client owns a store, the store is soft-deleted in the same operation
 * and tagged `deleted_via: "owner_cascade"`, so a restore knows to bring it
 * back too rather than leaving an orphaned offline storefront.
 */
export const adminSoftDeleteUser = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);

    const uid = requireStringArg(data, "uid", 128);
    const reason = optionalStringArg(data, "reason", 500);

    if (uid === caller.uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You cannot delete your own account from the CRM."
      );
    }

    const doc = await getUserOrThrow(uid);
    const previous = doc.data() ?? {};

    if (isDeleted(previous)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Client is already deleted."
      );
    }

    const now = FieldValue.serverTimestamp();
    const merchantId = previous.merchant_id as string | undefined;

    await setAuthDisabled(uid, true);

    const batch = db().batch();
    batch.update(doc.ref, {
      deleted_at: now,
      deleted_by: caller.uid,
      deleted_reason: reason,
      status_before_delete: previous.status ?? "active",
      status: "blocked",
      updated_at: now,
    });

    // Only report a cascade that actually happened. Production contains at
    // least one account whose `merchant_id` points at a store document that no
    // longer exists; echoing the stale ID back would tell the admin a store was
    // deleted when nothing was touched.
    let cascadedMerchantId: string | null = null;

    if (merchantId) {
      const merchantRef = db().collection("merchants").doc(merchantId);
      const merchantDoc = await merchantRef.get();
      if (merchantDoc.exists && !isDeleted(merchantDoc.data())) {
        batch.update(merchantRef, {
          deleted_at: now,
          deleted_by: caller.uid,
          deleted_reason: reason,
          deleted_via: "owner_cascade",
          status_before_delete: merchantDoc.data()?.status ?? "inactive",
          status: "inactive",
          updated_at: now,
        });
        cascadedMerchantId = merchantId;
      }
    }

    await batch.commit();

    await writeAuditLog({
      actor: caller,
      action: "user.soft_deleted",
      targetType: "user",
      targetId: uid,
      before: { status: previous.status ?? null, deleted_at: null },
      after: { status: "blocked", deleted_by: caller.uid },
      metadata: {
        ...(reason ? { reason } : {}),
        ...(cascadedMerchantId
          ? { cascaded_merchant_id: cascadedMerchantId }
          : {}),
      },
    });

    return { ok: true, cascadedMerchantId };
  });

/** Undo a soft delete: re-enable Auth and restore any cascaded store. */
export const adminRestoreUser = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);

    const uid = requireStringArg(data, "uid", 128);
    const doc = await getUserOrThrow(uid);
    const previous = doc.data() ?? {};

    if (!isDeleted(previous)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Client is not deleted."
      );
    }

    const restoredStatus =
      (previous.status_before_delete as string | undefined) ?? "active";
    const now = FieldValue.serverTimestamp();
    const clear = FieldValue.delete();

    await setAuthDisabled(uid, restoredStatus === "blocked");

    const batch = db().batch();
    batch.update(doc.ref, {
      deleted_at: null,
      deleted_by: clear,
      deleted_reason: clear,
      status_before_delete: clear,
      status: restoredStatus,
      updated_at: now,
    });

    const merchantId = previous.merchant_id as string | undefined;
    let restoredMerchantId: string | null = null;
    if (merchantId) {
      const merchantRef = db().collection("merchants").doc(merchantId);
      const merchantDoc = await merchantRef.get();
      const merchantData = merchantDoc.data();
      // Only undo the cascade we caused — a store deleted on its own merits
      // stays deleted until an admin restores it explicitly.
      if (
        merchantDoc.exists &&
        isDeleted(merchantData) &&
        merchantData?.deleted_via === "owner_cascade"
      ) {
        batch.update(merchantRef, {
          deleted_at: null,
          deleted_by: clear,
          deleted_reason: clear,
          deleted_via: clear,
          status_before_delete: clear,
          status:
            (merchantData.status_before_delete as string | undefined) ??
            "inactive",
          updated_at: now,
        });
        restoredMerchantId = merchantId;
      }
    }

    await batch.commit();

    await writeAuditLog({
      actor: caller,
      action: "user.restored",
      targetType: "user",
      targetId: uid,
      after: { status: restoredStatus },
      metadata: restoredMerchantId
        ? { restored_merchant_id: restoredMerchantId }
        : undefined,
    });

    return { ok: true, status: restoredStatus, restoredMerchantId };
  });
