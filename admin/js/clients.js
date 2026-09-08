// Clients — list, edit, block/unblock, soft delete, restore, create.

import * as api from "./api.js";
import {
  $,
  esc,
  toast,
  avatar,
  openModal,
  closeModal,
  confirmModal,
  emptyState,
  formatDate,
  userStatusBadge,
  userDisplayName,
  fieldHtml,
  collectChangedFields,
} from "./ui.js";

export const clientsTab = {
  id: "clients",
  title: "Clients",
  subtitle: "Comptes utilisateurs, y compris les propriétaires de boutique.",
  createLabel: "Nouveau client",
  searchPlaceholder: "E-mail, téléphone ou UID…",
  searchHint:
    "Correspondance exacte uniquement : e-mail complet, téléphone complet ou UID.",
  showStatusFilter: false,
  columnCount: 6,

  headHtml: `
    <tr>
      <th class="px-6 py-3.5">Client</th>
      <th class="px-6 py-3.5">Contact</th>
      <th class="px-6 py-3.5">Ville</th>
      <th class="px-6 py-3.5">Statut</th>
      <th class="px-6 py-3.5">Inscrit</th>
      <th class="px-6 py-3.5 text-right">Actions</th>
    </tr>`,

  emptyHtml: emptyState({
    icon: "group",
    title: "Aucun client",
    message: "Aucun compte ne correspond à ces critères de recherche.",
  }),

  fetch: (params) => api.listUsers(params),

  rowHtml(row) {
    const name = userDisplayName(row);
    const merchantChip = row.merchant_id
      ? `<span class="badge bg-gold/15 text-gold-deep"><span class="ms text-[13px]">storefront</span>Commerçant</span>`
      : "";
    return `
      <tr class="group transition-colors hover:bg-slate-50/70">
        <td class="px-6 py-3.5">
          <div class="flex items-center gap-3">
            ${avatar(name, { url: row.photoUrl })}
            <div class="min-w-0">
              <div class="flex items-center gap-2">
                <span class="truncate font-semibold text-navy">${esc(name)}</span>
                ${merchantChip}
              </div>
              <div class="truncate font-mono text-[11px] text-slate-400">${esc(row.id)}</div>
            </div>
          </div>
        </td>
        <td class="px-6 py-3.5">
          <div class="text-slate-600">${esc(row.email || "—")}</div>
          <div class="text-xs text-slate-400">${esc(row.phone || "")}</div>
        </td>
        <td class="px-6 py-3.5 text-slate-600">${esc(row.city || "—")}</td>
        <td class="px-6 py-3.5">${userStatusBadge(row)}</td>
        <td class="whitespace-nowrap px-6 py-3.5 text-slate-500">${formatDate(row.created_at)}</td>
        <td class="whitespace-nowrap px-6 py-3.5">
          <div class="flex items-center justify-end gap-1.5 opacity-60 transition-opacity group-hover:opacity-100">
            ${actionsHtml(row)}
          </div>
        </td>
      </tr>`;
  },

  onAction: handleAction,
  openCreate: openCreateModal,
};

function actionsHtml(row) {
  if (row.deleted_at) {
    return `<button class="btn-ghost btn-sm" data-action="restore" data-id="${esc(row.id)}">
              <span class="ms text-[15px]">restore_from_trash</span> Restaurer
            </button>`;
  }

  const blocked = row.status === "blocked";
  return `
    <button class="btn-ghost btn-sm" data-action="block" data-id="${esc(row.id)}"
            data-status="${esc(row.status ?? "active")}"
            title="${blocked ? "Rétablir l'accès" : "Révoquer l'accès"}">
      <span class="ms text-[15px]">${blocked ? "lock_open" : "block"}</span>
      ${blocked ? "Débloquer" : "Bloquer"}
    </button>
    <button class="btn-ghost btn-sm" data-action="edit" data-id="${esc(row.id)}" title="Modifier">
      <span class="ms text-[15px]">edit</span>
    </button>
    <button class="btn-danger btn-sm" data-action="delete" data-id="${esc(row.id)}" title="Supprimer">
      <span class="ms text-[15px]">delete</span>
    </button>`;
}

async function handleAction(action, id, dataset, reload) {
  if (action === "block") {
    const next = dataset.status === "blocked" ? "active" : "blocked";
    await api.setUserStatus({ uid: id, status: next });
    toast(
      next === "blocked"
        ? "Client bloqué — sa session est révoquée."
        : "Client débloqué."
    );
    return reload();
  }

  if (action === "edit") return openEditModal(id, reload);

  if (action === "delete") {
    return confirmModal({
      title: "Supprimer le client",
      message:
        "Le compte est désactivé immédiatement et sera définitivement effacé " +
        "après 30 jours. Si le client possède une boutique, elle est " +
        "supprimée avec lui.",
      confirmLabel: "Supprimer",
      withReason: true,
      onConfirm: async (reason) => {
        const result = await api.softDeleteUser({ uid: id, reason });
        closeModal();
        toast(
          result.cascadedMerchantId
            ? "Client et sa boutique déplacés dans la corbeille."
            : "Client déplacé dans la corbeille."
        );
        await reload();
      },
    });
  }

  if (action === "restore") {
    const result = await api.restoreUser({ uid: id });
    toast(
      result.restoredMerchantId
        ? "Client et sa boutique restaurés."
        : "Client restauré."
    );
    return reload();
  }
}

