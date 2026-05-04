// OMR Labeler — Annotation-Modus Frontend.
//
// Verantwortlich für:
//   * System-Liste laden + filtern (linke Sidebar)
//   * SVG-Overlay über System-Bild fuer Box-Drawing
//   * Click-Drag um neue Boxen zu erstellen
//   * Click auf bestehende Boxen (auto = grau, manuell = gruen) zum Bearbeiten
//   * Class-Picker-Popup mit Top-5-Hotkey + Live-Suche
//
// Vanilla-JS, kein Framework.
(function () {
  "use strict";

  const state = {
    systems: [],
    classes: [],
    recentClasses: [],
    currentSystemId: null,
    currentSystemMeta: null,
    autoBoxes: [],
    annotations: [],
    showAuto: true,
    // Aktive Drawing-Operation
    drawing: false,
    drawStart: null,
    pendingBox: null, // {x,y,w,h}
    // Editing-Mode
    editingId: null, // id der manuell gesetzten Box (zur Reklassifikation)
    promotingAutoBox: null, // {x,y,w,h} aus auto -> wartet auf Klasse
  };

  function $(id) { return document.getElementById(id); }
  async function jget(url) {
    const r = await fetch(url, { headers: { Accept: "application/json" } });
    if (!r.ok) throw new Error("GET " + url + " -> " + r.status);
    return r.json();
  }
  async function jpost(url, body, method) {
    const r = await fetch(url, {
      method: method || "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body || {}),
    });
    if (!r.ok) throw new Error(method + " " + url + " -> " + r.status);
    return r.json();
  }

  // ---------- Klassen laden -----------------------------------------

  async function loadClasses() {
    try {
      const builtin = await jget("/api/classes?include_atoms=1&include_phrases=0");
      let recent = [];
      try { recent = await jget("/api/classes/recent?limit=20"); } catch (e) {}
      state.recentClasses = recent || [];
      const seen = new Set(builtin.map(c => c.id));
      const customs = state.recentClasses
        .filter(rc => rc.custom && !seen.has(rc.id))
        .map(rc => ({ id: rc.id, display_name: rc.display_name + " (eigene)", level: "custom", atoms: [] }));
      state.classes = customs.concat(builtin);
    } catch (e) {
      console.error("loadClasses failed", e);
    }
  }

  // ---------- Systems-Liste -----------------------------------------

  async function loadSystems() {
    try {
      const r = await jget("/api/annotation/systems");
      state.systems = r.systems;
      renderSystemList();
      updateStats();
    } catch (e) {
      console.error("loadSystems failed", e);
    }
  }

  function renderSystemList() {
    const ul = $("ann-system-list");
    if (!ul) return;
    const filter = ($("ann-filter").value || "").toLowerCase();
    ul.innerHTML = "";
    const filtered = filter
      ? state.systems.filter(s => s.system_id.toLowerCase().includes(filter))
      : state.systems;
    filtered.slice(0, 200).forEach(sys => {
      const li = document.createElement("li");
      li.className = "ann-sys" + (sys.system_id === state.currentSystemId ? " active" : "");
      const title = prettySystemId(sys.system_id);
      const badge = sys.annotation_count > 0
        ? `<span class="badge badge-done">${sys.annotation_count}</span>`
        : `<span class="badge">${sys.auto_element_count} auto</span>`;
      li.innerHTML = `<span class="ann-sys-title">${title}</span>${badge}`;
      li.dataset.systemId = sys.system_id;
      li.addEventListener("click", () => loadSystem(sys.system_id));
      ul.appendChild(li);
    });
  }

  function prettySystemId(id) {
    // "<hash>-Title#p0s0" -> "Title  ·  P1 S1"
    const m = id.match(/^([0-9a-f]{32}-)?(.+?)#p(\d+)s(\d+)$/);
    if (!m) return id;
    const title = m[2].replace(/^\d+-/, "").replace(/\.pdf-Stimme$/, "").replace(/_/g, " ");
    return `<strong>${title}</strong> <span class="muted">· P${parseInt(m[3])+1} S${parseInt(m[4])+1}</span>`;
  }

  function updateStats() {
    const total = state.systems.length;
    const annotated = state.systems.filter(s => s.annotation_count > 0).length;
    const totalAnns = state.systems.reduce((a, s) => a + s.annotation_count, 0);
    $("ann-stats").textContent = `${annotated}/${total} Notenzeilen · ${totalAnns} Boxen`;
  }

  // ---------- System laden ------------------------------------------

  async function loadSystem(systemId) {
    state.currentSystemId = systemId;
    state.editingId = null;
    state.promotingAutoBox = null;
    state.pendingBox = null;
    const meta = state.systems.find(s => s.system_id === systemId);
    state.currentSystemMeta = meta;
    $("ann-current-info").innerHTML = prettySystemId(systemId);
    $("ann-system-img").src = "/api/system/" + encodeURIComponent(systemId) + "/image";
    try {
      const r = await jget("/api/annotation/system/" + encodeURIComponent(systemId));
      state.annotations = r.annotations || [];
      state.autoBoxes = r.auto_boxes || [];
      renderSystemList();
      renderOverlay();
    } catch (e) {
      console.error("loadSystem failed", e);
    }
  }

  // ---------- Overlay rendering -------------------------------------

  function renderOverlay() {
    const svg = $("ann-overlay");
    const img = $("ann-system-img");
    if (!svg || !img || !state.currentSystemMeta) return;
    const w = state.currentSystemMeta.width;
    const h = state.currentSystemMeta.height;
    svg.setAttribute("viewBox", `0 0 ${w} ${h}`);
    svg.setAttribute("preserveAspectRatio", "none");
    svg.innerHTML = "";

    // Auto-Boxen (grau, gestrichelt, klickbar)
    if (state.showAuto) {
      state.autoBoxes.forEach(b => {
        // Skip auto boxes that overlap heavily with manual ones
        const overlapped = state.annotations.some(a => iou(a, b) > 0.5);
        if (overlapped) return;
        const r = svgRect(b.x, b.y, b.w, b.h, "auto-box");
        r.dataset.kind = "auto";
        r.dataset.x = b.x;
        r.dataset.y = b.y;
        r.dataset.w = b.w;
        r.dataset.h = b.h;
        r.dataset.suggested = b.suggested_class || "";
        svg.appendChild(r);
      });
    }

    // Manuelle Boxen (gruen, mit Label)
    state.annotations.forEach(a => {
      const r = svgRect(a.x, a.y, a.w, a.h, "manual-box");
      r.dataset.kind = "manual";
      r.dataset.id = a.id;
      svg.appendChild(r);
      // Klassenname-Label oben links
      const lbl = document.createElementNS("http://www.w3.org/2000/svg", "text");
      lbl.setAttribute("x", a.x + 2);
      lbl.setAttribute("y", a.y - 2);
      lbl.setAttribute("class", "manual-label");
      lbl.textContent = shortClass(a.class_id);
      svg.appendChild(lbl);
    });

    // Pending-Box (waehrend gerade gezogen wird)
    if (state.pendingBox) {
      const p = state.pendingBox;
      const r = svgRect(p.x, p.y, p.w, p.h, "pending-box");
      svg.appendChild(r);
    }
  }

  function svgRect(x, y, w, h, cls) {
    const r = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    r.setAttribute("x", x);
    r.setAttribute("y", y);
    r.setAttribute("width", w);
    r.setAttribute("height", h);
    r.setAttribute("class", cls);
    return r;
  }

  function iou(a, b) {
    const ix0 = Math.max(a.x, b.x);
    const iy0 = Math.max(a.y, b.y);
    const ix1 = Math.min(a.x + a.w, b.x + b.w);
    const iy1 = Math.min(a.y + a.h, b.y + b.h);
    if (ix0 >= ix1 || iy0 >= iy1) return 0;
    const inter = (ix1 - ix0) * (iy1 - iy0);
    const ua = a.w * a.h + b.w * b.h - inter;
    return ua > 0 ? inter / ua : 0;
  }

  function shortClass(id) {
    // "ton/viertel" -> "viertel"
    const i = id.indexOf("/");
    return i >= 0 ? id.slice(i + 1) : id;
  }

  // ---------- Mouse-Drag -------------------------------------------

  function setupCanvas() {
    const wrap = $("ann-canvas-inner");
    const svg = $("ann-overlay");
    if (!wrap || !svg) return;

    function imgCoords(evt) {
      if (!state.currentSystemMeta) return null;
      const rect = svg.getBoundingClientRect();
      const sx = (evt.clientX - rect.left) / rect.width;
      const sy = (evt.clientY - rect.top) / rect.height;
      return {
        x: Math.round(sx * state.currentSystemMeta.width),
        y: Math.round(sy * state.currentSystemMeta.height),
      };
    }

    svg.addEventListener("mousedown", (e) => {
      if (e.button !== 0) return;
      const target = e.target;
      // Click auf existierende Box?
      if (target && target.dataset && target.dataset.kind) {
        e.preventDefault();
        if (target.dataset.kind === "manual") {
          state.editingId = parseInt(target.dataset.id);
          openClassPicker({ deletable: true });
        } else if (target.dataset.kind === "auto") {
          // Promote: erstelle eine manual annotation aus diesem auto-bbox
          state.promotingAutoBox = {
            x: parseInt(target.dataset.x),
            y: parseInt(target.dataset.y),
            w: parseInt(target.dataset.w),
            h: parseInt(target.dataset.h),
          };
          openClassPicker({ suggestion: target.dataset.suggested });
        }
        return;
      }
      // Sonst: Drawing starten
      const c = imgCoords(e);
      if (!c) return;
      state.drawing = true;
      state.drawStart = c;
      state.pendingBox = { x: c.x, y: c.y, w: 1, h: 1 };
      renderOverlay();
    });

    window.addEventListener("mousemove", (e) => {
      if (!state.drawing || !state.drawStart) return;
      const c = imgCoords(e);
      if (!c) return;
      const x0 = Math.min(state.drawStart.x, c.x);
      const y0 = Math.min(state.drawStart.y, c.y);
      const x1 = Math.max(state.drawStart.x, c.x);
      const y1 = Math.max(state.drawStart.y, c.y);
      state.pendingBox = { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
      renderOverlay();
    });

    window.addEventListener("mouseup", (e) => {
      if (!state.drawing) return;
      state.drawing = false;
      const b = state.pendingBox;
      if (!b || b.w < 4 || b.h < 4) {
        state.pendingBox = null;
        renderOverlay();
        return;
      }
      // Open class picker for new box
      openClassPicker({});
    });

    // Rechtsklick auf manuelle Box: schnell loeschen
    svg.addEventListener("contextmenu", (e) => {
      const target = e.target;
      if (target && target.dataset && target.dataset.kind === "manual") {
        e.preventDefault();
        const id = parseInt(target.dataset.id);
        deleteAnnotation(id);
      }
    });
  }

  // ---------- Class-Picker Popup ------------------------------------

  function openClassPicker(opts) {
    const picker = $("class-picker");
    picker.classList.remove("hidden");
    const top5 = $("cp-top5");
    top5.innerHTML = "";
    const recent = state.recentClasses.slice(0, 5);
    if (recent.length === 0) {
      // Default-Top-5 aus state.classes (erste 5 Group-Klassen)
      const groups = state.classes.filter(c => c.level === "group").slice(0, 5);
      groups.forEach((c, i) => {
        const btn = document.createElement("button");
        btn.className = "btn btn-top";
        btn.textContent = `${i + 1}. ${c.display_name}`;
        btn.dataset.cls = c.id;
        top5.appendChild(btn);
      });
    } else {
      recent.forEach((c, i) => {
        const btn = document.createElement("button");
        btn.className = "btn btn-top";
        btn.textContent = `${i + 1}. ${c.display_name} (${c.count}×)`;
        btn.dataset.cls = c.id;
        top5.appendChild(btn);
      });
    }
    if (top5.children.length > 0) {
      Array.from(top5.children).forEach(b => {
        b.addEventListener("click", () => commitClass(b.dataset.cls));
      });
    }

    const search = $("cp-search");
    search.value = opts.suggestion || "";
    setTimeout(() => search.focus(), 0);
    renderPickerResults(search.value);
    search.oninput = () => renderPickerResults(search.value);
    search.onkeydown = (e) => {
      if (e.key === "Enter") {
        const first = $("cp-results").querySelector("li");
        if (first) commitClass(first.dataset.cls);
        else if (search.value.trim()) commitClass(search.value.trim());
      } else if (e.key === "Escape") {
        closePicker();
      }
    };

    const del = $("cp-delete");
    if (opts.deletable && state.editingId != null) {
      del.classList.remove("hidden");
      del.onclick = () => deleteAnnotation(state.editingId);
    } else {
      del.classList.add("hidden");
    }
    $("cp-cancel").onclick = closePicker;
  }

  function renderPickerResults(q) {
    const list = $("cp-results");
    if (!list) return;
    list.innerHTML = "";
    const ql = (q || "").toLowerCase();
    const matches = state.classes.filter(c => {
      if (!ql) return true;
      return c.id.toLowerCase().includes(ql) || c.display_name.toLowerCase().includes(ql);
    }).slice(0, 30);
    matches.forEach(c => {
      const li = document.createElement("li");
      const tag = c.level === "custom" ? " [eigene]" : "";
      li.textContent = c.display_name + " — " + c.id + tag;
      li.dataset.cls = c.id;
      li.onclick = () => commitClass(c.id);
      list.appendChild(li);
    });
  }

  function closePicker() {
    $("class-picker").classList.add("hidden");
    state.pendingBox = null;
    state.editingId = null;
    state.promotingAutoBox = null;
    renderOverlay();
  }

  async function commitClass(classId) {
    if (!classId) return classId;
    classId = classId.trim();
    if (!classId) return;
    try {
      if (state.editingId != null) {
        // Reklassifikation
        await jpost(`/api/annotation/box/${state.editingId}`, { class_id: classId }, "PATCH");
      } else {
        // Neu speichern (entweder pendingBox oder promotingAutoBox)
        const b = state.pendingBox || state.promotingAutoBox;
        if (!b) return;
        await jpost("/api/annotation/box", {
          system_id: state.currentSystemId,
          x: b.x, y: b.y, w: b.w, h: b.h,
          class_id: classId,
        });
      }
      closePicker();
      await loadSystem(state.currentSystemId);
      await loadSystems();
    } catch (e) {
      console.error("commitClass failed", e);
      alert("Speichern fehlgeschlagen: " + e.message);
    }
  }

  async function deleteAnnotation(id) {
    try {
      await jpost(`/api/annotation/box/${id}`, {}, "DELETE");
      closePicker();
      await loadSystem(state.currentSystemId);
      await loadSystems();
    } catch (e) {
      console.error("delete failed", e);
    }
  }

  // ---------- Hotkeys ----------------------------------------------

  function setupHotkeys() {
    window.addEventListener("keydown", (e) => {
      // Im Suchfeld nur Esc abfangen
      if (e.target && (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA")) {
        if (e.key === "Escape") {
          if ($("class-picker").classList.contains("hidden")) {
            e.target.blur();
          } else {
            closePicker();
          }
        }
        return;
      }
      // Hotkey 1-5 fuer Top-5
      if (/^[1-5]$/.test(e.key) && !$("class-picker").classList.contains("hidden")) {
        const idx = parseInt(e.key) - 1;
        const btn = $("cp-top5").children[idx];
        if (btn) commitClass(btn.dataset.cls);
        return;
      }
      if (e.key === "Escape" && !$("class-picker").classList.contains("hidden")) {
        closePicker();
      }
      if (e.key === "Delete" && state.editingId != null) {
        deleteAnnotation(state.editingId);
      }
    });
  }

  // ---------- Init -------------------------------------------------

  function init() {
    setupCanvas();
    setupHotkeys();
    $("ann-filter").addEventListener("input", renderSystemList);
    $("ann-show-auto").addEventListener("change", (e) => {
      state.showAuto = e.target.checked;
      renderOverlay();
    });
    loadClasses().then(() => loadSystems());
    setInterval(loadSystems, 30000);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
