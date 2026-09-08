// Thin wrapper over Firebase Auth and the admin callables.
//
// This module is the console's entire data layer. There is no Firestore
// client here on purpose: the browser holds no database privileges, so every
// read and write goes through a callable that re-checks the `admin` claim
// server-side. Adding a direct Firestore import would quietly undo that.

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import {
  getAuth,
  connectAuthEmulator,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  getIdTokenResult,
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import {
  getFunctions,
  connectFunctionsEmulator,
  httpsCallable,
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-functions.js";
import {
  FIREBASE_CONFIG,
  FUNCTIONS_REGION,
  EMULATOR_PORTS,
  USE_EMULATORS,
} from "./config.js";

const app = initializeApp(FIREBASE_CONFIG);
export const auth = getAuth(app);
const functions = getFunctions(app, FUNCTIONS_REGION);

if (USE_EMULATORS) {
  connectAuthEmulator(auth, `http://127.0.0.1:${EMULATOR_PORTS.auth}`, {
    disableWarnings: true,
  });
  connectFunctionsEmulator(functions, "127.0.0.1", EMULATOR_PORTS.functions);
}

/**
 * Wrap a callable so the UI receives plain data and predictable errors.
 * Firebase surfaces `HttpsError` as `{ code, message }`; the codes the
 * backend uses map to specific user-facing outcomes.
 */
function callable(name) {
  const fn = httpsCallable(functions, name);
  return async (payload = {}) => {
    try {
      const result = await fn(payload);
      return result.data;
    } catch (error) {
      throw normalizeError(error, name);
    }
  };
}

export class AdminApiError extends Error {
  constructor(code, message, fnName) {
    super(message);
    this.code = code;
    this.fnName = fnName;
  }
}

function normalizeError(error, fnName) {
  const code = (error?.code ?? "unknown").replace(/^functions\//, "");

  const friendly = {
    "permission-denied":
      "Votre compte n'a pas les droits administrateur.",
    unauthenticated: "Session expirée — reconnectez-vous.",
    "failed-precondition":
      error?.message ??
      "Action impossible dans l'état actuel.",
    "already-exists": error?.message ?? "Cet élément existe déjà.",
    "not-found": "Introuvable.",
    "invalid-argument": error?.message ?? "Données invalides.",
    unavailable:
      "Backend injoignable. Les émulateurs Firebase sont-ils démarrés ?",
    internal: "Erreur serveur — consultez les logs des Cloud Functions.",
  }[code];

  return new AdminApiError(code, friendly ?? error?.message ?? String(error), fnName);
}

// ── Auth ─────────────────────────────────────────────────────────────────────

export function watchAuth(callback) {
  return onAuthStateChanged(auth, callback);
}

export function login(email, password) {
  return signInWithEmailAndPassword(auth, email, password).catch((e) => {
    throw normalizeError(e, "signIn");
  });
}

export function logout() {
  return signOut(auth);
}

/**
 * Read the `admin` custom claim from a freshly minted ID token.
 *
 * `forceRefresh` matters: after `set_admin_claim.mjs` grants the claim, a
 * cached token still says otherwise for up to an hour. This is only a UI
 * gate — the authoritative check runs in every callable.
 */
export async function isAdmin(user) {
  if (!user) return false;
  const token = await getIdTokenResult(user, true);
  return token.claims.admin === true;
}

// ── Dashboard ────────────────────────────────────────────────────────────────

export const getOverview = callable("adminGetOverview");

// ── Stores ───────────────────────────────────────────────────────────────────

export const listMerchants = callable("adminListMerchants");
export const getMerchant = callable("adminGetMerchant");
export const createMerchant = callable("adminCreateMerchant");
export const updateMerchant = callable("adminUpdateMerchant");
export const setMerchantStatus = callable("adminSetMerchantStatus");
export const softDeleteMerchant = callable("adminSoftDeleteMerchant");
export const restoreMerchant = callable("adminRestoreMerchant");

// ── Clients ──────────────────────────────────────────────────────────────────

export const listUsers = callable("adminListUsers");
export const getUser = callable("adminGetUser");
export const createClient = callable("adminCreateClient");
export const updateUser = callable("adminUpdateUser");
export const setUserStatus = callable("adminSetUserStatus");
export const softDeleteUser = callable("adminSoftDeleteUser");
export const restoreUser = callable("adminRestoreUser");
