/**
 * P0 Firestore rules — loyalty_clients + active_validations.
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
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rulesPath = join(__dirname, '../../../firestore.rules');

const PROJECT_ID = 'yuztoo-rules-test';
const MERCHANT = 'm_rules';
const OWNER = 'owner_uid';
const CLIENT = 'client_uid';
const STRANGER = 'stranger_uid';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
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

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'merchants', MERCHANT), {
      owner_uid: OWNER,
      name: 'Rules Shop',
      passage_cooldown_enabled: true,
    });
  });
});

function authed(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function programSnapshot() {
  return {
    program_enabled: true,
    trigger_type: 'visitCount',
    visits_required: 10,
    passage_validation: 'manual',
  };
}

describe('P0 rules — loyalty_clients privilege', () => {
  test('client cannot create loyalty_clients doc', async () => {
    const db = authed(CLIENT);
    await assertFails(
      setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        updated_at: serverTimestamp(),
      }),
    );
  });

  test('merchant owner can create loyalty_clients on first validation', async () => {
    const db = authed(OWNER);
    await assertSucceeds(
      setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: serverTimestamp(),
        last_passage_at: serverTimestamp(),
        first_visit_at: serverTimestamp(),
      }),
    );
  });

  test('client cannot bump validated_passages', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: Timestamp.now(),
        last_passage_at: Timestamp.now(),
      });
    });

    const db = authed(CLIENT);
    await assertFails(
      updateDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 99,
      }),
    );
  });

  test('stranger cannot read another client loyalty doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: Timestamp.now(),
      });
    });

    const db = authed(STRANGER);
    await assertFails(
      getDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT)),
    );
  });

  test('client can read own loyalty doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: Timestamp.now(),
      });
    });

    const db = authed(CLIENT);
    await assertSucceeds(
      getDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT)),
    );
  });

  test('loyalty_clients delete always denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: Timestamp.now(),
      });
    });

    const ownerDb = authed(OWNER);
    await assertFails(
      deleteDoc(doc(ownerDb, 'merchants', MERCHANT, 'loyalty_clients', CLIENT)),
    );
  });
});

describe('P0 rules — passage cooldown on last_passage_at', () => {
  test('merchant cannot bump last_passage_at within 1 hour', async () => {
    const recent = Timestamp.fromMillis(Date.now() - 5 * 60 * 1000);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: recent,
        last_passage_at: recent,
      });
    });

    const db = authed(OWNER);
    await assertFails(
      updateDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 2,
        last_passage_at: serverTimestamp(),
        updated_at: serverTimestamp(),
      }),
    );
  });

  test('merchant can bump last_passage_at when cooldown disabled on merchant', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT), {
        owner_uid: OWNER,
        name: 'Rules Shop',
        passage_cooldown_enabled: false,
      });
      const recent = Timestamp.fromMillis(Date.now() - 5 * 60 * 1000);
      await setDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 1,
        cumulative_spend_euros: 0,
        pending_passages: 0,
        updated_at: recent,
        last_passage_at: recent,
      });
    });

    const db = authed(OWNER);
    await assertSucceeds(
      updateDoc(doc(db, 'merchants', MERCHANT, 'loyalty_clients', CLIENT), {
        validated_passages: 2,
        last_passage_at: serverTimestamp(),
        updated_at: serverTimestamp(),
      }),
    );
  });
});

describe('P0 rules — active_validations', () => {
  test('client can create awaiting vitrine session for self', async () => {
    const db = authed(CLIENT);
    await assertSucceeds(
      setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        client_uid: CLIENT,
        client_display_name: 'Client',
        created_at: serverTimestamp(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
      }),
    );
  });

  test('client cannot create session as someone else', async () => {
    const db = authed(CLIENT);
    await assertFails(
      setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', STRANGER), {
        client_uid: STRANGER,
        client_display_name: 'X',
        created_at: serverTimestamp(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
      }),
    );
  });

  test('client cannot set status completed', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        client_uid: CLIENT,
        client_display_name: 'Client',
        created_at: Timestamp.now(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
      });
    });

    const db = authed(CLIENT);
    await assertFails(
      updateDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        status: 'completed',
        completed_at: serverTimestamp(),
        result_validated_delta: 1,
        result_spend_delta: 0,
      }),
    );
  });

  test('client can cancel awaiting session', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        client_uid: CLIENT,
        client_display_name: 'Client',
        created_at: Timestamp.now(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
      });
    });

    const db = authed(CLIENT);
    await assertSucceeds(
      updateDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        status: 'cancelled',
        cancel_reason: 'client_cancelled',
      }),
    );
  });

  test('merchant can complete awaiting vitrine session', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        client_uid: CLIENT,
        client_display_name: 'Client',
        created_at: Timestamp.now(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
      });
    });

    const db = authed(OWNER);
    await assertSucceeds(
      updateDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        status: 'completed',
        completed_at: serverTimestamp(),
        result_validated_delta: 1,
        result_spend_delta: 0,
      }),
    );
  });

  test('merchant cannot complete BLE session without merchant_ble_connected_at', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        client_uid: CLIENT,
        client_display_name: 'Client',
        created_at: Timestamp.now(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
        source: 'ble',
        client_ble_connected_at: Timestamp.now(),
      });
    });

    const db = authed(OWNER);
    await assertFails(
      updateDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        status: 'completed',
        completed_at: serverTimestamp(),
        result_validated_delta: 1,
        result_spend_delta: 0,
      }),
    );
  });

  test('merchant owner cannot create self BLE session as client', async () => {
    const db = authed(OWNER);
    await assertFails(
      setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', OWNER), {
        client_uid: OWNER,
        client_display_name: 'Owner',
        created_at: serverTimestamp(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
        source: 'ble',
        client_ble_connected_at: serverTimestamp(),
      }),
    );
  });

  test('stranger cannot read active_validations', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT), {
        client_uid: CLIENT,
        client_display_name: 'Client',
        created_at: Timestamp.now(),
        status: 'awaiting',
        program_snapshot: programSnapshot(),
      });
    });

    const db = authed(STRANGER);
    await assertFails(
      getDoc(doc(db, 'merchants', MERCHANT, 'active_validations', CLIENT)),
    );
  });
});
