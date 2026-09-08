/**
 * Grant or revoke back-office access.
 *
 * This is the root of trust for the admin CRM. The `admin: true` custom claim
 * lives in the Firebase Auth token and can only be minted by the Admin SDK —
 * there is no document write, callable, or security rule anywhere in the
 * project that can produce it. Which means back-office access cannot be
 * escalated from inside the app, only granted here, from a machine holding
 * Google credentials for the project.
 *
 * Run it deliberately, from your own machine, and keep the list short.
 *
 * Usage:
 *   cd functions
 *   gcloud auth application-default login      # once, if not already done
 *
 *   node scripts/set_admin_claim.mjs --list
 *   node scripts/set_admin_claim.mjs --email someone@example.com --grant
 *   node scripts/set_admin_claim.mjs --uid  aBc123...            --grant
 *   node scripts/set_admin_claim.mjs --email someone@example.com --revoke
 *
 * After a change the target must sign out and back in (or wait up to an hour)
 * before their ID token carries the new claim. `--grant` and `--revoke` both
 * revoke existing refresh tokens to force that immediately.
 */
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

const PROJECT_ID = "yuztoo";

function argValue(flag) {
  const index = process.argv.indexOf(flag);
  if (index === -1) return null;
  const value = process.argv[index + 1];
  return value && !value.startsWith("--") ? value : null;
}

const wantsList = process.argv.includes("--list");
const grant = process.argv.includes("--grant");
const revoke = process.argv.includes("--revoke");
const email = argValue("--email");
const uidArg = argValue("--uid");

admin.initializeApp({ projectId: PROJECT_ID });
const auth = admin.auth();

/** Page through every account and report the ones holding the claim. */
async function listAdmins() {
  const admins = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      if (user.customClaims?.admin === true) {
        admins.push({
          uid: user.uid,
          email: user.email ?? null,
          disabled: user.disabled,
          lastSignIn: user.metadata.lastSignInTime ?? null,
        });
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);

  if (admins.length === 0) {
    console.log("No accounts currently hold the admin claim.");
    return;
  }
  console.log(`${admins.length} admin account(s):`);
  console.table(admins);
}

async function setClaim(shouldBeAdmin) {
  const user = uidArg
    ? await auth.getUser(uidArg)
    : await auth.getUserByEmail(email);

  // Preserve any unrelated claims rather than replacing the whole object.
  const claims = { ...(user.customClaims ?? {}) };
  if (shouldBeAdmin) {
    claims.admin = true;
  } else {
    delete claims.admin;
  }

  await auth.setCustomUserClaims(user.uid, claims);

  // Force a token refresh so the change takes effect now, not in an hour.
  await auth.revokeRefreshTokens(user.uid);

  console.log(
    `${shouldBeAdmin ? "Granted" : "Revoked"} admin for ${
      user.email ?? user.uid
    } (uid ${user.uid}).`
  );
  console.log("They must sign in again for the change to apply.");
}

async function main() {
  if (wantsList) {
    await listAdmins();
    return;
  }

  if (grant === revoke) {
    console.error("Specify exactly one of --grant or --revoke (or --list).");
    process.exitCode = 1;
    return;
  }
  if (!email && !uidArg) {
    console.error("Specify --email <address> or --uid <uid>.");
    process.exitCode = 1;
    return;
  }

  await setClaim(grant);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
