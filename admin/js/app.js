// Console shell: sign-in gate, sidebar navigation, list rendering, pagination.

import * as api from "./api.js";
import { USE_EMULATORS, IS_LOCAL_AGAINST_PROD } from "./config.js";
import { $, toast, closeModal, skeletonRows } from "./ui.js";
import { dashboardView } from "./dashboard.js";
import { storesTab } from "./stores.js";
import { clientsTab } from "./clients.js";

const LIST_VIEWS = { stores: storesTab, clients: clientsTab };

const state = {
  viewId: "dashboard",
  tab: null,
  rows: [],
  cursor: null,
  loading: false,
};

// ── Sign-in gate ─────────────────────────────────────────────────────────────

function showLogin(message) {
  $("login-view").classList.remove("hidden");
  $("login-view").classList.add("flex");
  $("app-view").classList.add("hidden");
  if (message) {
    const box = $("login-error");
    box.textContent = message;
    box.classList.remove("hidden");
  }
}

function showApp(user) {
  $("login-view").classList.add("hidden");
  $("login-view").classList.remove("flex");
  $("app-view").classList.remove("hidden");

  const email = user.email ?? user.uid;
  $("admin-email").textContent = email;
  $("admin-avatar").textContent = email.slice(0, 2).toUpperCase();
}

api.watchAuth(async (user) => {
  if (!user) return showLogin();

  // The claim gate here is convenience only — it keeps a non-admin from
  // seeing a console full of failing requests. Enforcement lives server-side.
  let admin = false;
  try {
    admin = await api.isAdmin(user);
  } catch {
    admin = false;
  }

  if (!admin) {
    await api.logout();
    return showLogin(
      "Ce compte n'a pas les droits administrateur. " +
        "Demandez l'attribution via set_admin_claim.mjs."
    );
  }

  showApp(user);
  navigate("dashboard");
});

$("login-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  $("login-error").classList.add("hidden");
  try {
    await api.login($("login-email").value.trim(), $("login-password").value);
  } catch (error) {
    showLogin(error.message);
  }
});

$("logout-btn").addEventListener("click", () => api.logout());

// ── Navigation ───────────────────────────────────────────────────────────────

function setHeader({ title, subtitle, actionsHtml = "" }) {
  $("page-title").textContent = title;
  $("page-subtitle").textContent = subtitle;
  $("page-actions").innerHTML = actionsHtml;
}

function navigate(viewId) {
  state.viewId = viewId;

  for (const button of document.querySelectorAll(".nav-item[data-view]")) {
    button.classList.toggle("is-active", button.dataset.view === viewId);
  }

  const isDashboard = viewId === "dashboard";
  $("view-dashboard").classList.toggle("hidden", !isDashboard);
  $("view-list").classList.toggle("hidden", isDashboard);

  if (isDashboard) {
    state.tab = null;
    setHeader({
      title: dashboardView.title,
      subtitle: dashboardView.subtitle,
      actionsHtml: dashboardView.actionsHtml,
    });
    dashboardView.onMount();
    return dashboardView.load();
  }

  const tab = LIST_VIEWS[viewId];
  state.tab = tab;

  setHeader({
    title: tab.title,
    subtitle: tab.subtitle,
    actionsHtml: `
      <button id="list-refresh" class="btn-ghost">
        <span class="ms text-base">refresh</span> Actualiser
      </button>
      <button id="list-create" class="btn-gold">
        <span class="ms text-base">add</span> ${tab.createLabel}
      </button>`,
  });
  $("list-refresh").addEventListener("click", reload);
  $("list-create").addEventListener("click", () => tab.openCreate(reload));

  $("search-input").value = "";
  $("search-input").placeholder = tab.searchPlaceholder;
  $("search-hint").textContent = tab.searchHint;
  $("status-filter-wrap").classList.toggle("hidden", !tab.showStatusFilter);
  $("status-filter").value = "";
  $("list-mode").value = "active";
  $("table-head").innerHTML = tab.headHtml;

  reload();
}

