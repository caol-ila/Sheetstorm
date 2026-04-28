/* Sheetstorm Score-Viewer + Annotation-Layer
 *
 * Architektur:
 *  ┌───────────────────────────────────────┐
 *  │  ss-stage  (position: relative)       │
 *  │  ┌──────────────────────────────────┐ │
 *  │  │  ss-content  (OSMD-SVG / iframe) │ │  <- reines Anzeige-Layer
 *  │  └──────────────────────────────────┘ │
 *  │  ┌──────────────────────────────────┐ │
 *  │  │  ss-canvas (absolute, top:0)     │ │  <- Pen/Marker-Strokes
 *  │  └──────────────────────────────────┘ │
 *  │  ┌──────────────────────────────────┐ │
 *  │  │  ss-text-layer (absolute)        │ │  <- DOM-Boxen pro Text
 *  │  └──────────────────────────────────┘ │
 *  └───────────────────────────────────────┘
 *
 * OSMD wird vom CDN geladen und rendert ein <svg> in #ss-content.
 * Der Annotation-Layer liegt darüber. Strokes werden auf einem Canvas
 * gezeichnet, Texte sind absolute <div>s (deshalb verschiebbar/skalierbar/
 * drehbar via Maus + Touch).
 *
 * Tools:
 *   pen   : 2px, opaque, default rot
 *   marker: 14px, alpha 0.35, default gelb
 *   text  : nach Platzieren Auto-Switch zu pen
 *   eraser: löscht Strokes oder Text-Boxen unter dem Cursor
 *
 * Persistierung: layer.strokes (norm. 0..1) + layer.texts ({x,y,scale,rotation,...})
 * werden bei jeder Änderung debounced (700ms) als JSON ans Backend geschickt.
 */

const OSMD_CDN = 'https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@1.9.0/build/opensheetmusicdisplay.min.js';

let osmdLoadingPromise = null;
function loadOsmd() {
  if (osmdLoadingPromise) return osmdLoadingPromise;
  osmdLoadingPromise = new Promise((resolve, reject) => {
    if (window.opensheetmusicdisplay) { resolve(); return; }
    const s = document.createElement('script');
    s.src = OSMD_CDN;
    s.async = true;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error('OSMD konnte nicht geladen werden'));
    document.head.appendChild(s);
  });
  return osmdLoadingPromise;
}

window.SheetstormOsmd = {
  /** Rendert MusicXML in #<contentId>. Rückgabe: {ok, error?} */
  async render({ contentId, musicXmlUrl, zoom = 1.0 }) {
    try {
      await loadOsmd();
    } catch (e) {
      const c = document.getElementById(contentId);
      if (c) c.innerHTML = `<div class="alert alert-warning">OSMD-Bibliothek konnte nicht geladen werden: ${e.message}</div>`;
      return { ok: false, error: e.message };
    }
    const container = document.getElementById(contentId);
    if (!container) return { ok: false, error: 'Container nicht gefunden: ' + contentId };
    container.innerHTML = '';
    const osmd = new window.opensheetmusicdisplay.OpenSheetMusicDisplay(container, {
      autoResize: true,
      drawTitle: true,
      drawSubtitle: false,
      drawComposer: true,
      drawCredits: false,
      backend: 'svg',
    });
    osmd.zoom = zoom;
    try {
      const r = await fetch(musicXmlUrl, { credentials: 'include' });
      if (!r.ok) throw new Error('MusicXML-Download fehlgeschlagen: ' + r.status);
      const xml = await r.text();
      await osmd.load(xml);
      osmd.render();
      // Layer-Resize triggern
      const stage = container.closest('.ss-stage');
      if (stage && stage.__sheetstormLayer) stage.__sheetstormLayer.resize();
      return { ok: true };
    } catch (e) {
      container.innerHTML = `<div class="alert alert-warning">Notenrendering fehlgeschlagen: ${e.message}</div>`;
      return { ok: false, error: e.message };
    }
  },
};

/** Tool-Defaults — können per setColor/setWidth überschrieben werden. */
const TOOL_DEFAULTS = {
  pen:    { width: 2,  opacity: 1.0,  color: '#dc2626' }, // dünner roter Stift
  marker: { width: 14, opacity: 0.35, color: '#fde047' }, // breiter gelber Marker
  text:   { width: 2,  opacity: 1.0,  color: '#1f2937' }, // dunkles Anthrazit
  eraser: { width: 1,  opacity: 1.0,  color: '#000000' },
};

