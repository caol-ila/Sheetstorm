/* Sheetstorm OSMD Wrapper
 *
 * Lädt OpenSheetMusicDisplay (OSMD) on-demand und rendert MusicXML als SVG.
 * OSMD wird vom CDN geladen, weil das NPM-Bundle pro Page kopiert werden müsste.
 * In Production: lokal gehosteten Asset vorziehen.
 *
 * Annotation-Layer ist ein zweites Canvas/SVG-Element absolut über dem
 * OSMD-Container — Maus/Touch-Events landen darauf, das Zeichnen passiert
 * komplett auf der Browser-Seite, wir senden nur das JSON an den Server.
 */

const OSMD_CDN = 'https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@1.9.0/build/opensheetmusicdisplay.min.js';

let osmdLoaded = null;
function loadOsmd() {
  if (osmdLoaded) return osmdLoaded;
  osmdLoaded = new Promise((resolve, reject) => {
    if (window.opensheetmusicdisplay) { resolve(); return; }
    const s = document.createElement('script');
    s.src = OSMD_CDN;
    s.async = true;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error('OSMD konnte nicht geladen werden'));
    document.head.appendChild(s);
  });
  return osmdLoaded;
}

window.SheetstormOsmd = {
  /** Rendert MusicXML in einen Container. */
  async render({ containerId, musicXmlUrl, zoom = 1.0 }) {
    await loadOsmd();
    const container = document.getElementById(containerId);
    if (!container) throw new Error('Container nicht gefunden: ' + containerId);
    container.innerHTML = '';

    const osmd = new window.opensheetmusicdisplay.OpenSheetMusicDisplay(container, {
      autoResize: true,
      drawTitle: false,
      drawSubtitle: false,
      drawComposer: false,
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
      const svg = container.querySelector('svg');
      return { ok: true, width: svg?.clientWidth, height: svg?.clientHeight };
    } catch (e) {
      container.innerHTML = `<div class="alert alert-warning">Notenrendering fehlgeschlagen: ${e.message}</div>`;
      return { ok: false, error: e.message };
    }
  },
};

/* ── Annotation-Layer ─────────────────────────────────────
 *
 * Über einem beliebigen Container wird ein Canvas absolut platziert.
 * Tools: Pen, Marker (transparenter Pen), Eraser, Text.
 * Punkte werden in normalisierten 0..1 Koordinaten gespeichert,
 * damit Zoom/DPI-Wechsel die Position nicht verschieben.
 */
class AnnotationLayer {
  constructor(host, layerData = {}, { onChange } = {}) {
    this.host = host;
    this.onChange = onChange;
    this.tool = 'pen';
    this.color = '#dc2626';
    this.width = 2;
    this.layer = layerData?.strokes ? layerData : { version: 1, strokes: [], texts: [] };
    this.history = [];

    const wrapper = document.createElement('div');
    wrapper.style.position = 'relative';
    wrapper.style.display = 'inline-block';
    wrapper.style.minWidth = '100%';
    while (host.firstChild) wrapper.appendChild(host.firstChild);
    host.appendChild(wrapper);
    this.wrapper = wrapper;

    const canvas = document.createElement('canvas');
    canvas.style.position = 'absolute';
    canvas.style.left = '0';
    canvas.style.top = '0';
    canvas.style.pointerEvents = 'auto';
    canvas.style.touchAction = 'none';
    wrapper.appendChild(canvas);
    this.canvas = canvas;
    this.resize();

    new ResizeObserver(() => this.resize()).observe(wrapper);
    window.addEventListener('resize', () => this.resize());

    this.bindPointerEvents();
    this.redraw();
  }

  resize() {
    const r = this.wrapper.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = Math.max(1, r.width) * dpr;
    this.canvas.height = Math.max(1, r.height) * dpr;
    this.canvas.style.width = r.width + 'px';
    this.canvas.style.height = r.height + 'px';
    this.ctx = this.canvas.getContext('2d');
    this.ctx.scale(dpr, dpr);
    this.cw = r.width;
    this.ch = r.height;
    this.redraw();
  }

  setTool(t) { this.tool = t; }
  setColor(c) { this.color = c; }
  setWidth(w) { this.width = w; }

  bindPointerEvents() {
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
        this.notify();
        return;
      }
      if (this.tool === 'text') {
        const [x, y] = norm(e);
        const t = prompt('Text:');
        if (!t) return;
        this.layer.texts.push({ x, y, text: t, color: this.color });
        this.redraw();
        this.notify();
        return;
      }
      drawing = true;
      stroke = {
        tool: this.tool,
        color: this.color,
        width: this.width,
        opacity: this.tool === 'marker' ? 0.4 : 1,
        points: [norm(e)],
      };
      this.canvas.setPointerCapture(e.pointerId);
    });

    this.canvas.addEventListener('pointermove', (e) => {
      if (!drawing || !stroke) return;
      stroke.points.push(norm(e));
      this.drawStroke(stroke, true);
    });

    const finish = () => {
      if (drawing && stroke && stroke.points.length >= 2) {
        this.layer.strokes.push(stroke);
        this.notify();
      }
      drawing = false;
      stroke = null;
    };
    this.canvas.addEventListener('pointerup', finish);
    this.canvas.addEventListener('pointercancel', finish);
    this.canvas.addEventListener('pointerleave', finish);
  }

  eraseAt(x, y, radius = 0.02) {
    const before = this.layer.strokes.length;
    this.layer.strokes = this.layer.strokes.filter(s =>
      !s.points.some(([px, py]) => Math.hypot(px - x, py - y) < radius));
    this.layer.texts = this.layer.texts.filter(t => Math.hypot(t.x - x, t.y - y) > radius);
    if (this.layer.strokes.length !== before) this.redraw();
  }

  drawStroke(s, incremental = false) {
    if (!s || !s.points.length) return;
    this.ctx.strokeStyle = s.color;
    this.ctx.lineWidth = (s.width ?? 2);
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

  drawText(t) {
    this.ctx.fillStyle = t.color || '#000';
    this.ctx.font = '14px sans-serif';
    this.ctx.fillText(t.text, t.x * this.cw, t.y * this.ch);
  }

  redraw() {
    if (!this.ctx) return;
    this.ctx.clearRect(0, 0, this.cw, this.ch);
    for (const s of this.layer.strokes) this.drawStroke(s);
    for (const t of (this.layer.texts || [])) this.drawText(t);
  }

  clear() {
    this.layer = { version: 1, strokes: [], texts: [] };
    this.redraw();
    this.notify();
  }

  undo() {
    if (this.layer.strokes.length === 0) return;
    this.layer.strokes.pop();
    this.redraw();
    this.notify();
  }

  toJson() { return JSON.stringify(this.layer); }

  notify() {
    if (this.onChange) {
      clearTimeout(this._t);
      this._t = setTimeout(() => this.onChange(this.toJson()), 800);
    }
  }
}

window.SheetstormAnnotations = {
  layers: new Map(),

  async attach({ hostId, partId, page, dotnetRef }) {
    const host = document.getElementById(hostId);
    if (!host) return null;
    let initial = { version: 1, strokes: [], texts: [] };
    try {
      const r = await fetch(`/api/parts/${partId}/annotations/${page}`, { credentials: 'include' });
      if (r.ok) {
        const j = await r.json();
        initial = JSON.parse(j.layerJson);
      }
    } catch { /* keine vorhandene */ }

    const layer = new AnnotationLayer(host, initial, {
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
    });
    this.layers.set(hostId, layer);
    return { attached: true };
  },

  setTool(hostId, tool) { this.layers.get(hostId)?.setTool(tool); },
  setColor(hostId, color) { this.layers.get(hostId)?.setColor(color); },
  undo(hostId) { this.layers.get(hostId)?.undo(); },
  clear(hostId) { this.layers.get(hostId)?.clear(); },
};
