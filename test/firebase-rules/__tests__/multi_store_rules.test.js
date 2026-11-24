/**
 * Multi-store (enseignes) Firestore rules — roles owner / manager / employee.
 * Run via: npm test (starts Firestore emulator via firebase emulators:exec)
 */
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  deleteDoc,
  where,
  writeBatch,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rulesPath = join(__dirname, '../../../firestore.rules');

const ORG = 'org_dupont';
const OWNER = 'owner_uid';
const MANAGER = 'manager_uid';
const EMPLOYEE = 'employee_uid';
const OTHER_MANAGER = 'other_manager_uid';
const STRANGER = 'stranger_uid';
const CLIENT = 'client_uid';
const STORE_A = 'store_a';
const STORE_B = 'store_b';
const SOLO = 'solo_store';
const SOLO_OWNER = 'solo_owner_uid';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'yuztoo-rules-test',
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
      host: '127.0.0.1',
      port: 9555,
    },
  });
});

afterAll(async () => {
  await testEnv?.cleanup();
});

function member(uid, role, storeIds, status = 'active') {
  return {
    uid,
    org_id: ORG,
    role,
    store_ids: storeIds,
    status,
  };
}

function inFuture(hours = 24) {
  return Timestamp.fromMillis(Date.now() + hours * 3600 * 1000);
}

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'organizations', ORG), {
      name: 'Boulangeries Dupont',
      owner_uid: OWNER,
      loyalty_mode: 'per_store',
    });
    for (const id of [STORE_A, STORE_B]) {
      await setDoc(doc(db, 'merchants', id), {
        owner_uid: OWNER,
        organization_id: ORG,
        name: `Dupont ${id}`,
        status: 'inactive',
      });
    }
    await setDoc(doc(db, 'merchants', SOLO), {
      owner_uid: SOLO_OWNER,
      name: 'Solo shop',
      status: 'active',
    });
    await setDoc(doc(db, `organizations/${ORG}/members/${OWNER}`), member(OWNER, 'owner', []));
    await setDoc(doc(db, `organizations/${ORG}/members/${MANAGER}`), member(MANAGER, 'manager', [STORE_A]));
    await setDoc(doc(db, `organizations/${ORG}/members/${EMPLOYEE}`), member(EMPLOYEE, 'employee', [STORE_A]));
    await setDoc(doc(db, `organizations/${ORG}/members/${OTHER_MANAGER}`), member(OTHER_MANAGER, 'manager', [STORE_B]));
  });
});

