// Tableau de bord — top-line figures plus the slots reserved for the richer
// analytics landing in V2.
//
// The KPI numbers are real, served by `adminGetOverview` (Firestore count
// aggregations). The "Prochainement" panels are deliberately inert: they mark
// out the layout the future charts will occupy so the page does not visibly
// reshuffle when the data arrives, and they are labelled V2 so nobody mistakes
// a placeholder for a broken widget.

import * as api from "./api.js";
import { $, esc, toast } from "./ui.js";

let cache = null;

/** A number, a dash if the aggregation failed, or a shimmer while loading. */
function figure(value, { loading = false } = {}) {
  if (loading) return `<div class="shimmer h-9 w-20 rounded-lg"></div>`;
  if (value === null || value === undefined) {
    return `<div class="text-3xl font-extrabold tracking-tight text-slate-300">—</div>`;
  }
  return `<div class="text-3xl font-extrabold tracking-tight text-navy">${value.toLocaleString("fr-FR")}</div>`;
}

function kpiCard({ icon, tone, label, value, hint, loading }) {
  const tones = {
    emerald: "bg-emerald-50 text-emerald-600",
    slate: "bg-slate-100 text-slate-500",
    gold: "bg-gold/15 text-gold-deep",
    navy: "bg-navy/5 text-navy",
  };
  return `
    <div class="card p-5 transition-shadow hover:shadow-lift">
      <div class="flex items-start justify-between">
        <span class="text-[11px] font-bold uppercase tracking-[.08em] text-slate-400">${esc(label)}</span>
        <div class="flex h-9 w-9 items-center justify-center rounded-xl ${tones[tone]}">
          <span class="ms text-[19px]">${icon}</span>
        </div>
      </div>
      <div class="mt-3">${figure(value, { loading })}</div>
      <p class="mt-1.5 text-xs text-slate-400">${esc(hint)}</p>
    </div>`;
}

/** Inert panel standing in for a V2 chart. */
function soonCard({ icon, title, description, chart }) {
  return `
    <div class="card relative overflow-hidden p-5">
      <span class="badge absolute right-4 top-4 bg-gold/15 text-gold-deep">V2</span>
      <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-navy/5">
        <span class="ms text-[19px] text-navy">${icon}</span>
      </div>
      <p class="mt-3 text-sm font-bold text-navy">${esc(title)}</p>
      <p class="mt-1 text-xs leading-relaxed text-slate-400">${esc(description)}</p>
      <div class="mt-4 select-none opacity-45">${chart}</div>
    </div>`;
}

/** Decorative bar sketch — no data, just the silhouette of the future chart. */
function barSketch() {
  const heights = [38, 62, 45, 78, 56, 88, 70];
  return `
    <div class="flex h-24 items-end gap-1.5">
      ${heights
        .map(
          (h) =>
            `<div class="flex-1 rounded-t-md bg-gradient-to-t from-slate-200 to-slate-300" style="height:${h}%"></div>`
        )
        .join("")}
    </div>`;
}

function lineSketch() {
  return `
    <svg viewBox="0 0 200 90" class="h-24 w-full" preserveAspectRatio="none">
      <defs>
        <linearGradient id="ls" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#94a3b8" stop-opacity=".35" />
          <stop offset="100%" stop-color="#94a3b8" stop-opacity="0" />
        </linearGradient>
      </defs>
      <path d="M0,70 C30,66 40,34 65,38 C92,42 100,18 130,24 C158,30 172,10 200,14 L200,90 L0,90 Z" fill="url(#ls)" />
      <path d="M0,70 C30,66 40,34 65,38 C92,42 100,18 130,24 C158,30 172,10 200,14"
            fill="none" stroke="#94a3b8" stroke-width="2.5" stroke-linecap="round" />
    </svg>`;
}

function donutSketch() {
  return `
    <div class="flex h-24 items-center justify-center">
      <svg viewBox="0 0 42 42" class="h-24 w-24 -rotate-90">
        <circle cx="21" cy="21" r="15.9" fill="none" stroke="#e2e8f0" stroke-width="6" />
        <circle cx="21" cy="21" r="15.9" fill="none" stroke="#cbd5e1" stroke-width="6"
                stroke-dasharray="62 100" stroke-linecap="round" />
      </svg>
    </div>`;
}

