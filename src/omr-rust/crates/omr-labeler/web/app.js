// OMR Labeler — Vanilla JS frontend.
// ----------------------------------------------------------------------
// Verantwortlich für:
//   * Polling der Queue (`/api/queue/next`)
//   * Rendern des Items je nach Level (line / element / class)
//   * Senden von Antworten (`/api/queue/answer`, `/skip`, `/undo`)
//   * Hotkey-Handling
//   * Stats / Progress-Aktualisierung
//
// Bewusst kein Framework — der Tool soll ohne Build-Schritt laufen.
// ----------------------------------------------------------------------

(function () {
  "use strict";

  const state = {
    currentItem: null,
    contextSystems: [],
  };

  // ---------- Utility ---------------------------------------------------

  function $(id) {
    return document.getElementById(id);
  }

  async function jsonGet(url) {
    const r = await fetch(url, { headers: { "Accept": "application/json" } });
    if (!r.ok) throw new Error("GET " + url + " → " + r.status);
    return r.json();
  }

  async function jsonPost(url, body) {
    const r = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body || {}),
    });
    if (!r.ok) throw new Error("POST " + url + " → " + r.status);
    return r.json();
  }

  function setText(id, text) {
    const el = $(id);
    if (el) el.textContent = text;
  }

  // ---------- Status / Stats --------------------------------------------

  async function updateStatus() {
    try {
      const s = await jsonGet("/api/status");
      setText("stat-pdfs", "PDFs: " + s.pdfs);
      setText("stat-systems", "Systems: " + s.systems);
      setText("stat-elements", "Elements: " + s.elements);
      setText("stat-labels", "Labels: " + s.labels);
    } catch (e) {
      console.warn("status failed", e);
    }
  }

  async function updateStats() {
    try {
      const s = await jsonGet("/api/stats");
      const pct = Math.round(s.progress * 100);
      const bar = $("progress-bar");
      if (bar) bar.style.width = pct + "%";
      setText(
        "progress-text",
        s.labeled + " / " + s.total + " (" + pct + "%)",
      );
    } catch (e) {
      console.warn("stats failed", e);
    }
  }

  // ---------- Queue -----------------------------------------------------

  async function fetchQueue() {
    try {
      const r = await jsonGet("/api/queue/next?n=1");
      if (r.items && r.items.length > 0) {
        state.currentItem = r.items[0];
        renderLevel(state.currentItem);
      } else {
        state.currentItem = null;
        renderEmpty();
      }
    } catch (e) {
      console.error("queue fetch failed", e);
      renderEmpty("Verbindung verloren — bitte neu laden.");
    }
  }

  function renderEmpty(msg) {
    state.currentItem = null;
    const m = $("main-image");
    if (m) m.innerHTML = '<p class="empty">' + (msg || "Queue leer — alle Items bearbeitet 🎉") + "</p>";
    const c = $("class-buttons");
    if (c) c.classList.add("hidden");
    setText("current-info", "—");
  }

  function renderLevel(item) {
    const m = $("main-image");
    if (!m) return;
    m.innerHTML = "";
    const img = document.createElement("img");
    if (item.level === "line") {
      img.src = "/api/system/" + encodeURIComponent(item.system_id) + "/image";
    } else {
      const id = item.element_id || item.system_id;
      img.src = "/api/element/" + encodeURIComponent(id) + "/image";
    }
    img.alt = "Item " + item.id;
    img.onerror = () => {
      m.innerHTML = '<p class="empty">Kein Bild verfügbar (id=' + item.id + ").</p>";
    };
    m.appendChild(img);
    setText(
      "current-info",
      "ID " + item.id + " · Level " + item.level + " · u=" + (item.uncertainty || 0).toFixed(2) +
        (item.suggested_class ? " · suggested " + item.suggested_class : ""),
    );

    renderContextImages(item);
    renderClassButtons(item);
  }

  function renderContextImages(item) {
    // Platzhalter: wir laden keine echten Nachbar-Systeme, aber zeigen
    // die letzten beiden gelabelten als gedimmte Strip-Items.
    const prev = $("context-prev");
    const next = $("context-next");
    if (prev) prev.innerHTML = "";
    if (next) next.innerHTML = "";
  }

  function renderClassButtons(item) {
    const wrap = $("class-buttons");
    if (!wrap) return;
    wrap.innerHTML = "";
    if (item.level !== "class" || !item.top_k || item.top_k.length === 0) {
      wrap.classList.add("hidden");
      return;
    }
    wrap.classList.remove("hidden");
    item.top_k.slice(0, 5).forEach((entry, idx) => {
      const btn = document.createElement("button");
      btn.className = "btn";
      btn.textContent = (idx + 1) + ". " + entry[0];
      btn.dataset.action = "class";
      btn.dataset.value = entry[0];
      wrap.appendChild(btn);
    });
  }

  // ---------- Sending ---------------------------------------------------

  async function sendAnswer(decision, value) {
    if (!state.currentItem) return;
    const item = state.currentItem;
    try {
      await jsonPost("/api/queue/answer", {
        item_id: item.id,
        level: item.level,
        decision: decision,
        value: value || null,
      });
    } catch (e) {
      console.error("answer failed", e);
    }
    autoAdvance();
  }

  async function sendSkip() {
    if (!state.currentItem) return;
    try {
      await jsonPost("/api/queue/skip", { item_id: state.currentItem.id });
    } catch (e) {
      console.error("skip failed", e);
    }
    autoAdvance();
  }

  async function sendUndo() {
    try {
      await jsonPost("/api/queue/undo", {});
    } catch (e) {
      console.error("undo failed", e);
    }
    refreshAll();
  }

  function autoAdvance() {
    refreshAll();
  }

  function refreshAll() {
    fetchQueue();
    updateStatus();
    updateStats();
  }

  // ---------- Hotkeys ---------------------------------------------------

  function handleKeypress(e) {
    if (e.target && (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA")) {
      return;
    }
    const k = e.key.toLowerCase();
    if (k === "y") return sendAnswer("yes");
    if (k === "n") return sendAnswer("no");
    if (k === " " || k === "spacebar") {
      e.preventDefault();
      return sendSkip();
    }
    if (k === "u") return sendUndo();
    if (k === "e") {
      const cls = prompt("Klasse eingeben:");
      if (cls && cls.trim().length > 0) {
        sendAnswer("class", cls.trim());
      }
      return;
    }
    if (/^[1-5]$/.test(k)) {
      const idx = parseInt(k, 10) - 1;
      const item = state.currentItem;
      if (item && item.top_k && item.top_k[idx]) {
        return sendAnswer("class", item.top_k[idx][0]);
      }
    }
  }

  // ---------- Setup -----------------------------------------------------

  function bindButtons() {
    document.body.addEventListener("click", (e) => {
      const t = e.target;
      if (!(t instanceof HTMLElement)) return;
      const action = t.dataset.action;
      if (!action) return;
      if (action === "yes") return sendAnswer("yes");
      if (action === "no") return sendAnswer("no");
      if (action === "skip") return sendSkip();
      if (action === "undo") return sendUndo();
      if (action === "class") return sendAnswer("class", t.dataset.value || "");
    });
  }

  function init() {
    bindButtons();
    window.addEventListener("keydown", handleKeypress);
    refreshAll();
    setInterval(updateStatus, 5000);
    setInterval(() => {
      if (!state.currentItem) fetchQueue();
    }, 4000);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
