# Yuztoo Sales CRM — Project structure

Base layout adapted from **IMIGO CRM** (feature-first DDD).

The web app lives in **`sales-crm/`** at the repo root, isolated from the Flutter product app (`lib/`). Stack: **Vite + React + TypeScript + Tailwind v4**.

```
sales-crm/                 # (branch crm-sales-yuztoo)
├── src/
│   ├── app/               # navigation map, routing config
│   ├── components/        # Shared UI (layout/ = app shell)
│   ├── contexts/          # Auth, shell
│   ├── features/          # DDD feature modules
│   │   ├── accounts/
│   │   ├── leads/
│   │   ├── deals/
│   │   ├── quotes/
│   │   └── configuration/
│   │       ├── components/
│   │       ├── containers/
│   │       ├── hooks/       # call services only
│   │       ├── services/    # ONLY place for supabase client
│   │       ├── helpers/
│   │       └── constants/
│   ├── lib/               # supabase client, theme, shared libs
│   ├── pages/
│   └── index.css          # design tokens (light + dark)
├── supabase/              # migrations + edge functions
├── public/
└── package.json
```

Documentation stays at the repo root in `docs/sales-crm/`.

## Running it

```bash
cd sales-crm
npm install
npm run dev
```

## Theming

`src/index.css` holds the only color definitions: `:root` (Alabaster / light) and `.dark` (Charcoal Ink), mapped to Tailwind through `@theme inline`. The accent is Yuztoo gold.

**Never hardcode a color in a feature** — no `bg-[#0E2A44]`, no `text-white`. Use `bg-card`, `text-muted-foreground`, `border-border`, `bg-primary`, etc. That is what keeps dark mode correct on every new screen. The active theme is toggled by `src/lib/useTheme.ts`, which adds `.dark` on `<html>` and persists the choice.

## Feature module (required pieces)

| Folder | Role |
|--------|------|
| `services/` | All Supabase / API I/O |
| `hooks/` | UI state + orchestration; **no** direct DB |
| `components/` / `containers/` | Presentation |
| `helpers/` / `domain/` | Pure logic (formatters, rules) |
| `constants/` | Enums, step ids, labels |

## App shell

`src/components/layout/` holds the shared shell, reused by every feature:

| File | Role |
|------|------|
| `AppShell.tsx` | Sidebar + header + theme toggle + ⌘K wiring |
| `SidebarNav.tsx` | Navigation groups |
| `NavItemRow.tsx` | One nav row, with children and badges |
| `WorkspaceSwitcher.tsx` | Workspace / team selector |
| `CommandPalette.tsx` | ⌘K search |

The navigation map lives in `src/app/navigation.ts` — add a feature there, not inside the shell components.

## Features built so far

| Feature | Scope |
|---------|-------|
| `features/dashboard` | KPI cards, derniers leads, répartition du pipeline |
| `features/leads` | Table dense, segmenteur Tous / Commerçants / Clients, tri et recherche |
| `features/pipeline` | Kanban par étape, drag au pointeur, déplacement optimiste |
| `features/calendar` | Vue mois et semaine, agenda du jour, rendez-vous rattachés aux leads |
| `features/quotes` | Devis sur la grille tarifaire : formules, modules, NFC, engagement, remises, lien client |
| `features/inbox` | Demandes entrantes du site (formulaire, démo, rappel) et e-mails, réponse et conversion en lead |
| `features/contracts` | Contrats générés depuis un devis, envoi par lien et signature électronique |
| `features/marketing` | Publication Meta en masse, calendrier éditorial, comptes Facebook et Instagram connectés |
| `features/whatsapp` | Conversations WhatsApp Business, fenêtre de 24 h, modèles approuvés et numéros déclarés |
| `features/billing` | Abonnements, recouvrement et échéancier de prélèvement |
| `features/cms-app` | **CMS App Yuztoo** — ops produit (tableau de bord, boutiques, clients, Images app), fenêtre `?cms=1`, mocks phase 1 → pont Firebase |

La grille tarifaire (prix, modules compris, quotas NFC, remises d’usage) vit dans
`features/quotes/domain/catalog.ts`, et le calcul dans `domain/pricing.ts` — un
changement de tarif ne touche aucun composant.

