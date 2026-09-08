import type { DocumentSnapshot } from "firebase-admin/firestore";

// Callable responses are JSON — Firestore's Timestamp, GeoPoint and
// DocumentReference are not. Convert them to plain values so the admin web app
// receives something it can render without importing the Firestore SDK.

/**
 * Recursively convert Firestore field values into JSON-safe equivalents.
 *
 * Shapes are detected by duck-typing rather than `instanceof`. In
 * firebase-admin, `admin.firestore.GeoPoint` and
 * `admin.firestore.DocumentReference` are declaration-merged *types* with no
 * runtime value behind them, so `x instanceof admin.firestore.GeoPoint` throws
 * "Right-hand side of 'instanceof' is not an object" the moment a document
 * reaches it. Structural checks work regardless of how the SDK exports things.
 */
export function toJsonValue(value: unknown): unknown {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value.toISOString();
  if (typeof value !== "object") return value;
  if (Array.isArray(value)) return value.map(toJsonValue);
  if (Buffer.isBuffer(value)) return value.toString("base64");

  const candidate = value as Record<string, unknown>;

  // Timestamp
  if (typeof candidate.toDate === "function") {
    const date = (candidate.toDate as () => Date)();
    if (date instanceof Date && !Number.isNaN(date.getTime())) {
      return date.toISOString();
    }
  }

  // GeoPoint
  if (
    typeof candidate.latitude === "number" &&
    typeof candidate.longitude === "number"
  ) {
    return { latitude: candidate.latitude, longitude: candidate.longitude };
  }

  // DocumentReference
  if (
    typeof candidate.path === "string" &&
    typeof candidate.collection === "function"
  ) {
    return candidate.path;
  }

  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(candidate)) {
    out[k] = toJsonValue(v);
  }
  return out;
}

/** A Firestore document as `{ id, ...jsonSafeFields }`. */
export function docToJson(doc: DocumentSnapshot): Record<string, unknown> {
  return {
    id: doc.id,
    ...(toJsonValue(doc.data() ?? {}) as Record<string, unknown>),
  };
}

/** Project a document down to the fields a list view actually renders. */
export function docToSummary(
  doc: DocumentSnapshot,
  fields: readonly string[]
): Record<string, unknown> {
  const data = doc.data() ?? {};
  const out: Record<string, unknown> = { id: doc.id };
  for (const field of fields) {
    out[field] = toJsonValue(data[field]);
  }
  return out;
}
