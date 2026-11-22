/**
 * Pure helpers for force-update + Actu YuzToo admin callables.
 */

const firestoreFn: any = jest.fn(() => ({}));
firestoreFn.Timestamp = {
  fromDate: (d: Date) => ({
    toDate: () => d,
    seconds: Math.floor(d.getTime() / 1000),
    nanoseconds: 0,
  }),
  fromMillis: (ms: number) => ({
    toDate: () => new Date(ms),
    seconds: Math.floor(ms / 1000),
    nanoseconds: 0,
  }),
  now: () => ({ toMillis: () => Date.now() }),
};
firestoreFn.FieldValue = {
  serverTimestamp: () => "__server_ts__",
};

jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: firestoreFn,
}));

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn(() => ({})),
  FieldValue: firestoreFn.FieldValue,
  Timestamp: {
    fromDate: (d: Date) => ({
      toDate: () => d,
      seconds: Math.floor(d.getTime() / 1000),
      nanoseconds: 0,
    }),
  },
}));

const noopFn = jest.fn().mockReturnThis();
const httpsRegion = { onCall: noopFn, onRequest: noopFn };
const regionMock: any = { https: httpsRegion };
regionMock.runWith = jest.fn().mockReturnValue(regionMock);

jest.mock("firebase-functions", () => ({
  region: jest.fn().mockReturnValue(regionMock),
  https: {
    HttpsError: class HttpsError extends Error {
      code: string;
      constructor(code: string, message: string) {
        super(message);
        this.code = code;
      }
    },
  },
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { normalizeForceUpdateInput } from "../admin/crm_force_update";
import {
  canPublishYuztooNewsLive,
  parseYuztooNewsInput,
} from "../admin/crm_yuztoo_news";
import {
  clientDisplayName,
  maskEmail,
  maskPhone,
  phoneCandidates,
} from "../admin/crm_yuztoo_news_lookup";

describe("normalizeForceUpdateInput", () => {
  it("defaults missing fields safely", () => {
    expect(normalizeForceUpdateInput({})).toEqual({
      force: false,
      android_min_build: 0,
      ios_min_build: 0,
      message_fr: null,
      android_store_url: null,
      ios_store_url: null,
    });
  });

  it("accepts a full payload", () => {
    expect(
      normalizeForceUpdateInput({
        force: true,
        android_min_build: 70,
        ios_min_build: 71,
        message_fr: "  Please update  ",
        android_store_url: "https://play.google.com/store/apps/details?id=x",
        ios_store_url: "https://apps.apple.com/app/id1",
      })
    ).toEqual({
      force: true,
      android_min_build: 70,
      ios_min_build: 71,
      message_fr: "Please update",
      android_store_url: "https://play.google.com/store/apps/details?id=x",
      ios_store_url: "https://apps.apple.com/app/id1",
    });
  });

  it("rejects negative build numbers", () => {
    expect(() =>
      normalizeForceUpdateInput({ android_min_build: -1 })
    ).toThrow(/android_min_build/);
  });

  it("rejects non-http store URLs", () => {
    expect(() =>
      normalizeForceUpdateInput({ android_store_url: "ftp://x" })
    ).toThrow(/android_store_url/);
  });
});

describe("parseYuztooNewsInput", () => {
  it("parses ISO publish_on and required fields", () => {
    const parsed = parseYuztooNewsInput({
      title: "Hello",
      body: "World body",
      publish_on: "2026-11-21T10:00:00.000Z",
      active: true,
      image_url: "https://cdn.example/a.jpg",
      cta_label: "Voir",
      cta_url: "https://yuztoo.com",
    });
    expect(parsed.title).toBe("Hello");
    expect(parsed.body).toBe("World body");
    expect(parsed.active).toBe(true);
    expect(parsed.image_url).toBe("https://cdn.example/a.jpg");
    expect(parsed.cta_url).toBe("https://yuztoo.com");
    expect(parsed.publish_on.toDate().toISOString()).toBe(
      "2026-11-21T10:00:00.000Z"
    );
  });

  it("defaults active to true when omitted", () => {
    const parsed = parseYuztooNewsInput({
      title: "T",
      body: "B",
      publish_on: "2026-01-01T00:00:00.000Z",
    });
    expect(parsed.active).toBe(true);
  });

  it("rejects missing title", () => {
    expect(() =>
      parseYuztooNewsInput({
        body: "B",
        publish_on: "2026-01-01T00:00:00.000Z",
      })
    ).toThrow(/title/);
  });

  it("rejects non-http cta_url", () => {
    expect(() =>
      parseYuztooNewsInput({
        title: "T",
        body: "B",
        publish_on: "2026-01-01T00:00:00.000Z",
        cta_url: "javascript:alert(1)",
      })
    ).toThrow(/cta_url/);
  });
});

describe("parseYuztooNewsInput — button kinds", () => {
  const base = {
    title: "T",
    body: "B",
    publish_on: "2026-01-01T00:00:00.000Z",
  };

  it("text only: drops a label that has no target", () => {
    const parsed = parseYuztooNewsInput({ ...base, cta_label: "Voir" });
    expect(parsed.cta_label).toBeNull();
    expect(parsed.cta_url).toBeNull();
    expect(parsed.cta_merchant_id).toBeNull();
  });

  it("shop button: keeps merchant id, label and shop name", () => {
    const parsed = parseYuztooNewsInput({
      ...base,
      cta_label: "Voir la boutique",
      cta_merchant_id: "m1",
      cta_merchant_label: "Boulangerie du Marché",
    });
    expect(parsed.cta_merchant_id).toBe("m1");
    expect(parsed.cta_label).toBe("Voir la boutique");
    expect(parsed.cta_merchant_label).toBe("Boulangerie du Marché");
  });

  it("link button: no shop name without a shop id", () => {
    const parsed = parseYuztooNewsInput({
      ...base,
      cta_url: "https://yuztoo.com",
      cta_merchant_label: "stale",
    });
    expect(parsed.cta_url).toBe("https://yuztoo.com");
    expect(parsed.cta_merchant_label).toBeNull();
  });
});

describe("Actu test-account lookup helpers", () => {
  it("masks email and phone", () => {
    expect(maskEmail("ayoub@gmail.com")).toBe("ay***@gmail.com");
    expect(maskEmail("a@x.fr")).toBe("a***@x.fr");
    expect(maskEmail("nope")).toBeNull();
    expect(maskPhone("+33612345678")).toBe("+33 ••• •• 78");
    expect(maskPhone("+212612345678")).toBe("+212 ••• •• 78");
  });

  it("expands typed phones into stored E.164 candidates", () => {
    expect(phoneCandidates("06 12 34 56 78")).toEqual([
      "+33612345678",
      "+212612345678",
      "0612345678",
    ]);
    expect(phoneCandidates("0033612345678")).toEqual([
      "+33612345678",
      "0033612345678",
    ]);
    expect(phoneCandidates("+212 6 12 34 56 78")).toEqual(["+212612345678"]);
    expect(phoneCandidates("hello")).toEqual([]);
  });

  it("builds a display name from mixed fields", () => {
    expect(clientDisplayName({ displayName: "Sara" })).toBe("Sara");
    expect(clientDisplayName({ firstName: "Sara", lastName: "Mansouri" })).toBe(
      "Sara M."
    );
    expect(clientDisplayName({})).toBe("Client sans nom");
  });
});

describe("canPublishYuztooNewsLive", () => {
  it("requires preview + test account + preview stamp", () => {
    expect(
      canPublishYuztooNewsLive({
        release_status: "preview",
        test_account_id: "uid1",
        preview_activated_at: "2026-11-21T10:00:00.000Z",
      })
    ).toBe(true);
    expect(
      canPublishYuztooNewsLive({
        release_status: "draft",
        test_account_id: "uid1",
        preview_activated_at: "2026-11-21T10:00:00.000Z",
      })
    ).toBe(false);
    expect(
      canPublishYuztooNewsLive({
        release_status: "preview",
        test_account_id: null,
        preview_activated_at: "2026-11-21T10:00:00.000Z",
      })
    ).toBe(false);
    expect(
      canPublishYuztooNewsLive({
        release_status: "preview",
        test_account_id: "uid1",
        preview_activated_at: null,
      })
    ).toBe(false);
  });
});