Le lien public d'un devis (`/?devis=<jeton>`) rend `PublicQuotePage` sans le shell.
Le jeton de démonstration est dérivé de l'identifiant dans `domain/share.ts` ;
**en production il doit être aléatoire, généré côté serveur, stocké en base et
protégé par une policy RLS** qui n'expose que le devis correspondant.

L'échelle de recouvrement (relance, appel, mise en demeure, suspension) est
déclarée dans `features/billing/domain/dunning.ts`. Elle **recommande** une
action, elle n'en déclenche aucune : suspendre un service reste une décision
humaine, et le restera quand un vrai prestataire de paiement sera branché.

Le cycle de vie d’un abonnement (démarrage depuis un devis accepté, suspension,
reprise, résiliation) passe uniquement par `billingService`. Les transitions
autorisées sont déclarées dans `domain/subscription.ts`, et chaque changement
réaligne les échéances encore planifiées : un abonnement suspendu ou résilié
n’est plus prélevé, les échéances passées restent au recouvrement. La
facturation lit le devis accepté ; la dépendance ne va jamais dans l’autre sens.

Le marketing publie **en masse** : le marketeur décrit une population de
comptes (`domain/audience.ts` — réseau, ville, formule, Yuztoo ou commerçants)
et le CRM résout la liste, chaque compte réussissant ou échouant seul. Côté
production, **l’échange OAuth Meta et les jetons de page restent serveur** : la
publication part d’une fonction Edge appelant l’API Graph, le navigateur ne
reçoit que l’identifiant du compte et le résultat. Un jeton de page expire, d’où
le suivi d’échéance sur l’écran Comptes connectés.

WhatsApp est contraint par **la fenêtre de 24 h de Meta** : passé 24 h sans
message entrant du contact, le message libre est refusé et seul un modèle
approuvé peut partir. La règle vit dans `domain/conversation.ts`
(`isWindowOpen`) et est vérifiée dans `whatsappService` avant l’envoi, pas
seulement dans l’interface — sinon l’API rejette et le message est perdu sans
trace. Les modèles (`domain/template.ts`) ne sont envoyables qu’au statut
`approved`, toutes variables `{{n}}` renseignées. En production, **le jeton
permanent du compte WhatsApp Business et les appels à l’API Graph restent dans
une fonction Edge** ; les messages entrants arrivent par webhook signé
(vérification de la signature Meta) et le navigateur ne voit jamais le jeton.

Dans l’inbox, « lu » et « traité » sont deux états distincts : ouvrir un
message ne vaut pas réponse. Le compteur de la navigation suit les non-lus. Les
messages sont aujourd’hui un jeu de démonstration ; côté production ils
arriveront par un webhook du formulaire de yuztoo.fr vers une fonction Edge,
qui validera et écrira dans une table en RLS — le navigateur ne doit jamais
recevoir la boîte d’un autre tenant.

Les devis et les contrats sont mis en cache dans `localStorage` via
`lib/mockStore.ts`, uniquement pour qu'un lien partagé pendant une démo survive
à un rechargement. Les services continuent de travailler sur des tableaux en
mémoire ; ce cache disparaîtra au branchement de Supabase. Pour repartir du jeu
de départ, vider les clés `yuztoo-crm:*`.

`features/contracts` génère un contrat depuis un devis accepté, fige ses
conditions, l’envoie par lien et recueille une signature électronique. Le texte
des articles (`domain/contractTemplate.ts`) est **un remplissage de maquette
sans valeur juridique**, à remplacer par la version validée par un juriste.

La preuve de signature (tracé, horodatage, empreinte du texte, appareil) est
aujourd’hui produite dans le navigateur, **ce qui n’est acceptable qu’en
démonstration**. En production : jeton de signature aléatoire, à usage unique
et daté, généré côté serveur ; écriture de la preuve réservée à une fonction
Edge ; empreinte SHA-256 sur le document scellé ; table protégée par RLS et
non modifiable depuis le client.

All four read from mock data in `services/*Data.ts`, behind services that already
return `{ data, error }`, so plugging Supabase touches only the service files.

## Dependency rule

```
pages / components / hooks  →  services  →  supabase / edge
                ↘ helpers (pure)
```

UI never imports `supabase` except via services (and even then, only services import it).

## Docs

See [README.md](./README.md) for the documentation index.