for (const button of document.querySelectorAll(".nav-item[data-view]")) {
  button.addEventListener("click", () => navigate(button.dataset.view));
}

// ── List rendering ───────────────────────────────────────────────────────────

function currentParams() {
  const params = { limit: 25, listMode: $("list-mode").value };
  const search = $("search-input").value.trim();
  if (search) params.search = search;
  if (state.tab.showStatusFilter && $("status-filter").value) {
    params.status = $("status-filter").value;
  }
  return params;
}

function render() {
  $("table-body").innerHTML = state.rows
    .map((row) => state.tab.rowHtml(row))
    .join("");

  const empty = state.rows.length === 0 && !state.loading;
  $("table-empty").innerHTML = state.tab.emptyHtml;
  $("table-empty").classList.toggle("hidden", !empty);
  $("load-more-btn").classList.toggle("hidden", !state.cursor);
}

async function fetchPage({ append }) {
  if (state.loading) return;
  state.loading = true;

  if (!append) {
    $("table-empty").classList.add("hidden");
    $("table-body").innerHTML = skeletonRows(state.tab.columnCount);
  }

  try {
    const params = currentParams();
    if (append && state.cursor) params.cursor = state.cursor;

    const result = await state.tab.fetch(params);
    state.rows = append ? [...state.rows, ...result.items] : result.items;
    state.cursor = result.nextCursor ?? null;
    render();
  } catch (error) {
    state.rows = [];
    state.cursor = null;
    render();
    toast(error.message, "error");
  } finally {
    state.loading = false;
  }
}

function reload() {
  state.cursor = null;
  return fetchPage({ append: false });
}

// ── Events ───────────────────────────────────────────────────────────────────

$("load-more-btn").addEventListener("click", () => fetchPage({ append: true }));
$("status-filter").addEventListener("change", reload);
$("list-mode").addEventListener("change", reload);

let searchTimer;
$("search-input").addEventListener("input", () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(reload, 350);
});

// Row actions are delegated: rows are re-rendered on every load, so binding
// per-button listeners would leak handlers on each refresh.
$("table-body").addEventListener("click", async (event) => {
  const button = event.target.closest("[data-action]");
  if (!button) return;

  button.disabled = true;
  try {
    await state.tab.onAction(
      button.dataset.action,
      button.dataset.id,
      button.dataset,
      reload
    );
  } catch (error) {
    toast(error.message, "error");
  } finally {
    button.disabled = false;
  }
});

$("modal-close").addEventListener("click", closeModal);
$("modal-root").addEventListener("click", (event) => {
  if (event.target === $("modal-root")) closeModal();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeModal();
});

// ── Boot ─────────────────────────────────────────────────────────────────────

const chip = $("env-chip");
const note = $("emulator-note");

if (USE_EMULATORS) {
  chip.textContent = "ÉMULATEURS LOCAUX";
  chip.classList.remove("hidden");
  note.textContent =
    "Mode émulateur local. Compte de test : admin@yuztoo.test / admin1234 " +
    "(créé par seed_emulator.mjs).";
  note.classList.remove("hidden");
} else if (IS_LOCAL_AGAINST_PROD) {
  // Local page, live data. Make that impossible to miss: suppressions and
  // status changes here affect real merchants and real clients.
  chip.textContent = "DONNÉES RÉELLES";
  chip.className =
    "badge mt-4 max-lg:hidden justify-center bg-red-500/20 text-red-300 ring-1 ring-red-500/40";
  note.textContent =
    "⚠ Connecté à la PRODUCTION depuis une page locale. Toute suppression ou " +
    "mise hors ligne affecte de vrais commerçants.";
  note.className =
    "mt-5 rounded-xl bg-red-500/10 px-3.5 py-2.5 text-xs leading-relaxed text-red-300 ring-1 ring-red-500/25";
}

showLogin();