function render({ loading }) {
  const merchants = cache?.merchants ?? {};
  const clients = cache?.clients ?? {};

  $("view-dashboard").innerHTML = `
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
      ${kpiCard({
        icon: "storefront",
        tone: "emerald",
        label: "Boutiques en ligne",
        value: merchants.online,
        hint: `${merchants.live ?? "—"} boutiques au total`,
        loading,
      })}
      ${kpiCard({
        icon: "visibility_off",
        tone: "slate",
        label: "Boutiques hors ligne",
        value: merchants.offline,
        hint: "Non visibles dans Découvrir",
        loading,
      })}
      ${kpiCard({
        icon: "group",
        tone: "navy",
        label: "Clients actifs",
        value: clients.live,
        hint: `${clients.blocked ?? 0} bloqué(s)`,
        loading,
      })}
      ${kpiCard({
        icon: "trending_up",
        tone: "gold",
        label: "Nouveaux (30 j)",
        value: clients.new30,
        hint: `${clients.new7 ?? "—"} sur les 7 derniers jours`,
        loading,
      })}
    </div>

    <div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-3">
      <div class="card p-5 lg:col-span-2">
        <p class="text-sm font-bold text-navy">Corbeille</p>
        <p class="mt-1 text-xs text-slate-400">
          Éléments supprimés, effacés définitivement après 30 jours. Restaurables jusque-là.
        </p>
        <div class="mt-4 grid grid-cols-2 gap-3">
          <div class="rounded-xl bg-slate-50 p-4">
            <div class="text-2xl font-extrabold text-navy">${merchants.deleted ?? "—"}</div>
            <div class="mt-0.5 text-xs font-medium text-slate-500">Boutiques</div>
          </div>
          <div class="rounded-xl bg-slate-50 p-4">
            <div class="text-2xl font-extrabold text-navy">${clients.deleted ?? "—"}</div>
            <div class="mt-0.5 text-xs font-medium text-slate-500">Clients</div>
          </div>
        </div>
      </div>

      <div class="card flex flex-col justify-between bg-gradient-to-br from-navy to-navy-light p-5 text-white">
        <div>
          <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-white/10">
            <span class="ms text-[19px] text-gold">bolt</span>
          </div>
          <p class="mt-3 text-sm font-bold">Nouvelles boutiques</p>
          <p class="mt-1 text-xs text-slate-400">Créées ces 30 derniers jours</p>
        </div>
        <div class="mt-4 text-4xl font-extrabold tracking-tight text-gold">
          ${merchants.new30 ?? "—"}
        </div>
      </div>
    </div>

    <div class="mt-8">
      <div class="mb-1 flex items-center gap-2">
        <h2 class="text-sm font-extrabold tracking-tight text-navy">Statistiques avancées</h2>
        <span class="badge bg-gold/15 text-gold-deep">Prochaine version</span>
      </div>
      <p class="mb-4 text-xs text-slate-400">
        Emplacements réservés — les graphiques arriveront branchés sur les mêmes endpoints.
      </p>

      <div class="grid grid-cols-1 gap-4 lg:grid-cols-3">
        ${soonCard({
          icon: "monitoring",
          title: "Croissance des inscriptions",
          description: "Courbe des nouveaux clients et commerçants, semaine par semaine.",
          chart: lineSketch(),
        })}
        ${soonCard({
          icon: "bar_chart",
          title: "Activité par ville",
          description: "Répartition des boutiques et passages validés par zone.",
          chart: barSketch(),
        })}
        ${soonCard({
          icon: "donut_large",
          title: "Rétention & fidélité",
          description: "Part des clients récurrents et bons de fidélité utilisés.",
          chart: donutSketch(),
        })}
      </div>
    </div>

    <p class="mt-6 text-center text-xs text-slate-400">
      ${cache ? `Dernière mise à jour : ${new Date(cache.generatedAt).toLocaleTimeString("fr-FR")}` : ""}
    </p>`;
}

/** Counts shown next to the sidebar entries. */
function updateNavCounts() {
  $("nav-count-stores").textContent = cache?.merchants?.live ?? "";
  $("nav-count-clients").textContent = cache?.clients?.live ?? "";
}

export const dashboardView = {
  id: "dashboard",
  title: "Tableau de bord",
  subtitle: "Vue d'ensemble de la plateforme Yuztoo.",

  actionsHtml: `
    <button id="dash-refresh" class="btn-ghost">
      <span class="ms text-base">refresh</span> Actualiser
    </button>`,

  onMount() {
    $("dash-refresh")?.addEventListener("click", () => this.load(true));
  },

  async load(force = false) {
    if (cache && !force) {
      render({ loading: false });
      updateNavCounts();
      return;
    }
    render({ loading: true });
    try {
      cache = await api.getOverview();
      render({ loading: false });
      updateNavCounts();
    } catch (error) {
      render({ loading: false });
      toast(error.message, "error");
    }
  },
};
