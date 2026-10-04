import { rpc } from "./api.js";

// Cells that start with = + - @ can run as formulas in spreadsheets. Neutralise them.
const cell = (v) => {
  let s = v === null || v === undefined ? "" : typeof v === "object" ? JSON.stringify(v) : String(v);
  if (/^[=+\-@\t\r]/.test(s)) s = "'" + s;
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
export const csvRows = (rows) => rows.map((r) => r.map(cell).join(",")).join("\r\n");

export function download(name, text, type = "text/csv;charset=utf-8") {
  const blob = new Blob(["﻿" + text], { type });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob); a.download = name; document.body.appendChild(a); a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500);
}
export const stamp = () => new Date().toISOString().slice(0, 10);
export const safeName = (s) => String(s || "export").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40) || "export";

// Every export is written to the audit log (what and in which format, never the data itself).
export async function logExport(kind, target, format) { try { await rpc("admin_log_export", { p_kind: kind, p_target: target, p_format: format }); } catch { /* the export itself still works */ } }

export async function exportTable(name, header, rows) {
  download(`seculate-${safeName(name)}-${stamp()}.csv`, csvRows([header, ...rows]));
  await logExport(name, `${rows.length} rows`, "csv");
}

// Print the page as a PDF (the browser's "Save as PDF"). Print styles hide the app chrome.
export async function printPage(title, kind, target) {
  const old = document.title; document.title = title;
  await logExport(kind, target, "pdf");
  const restore = () => { document.title = old; window.removeEventListener("afterprint", restore); };
  window.addEventListener("afterprint", restore); window.print(); setTimeout(restore, 4000);
}
