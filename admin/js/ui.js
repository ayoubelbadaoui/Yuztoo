// Shared DOM helpers: toasts, the modal shell, and presentation primitives.

export const $ = (id) => document.getElementById(id);

/** Escape user-controlled text before it reaches innerHTML. */
export function esc(value) {
  if (value === null || value === undefined) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// ── Toasts ───────────────────────────────────────────────────────────────────

export function toast(message, variant = "success") {
  const style = {
    success: { bg: "bg-emerald-600", icon: "check_circle" },
    error: { bg: "bg-red-600", icon: "error" },
    info: { bg: "bg-navy-light", icon: "info" },
  }[variant];

  const node = document.createElement("div");
  node.className = `fade-in flex max-w-sm items-start gap-2.5 rounded-xl ${style.bg} px-4 py-3 text-sm font-medium text-white shadow-lift`;
  node.innerHTML = `<span class="ms mt-px text-[18px]">${style.icon}</span><span></span>`;
  node.lastElementChild.textContent = message;

  $("toast-root").appendChild(node);
  setTimeout(() => {
    node.style.transition = "opacity .2s, transform .2s";
    node.style.opacity = "0";
    node.style.transform = "translateX(8px)";
    setTimeout(() => node.remove(), 220);
  }, variant === "error" ? 7000 : 3500);
}

// ── Modal ────────────────────────────────────────────────────────────────────

let modalCleanup = null;

export function closeModal() {
  const root = $("modal-root");
  root.classList.add("hidden");
  root.classList.remove("flex");
  $("modal-body").innerHTML = "";
  $("modal-footer").innerHTML = "";
  if (modalCleanup) {
    modalCleanup();
    modalCleanup = null;
  }
}

/**
 * Show the modal.
 *
 * [buttons] are `{ label, variant, onClick }`. An `onClick` returning a
 * promise keeps the button disabled until it settles, so a slow callable
 * cannot be double-submitted.
 */
export function openModal({ title, bodyHtml, buttons = [], onMount }) {
  $("modal-title").textContent = title;
  $("modal-body").innerHTML = bodyHtml;
  const footer = $("modal-footer");
  footer.innerHTML = "";

  for (const button of buttons) {
    const el = document.createElement("button");
    el.className = button.variant ?? "btn-ghost";
    el.textContent = button.label;
    el.addEventListener("click", async () => {
      if (!button.onClick) return closeModal();
      const previous = el.textContent;
      el.disabled = true;
      el.textContent = "…";
      try {
        await button.onClick();
      } finally {
        el.disabled = false;
        el.textContent = previous;
      }
    });
    footer.appendChild(el);
  }

  const root = $("modal-root");
  root.classList.remove("hidden");
  root.classList.add("flex");

  modalCleanup = onMount?.() ?? null;
}

/** Confirmation dialog with an optional free-text reason for the audit log. */
export function confirmModal({
  title,
  message,
  confirmLabel,
  withReason = false,
  onConfirm,
}) {
  openModal({
    title,
    bodyHtml: `
      <div class="flex gap-3.5">
        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-50">
          <span class="ms text-[22px] text-red-600">warning</span>
        </div>
        <div class="flex-1">
          <p class="text-sm leading-relaxed text-slate-600">${esc(message)}</p>
          ${
            withReason
              ? `<div class="mt-4">
                   <label class="label" for="confirm-reason">Motif (journalisé)</label>
                   <input id="confirm-reason" type="text" class="field" maxlength="500"
                          placeholder="Ex. demande du commerçant" />
                 </div>`
              : ""
          }
        </div>
      </div>`,
    buttons: [
      { label: "Annuler", variant: "btn-ghost", onClick: () => closeModal() },
      {
        label: confirmLabel,
        variant: "btn-danger",
        onClick: async () => {
          const reason = withReason
            ? $("confirm-reason")?.value.trim() || null
            : null;
          await onConfirm(reason);
        },
      },
    ],
  });
}

// ── Presentation primitives ──────────────────────────────────────────────────

/** Callables return ISO strings (see `admin/serialize.ts`). */
export function formatDate(iso) {
  if (!iso) return "—";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "—";
  return date.toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

/** Initials disc — gives every row a visual anchor without needing an image. */
export function avatar(label, { url = null, tone = "navy" } = {}) {
  if (url) {
    return `<img src="${esc(url)}" alt="" class="h-9 w-9 shrink-0 rounded-xl object-cover ring-1 ring-slate-200" />`;
  }
  const initials = String(label || "?")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0])
    .join("")
    .toUpperCase();

  const tones = {
    navy: "bg-navy/5 text-navy",
    gold: "bg-gold/15 text-gold-deep",
  };
  return `<div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-[11px] font-extrabold ${tones[tone]}">${esc(initials)}</div>`;
}

export function merchantStatusBadge(row) {
  if (row.deleted_at) {
    return `<span class="badge bg-slate-100 text-slate-500"><span class="ms text-[13px]">delete</span>Corbeille</span>`;
  }
  return row.status === "active"
    ? `<span class="badge bg-emerald-50 text-emerald-700"><span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>En ligne</span>`
    : `<span class="badge bg-slate-100 text-slate-600"><span class="h-1.5 w-1.5 rounded-full bg-slate-400"></span>Hors ligne</span>`;
}

export function userStatusBadge(row) {
  if (row.deleted_at) {
    return `<span class="badge bg-slate-100 text-slate-500"><span class="ms text-[13px]">delete</span>Corbeille</span>`;
  }
  return row.status === "blocked"
    ? `<span class="badge bg-red-50 text-red-700"><span class="ms text-[13px]">block</span>Bloqué</span>`
    : `<span class="badge bg-emerald-50 text-emerald-700"><span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>Actif</span>`;
}

export function userDisplayName(row) {
  const name = [row.firstName, row.lastName].filter(Boolean).join(" ").trim();
  return name || row.displayName || "—";
}

/** Placeholder rows shown while a page is in flight. */
export function skeletonRows(columns, count = 5) {
  const cell = `<td class="px-6 py-4"><div class="shimmer h-3.5 rounded-md"></div></td>`;
  return Array.from(
    { length: count },
    () => `<tr>${cell.repeat(columns)}</tr>`
  ).join("");
}

export function emptyState({ icon, title, message }) {
  return `
    <div class="mx-auto max-w-sm">
      <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100">
        <span class="ms text-[26px] text-slate-400">${icon}</span>
      </div>
      <p class="text-sm font-semibold text-slate-700">${esc(title)}</p>
      <p class="mt-1 text-sm text-slate-400">${esc(message)}</p>
    </div>`;
}

// ── Form helpers ─────────────────────────────────────────────────────────────

export function fieldHtml(name, label, value, { type = "text" } = {}) {
  return `
    <div>
      <label class="label" for="f-${name}">${esc(label)}</label>
      <input id="f-${name}" data-field="${name}" type="${type}"
             class="field" value="${esc(value ?? "")}" />
    </div>`;
}

/** Collect `data-field` inputs, keeping only values the user actually changed. */
export function collectChangedFields(container, original) {
  const patch = {};
  for (const input of container.querySelectorAll("[data-field]")) {
    const key = input.dataset.field;
    const value = input.value.trim();
    const before = original?.[key] ?? "";
    if (value !== String(before ?? "")) {
      patch[key] = value;
    }
  }
  return patch;
}
