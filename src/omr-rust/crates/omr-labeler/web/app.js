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
    classes: [],
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
    if (item.level !== "class") {
      wrap.classList.add("hidden");
      return;
    }
    wrap.classList.remove("hidden");

    // Top-5 (Hotkey 1-5) — eingebaute Vorschlaege oder erste 5 aus Klassen-Liste.
    const topK = (item.top_k && item.top_k.length > 0)
      ? item.top_k.slice(0, 5).map((e) => ({ id: e[0], score: e[1], display: e[0] }))
      : (state.classes.slice(0, 5).map((c) => ({ id: c.id, score: 0, display: c.display_name })));
    const topWrap = document.createElement("div");
    topWrap.className = "class-top5";
    topWrap.innerHTML = "<h3>Top 5 (Hotkey 1–5)</h3>";
    topK.forEach((entry, idx) => {
      const btn = document.createElement("button");
      btn.className = "btn btn-top";
      const pct = entry.score > 0 ? " (" + (entry.score * 100).toFixed(0) + "%)" : "";
      btn.textContent = (idx + 1) + ". " + entry.display + pct;
      btn.dataset.action = "class";
      btn.dataset.value = entry.id;
      topWrap.appendChild(btn);
    });
    wrap.appendChild(topWrap);

    // Suche-Filter mit Live-Filter
    const searchWrap = document.createElement("div");
    searchWrap.className = "class-search";
    searchWrap.innerHTML = '<h3>Alle Klassen (<kbd>/</kbd>)</h3>' +
      '<input id="class-filter-input" type="text" placeholder="Tippen filtert..." autocomplete="off" />' +
      '<ul id="class-filter-list"></ul>';
    wrap.appendChild(searchWrap);
    const input = $("class-filter-input");
    const list = $("class-filter-list");
    if (input && list) {
      const renderList = (q) => {
        list.innerHTML = "";
        const ql = (q || "").toLowerCase();
        const matches = state.classes.filter((c) => {
          if (!ql) return true;
          return c.id.toLowerCase().includes(ql) || c.display_name.toLowerCase().includes(ql);
        }).slice(0, 30);
        matches.forEach((c) => {
          const li = document.createElement("li");
          li.textContent = c.display_name + " — " + c.id;
          li.dataset.action = "class";
          li.dataset.value = c.id;
          list.appendChild(li);
        });
      };
      renderList("");
      input.addEventListener("input", () => renderList(input.value));
      input.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          const first = list.querySelector("li");
          if (first) {
            sendAnswer("class", first.dataset.value || "");
          }
        }
        if (e.key === "Escape") {
          input.value = "";
          input.blur();
          renderList("");
        }
      });
    }

    // Drill-Down-Hinweis fuer Group-Klassen
    if (item.suggested_class && item.suggested_class.startsWith("group/")) {
      const drillBtn = document.createElement("button");
      drillBtn.className = "btn btn-drill";
      drillBtn.textContent = "[d] Drill-Down zu Atomen von " + item.suggested_class;
      drillBtn.dataset.action = "drill";
      drillBtn.dataset.value = item.suggested_class;
      wrap.appendChild(drillBtn);
    }

    // Spezial-Aktionen
    const special = document.createElement("div");
    special.className = "class-special";
    special.innerHTML =
      '<button class="btn" data-action="answer-no">[n] None of these</button>' +
      '<button class="btn" data-action="edit">[e] Eigene Klasse</button>' +
      '<button class="btn" data-action="skip">[Space] Skip</button>';
    wrap.appendChild(special);
  }

  async function fetchClasses() {
    try {
      state.classes = await jsonGet("/api/classes?include_atoms=1&include_phrases=0");
    } catch (e) {
      console.error("fetchClasses failed", e);
      state.classes = [];
    }
  }

  async function showDrillDown(groupId) {
    try {
      const atoms = await jsonGet("/api/classes/drilldown/" + encodeURIComponent(groupId));
      if (atoms.length === 0) {
        alert("Keine Atome bekannt fuer " + groupId);
        return;
      }
      // Zeige Atom-Liste in einem temporaeren Overlay
      const wrap = $("class-buttons");
      if (!wrap) return;
      wrap.innerHTML = "";
      const h = document.createElement("h3");
      h.textContent = "Drill-Down: " + groupId;
      wrap.appendChild(h);
      atoms.forEach((c, idx) => {
        const btn = document.createElement("button");
        btn.className = "btn";
        btn.textContent = (idx + 1) + ". " + c.display_name;
        btn.dataset.action = "class";
        btn.dataset.value = c.id;
        wrap.appendChild(btn);
      });
      const back = document.createElement("button");
      back.className = "btn";
      back.textContent = "[Esc] zurueck";
      back.addEventListener("click", () => {
        if (state.currentItem) renderClassButtons(state.currentItem);
      });
      wrap.appendChild(back);
    } catch (e) {
      console.error("drilldown failed", e);
    }
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
      // Im Sucheingabe-Feld: nur Esc abfangen
      if (e.key === "Escape") {
        e.target.blur();
      }
      return;
    }
    const k = e.key.toLowerCase();
    if (k === "y") return sendAnswer("yes");
    if (k === "n") {
      // Im class-Level: "n" = none of these (geht zu manueller Eingabe)
      if (state.currentItem && state.currentItem.level === "class") {
        const cls = prompt("Klasse manuell eingeben (oder leer fuer Skip):");
        if (cls && cls.trim().length > 0) {
          sendAnswer("class", cls.trim());
        }
        return;
      }
      return sendAnswer("no");
    }
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
    if (k === "/") {
      e.preventDefault();
      const input = $("class-filter-input");
      if (input) {
        input.focus();
        input.select();
      }
      return;
    }
    if (k === "d") {
      // Drill-Down zur aktuellen group-Klasse
      const item = state.currentItem;
      if (item && item.suggested_class && item.suggested_class.startsWith("group/")) {
        return showDrillDown(item.suggested_class);
      }
      return;
    }
    if (/^[1-5]$/.test(k)) {
      const idx = parseInt(k, 10) - 1;
      const item = state.currentItem;
      if (!item) return;
      // Top-K aus Suggestions, fallback auf state.classes
      if (item.top_k && item.top_k[idx]) {
        return sendAnswer("class", item.top_k[idx][0]);
      }
      if (state.classes && state.classes[idx]) {
        return sendAnswer("class", state.classes[idx].id);
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
      if (action === "answer-no") {
        const cls = prompt("Klasse manuell eingeben (oder Abbruch fuer Skip):");
        if (cls && cls.trim().length > 0) sendAnswer("class", cls.trim());
        return;
      }
      if (action === "skip") return sendSkip();
      if (action === "undo") return sendUndo();
      if (action === "edit") {
        const cls = prompt("Klasse eingeben:");
        if (cls && cls.trim().length > 0) sendAnswer("class", cls.trim());
        return;
      }
      if (action === "drill") return showDrillDown(t.dataset.value || "");
      if (action === "class") return sendAnswer("class", t.dataset.value || "");
    });
  }

  function init() {
    bindButtons();
    window.addEventListener("keydown", handleKeypress);
    fetchClasses().then(() => refreshAll());
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
