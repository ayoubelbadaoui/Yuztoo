# Design QA screen-recording script (phone)

Record with: `adb shell screenrecord --time-limit 180 /sdcard/yuztoo_design_qa.mp4`

## Client (FR)
1. Accueil — titre **Mon carnet** white→gold; UI 100% FR
2. Découvrir — chips L→R: **Recommandés → Proche de moi → Associations → Artiste**; starts on Recommandés
3. Fidélité — titre gradient
4. Alertes (client tab) — titre gradient (onglet reste « Alertes »)
5. Profil — titres FR

## Merchant (switch or QA login)
6. Bottom nav tab 2 = **NOTIFICATIONS** (not Alertes / Communiquer)
7. Vos clients › Aperçu — **Alertes** + **Nouveaux clients / Passages** (moved here)
8. Notifications tab — no weekly quota row; quick send + auto rules
9. Vitrine › edit profile — address: manual entry, no infinite spinner
10. Horaires — cascade from Monday
11. Liens personnalisés — shortened URLs
12. Promotions — adaptive image; description max 150
13. Validation montant — keyboard numeric
14. Fidélité / titres — gold gradient emphasis