function authed(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function loyaltyCreate() {
  return {
    validated_passages: 1,
    cumulative_spend_euros: 0,
    updated_at: serverTimestamp(),
  };
}

describe('single-store merchants are unchanged', () => {
  test('solo owner edits his vitrine', async () => {
    await assertSucceeds(updateDoc(doc(authed(SOLO_OWNER), 'merchants', SOLO), { name: 'Solo 2' }));
  });

  test('solo owner manages promotions and loyalty', async () => {
    const db = authed(SOLO_OWNER);
    await assertSucceeds(setDoc(doc(db, `merchants/${SOLO}/promotions/p1`), { title: 'x' }));
    await assertSucceeds(setDoc(doc(db, `merchants/${SOLO}/loyalty_clients/${CLIENT}`), loyaltyCreate()));
  });

  test('enseigne members get nothing on a store outside the enseigne', async () => {
    for (const uid of [OWNER, MANAGER, EMPLOYEE]) {
      const db = authed(uid);
      await assertFails(updateDoc(doc(db, 'merchants', SOLO), { name: 'hack' }));
      await assertFails(setDoc(doc(db, `merchants/${SOLO}/promotions/p1`), { title: 'x' }));
      await assertFails(getDoc(doc(db, `merchants/${SOLO}/loyalty_clients/${CLIENT}`)));
    }
  });

  test('solo owner cannot attach his store to someone else\'s enseigne', async () => {
    await assertFails(updateDoc(doc(authed(SOLO_OWNER), 'merchants', SOLO), { organization_id: ORG }));
  });
});

describe('creating an enseigne', () => {
  test('owner creates enseigne + store + own membership in one batch', async () => {
    const db = authed('new_owner');
    const batch = writeBatch(db);
    batch.set(doc(db, 'organizations', 'org_new'), {
      name: 'Nouvelle enseigne',
      owner_uid: 'new_owner',
      loyalty_mode: 'shared',
    });
    batch.set(doc(db, 'merchants', 'new_store'), {
      owner_uid: 'new_owner',
      organization_id: 'org_new',
      name: 'Store 1',
      status: 'inactive',
    });
    batch.set(doc(db, 'organizations/org_new/members/new_owner'), {
      uid: 'new_owner',
      org_id: 'org_new',
      role: 'owner',
      store_ids: [],
      status: 'active',
    });
    await assertSucceeds(batch.commit());
  });

  test('cannot create an enseigne for another user', async () => {
    await assertFails(setDoc(doc(authed(STRANGER), 'organizations', 'org_x'), {
      name: 'X',
      owner_uid: OWNER,
      loyalty_mode: 'per_store',
    }));
  });

  test('cannot create a store inside an enseigne you do not own', async () => {
    await assertFails(setDoc(doc(authed(STRANGER), 'merchants', 'evil'), {
      owner_uid: STRANGER,
      organization_id: ORG,
      name: 'Evil',
    }));
  });

  test('owner adds a new store to his enseigne', async () => {
    await assertSucceeds(setDoc(doc(authed(OWNER), 'merchants', 'store_c'), {
      owner_uid: OWNER,
      organization_id: ORG,
      name: 'Dupont C',
      status: 'inactive',
    }));
  });

  test('loyalty_mode must be valid', async () => {
    await assertFails(updateDoc(doc(authed(OWNER), 'organizations', ORG), { loyalty_mode: 'whatever' }));
    await assertSucceeds(updateDoc(doc(authed(OWNER), 'organizations', ORG), { loyalty_mode: 'shared' }));
  });

  test('only the owner edits the enseigne', async () => {
    await assertFails(updateDoc(doc(authed(MANAGER), 'organizations', ORG), { name: 'Hack' }));
  });
});

describe('gérant (manager)', () => {
  test('edits the vitrine of his store', async () => {
    await assertSucceeds(updateDoc(doc(authed(MANAGER), 'merchants', STORE_A), { description: 'Pain' }));
  });

  test('cannot edit a store he does not run', async () => {
    await assertFails(updateDoc(doc(authed(MANAGER), 'merchants', STORE_B), { description: 'Pain' }));
  });

  test('cannot change ownership, enseigne link or plan', async () => {
    const db = authed(MANAGER);
    await assertFails(updateDoc(doc(db, 'merchants', STORE_A), { owner_uid: MANAGER }));
    await assertFails(updateDoc(doc(db, 'merchants', STORE_A), { organization_id: null }));
    await assertFails(updateDoc(doc(db, 'merchants', STORE_A), { subscription_plan: 'premium' }));
  });

  test('manages promotions, CRM and notifications of his store', async () => {
    const db = authed(MANAGER);
    await assertSucceeds(setDoc(doc(db, `merchants/${STORE_A}/promotions/p1`), { title: 'x' }));
    await assertSucceeds(setDoc(doc(db, `merchants/${STORE_A}/clients/${CLIENT}`), { note: 'VIP' }));
    await assertSucceeds(getDocs(collection(db, `merchants/${STORE_A}/sent_notifications`)));
    await assertFails(setDoc(doc(db, `merchants/${STORE_B}/promotions/p1`), { title: 'x' }));
  });

  test('validates passages in his store', async () => {
    await assertSucceeds(setDoc(
      doc(authed(MANAGER), `merchants/${STORE_A}/loyalty_clients/${CLIENT}`),
      loyaltyCreate(),
    ));
  });

  test('invites an employee for his store only', async () => {
    const db = authed(MANAGER);
    const base = {
      org_id: ORG,
      role: 'employee',
      status: 'pending',
      created_by: MANAGER,
      expires_at: inFuture(),
    };
    await assertSucceeds(setDoc(doc(db, `organizations/${ORG}/invites/i1`), { ...base, store_ids: [STORE_A] }));
    await assertFails(setDoc(doc(db, `organizations/${ORG}/invites/i2`), { ...base, store_ids: [STORE_B] }));
    await assertFails(setDoc(doc(db, `organizations/${ORG}/invites/i3`), {
      ...base,
      role: 'manager',
      store_ids: [STORE_A],
    }));
  });

  test('cannot promote himself or touch other managers', async () => {
    const db = authed(MANAGER);
    await assertFails(updateDoc(doc(db, `organizations/${ORG}/members/${MANAGER}`), { role: 'owner' }));
    await assertFails(updateDoc(doc(db, `organizations/${ORG}/members/${MANAGER}`), { store_ids: [STORE_A, STORE_B] }));
    await assertFails(updateDoc(doc(db, `organizations/${ORG}/members/${OTHER_MANAGER}`), { status: 'removed' }));
  });

  test('can remove an employee of his store', async () => {
    await assertSucceeds(updateDoc(
      doc(authed(MANAGER), `organizations/${ORG}/members/${EMPLOYEE}`),
      { status: 'removed' },
    ));
  });
});

describe('employé (employee)', () => {
  test('validates passages in his store', async () => {
    const db = authed(EMPLOYEE);
    await assertSucceeds(setDoc(doc(db, `merchants/${STORE_A}/loyalty_clients/${CLIENT}`), loyaltyCreate()));
    await assertSucceeds(getDoc(doc(db, `merchants/${STORE_A}/active_validations/${CLIENT}`)));
  });

  test('cannot validate in another store', async () => {
    await assertFails(setDoc(
      doc(authed(EMPLOYEE), `merchants/${STORE_B}/loyalty_clients/${CLIENT}`),
      loyaltyCreate(),
    ));
  });

  test('cannot edit vitrine, promotions or CRM', async () => {
    const db = authed(EMPLOYEE);
    await assertFails(updateDoc(doc(db, 'merchants', STORE_A), { description: 'x' }));
    await assertFails(setDoc(doc(db, `merchants/${STORE_A}/promotions/p1`), { title: 'x' }));
    await assertFails(getDoc(doc(db, `merchants/${STORE_A}/clients/${CLIENT}`)));
  });

  test('cannot invite anyone', async () => {
    await assertFails(setDoc(doc(authed(EMPLOYEE), `organizations/${ORG}/invites/i1`), {
      org_id: ORG,
      role: 'employee',
      store_ids: [STORE_A],
      status: 'pending',
      created_by: EMPLOYEE,
      expires_at: inFuture(),
    }));
  });

  test('can leave the team', async () => {
    await assertSucceeds(updateDoc(
      doc(authed(EMPLOYEE), `organizations/${ORG}/members/${EMPLOYEE}`),
      { status: 'removed' },
    ));
  });

  test('loses access once removed', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await updateDoc(
        doc(context.firestore(), `organizations/${ORG}/members/${EMPLOYEE}`),
        { status: 'removed' },
      );
    });
    await assertFails(setDoc(
      doc(authed(EMPLOYEE), `merchants/${STORE_A}/loyalty_clients/${CLIENT}`),
      loyaltyCreate(),
    ));
  });
});

