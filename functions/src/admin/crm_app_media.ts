import { randomUUID } from "crypto";
import * as functions from "firebase-functions";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import {
  ADMIN_REGION,
  assertAdmin,
  assertFreshAdmin,
  writeAuditLog,
} from "./guard";

// ─── Admin CRM — app media catalog (Images app) ──────────────────────────────
//
// Source of truth for Flutter remote images. Exactly two Firestore docs + one
// Storage object per slot (overwrite). No base64 in Firestore — only URLs.
// CMS SPA stays on localStorage until Supabase Edge bridges here.

const RELEASE_PATH = "app_config/app_media_release";
const CATALOG_PATH = "app_config/app_media_catalog";
const MAX_BYTES_DEFAULT = 1_500_000;
const MAX_BYTES_ICON = 200_000;

const ALLOWED_SLOTS = new Set([
  "brand.logo",
  "onboarding.merchant.hero_personal",
  "onboarding.merchant.hero_commerce",
  "onboarding.merchant.hero_audience",
  "onboarding.merchant.hero_city",
  "onboarding.client.hero",
  "empty.loyalty",
  "empty.passages",
  "empty.promotions",
  "onboarding.category.bouche",
  "onboarding.category.commerce",
  "onboarding.category.beaute",
  "onboarding.category.sante",
  "onboarding.category.services_particuliers",
  "onboarding.category.loisirs",
  "onboarding.category.association",
  "onboarding.category.autre",
  "onboarding.category.artisan_btp",
  "onboarding.category.services_pro",
  "onboarding.category.grossiste",
  "onboarding.category.immobilier",
  "onboarding.category.finance_juridique",
  "onboarding.category.livraison",
  "onboarding.category.independants",
  "onboarding.category.autres_pro",
]);

function maxBytesFor(slotId: string): number {
  return slotId.startsWith("onboarding.category.")
    ? MAX_BYTES_ICON
    : MAX_BYTES_DEFAULT;
}

const ALLOWED_MIME = new Set([
  "image/png",
  "image/jpeg",
  "image/webp",
]);

type ReleaseStatus = "draft" | "preview" | "live";

type MediaRelease = {
  status: ReleaseStatus;
  testAccountId: string | null;
  testAccountKind: "client" | "merchant" | null;
  testAccountLabel: string | null;
  previewActivatedAt: FirebaseFirestore.Timestamp | string | null;
  liveAt: FirebaseFirestore.Timestamp | string | null;
  updatedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
};

function db() {
  return getFirestore();
}

function storagePathFor(slotId: string): string {
  return `app_media/${slotId}/current`;
}

function extFor(contentType: string): string {
  if (contentType === "image/png") return "png";
  if (contentType === "image/webp") return "webp";
  return "jpg";
}

async function readRelease(): Promise<MediaRelease | null> {
  const snap = await db().doc(RELEASE_PATH).get();
  if (!snap.exists) return null;
  return snap.data() as MediaRelease;
}

