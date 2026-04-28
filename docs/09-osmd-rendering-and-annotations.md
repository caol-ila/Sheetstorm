# 09 — Notenanzeige & Annotationen (MusicXML-First)

## Vision

Statt PDF-Embed sollen Stimmen als **echte SVG-gerenderte Noten**
angezeigt werden. Wenn Audiveris die MusicXML extrahiert hat, nutzen
wir [OpenSheetMusicDisplay (OSMD)](https://opensheetmusicdisplay.org)
für das Rendering im Browser.

Vorteile gegenüber PDF:
- Pixel-perfekt skalierbar
- Annotation-Layer als SVG-Overlay
- Klickbare Takte für Sprung-Marken
- Auto-Transposition (B → Es etc.)
- Audio-Vorhören via MIDI möglich
- Such- und Markier-Funktionen

## Datenfluss

```
PDF-Upload
    ↓
Audiveris-Sidecar (im Container)
    ↓                     ↓
MusicXML            Original-PDF (bleibt erhalten)
    ↓
PartFile mit Kind=MusicXml
    ↓
OSMD im Browser → SVG-Render → Annotation-Overlay
```

## Anzeige-Logik im Frontend

Pro Stimme prüfe verfügbare Files:

| Verfügbar | Anzeige |
|---|---|
| MusicXml + PDF | OSMD (Default), Toggle "Original-PDF anzeigen" |
| Nur MusicXml | OSMD |
| Nur PDF | PDF.js (statt nativem Embed für mehr Kontrolle) |
| Nichts | "Keine Datei" |

## Annotation-Format

JSON-Layer pro Seite, gespeichert in `Annotation.LayerJson`:

```json
{
  "version": 1,
  "strokes": [
    { "tool": "pen", "color": "#dc2626", "width": 2,
      "points": [[x, y], [x, y], ...] }
  ],
  "stamps": [
    { "kind": "fingering", "value": "3", "x": 120, "y": 80 }
  ],
  "texts": [
    { "x": 200, "y": 100, "text": "leise!", "color": "#000" }
  ]
}
```

Koordinaten relativ zum Render-Container (0..1 normalisiert), damit
Zoom + DPI-Wechsel keine Position kaputt macht.

## Toolbar

Über jeder Stimme:

```
[ Pen ] [ Marker ] [ Text ] [ Stempel ▾ ] [ Farbe ▾ ]
[ Rückgängig ] [ Wiederholen ] [ Alles löschen ]
[ Zoom -/+ ] [ Original-PDF ] [ Speichern ✓ Auto ]
```

## Annotation-Sync

* **Local-First**: Annotationen sofort sichtbar, im IndexedDB
  zwischengespeichert
* **Auto-Save** alle 2s (debounced) an `PUT /api/parts/{id}/annotations/{page}`
* **Last-Write-Wins** mit `Version`-Counter (siehe Domain)
* **Offline**: Änderungen queuen, sync bei Reconnect

## OSMD-Integration

OSMD wird via NPM/CDN geladen, in `wwwroot/js/osmd-viewer.js`
als selbstständiger Wrapper:

```js
window.SheetstormOsmd.render({
  containerId: 'osmd-target',
  musicXml: '<?xml version="1.0"...',
  zoom: 1.0,
  drawTitle: false, // Sheetstorm hat eigene UI dafür
  onReady: (info) => { /* pageCount, etc. */ }
});
```

JS-Interop von Blazor:
```razor
@inject IJSRuntime JS

protected override async Task OnAfterRenderAsync(bool firstRender) {
    if (firstRender) {
        await JS.InvokeVoidAsync("SheetstormOsmd.render", new { ... });
    }
}
```

## Performance

| Stück | Render-Zeit |
|---|---|
| 1-seitig | <500ms |
| 4-seitig | ~1s |
| 10-seitig | ~3s |

OSMD-Bundle: ~1.5 MB minified (lädt einmalig, dann gecached vom SW).

## Roadmap (in dieser Iteration)

1. OSMD-NPM-Paket via CDN-Skript einbinden
2. JS-Wrapper `osmd-viewer.js` mit `render()` und `getSvgRoot()`
3. Endpoint `/files/parts/{partId}/{fileId}/musicxml` der Audiveris-XML
   ausliefert (text/xml)
4. PieceDetail um Toggle "Noten | PDF | Original" ergänzen
5. Annotation-Canvas-Overlay (HTML5 Canvas oder SVG-Layer)
6. Toolbar mit Pen/Marker/Eraser/Text + Farbwahl
7. Auto-Save via `PUT /api/parts/{partId}/annotations/{page}`
8. E2E-Tests (Render, Annotation zeichnen, Persistenz)

## Spätere Erweiterungen

* **Auto-Transposition** über OSMD's `Transpose`-Plugin
* **Audio-Vorschau** per OSMD-MIDI-Generator + WebAudio
* **Klick-auf-Takt** triggert Sprung im Konzert-Modus
* **AI-Text-Erkennung** in Annotationen (handgeschriebene Notizen
  → durchsuchbarer Text)
* **Geteilte Annotationen** (Dirigent-Striche an alle pushen)