class AnnotationLayer {
  constructor(stage, layerData, { onChange, onToolChanged } = {}) {
    this.stage = stage;
    this.onChange = onChange;
    this.onToolChanged = onToolChanged;

    this.tool = 'pen';
    // Pro Tool eigener User-Override (Farbe/Width)
    this.toolState = JSON.parse(JSON.stringify(TOOL_DEFAULTS));
    this.layer = (layerData && layerData.strokes) ? layerData : { version: 2, strokes: [], texts: [] };

    // Stage-Setup
    this.stage.style.position = 'relative';
    this.canvas = document.createElement('canvas');
    this.canvas.className = 'ss-canvas';
    Object.assign(this.canvas.style, { position: 'absolute', left: '0', top: '0', touchAction: 'none' });
    this.stage.appendChild(this.canvas);

    this.textLayer = document.createElement('div');
    this.textLayer.className = 'ss-text-layer';
    Object.assign(this.textLayer.style, { position: 'absolute', left: '0', top: '0', width: '100%', height: '100%', pointerEvents: 'none' });
    this.stage.appendChild(this.textLayer);

    this.stage.__sheetstormLayer = this;

    new ResizeObserver(() => this.resize()).observe(this.stage);
    this.bindStrokeEvents();
    this.resize();
    this.rebuildTexts();
  }

  /* ── Layout ──────────────────────────────────────────── */
  resize() {
    const r = this.stage.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = Math.max(1, r.width) * dpr;
    this.canvas.height = Math.max(1, r.height) * dpr;
    this.canvas.style.width = r.width + 'px';
    this.canvas.style.height = r.height + 'px';
    this.ctx = this.canvas.getContext('2d');
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.cw = r.width; this.ch = r.height;
    this.redrawStrokes();
    this.layoutTexts();
  }

  /* ── Tool-Handling ───────────────────────────────────── */
  setTool(t) {
    this.tool = t;
    // Eraser/Text aktivieren Canvas-Eingaben; Selektion zurücksetzen
    if (t !== 'select') this.deselectText();
    // Canvas in Vordergrund wenn nicht "select"
    this.canvas.style.pointerEvents = (t === 'select') ? 'none' : 'auto';
    this.canvas.style.cursor = t === 'eraser' ? 'crosshair' : (t === 'text' ? 'text' : 'crosshair');
    this.notifyTool();
  }
  setColor(c) {
    if (this.toolState[this.tool]) this.toolState[this.tool].color = c;
    if (this.selectedText) {
      this.selectedText.color = c;
      this.layoutTexts(); this.notify();
    }
  }
  setWidth(w) {
    if (this.toolState[this.tool]) this.toolState[this.tool].width = Number(w);
  }
  notifyTool() {
    if (this.onToolChanged) {
      const s = this.toolState[this.tool] || TOOL_DEFAULTS.pen;
      this.onToolChanged({ tool: this.tool, color: s.color, width: s.width });
    }
  }

  /* ── Stroke-Events (Pen/Marker/Eraser) ───────────────── */
  bindStrokeEvents() {
    let drawing = false;
    let stroke = null;

    const norm = (e) => {
      const r = this.canvas.getBoundingClientRect();
      return [(e.clientX - r.left) / r.width, (e.clientY - r.top) / r.height];
    };

    this.canvas.addEventListener('pointerdown', (e) => {
      if (this.tool === 'eraser') {
        const [x, y] = norm(e);
        this.eraseAt(x, y);
        return;
      }
      if (this.tool === 'text') {
        const [x, y] = norm(e);
        const t = prompt('Notiz-Text:');
        if (t && t.trim().length > 0) {
          this.layer.texts.push({
            id: cryptoRandomId(),
            x, y,
            text: t,
            color: this.toolState.text.color,
            fontSize: 16,
            scale: 1,
            rotation: 0,
          });
          this.rebuildTexts();
          this.notify();
        }
        // Auto-Switch zurueck zu pen wie spezifiziert
        this.setTool('pen');
        return;
      }
      // Pen / Marker
      const s = this.toolState[this.tool] || TOOL_DEFAULTS.pen;
      drawing = true;
      stroke = {
        tool: this.tool,
        color: s.color,
        width: s.width,
        opacity: s.opacity,
        points: [norm(e)],
      };
      this.canvas.setPointerCapture(e.pointerId);
    });

    this.canvas.addEventListener('pointermove', (e) => {
      if (!drawing || !stroke) return;
      stroke.points.push(norm(e));
      this.drawStroke(stroke);
    });

    const finish = () => {
      if (drawing && stroke && stroke.points.length >= 2) {
        this.layer.strokes.push(stroke);
        this.notify();
      } else {
        this.redrawStrokes();
      }
      drawing = false;
      stroke = null;
    };
    this.canvas.addEventListener('pointerup', finish);
    this.canvas.addEventListener('pointercancel', finish);
    this.canvas.addEventListener('pointerleave', finish);
  }

