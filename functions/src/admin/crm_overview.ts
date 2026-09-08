import * as functions from "firebase-functions";
import { Query, getFirestore } from "firebase-admin/firestore";
import { ADMIN_REGION, assertAdmin } from "./guard";

// ─── Admin CRM — dashboard figures ───────────────────────────────────────────
//
// Top-line counts for the console home. Everything here uses Firestore's
// `count()` aggregation, which is billed per batch of index entries read
// rather than per document — so this stays cheap as the collections grow, and
// the dashboard never has to page through data it only wants to total.

function db() {
  return getFirestore();
}

/** Run a count aggregation, degrading to `null` rather than failing the page. */
async function countOf(query: Query, label: string): Promise<number | null> {
  try {
    const snapshot = await query.count().get();
    return snapshot.data().count;
  } catch (e) {
    functions.logger.warn("adminGetOverview: count failed", {
      label,
      error: e,
    });
    return null;
  }
}

function daysAgo(days: number): Date {
  return new Date(Date.now() - days * 24 * 60 * 60 * 1000);
}

/**
 * Aggregate counts for the dashboard.
 *
 * A note on the "deleted" counts: `where("deleted_at", "!=", null)` matches
 * only documents whose field holds a real timestamp. Documents written before
 * soft-delete existed have no such field and are excluded, which is exactly
 * right — they were never deleted.
 *
 * The "nouveaux" figures rely on `created_at`, so any legacy document missing
 * it is invisible to them. That is acceptable for a trend indicator and is why
 * these are labelled as recent activity rather than as totals.
 */
export const adminGetOverview = functions
  .region(ADMIN_REGION)
  .https.onCall(async (_data, context) => {
    assertAdmin(context);

    const merchants = db().collection("merchants");
    const users = db().collection("users");

    const last7 = daysAgo(7);
    const last30 = daysAgo(30);

    const [
      merchantsOnline,
      merchantsTotal,
      merchantsDeleted,
      clientsTotal,
      clientsBlocked,
      clientsDeleted,
      clientsNew7,
      clientsNew30,
      merchantsNew30,
    ] = await Promise.all([
      countOf(merchants.where("status", "==", "active"), "merchantsOnline"),
      countOf(merchants, "merchantsTotal"),
      countOf(merchants.where("deleted_at", "!=", null), "merchantsDeleted"),
      countOf(users, "clientsTotal"),
      countOf(users.where("status", "==", "blocked"), "clientsBlocked"),
      countOf(users.where("deleted_at", "!=", null), "clientsDeleted"),
      countOf(users.where("created_at", ">=", last7), "clientsNew7"),
      countOf(users.where("created_at", ">=", last30), "clientsNew30"),
      countOf(merchants.where("created_at", ">=", last30), "merchantsNew30"),
    ]);

    // Live totals exclude anything pending permanent deletion, so the numbers
    // match what the "Actifs" lists actually show.
    const subtract = (total: number | null, removed: number | null) =>
      total === null ? null : total - (removed ?? 0);

    const merchantsLive = subtract(merchantsTotal, merchantsDeleted);
    const clientsLive = subtract(clientsTotal, clientsDeleted);
    const merchantsOffline =
      merchantsLive === null || merchantsOnline === null
        ? null
        : merchantsLive - merchantsOnline;

    return {
      generatedAt: new Date().toISOString(),
      merchants: {
        live: merchantsLive,
        online: merchantsOnline,
        offline: merchantsOffline,
        deleted: merchantsDeleted,
        new30: merchantsNew30,
      },
      clients: {
        live: clientsLive,
        blocked: clientsBlocked,
        deleted: clientsDeleted,
        new7: clientsNew7,
        new30: clientsNew30,
      },
    };
  });
