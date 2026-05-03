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
    /// Custom + haeufig genutzte Klassen aus der DB ({id, display_name, count, custom}).
    /// Werden zu state.classes gemerged und priorisieren Top-5.
    recentClasses: [],
    /// Stabile Hotkey-Belegung (Hotkey 1-5 -> {id, display, count}).
    /// Bleibt zwischen Class-Items konstant, damit Hotkey 1 immer dieselbe
    /// Klasse aufruft. Aenderungen werden dem User als Banner angekuendigt.
    lockedTopK: null,
    /// Pending Update-Vorschlag fuer lockedTopK (wenn neue Klassen
    /// haeufiger werden) — wird im Banner angezeigt, User kann anwenden.
    pendingTopK: null,
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
    const c = $("context-view");
    if (c) c.innerHTML = '<p class="empty">' + (msg || "Queue leer — alle Items bearbeitet 🎉") + "</p>";
    const p = $("patch-view");
    if (p) p.classList.add("hidden");
    const cb = $("class-buttons");
    if (cb) cb.classList.add("hidden");
    setQuestion("Fertig!", "Alle Items bearbeitet oder Pipeline noch beim Laden.");
    setText("current-info", "—");
  }

  function setQuestion(text, hint) {
    setText("question-text", text || "");
    setText("question-hint", hint || "");
  }

  function renderLevel(item) {
    // Frage je nach Level klar formulieren
    if (item.level === "line") {
      setQuestion(
        "Ist das eine gültige Notenzeile?",
        "Y = Ja, das ist eine vollständige Notenzeile. N = Nein (Müll, abgeschnitten, kein Notensystem). Space = unsicher.",
      );
    } else if (item.level === "element") {
      const sug = item.suggested_class
        ? ` Vorschlag: <code>${item.suggested_class}</code>.`
        : "";
      setQuestion(
        "Ist der rote Rahmen ein gültiges Notations-Element?",
        `Y = Ja, der Rahmen umschließt sauber ein erkennbares Element (Notenkopf, Beam-Group, Akkord, Akzidens, …).${sug} N = Nein, der Rahmen ist Müll oder umschließt mehrere Elemente.`,
      );
    } else if (item.level === "class") {
      const sug = item.suggested_class
        ? ` Vorschlag: <code>${item.suggested_class}</code> — drücke 1, oder wähle eine andere.`
        : " (Top-5 erscheinen rechts)";
      setQuestion(
        "Was ist im roten Rahmen?",
        `Wähle die Klasse:${sug} Tippe <kbd>/</kbd> für Suche durch alle Klassen.`,
      );
    }

    // Kontext-Bild
    const ctx = $("context-view");
    if (ctx) {
      ctx.innerHTML = "";
      const img = document.createElement("img");
      img.className = "context-image";
      if (item.level === "line") {
        img.src = "/api/system/" + encodeURIComponent(item.system_id) + "/image";
        img.alt = "Notenzeile " + item.system_id;
      } else {
        const eid = item.element_id || item.system_id;
        img.src = "/api/element/" + encodeURIComponent(eid) + "/context";
        img.alt = "Element im Kontext " + eid;
      }
      img.onerror = () => {
        ctx.innerHTML = '<p class="empty">Kein Bild verfügbar (id=' + item.id + ").</p>";
      };
      ctx.appendChild(img);
    }

    // Patch-Detail (nur bei element/class)
    const patchView = $("patch-view");
    const patchImg = $("patch-image");
    if (patchView && patchImg) {
      if (item.level === "line") {
        patchView.classList.add("hidden");
      } else {
        const eid = item.element_id || item.system_id;
        patchImg.src = "/api/element/" + encodeURIComponent(eid) + "/image";
        patchImg.alt = "Patch " + eid;
        patchView.classList.remove("hidden");
      }
    }

    setText(
      "current-info",
      "ID " + item.id + " · Level " + item.level + " · u=" + (item.uncertainty || 0).toFixed(2) +
        (item.suggested_class ? " · suggested " + item.suggested_class : ""),
    );

    // Element-Info (bbox-Groesse) async holen und anzeigen — hilft dabei
    // unrealistisch grosse Detektionen zu erkennen.
    if (item.level !== "line" && item.element_id) {
      fetchElementInfo(item.element_id);
    } else {
      setText("element-info", "");
    }

    renderClassButtons(item);
  }

  async function fetchElementInfo(eid) {
    try {
      const info = await jsonGet("/api/element/" + encodeURIComponent(eid) + "/info");
      const b = info.bbox;
      const sys = info.system_size;
      let warn = "";
      if (b && sys && (b[2] > sys[0] * 0.85 || b[3] > sys[1] * 1.5)) {
        warn = " ⚠ verdächtig groß";
      }
      setText(
        "element-info",
        "Bbox " + (b ? b[2] + "×" + b[3] + "px @ (" + b[0] + "," + b[1] + ")" : "?") +
          " · System " + (sys ? sys[0] + "×" + sys[1] : "?") + warn,
      );
    } catch (e) {
      setText("element-info", "");
    }
  }

  // (renderContextImages entfernt — Kontext kommt jetzt direkt vom Server)

  function renderClassButtons(item) {
    const wrap = $("class-buttons");
    if (!wrap) return;
    wrap.innerHTML = "";
    if (item.level !== "class") {
      wrap.classList.add("hidden");
      return;
    }
    wrap.classList.remove("hidden");

    // Display-Name fuer eine Klassen-ID nachschlagen.
    const displayFor = (id) => {
      const recent = state.recentClasses.find((c) => c.id === id);
      if (recent) return recent.display_name;
      const cls = state.classes.find((c) => c.id === id);
      if (cls) return cls.display_name;
      return id;
    };

    // -- Stabile Hotkey-Belegung --------------------------------------
    //
    // 1 sollte zwischen aufeinanderfolgenden Class-Items dieselbe Klasse
    // aufrufen. Wir frieren daher state.lockedTopK ein und aktualisieren
    // ihn NUR auf User-Wunsch (oder beim allerersten Class-Item).
    //
    // Wenn der DB-State sich aendert (z.B. eine neue Klasse wird haeufig
    // verwendet), faellt das in pendingTopK und wird via Banner angezeigt.
    const computeServerTopK = () => {
      if (state.recentClasses.length >= 5) {
        return state.recentClasses.slice(0, 5).map((c) => ({
          id: c.id,
          display: c.display_name,
          count: c.count,
        }));
      }
      if (item.top_k && item.top_k.length > 0) {
        return item.top_k.slice(0, 5).map((e) => ({
          id: e[0],
          display: displayFor(e[0]),
          count: 0,
        }));
      }
      return state.classes.slice(0, 5).map((c) => ({
        id: c.id,
        display: c.display_name,
        count: 0,
      }));
    };

    const serverTopK = computeServerTopK();

    if (!state.lockedTopK || state.lockedTopK.length === 0) {
      // Erstes Class-Item: locken
      state.lockedTopK = serverTopK;
      state.pendingTopK = null;
    } else {
      // Pruefen ob sich die SET der IDs geaendert hat (neue rein / alte raus)
      const lockedIds = new Set(state.lockedTopK.map((e) => e.id));
      const serverIds = new Set(serverTopK.map((e) => e.id));
      const newComers = serverTopK.filter((e) => !lockedIds.has(e.id));
      const droppedOut = state.lockedTopK.filter((e) => !serverIds.has(e.id));
      if (newComers.length > 0 || droppedOut.length > 0) {
        state.pendingTopK = serverTopK;
      } else {
        state.pendingTopK = null;
        // Counts aktualisieren, Reihenfolge bleibt stabil.
        state.lockedTopK = state.lockedTopK.map((e) => {
          const fresh = serverTopK.find((s) => s.id === e.id);
          return fresh ? { ...e, count: fresh.count } : e;
        });
      }
    }

    // Banner mit Diff-Info (nur wenn pending Update vorliegt)
    if (state.pendingTopK) {
      const newComers = state.pendingTopK.filter(
        (e) => !state.lockedTopK.some((l) => l.id === e.id),
      );
      const droppedOut = state.lockedTopK.filter(
        (l) => !state.pendingTopK.some((e) => e.id === l.id),
      );
      const banner = document.createElement("div");
      banner.className = "topk-banner";
      const newList = newComers
        .map((e) => `<strong>${e.display}</strong> (${e.count}×)`)
        .join(", ");
      const dropList = droppedOut.map((e) => `${e.display}`).join(", ");
      banner.innerHTML =
        '<span class="topk-banner-title">⚡ Neue häufige Klasse:</span> ' +
        (newList || "—") +
        (dropList ? ` &nbsp;·&nbsp; rausfallen: ${dropList}` : "") +
        ' <button class="btn btn-small" data-action="apply-topk">[t] Übernehmen</button>' +
        ' <button class="btn btn-small" data-action="dismiss-topk">Behalten</button>';
      wrap.appendChild(banner);
    }

    const topK = state.lockedTopK;

    const topWrap = document.createElement("div");
    topWrap.className = "class-top5";
    topWrap.innerHTML =
      "<h3>Häufig verwendet (Hotkey 1–5) <span class='hint'>· stabile Reihenfolge</span></h3>";
    topK.forEach((entry, idx) => {
      const btn = document.createElement("button");
      btn.className = "btn btn-top";
      const suffix = entry.count > 0 ? " (" + entry.count + "×)" : "";
      btn.textContent = (idx + 1) + ". " + entry.display + suffix;
      btn.dataset.action = "class";
      btn.dataset.value = entry.id;
      topWrap.appendChild(btn);
    });
    wrap.appendChild(topWrap);

    // Suche-Filter mit Live-Filter (durchsucht built-in + custom)
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
          const tag = c.level === "custom" ? " [eigene]" : "";
          li.textContent = c.display_name + " — " + c.id + tag;
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

  /// Wendet pendingTopK an und macht ihn zur neuen lockedTopK-Belegung.
  function applyPendingTopK() {
    if (!state.pendingTopK) return;
    state.lockedTopK = state.pendingTopK;
    state.pendingTopK = null;
    if (state.currentItem) renderClassButtons(state.currentItem);
  }
  function dismissPendingTopK() {
    state.pendingTopK = null;
    if (state.currentItem) renderClassButtons(state.currentItem);
  }

  async function fetchClasses() {
    try {
      const builtin = await jsonGet("/api/classes?include_atoms=1&include_phrases=0");
      // Recent / custom classes vom Server (inkl. User-Eingaben).
      let recent = [];
      try {
        recent = await jsonGet("/api/classes/recent?limit=20");
      } catch (re) {
        console.warn("recent classes fetch failed", re);
      }
      state.recentClasses = recent || [];

      // Merge: zuerst built-in. Custom-Klassen (id nicht in built-in) als
      // ClassEntry-aehnliche Objekte appenden, damit sie in der Suche
      // auftauchen.
      const seen = new Set(builtin.map((c) => c.id));
      const customEntries = state.recentClasses
        .filter((rc) => rc.custom && !seen.has(rc.id))
        .map((rc) => ({
          id: rc.id,
          display_name: rc.display_name + " (eigene)",
          level: "custom",
          atoms: [],
        }));
      state.classes = customEntries.concat(builtin);
    } catch (e) {
      console.error("fetchClasses failed", e);
      state.classes = [];
    }
  }

  /// Lokale Aktualisierung nach einer User-Antwort: wenn der User eine
  /// Custom-Klasse eingegeben hat, fuegen wir sie sofort zu state.classes
  /// + state.recentClasses hinzu, damit sie beim naechsten Item bereits
  /// in der Suche und in den Top-5 sichtbar ist (ohne Roundtrip).
  function rememberClass(classId) {
    if (!classId) return;
    const existsInClasses = state.classes.some((c) => c.id === classId);
    const known = state.classes.find((c) => c.id === classId);
    const isBuiltin = known && (known.level === "atom" || known.level === "group" || known.level === "phrase");
    if (!existsInClasses) {
      state.classes.unshift({
        id: classId,
        display_name: classId + " (eigene)",
        level: "custom",
        atoms: [],
      });
    }
    const idx = state.recentClasses.findIndex((rc) => rc.id === classId);
    if (idx >= 0) {
      state.recentClasses[idx].count += 1;
    } else {
      state.recentClasses.unshift({
        id: classId,
        display_name: isBuiltin ? known.display_name : classId,
        count: 1,
        custom: !isBuiltin,
      });
    }
    state.recentClasses.sort((a, b) => b.count - a.count);
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
      // Optimistic update: Custom-Klasse merken, damit sie sofort
      // in der Suche und in den Top-5 auftaucht — ohne Roundtrip.
      if (decision === "class" && value) {
        rememberClass(value);
      }
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
      // Stabile Hotkey-Belegung: zuerst lockedTopK (wenn class-Level),
      // dann server-Top-K, dann state.classes.
      if (item.level === "class" && state.lockedTopK && state.lockedTopK[idx]) {
        return sendAnswer("class", state.lockedTopK[idx].id);
      }
      if (item.top_k && item.top_k[idx]) {
        return sendAnswer("class", item.top_k[idx][0]);
      }
      if (state.classes && state.classes[idx]) {
        return sendAnswer("class", state.classes[idx].id);
      }
    }
    if (k === "t" && state.pendingTopK) {
      // Top-5 Update anwenden
      applyPendingTopK();
      return;
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
      if (action === "apply-topk") return applyPendingTopK();
      if (action === "dismiss-topk") return dismissPendingTopK();
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