  eraseAt(nx, ny, radius = 0.025) {
    const beforeS = this.layer.strokes.length;
    const beforeT = this.layer.texts.length;
    this.layer.strokes = this.layer.strokes.filter(s =>
      !s.points.some(([px, py]) => Math.hypot(px - nx, py - ny) < radius));
    this.layer.texts = this.layer.texts.filter(t => Math.hypot(t.x - nx, t.y - ny) > radius);
    if (this.layer.strokes.length !== beforeS || this.layer.texts.length !== beforeT) {
      this.redrawStrokes();
      this.rebuildTexts();
      this.notify();
    }
  }

  drawStroke(s) {
    if (!s || s.points.length < 1) return;
    // Marker zeichnet zusätzlich auf das aktuelle Canvas, beim finalen redraw
    // werden alle Strokes deterministisch gerendert.
    this.ctx.strokeStyle = s.color;
    this.ctx.lineWidth = s.width || 2;
    this.ctx.globalAlpha = s.opacity ?? 1;
    this.ctx.lineCap = 'round';
    this.ctx.lineJoin = 'round';
    this.ctx.beginPath();
    for (let i = 0; i < s.points.length; i++) {
      const [x, y] = s.points[i];
      const cx = x * this.cw, cy = y * this.ch;
      if (i === 0) this.ctx.moveTo(cx, cy); else this.ctx.lineTo(cx, cy);
    }
    this.ctx.stroke();
    this.ctx.globalAlpha = 1;
  }

  redrawStrokes() {
    if (!this.ctx) return;
    this.ctx.clearRect(0, 0, this.cw, this.ch);
    for (const s of this.layer.strokes) this.drawStroke(s);
  }

  /* ── Text-Boxen (DOM) ────────────────────────────────── */
  rebuildTexts() {
    while (this.textLayer.firstChild) this.textLayer.removeChild(this.textLayer.firstChild);
    this.textBoxes = new Map();
    for (const t of this.layer.texts) this.createTextBox(t);
    this.layoutTexts();
  }

  createTextBox(t) {
    const box = document.createElement('div');
    box.className = 'ss-text-box';
    box.dataset.id = t.id;
    Object.assign(box.style, {
      position: 'absolute',
      transformOrigin: 'center center',
      pointerEvents: 'auto',
      cursor: 'move',
      userSelect: 'none',
      whiteSpace: 'pre',
      padding: '2px 6px',
      borderRadius: '4px',
      background: 'rgba(255,255,255,0.7)',
      border: '1px dashed transparent',
      fontFamily: 'system-ui, sans-serif',
    });
    box.textContent = t.text;
    this.textLayer.appendChild(box);

    const handle = document.createElement('div');
    handle.className = 'ss-text-handle';
    Object.assign(handle.style, {
      position: 'absolute', right: '-10px', bottom: '-10px',
      width: '14px', height: '14px',
      background: '#2563eb', border: '2px solid white',
      borderRadius: '50%', cursor: 'nwse-resize', display: 'none',
    });
    box.appendChild(handle);

    const rotateHandle = document.createElement('div');
    rotateHandle.className = 'ss-text-rotate';
    Object.assign(rotateHandle.style, {
      position: 'absolute', left: '50%', top: '-22px', transform: 'translateX(-50%)',
      width: '12px', height: '12px',
      background: '#16a34a', border: '2px solid white',
      borderRadius: '50%', cursor: 'grab', display: 'none',
    });
    box.appendChild(rotateHandle);

    this.bindTextEvents(box, t, handle, rotateHandle);
    this.textBoxes.set(t.id, { box, handle, rotateHandle });
  }

