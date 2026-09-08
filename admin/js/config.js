// Admin console configuration.
//
// Nothing secret lives in this file. A Firebase web API key is a public
// identifier, not a credential; access is decided by the `admin` custom claim
// checked server-side in `functions/src/admin/guard.ts`.

/** Config of the `yuztoo-admin-crm` Web app (separate from the mobile apps). */
export const FIREBASE_CONFIG = {
  apiKey: "AIzaSyAYKYlsHu-fO1l8xLh44Lub9s0pF04iY4g",
  authDomain: "yuztoo.firebaseapp.com",
  projectId: "yuztoo",
  storageBucket: "yuztoo.firebasestorage.app",
  messagingSenderId: "20266054150",
  appId: "1:20266054150:web:6e6be31fe9238bca5a4987",
};

/** Callables are deployed to europe-west1 — see `admin/guard.ts`. */
export const FUNCTIONS_REGION = "europe-west1";

/** Ports must match the `emulators` block in `firebase.json`. */
export const EMULATOR_PORTS = {
  auth: 9099,
  functions: 5001,
};

// Served from a real host → always production. Served locally → emulators by
// default, since that is what local work almost always means.
//
// To drive PRODUCTION data from a local page, append `?env=prod` to the URL.
// That is deliberately explicit and per-tab: every destructive action would
// then hit live merchant records, so it must never be the accidental default.
const envOverride = new URLSearchParams(window.location.search).get("env");
const isLocalHost = ["localhost", "127.0.0.1"].includes(
  window.location.hostname
);

export const USE_EMULATORS =
  envOverride === "prod" ? false : envOverride === "emulator" || isLocalHost;

/** Drives the warning banner — running live from a local page is unusual. */
export const IS_LOCAL_AGAINST_PROD = isLocalHost && !USE_EMULATORS;
