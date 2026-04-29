# 12 — Visualisierung & Datei-Strategie

> **Status:** Spec, ergänzt das Konzept aus `09-osmd-rendering-and-annotations.md`.
> **Ändert** das bisherige Verhalten von PDF-Anzeige auf Bild-Extraktion.

## 12.1 Grundregel

> **PDFs werden nie direkt in der App angezeigt.**

PDFs sind ein **Rohformat**: gut zum Archivieren, schlecht zum Annotieren
(keine pixelweise stabile Annotations-Position über Zoom-Stufen, Schriften
können fehlen, Browser-PDF-Plugins sind inkonsistent).

Stattdessen gibt es zwei Anzeige-Modi pro Stimme:

| Modus | Quelle | Default |
|---|---|---|
| **Score** | MusicXML → OSMD-SVG | ✅ Default wenn vorhanden |
| **Image** | Bilder (PNG, je 1 pro PDF-Seite) | Fallback / Override |

Das Original-PDF bleibt im FileStore und steht für **Download**
(genehmigungs­pflichtig, s. 12.5) zur Verfügung — wird aber **nicht im Viewer
gerendert**.

## 12.2 Bild-Extraktion

Wenn ein User für ein Stück oder eine Stimme den Image-Modus aktiviert oder
keine MusicXML vorhanden ist, baut der Server beim ersten Bedarf einen
Bilder-Satz aus dem PDF.

### Pipeline

```
PDF.Upload  ──►  OmrJob (optional)  ──►  Confirm
                                          │
                                          ├──► PartFile.Pdf      (Original, archiviert)
                                          ├──► PartFile.MusicXml (wenn OMR erfolgreich)
                                          └──► PartFile.PageImage (lazy: on first view)
```

`PartFile.PageImage` ist ein neuer `PartFileKind` mit
- `PageNumber` (1-basiert)
- BlobKey → PNG, ~150 dpi (lesbar auf Tablet, ~600 KB pro Seite)

### Tooling

- `pdftoppm` (poppler) ist die etablierte Wahl auf Linux/Windows/macOS.
- Aufruf:
  `pdftoppm -png -r 150 input.pdf out` → `out-1.png`, `out-2.png`, …
- Wir wrappen das in `IPdfImageExtractor` mit `pdftoppm` als
  Default-Implementierung. In Containern: poppler-utils mitinstallieren.
- Alternative für reines .NET: `PDFtoImage` (NuGet) auf SkiaSharp-Basis —
  liegt wahrscheinlich näher an unserer Aspire-Architektur als ein
  externes Tool, aber etwas langsamer.

### Ablage

- BlobKey: `parts/{partId}/page-{n:D3}.png`
- Idempotent: erneutes Extrahieren überschreibt nicht, sondern überspringt.
- Wenn das PDF ersetzt wird, werden alle abgeleiteten PNGs invalidiert.

## 12.3 Anzeige

### Score-Modus (Default mit MusicXML)

Wie heute: OSMD rendert `<svg>` aus MusicXML. Annotation-Layer (Canvas +
Text-DOM) liegt darüber. Vorteile: vektorbasiert, alle Annotationen bleiben
beim Zoom positionsstabil.

### Image-Modus

```
┌─────────────────────────────────────┐
│  Seite 1 / 4   ◄  ►   Zoom 100%     │
├─────────────────────────────────────┤
│                                      │
│   <img src="/api/parts/{id}/page/1"/>│  ← skaliert per CSS
│   <canvas>                           │  ← Annotationen
│   <div class="text-layer">           │
│                                      │
└─────────────────────────────────────┘
```

- Pro Seite ein Annotation-Layer (Strokes & Texte mit `page=N`).
- Mehrseitige PDFs: vertikal scrollbar, oder Pager mit ◄/►.
- Zoom-Buttons (50/75/100/150/200 %) — Strokes bleiben durch
  normalisierte 0..1-Koordinaten positionsstabil.

### Auswahl Score vs. Image

Pro Stimme gespeichert in `Part.PreferredViewMode` (Enum
`Score | Image | Auto`). Default `Auto`:
- MusicXML vorhanden → Score
- sonst → Image

Pro Stück gibt es einen Default, der pro Stimme überschreibbar ist:
`Piece.DefaultViewMode`.

### Was passiert mit Stimmen ohne MusicXML & ohne PageImages?

- Beim ersten Öffnen wird die Image-Pipeline lazy ausgelöst.
- Bis die PNGs fertig sind: Skeleton-Loader + "Bilder werden erstellt …".
- Audiveris-OMR (wenn aktiviert) ergänzt MusicXML zusätzlich, dann
  wechselt Default automatisch auf Score.

## 12.4 Caching & Offline

- PNGs sind statisch → aggressives HTTP-Caching (`Cache-Control: public,
  immutable, max-age=31536000`). BlobKey enthält Content-Hash.
- Service-Worker cached PNGs unter `/files/parts/.../page/N` cache-first
  (genauso wie heute PDFs).
- Offline-Service speichert den Image-Satz statt des PDFs für offline
  verfügbare Stücke (kleiner und schneller als PDF-Decoding).

## 12.5 Download-Berechtigung

Pro Verein konfigurierbar:

```csharp
public class Band
{
    public bool AllowMemberDownloads { get; set; } = false;
    public bool AllowConductorDownloads { get; set; } = true;
}
```

Logik:

| Rolle | AllowMemberDownloads = false | = true |
|---|---|---|
| Mitglied | kein Download-Button | Download via `?download=1` |
| Dirigent | je `AllowConductorDownloads` | Download |
| Admin/Owner | immer | immer |

Backend-Endpoint `/files/parts/{id}/{file}?download=1` prüft die
Berechtigung und liefert sonst 403. Der Inline-Modus (für gar keine
Anzeige seitens PDF, aber Download von MusicXML) bleibt für alle
zugänglich, da die App es selbst zur Anzeige fetched.

## 12.6 Migration

- Bestandene PartFiles bleiben bestehen (`Pdf`, `MusicXml`).
- Neuer Kind `PageImage` → DB-Migration.
- Bestehende Pieces ohne MusicXML: werden lazy auf Image-Modus migriert.
- `PartViewer`-Komponente bekommt neuen `image`-Modus, der vorhandene
  `pdf`-Modus wird entfernt (nur `score` und `image`).

## 12.7 Akzeptanzkriterien

- [ ] Beim Upload eines PDFs ohne OMR werden beim ersten Öffnen
      automatisch PNG-Seitenbilder generiert (höchstens 30 s pro PDF
      für Standard-Stimme).
- [ ] Score-Modus rendert MusicXML als SVG (OSMD), Annotationen liegen
      darüber, Zoom verschiebt sie nicht.
- [ ] Image-Modus zeigt PNGs, Annotationen pro Seite, Zoom 50–200 %.
- [ ] Pro Stimme kann zwischen Score und Image gewechselt werden, die
      Auswahl wird gespeichert.
- [ ] Pro Verein kann Download für Mitglieder freigeschaltet werden.
- [ ] Ohne Download-Recht liefert `/files/parts/.../?download=1` 403.
- [ ] PDFs werden nirgends in der App **angezeigt** (`<embed>`,
      `<iframe>` mit `application/pdf` ist verboten).