  layoutTexts() {
    if (!this.textBoxes) return;
    for (const t of this.layer.texts) {
      const entry = this.textBoxes.get(t.id);
      if (!entry) continue;
      const { box } = entry;
      box.style.color = t.color || '#1f2937';
      box.style.fontSize = (t.fontSize || 16) + 'px';
      box.textContent = t.text;
      // Re-append handles after textContent overwrite
      box.appendChild(entry.handle);
      box.appendChild(entry.rotateHandle);
      const px = t.x * this.cw, py = t.y * this.ch;
      box.style.left = px + 'px';
      box.style.top = py + 'px';
      box.style.transform = `translate(-50%, -50%) rotate(${t.rotation || 0}deg) scale(${t.scale || 1})`;
    }
  }

  selectText(t) {
    this.deselectText();
    this.selectedText = t;
    const entry = this.textBoxes.get(t.id);
    if (!entry) return;
    entry.box.style.borderColor = '#2563eb';
    entry.handle.style.display = 'block';
    entry.rotateHandle.style.display = 'block';
  }
  deselectText() {
    if (!this.selectedText) return;
    const entry = this.textBoxes.get(this.selectedText.id);
    if (entry) {
      entry.box.style.borderColor = 'transparent';
      entry.handle.style.display = 'none';
      entry.rotateHandle.style.display = 'none';
    }
    this.selectedText = null;
  }

  bindTextEvents(box, t, handle, rotateHandle) {
    // Pointer/Touch-Pointer: einfaches Drag, plus Pinch/Rotate über zwei Pointer
    const pointers = new Map();
    let mode = null; // 'drag' | 'scale' | 'rotate' | 'gesture'
    let dragStart = null;
    let initial = null; // {x,y,scale,rotation}
    let gestureStart = null; // {dist, angle, scale, rotation}

    const stageRect = () => this.canvas.getBoundingClientRect();
    const pointerNorm = (e) => {
      const r = stageRect();
      return [(e.clientX - r.left) / r.width, (e.clientY - r.top) / r.height];
    };

    box.addEventListener('pointerdown', (e) => {
      if (e.target === handle) {
        e.stopPropagation();
        mode = 'scale';
        box.setPointerCapture(e.pointerId);
        const r = stageRect();
        dragStart = { cx: e.clientX, cy: e.clientY };
        initial = { ...t };
        // Distanz vom Zentrum als Referenz
        initial.startDist = Math.hypot(
          e.clientX - (r.left + t.x * r.width),
          e.clientY - (r.top + t.y * r.height)
        ) || 1;
        return;
      }
      if (e.target === rotateHandle) {
        e.stopPropagation();
        mode = 'rotate';
        box.setPointerCapture(e.pointerId);
        const r = stageRect();
        initial = { ...t };
        initial.cx = r.left + t.x * r.width;
        initial.cy = r.top + t.y * r.height;
        initial.startAngle = Math.atan2(e.clientY - initial.cy, e.clientX - initial.cx) * 180 / Math.PI;
        return;
      }

      pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
      this.selectText(t);

      if (pointers.size === 1) {
        mode = 'drag';
        box.setPointerCapture(e.pointerId);
        const [nx, ny] = pointerNorm(e);
        dragStart = { nx, ny };
        initial = { ...t };
      } else if (pointers.size === 2) {
        mode = 'gesture';
        const pts = Array.from(pointers.values());
        gestureStart = {
          dist: Math.hypot(pts[1].x - pts[0].x, pts[1].y - pts[0].y),
          angle: Math.atan2(pts[1].y - pts[0].y, pts[1].x - pts[0].x) * 180 / Math.PI,
          scale: t.scale || 1,
          rotation: t.rotation || 0,
        };
      }
    });

    box.addEventListener('pointermove', (e) => {
      if (!mode) return;
      if (pointers.has(e.pointerId)) pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

      if (mode === 'drag' && pointers.size === 1) {
        const [nx, ny] = pointerNorm(e);
        t.x = initial.x + (nx - dragStart.nx);
        t.y = initial.y + (ny - dragStart.ny);
        t.x = Math.min(1, Math.max(0, t.x));
        t.y = Math.min(1, Math.max(0, t.y));
        this.layoutTexts();
      } else if (mode === 'scale') {
        const r = stageRect();
        const d = Math.hypot(
          e.clientX - (r.left + initial.x * r.width),
          e.clientY - (r.top + initial.y * r.height)
        );
        t.scale = Math.max(0.3, Math.min(8, (initial.scale || 1) * (d / initial.startDist)));
        this.layoutTexts();
      } else if (mode === 'rotate') {
        const ang = Math.atan2(e.clientY - initial.cy, e.clientX - initial.cx) * 180 / Math.PI;
        t.rotation = (initial.rotation || 0) + (ang - initial.startAngle);
        this.layoutTexts();
      } else if (mode === 'gesture' && pointers.size === 2) {
        const pts = Array.from(pointers.values());
        const dist = Math.hypot(pts[1].x - pts[0].x, pts[1].y - pts[0].y);
        const angle = Math.atan2(pts[1].y - pts[0].y, pts[1].x - pts[0].x) * 180 / Math.PI;
        t.scale = Math.max(0.3, Math.min(8, gestureStart.scale * (dist / Math.max(1, gestureStart.dist))));
        t.rotation = gestureStart.rotation + (angle - gestureStart.angle);
        this.layoutTexts();
      }
    });

    const end = (e) => {
      if (pointers.has(e.pointerId)) pointers.delete(e.pointerId);
      if (mode) this.notify();
      if (pointers.size === 0) mode = null;
    };
    box.addEventListener('pointerup', end);
    box.addEventListener('pointercancel', end);

    // Doppelklick → Text editieren
    box.addEventListener('dblclick', () => {
      const next = prompt('Text bearbeiten:', t.text);
      if (next !== null) {
        t.text = next;
        this.layoutTexts();
        this.notify();
      }
    });
  }