async function ensureDraftRelease(): Promise<void> {
  const existing = await readRelease();
  if (existing) return;
  await db().doc(RELEASE_PATH).set({
    status: "draft",
    testAccountId: null,
    testAccountKind: null,
    testAccountLabel: null,
    previewActivatedAt: null,
    liveAt: null,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

/**
 * Upload / replace one catalog slot. Overwrites Storage path so we never
 * accumulate orphan objects. Catalog stays a single document (1 read for app).
 */
export const adminUpsertAppMediaSlot = functions
  .region(ADMIN_REGION)
  .runWith({ memory: "512MB", timeoutSeconds: 60 })
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);

    const slotId = String(
      (data as Record<string, unknown> | undefined)?.slotId ?? ""
    ).trim();
    const contentType = String(
      (data as Record<string, unknown> | undefined)?.contentType ?? ""
    ).trim();
    const dataBase64 = String(
      (data as Record<string, unknown> | undefined)?.dataBase64 ?? ""
    ).trim();

    if (!ALLOWED_SLOTS.has(slotId)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Unknown media slot."
      );
    }
    if (!ALLOWED_MIME.has(contentType)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "contentType must be image/png, image/jpeg, or image/webp."
      );
    }
    if (!dataBase64) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "dataBase64 is required."
      );
    }

    let buffer: Buffer;
    try {
      buffer = Buffer.from(dataBase64, "base64");
    } catch {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "dataBase64 is invalid."
      );
    }
    const maxBytes = maxBytesFor(slotId);
    if (buffer.byteLength === 0 || buffer.byteLength > maxBytes) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Image must be between 1 byte and ${maxBytes} bytes for this slot.`
      );
    }

    await ensureDraftRelease();

    const path = storagePathFor(slotId);
    const bucket = getStorage().bucket();
    const file = bucket.file(path);
    const token = cryptoRandomToken();
    await file.save(buffer, {
      resumable: false,
      metadata: {
        contentType,
        cacheControl: "public,max-age=3600",
        metadata: {
          firebaseStorageDownloadTokens: token,
          slotId,
          ext: extFor(contentType),
        },
      },
    });

    // Tokenized download URL — clients never need Storage list; catalog holds URL.
    const bucketName = bucket.name;
    const encoded = encodeURIComponent(path);
    const url = `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encoded}?alt=media&token=${token}`;

    const catalogRef = db().doc(CATALOG_PATH);
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(catalogRef);
      const prev = snap.exists ? snap.data() ?? {} : {};
      const slots = {
        ...((prev.slots as Record<string, unknown> | undefined) ?? {}),
        [slotId]: {
          url,
          storagePath: path,
          contentType,
          bytes: buffer.byteLength,
          updatedAt: new Date().toISOString(),
        },
      };
      const version = typeof prev.version === "number" ? prev.version + 1 : 1;
      tx.set(
        catalogRef,
        {
          version,
          updatedAt: FieldValue.serverTimestamp(),
          slots,
        },
        { merge: true }
      );
    });

    // Editing while live forces re-preview (same gate as CMS).
    const release = await readRelease();
    if (release?.status === "live") {
      await db()
        .doc(RELEASE_PATH)
        .set(
          {
            status: "draft",
            previewActivatedAt: null,
            liveAt: null,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    }

    await writeAuditLog({
      actor: caller,
      action: "app_media.slot_upserted",
      targetType: "system",
      targetId: slotId,
      after: { contentType, bytes: buffer.byteLength },
    });

    return { slotId, url, bytes: buffer.byteLength };
  });

/** Remove one slot from catalog + Storage. */
export const adminClearAppMediaSlot = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertFreshAdmin(context);
    const slotId = String(
      (data as Record<string, unknown> | undefined)?.slotId ?? ""
    ).trim();
    if (!ALLOWED_SLOTS.has(slotId)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Unknown media slot."
      );
    }

    const path = storagePathFor(slotId);
    try {
      await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
    } catch (e) {
      functions.logger.warn("adminClearAppMediaSlot: storage delete", { e });
    }

    const catalogRef = db().doc(CATALOG_PATH);
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(catalogRef);
      if (!snap.exists) return;
      const prev = snap.data() ?? {};
      const slots = {
        ...((prev.slots as Record<string, unknown> | undefined) ?? {}),
      };
      delete slots[slotId];
      const version = typeof prev.version === "number" ? prev.version + 1 : 1;
      tx.set(
        catalogRef,
        {
          version,
          updatedAt: FieldValue.serverTimestamp(),
          slots,
        },
        { merge: true }
      );
    });

    await writeAuditLog({
      actor: caller,
      action: "app_media.slot_cleared",
      targetType: "system",
      targetId: slotId,
    });

    return { slotId, cleared: true };
  });

/**
 * Publication gate: draft → preview (test account required) → live.
 * Live is rejected unless currently in preview with a test account.
 */
export const adminSetAppMediaRelease = functions
  .region(ADMIN_REGION)
  .https.onCall(async (data, context) => {
    const caller = assertAdmin(context);
    const payload = (data ?? {}) as Record<string, unknown>;
    const status = String(payload.status ?? "").trim() as ReleaseStatus;
    if (!["draft", "preview", "live"].includes(status)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "status must be draft, preview, or live."
      );
    }

    const current = (await readRelease()) ?? {
      status: "draft" as ReleaseStatus,
      testAccountId: null,
      testAccountKind: null,
      testAccountLabel: null,
      previewActivatedAt: null,
      liveAt: null,
      updatedAt: FieldValue.serverTimestamp(),
    };

    let testAccountId =
      payload.testAccountId === undefined
        ? current.testAccountId
        : payload.testAccountId === null
          ? null
          : String(payload.testAccountId).trim() || null;
    let testAccountKind =
      payload.testAccountKind === undefined
        ? current.testAccountKind
        : payload.testAccountKind === null
          ? null
          : (String(payload.testAccountKind) as "client" | "merchant");
    let testAccountLabel =
      payload.testAccountLabel === undefined
        ? current.testAccountLabel
        : payload.testAccountLabel === null
          ? null
          : String(payload.testAccountLabel).trim() || null;

    if (
      testAccountKind != null &&
      testAccountKind !== "client" &&
      testAccountKind !== "merchant"
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "testAccountKind must be client or merchant."
      );
    }

    if (status === "preview") {
      if (!testAccountId) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Select a test account before activating preview."
        );
      }
    }

    if (status === "live") {
      const ready =
        current.status === "preview" &&
        Boolean(current.testAccountId) &&
        Boolean(current.previewActivatedAt);
      if (!ready) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Publish blocked: activate preview with a test account first."
        );
      }
      testAccountId = current.testAccountId;
      testAccountKind = current.testAccountKind;
      testAccountLabel = current.testAccountLabel;
    }

    if (status === "draft") {
      // Keep selected account for convenience; clear preview/live stamps.
    }

    const next: Record<string, unknown> = {
      status,
      testAccountId,
      testAccountKind,
      testAccountLabel,
      updatedAt: FieldValue.serverTimestamp(),
      previewActivatedAt:
        status === "preview"
          ? FieldValue.serverTimestamp()
          : status === "live"
            ? current.previewActivatedAt
            : null,
      liveAt: status === "live" ? FieldValue.serverTimestamp() : null,
    };

    await db().doc(RELEASE_PATH).set(next, { merge: true });

    await writeAuditLog({
      actor: caller,
      action: "app_media.release_set",
      targetType: "system",
      targetId: "app_media_release",
      before: {
        status: current.status,
        testAccountId: current.testAccountId,
      },
      after: { status, testAccountId },
    });

    return { status, testAccountId };
  });

function cryptoRandomToken(): string {
  return randomUUID();
}