/** Matches `USER_EDITABLE_FIELDS`; e-mail and téléphone are identity keys. */
const EDIT_FIELDS = [
  ["firstName", "Prénom"],
  ["lastName", "Nom"],
  ["displayName", "Nom affiché"],
  ["city", "Ville"],
];

async function openEditModal(uid, reload) {
  openModal({
    title: "Chargement…",
    bodyHtml: `<div class="space-y-3">${'<div class="shimmer h-10 rounded-xl"></div>'.repeat(4)}</div>`,
  });

  const { user, auth: authRecord, merchant } = await api.getUser({ uid });

  openModal({
    title: "Modifier le client",
    bodyHtml: `
      <div class="space-y-4">
        <div class="rounded-xl bg-slate-50 px-4 py-3 text-xs text-slate-500">
          <div class="flex gap-2"><span class="ms text-[15px]">tag</span><span class="font-mono">${esc(user.id)}</span></div>
          <div class="mt-1 flex gap-2"><span class="ms text-[15px]">mail</span><span>${esc(user.email ?? "—")} · ${esc(user.phone ?? "—")}</span></div>
          <div class="mt-1 flex gap-2"><span class="ms text-[15px]">schedule</span><span>Dernière connexion : ${esc(authRecord?.lastSignInTime ?? "jamais")}</span></div>
          ${
            merchant
              ? `<div class="mt-1 flex gap-2"><span class="ms text-[15px]">storefront</span><span>${esc(merchant.name ?? merchant.id)}</span></div>`
              : ""
          }
        </div>
        <p class="text-xs leading-relaxed text-slate-400">
          L'e-mail et le téléphone sont des identifiants indexés : ils ne se
          modifient pas ici.
        </p>
        <div class="grid grid-cols-2 gap-3">
          ${EDIT_FIELDS.map(([key, label]) => fieldHtml(key, label, user[key])).join("")}
        </div>
      </div>`,
    buttons: [
      { label: "Annuler", variant: "btn-ghost", onClick: () => closeModal() },
      {
        label: "Enregistrer",
        variant: "btn-gold",
        onClick: async () => {
          const patch = collectChangedFields($("modal-body"), user);
          if (Object.keys(patch).length === 0) {
            closeModal();
            return toast("Aucune modification.", "info");
          }
          await api.updateUser({ uid, patch });
          closeModal();
          toast("Client enregistré.");
          await reload();
        },
      },
    ],
  });
}

function openCreateModal(reload) {
  openModal({
    title: "Nouveau client",
    bodyHtml: `
      <div class="space-y-4">
        <p class="flex gap-2.5 rounded-xl bg-gold/10 px-4 py-3 text-xs leading-relaxed text-gold-deep">
          <span class="ms text-[16px]">key</span>
          <span>Aucun mot de passe n'est défini ici. Un lien de
          réinitialisation sera généré pour être transmis au client.</span>
        </p>
        ${fieldHtml("email", "E-mail", "", { type: "email" })}
        <div class="grid grid-cols-2 gap-3">
          ${fieldHtml("phone", "Téléphone (+33…)", "")}
          ${fieldHtml("city", "Ville", "")}
          ${fieldHtml("firstName", "Prénom", "")}
          ${fieldHtml("lastName", "Nom", "")}
        </div>
      </div>`,
    buttons: [
      { label: "Annuler", variant: "btn-ghost", onClick: () => closeModal() },
      {
        label: "Créer",
        variant: "btn-gold",
        onClick: async () => {
          const body = $("modal-body");
          const value = (name) =>
            body.querySelector(`[data-field="${name}"]`).value.trim();

          const result = await api.createClient({
            email: value("email"),
            phone: value("phone") || undefined,
            firstName: value("firstName") || undefined,
            lastName: value("lastName") || undefined,
            city: value("city") || undefined,
          });

          closeModal();
          await reload();
          showResetLink(result);
        },
      },
    ],
  });
}

/** Surface the password-reset link so the admin can copy it to the client. */
function showResetLink({ uid, passwordResetLink }) {
  if (!passwordResetLink) {
    return toast(`Client créé (${uid}). Lien de réinitialisation indisponible.`);
  }
  openModal({
    title: "Client créé",
    bodyHtml: `
      <div class="text-center">
        <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-50">
          <span class="ms text-[26px] text-emerald-600">check_circle</span>
        </div>
        <p class="text-sm text-slate-600">
          Transmettez ce lien au client pour qu'il définisse son mot de passe.
        </p>
      </div>
      <textarea id="reset-link" readonly rows="4"
        class="field mt-4 font-mono text-[11px] leading-relaxed">${esc(passwordResetLink)}</textarea>`,
    buttons: [
      {
        label: "Copier",
        variant: "btn-ghost",
        onClick: async () => {
          $("reset-link").select();
          await navigator.clipboard.writeText($("reset-link").value);
          toast("Lien copié.", "info");
        },
      },
      { label: "Fermer", variant: "btn-gold", onClick: () => closeModal() },
    ],
  });
}
