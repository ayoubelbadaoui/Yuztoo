// Boutiques — list, edit, publish/unpublish, soft delete, restore.

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
  merchantStatusBadge,
  fieldHtml,
  collectChangedFields,
} from "./ui.js";

export const storesTab = {
  id: "stores",
  title: "Boutiques",
  subtitle: "Créer, modifier, publier ou retirer une boutique.",
  createLabel: "Nouvelle boutique",
  searchPlaceholder: "Nom de la boutique…",
  searchHint: "Recherche par début du nom (« bou » trouve « Boulangerie »).",
  showStatusFilter: true,
  columnCount: 6,

  headHtml: `
    <tr>
      <th class="px-6 py-3.5">Boutique</th>
      <th class="px-6 py-3.5">Ville</th>
      <th class="px-6 py-3.5">Contact</th>
      <th class="px-6 py-3.5">Statut</th>
      <th class="px-6 py-3.5">Modifiée</th>
      <th class="px-6 py-3.5 text-right">Actions</th>
    </tr>`,

  emptyHtml: emptyState({
    icon: "storefront",
    title: "Aucune boutique",
    message: "Aucune boutique ne correspond à ces critères de recherche.",
  }),

  fetch: (params) => api.listMerchants(params),

  rowHtml(row) {
    const name = row.display_name || row.name || "(sans nom)";
    return `
      <tr class="group transition-colors hover:bg-slate-50/70">
        <td class="px-6 py-3.5">
          <div class="flex items-center gap-3">
            ${avatar(name, { url: row.logo_url, tone: "gold" })}
            <div class="min-w-0">
              <div class="truncate font-semibold text-navy">${esc(name)}</div>
              <div class="truncate font-mono text-[11px] text-slate-400">${esc(row.id)}</div>
            </div>
          </div>
        </td>
        <td class="px-6 py-3.5 text-slate-600">${esc(row.city || "—")}</td>
        <td class="px-6 py-3.5">
          <div class="text-slate-600">${esc(row.email || "—")}</div>
          <div class="text-xs text-slate-400">${esc(row.phone || "")}</div>
        </td>
        <td class="px-6 py-3.5">${merchantStatusBadge(row)}</td>
        <td class="whitespace-nowrap px-6 py-3.5 text-slate-500">${formatDate(row.updated_at)}</td>
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

  const online = row.status === "active";
  return `
    <button class="btn-ghost btn-sm" data-action="toggle" data-id="${esc(row.id)}"
            data-status="${esc(row.status ?? "inactive")}"
            title="${online ? "Retirer de Découvrir" : "Publier dans Découvrir"}">
      <span class="ms text-[15px]">${online ? "visibility_off" : "visibility"}</span>
      ${online ? "Hors ligne" : "En ligne"}
    </button>
    <button class="btn-ghost btn-sm" data-action="edit" data-id="${esc(row.id)}" title="Modifier">
      <span class="ms text-[15px]">edit</span>
    </button>
    <button class="btn-danger btn-sm" data-action="delete" data-id="${esc(row.id)}" title="Supprimer">
      <span class="ms text-[15px]">delete</span>
    </button>`;
}

async function handleAction(action, id, dataset, reload) {
  if (action === "toggle") {
    const next = dataset.status === "active" ? "inactive" : "active";
    await api.setMerchantStatus({ merchantId: id, status: next });
    toast(next === "active" ? "Boutique en ligne." : "Boutique hors ligne.");
    return reload();
  }

  if (action === "edit") return openEditModal(id, reload);

  if (action === "delete") {
    return confirmModal({
      title: "Supprimer la boutique",
      message:
        "La boutique passe hors ligne immédiatement et sera définitivement " +
        "effacée après 30 jours. Vous pouvez la restaurer avant cette échéance.",
      confirmLabel: "Supprimer",
      withReason: true,
      onConfirm: async (reason) => {
        await api.softDeleteMerchant({ merchantId: id, reason });
        closeModal();
        toast("Boutique déplacée dans la corbeille.");
        await reload();
      },
    });
  }

  if (action === "restore") {
    await api.restoreMerchant({ merchantId: id });
    toast("Boutique restaurée.");
    return reload();
  }
}

/** Fields exposed for editing — the subset `MERCHANT_EDITABLE_FIELDS` accepts. */
const EDIT_FIELDS = [
  ["name", "Nom"],
  ["display_name", "Nom affiché"],
  ["email", "E-mail"],
  ["phone", "Téléphone"],
  ["city", "Ville"],
  ["address", "Adresse"],
  ["website_url", "Site web"],
];

async function openEditModal(merchantId, reload) {
  openModal({
    title: "Chargement…",
    bodyHtml: `<div class="space-y-3">${'<div class="shimmer h-10 rounded-xl"></div>'.repeat(4)}</div>`,
  });

  const { merchant, owner } = await api.getMerchant({ merchantId });

  const ownerLine = owner
    ? `${owner.email ?? owner.uid}${
        [owner.firstName, owner.lastName].filter(Boolean).length
          ? ` · ${[owner.firstName, owner.lastName].filter(Boolean).join(" ")}`
          : ""
      }`
    : "Propriétaire introuvable";

  openModal({
    title: "Modifier la boutique",
    bodyHtml: `
      <div class="space-y-4">
        <div class="rounded-xl bg-slate-50 px-4 py-3 text-xs text-slate-500">
          <div class="flex gap-2"><span class="ms text-[15px]">tag</span><span class="font-mono">${esc(merchant.id)}</span></div>
          <div class="mt-1 flex gap-2"><span class="ms text-[15px]">person</span><span>${esc(ownerLine)}</span></div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          ${EDIT_FIELDS.map(([key, label]) => fieldHtml(key, label, merchant[key])).join("")}
        </div>
        <div>
          <label class="label" for="f-description">Description</label>
          <textarea id="f-description" data-field="description" rows="3"
                    class="field">${esc(merchant.description ?? "")}</textarea>
        </div>
      </div>`,
    buttons: [
      { label: "Annuler", variant: "btn-ghost", onClick: () => closeModal() },
      {
        label: "Enregistrer",
        variant: "btn-gold",
        onClick: async () => {
          const patch = collectChangedFields($("modal-body"), merchant);
          if (Object.keys(patch).length === 0) {
            closeModal();
            return toast("Aucune modification.", "info");
          }
          const result = await api.updateMerchant({ merchantId, patch });
          closeModal();
          toast(
            result.rejectedFields?.length
              ? `Enregistré. Champs ignorés : ${result.rejectedFields.join(", ")}`
              : "Boutique enregistrée."
          );
          await reload();
        },
      },
    ],
  });
}

function openCreateModal(reload) {
  openModal({
    title: "Nouvelle boutique",
    bodyHtml: `
      <div class="space-y-4">
        <p class="flex gap-2.5 rounded-xl bg-gold/10 px-4 py-3 text-xs leading-relaxed text-gold-deep">
          <span class="ms text-[16px]">info</span>
          <span>La boutique est rattachée à un compte existant, qui devient
          commerçant. Elle démarre hors ligne.</span>
        </p>
        ${fieldHtml("ownerUid", "UID du propriétaire", "")}
        <div class="grid grid-cols-2 gap-3">
          ${fieldHtml("name", "Nom de la boutique", "")}
          ${fieldHtml("city", "Ville", "")}
          ${fieldHtml("email", "E-mail de contact", "")}
          ${fieldHtml("phone", "Téléphone", "")}
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

          const result = await api.createMerchant({
            ownerUid: value("ownerUid"),
            name: value("name"),
            city: value("city"),
            email: value("email") || undefined,
            phone: value("phone") || undefined,
          });
          closeModal();
          toast(`Boutique créée (${result.merchantId}).`);
          await reload();
        },
      },
    ],
  });
}