  /* ── Persistierung ───────────────────────────────────── */
  clear() {
    this.layer = { version: 2, strokes: [], texts: [] };
    this.deselectText();
    this.redrawStrokes();
    this.rebuildTexts();
    this.notify();
  }

  undo() {
    if (this.layer.strokes.length > 0) {
      this.layer.strokes.pop();
    } else if (this.layer.texts.length > 0) {
      this.layer.texts.pop();
      this.rebuildTexts();
    } else { return; }
    this.redrawStrokes();
    this.notify();
  }

  toJson() { return JSON.stringify(this.layer); }

  notify() {
    if (this.onChange) {
      clearTimeout(this._t);
      this._t = setTimeout(() => this.onChange(this.toJson()), 700);
    }
  }
}

function cryptoRandomId() {
  if (window.crypto && window.crypto.randomUUID) return window.crypto.randomUUID();
  return 'tx-' + Math.random().toString(36).slice(2, 10);
}

window.SheetstormAnnotations = {
  layers: new Map(),

  async attach({ stageId, partId, page, dotnetRef }) {
    const stage = document.getElementById(stageId);
    if (!stage) return null;
    // Bereits attached? Aufräumen.
    if (this.layers.has(stageId)) {
      const old = this.layers.get(stageId);
      try { old.canvas.remove(); old.textLayer.remove(); } catch { }
      this.layers.delete(stageId);
    }

    let initial = { version: 2, strokes: [], texts: [] };
    try {
      const r = await fetch(`/api/parts/${partId}/annotations/${page}`, { credentials: 'include' });
      if (r.ok) {
        const j = await r.json();
        const parsed = JSON.parse(j.layerJson);
        if (parsed) initial = parsed;
        if (!initial.texts) initial.texts = [];
        if (!initial.strokes) initial.strokes = [];
      }
    } catch { /* noch keine */ }

    const layer = new AnnotationLayer(stage, initial, {
      onChange: (json) => {
        fetch(`/api/parts/${partId}/annotations/${page}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({ layerJson: json }),
        }).then(() => {
          if (dotnetRef) dotnetRef.invokeMethodAsync('OnAnnotationSaved').catch(() => {});
        });
      },
      onToolChanged: (info) => {
        if (dotnetRef) dotnetRef.invokeMethodAsync('OnToolChanged', info.tool, info.color, info.width).catch(() => {});
      },
    });
    this.layers.set(stageId, layer);
    return { attached: true };
  },

  setTool(stageId, tool) { this.layers.get(stageId)?.setTool(tool); },
  setColor(stageId, color) { this.layers.get(stageId)?.setColor(color); },
  setWidth(stageId, width) { this.layers.get(stageId)?.setWidth(width); },
  undo(stageId) { this.layers.get(stageId)?.undo(); },
  clear(stageId) { this.layers.get(stageId)?.clear(); },
  detach(stageId) {
    const l = this.layers.get(stageId);
    if (l) { try { l.canvas.remove(); l.textLayer.remove(); } catch { } this.layers.delete(stageId); }
  },
};