describe('enseigne owner', () => {
  test('keeps full access to every store', async () => {
    const db = authed(OWNER);
    await assertSucceeds(updateDoc(doc(db, 'merchants', STORE_B), { description: 'x' }));
    await assertSucceeds(setDoc(doc(db, `merchants/${STORE_B}/promotions/p1`), { title: 'x' }));
  });

  test('cannot demote himself', async () => {
    await assertFails(updateDoc(doc(authed(OWNER), `organizations/${ORG}/members/${OWNER}`), { role: 'manager' }));
  });

  test('adds a manager directly and removes members', async () => {
    const db = authed(OWNER);
    await assertSucceeds(setDoc(doc(db, `organizations/${ORG}/members/new_manager`), {
      uid: 'new_manager',
      org_id: ORG,
      role: 'manager',
      store_ids: [STORE_B],
      status: 'active',
    }));
    await assertSucceeds(deleteDoc(doc(db, `organizations/${ORG}/members/${EMPLOYEE}`)));
  });

  test('cannot make someone else owner', async () => {
    await assertFails(setDoc(doc(authed(OWNER), `organizations/${ORG}/members/x`), {
      uid: 'x',
      org_id: ORG,
      role: 'owner',
      store_ids: [],
      status: 'active',
    }));
  });
});

