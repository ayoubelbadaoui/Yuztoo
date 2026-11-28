# Tarifs — BROUILLON à valider par le client

> Proposition, rien n'est publié sur le site. Les prix sont ceux du brief
> client (nov. 2026), aucun autre prix n'est inventé. Le contenu des offres
> s'appuie uniquement sur des fonctionnalités qui existent dans l'application
> (tutoriels « YuzToo en 30 secondes » 01 à 12). La répartition entre les deux
> offres est une proposition à confirmer.

## Ce que l'application définit déjà (code `develop`)

- Trois niveaux de compte : **gratuit**, **essentiel**, **premium**
  (`lib/feature/merchant/domain/entities/merchant_subscription_plan.dart`).
- Visibilité dans « Découvrir » : 90 jours pour le compte gratuit, illimitée
  pour Essentiel et Premium (`discovery_subscription_visibility.dart`).
- Notifications manuelles : 5 par semaine sur le compte gratuit, illimitées sur
  les offres payantes. Quota désactivé pendant le lancement
  (`notification_quota_policy.dart`).
- Promotions ciblées : « 5 € HT ou inclus avec abonnement premium »
  (`client_type_details.part.dart`) : l'application affiche déjà ses prix HT.

## Offre Essentiel

- Tarif normal : ~~29 € HT / mois~~
- Offre pionniers : **0 € HT / mois**

Inclus :
- Visibilité illimitée dans « Découvrir »
- Notifications manuelles illimitées
- Votre vitrine YuzToo personnalisée (logo, couverture, horaires, actualités)
- La plaque NFC et votre QR code, installés par notre équipe
- La liste de vos clients connectés, avec leurs statuts (nouveau, habitué, VIP, inactif)
- Les notifications immédiates à vos clients
- Votre programme de fidélité (X passages = une récompense)
- Le bon de bienvenue pour vos nouveaux clients

## Offre Premium

- Tarif normal : ~~49 € HT / mois~~
- Offre pionniers : **29 € HT / mois**

Tout l'Essentiel, plus :
- Les notifications automatiques (anniversaire, relance des inactifs…)
- Les promotions ciblées par type de client (VIP, habitués, nouveaux…)¹
- Le réseau local : partenariats entre commerçants et associations de commerçants
- La gamification : niveaux clients affichés sur votre vitrine
- Un accompagnement prioritaire

¹ Dans l'application, le ciblage des promotions est indiqué « 5 € HT ou inclus
avec abonnement premium » : c'est ce qui justifie de le placer en Premium.

## Mention sous les offres

> *Offre pionniers réservée aux 300 premiers commerçants inscrits, valable
> **[DURÉE À CONFIRMER : à vie / 12 mois / 24 mois]** à compter de l'inscription.
> Prix hors taxes, par commerce et par mois. Sans engagement, sans commission
> sur vos ventes. L'application reste gratuite pour vos clients.

## À confirmer par le client

1. La répartition des fonctionnalités entre Essentiel et Premium, et le sort
   du compte gratuit de l'application (affiché ou non sur le site).
2. La durée de validité des prix pionniers.
3. HT : retenu, comme dans l'application (sauf avis contraire du client).
4. « Accompagnement prioritaire » : à garder seulement si le client l'offre réellement.
