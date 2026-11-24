# Découvrir — bassins géographiques (contrat produit)

**Status :** binding — toute évolution de Découvrir doit respecter ce document.  
**Updated :** 2026-11-24

## Règle

Un client lié à une commune **C** voit, dans **Proche de moi**, tous les commerces **actifs** dont la ville appartient au **même bassin** que C.

### Définition du bassin

| Cas | Bassin | Exemple |
|---|---|---|
| Commune du **Territoire de Belfort (90)** | **Tout le département 90** (~101 communes) | Petit-Croix → Belfort + Giromagny + Delle + … |
| Toute autre commune en France | **EPCI** (intercommunalité / « pays ») officiel | Héricourt → Pays d’Héricourt ; Montbéliard → PMA |

Héricourt, Montbéliard et Belfort **ne se croisent pas** automatiquement (départements / EPCI distincts).

### Conséquences produit

- Petit-Croix **ou** Belfort → mêmes commerces du bassin 90.
- Village du Pays d’Héricourt **ou** Héricourt → commerces de cet EPCI uniquement.
- La recherche par nom reste **nationale** (hors filtre bassin).

## Implémentation

- Expander : `lib/feature/discovery/domain/city_agglomeration_expander.dart`
- Bassins bundlés (offline) : `lib/core/utils/launch_area_basins.dart`
- Index Firestore : `merchants.city_keys` (+ trigger `onMerchantCityKeysSync`)
- Visibilité catalogue : commerces `status == active` (l’abonnement ne masque plus Découvrir)

## Tests non-régression

- `test/feature/discovery/domain/city_agglomeration_expander_test.dart`
- Petit-Croix / Belfort / Giromagny → peers 90
- Héricourt → peers EPCI, pas Belfort / Montbéliard
- Montbéliard → peers EPCI, pas Belfort / Héricourt