describe('invitations', () => {
  async function seedInvite(id, overrides = {}) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `organizations/${ORG}/invites/${id}`), {
        org_id: ORG,
        role: 'manager',
        store_ids: [STORE_B],
        status: 'pending',
        created_by: OWNER,
        expires_at: inFuture(),
        ...overrides,
      });
    });
  }

  function acceptBatch(db, uid, inviteId, role = 'manager', storeIds = [STORE_B]) {
    const batch = writeBatch(db);
    batch.set(doc(db, `organizations/${ORG}/members/${uid}`), {
      uid,
      org_id: ORG,
      role,
      store_ids: storeIds,
      status: 'active',
      invite_id: inviteId,
    });
    batch.update(doc(db, `organizations/${ORG}/invites/${inviteId}`), {
      status: 'accepted',
      accepted_by: uid,
      accepted_at: serverTimestamp(),
    });
    return batch.commit();
  }

  test('invitee opens the invite by id and accepts it', async () => {
    await seedInvite('inv1');
    const db = authed('new_guy');
    await assertSucceeds(getDoc(doc(db, `organizations/${ORG}/invites/inv1`)));
    await assertSucceeds(acceptBatch(db, 'new_guy', 'inv1'));
    await assertSucceeds(updateDoc(doc(db, 'merchants', STORE_B), { description: 'ok' }));
  });

  test('strangers cannot list invites', async () => {
    await seedInvite('inv1');
    await assertFails(getDocs(collection(authed(STRANGER), `organizations/${ORG}/invites`)));
  });

  test('an invite cannot be reused by a second account', async () => {
    await seedInvite('inv1');
    await assertSucceeds(acceptBatch(authed('first'), 'first', 'inv1'));
    await assertFails(acceptBatch(authed('second'), 'second', 'inv1'));
  });

  test('cannot join without consuming the invite', async () => {
    await seedInvite('inv1');
    const db = authed('sneaky');
    await assertFails(setDoc(doc(db, `organizations/${ORG}/members/sneaky`), {
      uid: 'sneaky',
      org_id: ORG,
      role: 'manager',
      store_ids: [STORE_B],
      status: 'active',
      invite_id: 'inv1',
    }));
  });

  test('cannot upgrade the role or stores of an invite', async () => {
    await seedInvite('inv1', { role: 'employee', store_ids: [STORE_A] });
    await assertFails(acceptBatch(authed('x'), 'x', 'inv1', 'manager', [STORE_A]));
    await assertFails(acceptBatch(authed('x'), 'x', 'inv1', 'employee', [STORE_A, STORE_B]));
  });

  test('expired or revoked invites are refused', async () => {
    await seedInvite('old', { expires_at: Timestamp.fromMillis(Date.now() - 1000) });
    await seedInvite('rev', { status: 'revoked' });
    await assertFails(acceptBatch(authed('x'), 'x', 'old'));
    await assertFails(acceptBatch(authed('y'), 'y', 'rev'));
  });

  test('owner revokes a pending invite', async () => {
    await seedInvite('inv1');
    await assertSucceeds(updateDoc(doc(authed(OWNER), `organizations/${ORG}/invites/inv1`), { status: 'revoked' }));
  });
});

describe('memberships lookup', () => {
  test('a user lists only his own memberships', async () => {
    const db = authed(MANAGER);
    await assertSucceeds(getDocs(query(collectionGroup(db, 'members'), where('uid', '==', MANAGER))));
    await assertFails(getDocs(query(collectionGroup(db, 'members'), where('uid', '==', OWNER))));
  });

  test('team members see the team, strangers do not', async () => {
    await assertSucceeds(getDocs(collection(authed(EMPLOYEE), `organizations/${ORG}/members`)));
    await assertFails(getDocs(collection(authed(STRANGER), `organizations/${ORG}/members`)));
  });
});
