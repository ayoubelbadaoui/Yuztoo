import {
  cityCandidateKeys,
  cityKey,
  merchantCityKeys,
  sameKeys,
} from "../merchant_city_keys_core";

// Mirrors test/core/utils/city_match_test.dart: the app and the server must
// produce the same keys, or Découvrir's Firestore query misses shops.
describe("cityKey (parity with CityMatch.key)", () => {
  it("drops accents, case, hyphens and apostrophes", () => {
    expect(cityKey("Châtenois-les-Forges")).toBe("chatenois les forges");
    expect(cityKey("Fêche-l'Église")).toBe(cityKey("FECHE L EGLISE"));
    expect(cityKey("  Belfort ")).toBe("belfort");
    expect(cityKey("Héricourt")).toBe("hericourt");
    expect(cityKey("Montbéliard")).toBe("montbeliard");
  });

  it("expands st / ste", () => {
    expect(cityKey("St-Dizier-l'Évêque")).toBe(cityKey("Saint-Dizier-l'Évêque"));
    expect(cityKey("Ste Suzanne")).toBe(cityKey("Sainte-Suzanne"));
  });

  it("keeps distinct communes distinct", () => {
    expect(cityKey("Lepuix")).not.toBe(cityKey("Lepuix-Neuf"));
  });
});

describe("cityCandidateKeys", () => {
  it("splits legacy multi-city labels", () => {
    expect(new Set(cityCandidateKeys("Belfort/ andelnans"))).toEqual(
      new Set(["belfort/ andelnans", "belfort", "andelnans"])
    );
    expect(cityCandidateKeys("Giromagny")).toEqual(["giromagny"]);
  });
});

describe("merchantCityKeys", () => {
  it("combines the free-text city and the official commune name", () => {
    expect(
      merchantCityKeys({ city: "hericourt", city_metadata: { name: "Héricourt" } })
    ).toEqual(["hericourt"]);
    expect(
      merchantCityKeys({ city: "Belfort/ andelnans", city_metadata: { name: "Andelnans" } })
    ).toEqual(["andelnans", "belfort", "belfort/ andelnans"]);
  });

  it("is empty without a city", () => {
    expect(merchantCityKeys({})).toEqual([]);
  });
});

describe("sameKeys", () => {
  it("compares as sets in any order", () => {
    expect(sameKeys(["b", "a"], ["a", "b"])).toBe(true);
    expect(sameKeys(["a"], ["a", "b"])).toBe(false);
    expect(sameKeys(undefined, [])).toBe(false);
  });
});
