# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28 — Marktanalyse abgeschlossen

**Wettbewerber-Landschaft:**
- 17+ Produkte analysiert in 9 Kategorien (Sheet Music, Blasmusik, Vereinsverwaltung, Setlist, Lehre, AI/OCR, Echtzeit-Sync)
- Markt ist stark fragmentiert — kein All-in-One-Produkt existiert
- **Stärkste Wettbewerber für unseren Use Case:** Marschpat (Blasmusik-Noten), Notabl (Musikverein All-in-One), Newzik (Ensemble-Kollaboration), Konzertmeister (Vereinsorganisation)
- forScore und MobileSheets dominieren bei Notenanzeige, sind aber reine Einzelmusiker-Tools

**Zentrale Marktlücken identifiziert:**
1. Kein Produkt kombiniert professionelle Notenanzeige + Vereinsverwaltung + AI-Upload
2. Intelligentes Stimmen-Mapping mit Fallback-Logik existiert nirgendwo
3. AI-gestützter Multi-Lied-Upload mit Labeling ist ein Novum
4. Multi-Kapellen-Zugehörigkeit wird von keinem Wettbewerber unterstützt
5. Drei-Ebenen-Annotationen (Privat/Stimme/Orchester) als Kernkonzept fehlt überall
6. Echtzeit-Metronom-Sync im Notenkontext existiert nicht integriert
7. Lehre-Modul im Vereinskontext existiert nicht

**Wichtige Muster:**
- Blasmusik-Markt (DACH) hat eigene Anbieter (Marschpat, Notabl, Glissandoo, Musicorum) — internationaler Markt ist anders strukturiert
- Preismodelle: Mix aus Einmalkauf (forScore, MobileSheets), Abo (Newzik, Marschpat), Freemium (Glissandoo, Konzertmeister), und Open Source (BNote)
- Cross-Platform ist Pflicht — Kapellenmitglieder nutzen gemischte Geräte
- DSGVO-Konformität ist im DACH-Raum ein entscheidender Faktor
- BYOK (Bring Your Own Key) für AI-Dienste ist ein Alleinstellungsmerkmal ohne Konkurrenz

### 2026-03-28 — Marktanalyse v2 + UX-Research abgeschlossen (vollständige Neuerstellung)

**Neue Preisdaten (2024/2025 verifiziert):**
- forScore: $24,99 Einmalkauf + $9,99/Jahr Pro (forScore 15 neu 2025)
- MobileSheets: $15,99 Einmalkauf (Android/Windows/iOS)
- Newzik: Freemium; Premium $49-179/Jahr; Ensemble auf Anfrage (intransparent!)
- Konzertmeister: Gratis bis 30; Pro 33-99€/Jahr; Speicher-Extra 10-40€/Jahr
- Marschpat: Individual 97€/Jahr; Gruppe ab 151€/Jahr; Hardware extra
- Glissandoo: Bis 20 Mitglieder kostenlos; größere Gruppen auf Anfrage
- BAND: Kostenlos (werbefinanziert)

**UX-Erkenntnisse (neu in v2):**
- forScore Performance-Modus: UI-Lockdown mit Page-Zones (rechts 2/3 = vor, links 1/5 = zurück)
- Half-Page-Turn: Industriestandard bei forScore, MobileSheets, Newzik — verhindert "Page Jump Schock"
- Newzik LiveScore AI: PDF→interaktiv, aber Genauigkeit bei Blasmusik-Notation variabel
- Konzertmeister: 1-Klick Zu-/Absage ist perfektes UX-Pattern, aber Notenverwaltung ist Datei-Ablage
- Marschpat: Dirigenten-Masterfunktion (zentrales Umblättern) ist essentiell für Blaskapellen
- BAND: Viral-Einladungslink ohne Account = Muster für Aushilfen-Feature

**Kritisch validierte Architekturentscheidung:**
- "Web = Admin / App = Performance" (nach Newzik-Vorbild) sollte für Sheetstorm von Tag 1 gelten
- Offline-First ist bei Blaskapellen Pflicht (Outdoor, schlechtes WLAN in Pfarrsälen)
- Transparente öffentliche Preise (vs. "auf Anfrage") sind Vertrauensfaktor im DACH-Markt

**Anti-Patterns dokumentiert:**
- Zu viele Display-Modi ohne gute Defaults (MobileSheets-Problem)
- Notenverwaltung als Datei-Ablage ohne Struktur (Konzertmeister-Problem)
- Preis nur auf Anfrage (Newzik Ensemble, notabl — erzeugt Misstrauen)
- App-Absturz-Risiko bei Live-Performance → Performance-Tests + Offline-Fallback Pflicht

### 2026-03-28 — Feature-Gap-Analyse v2 + SheetHappens-Vergleich

**Baseline-Update:**
- `docs/feature-gap-analyse.md` auf `spezifikation.md v2` abgeglichen
- 3 Gaps als ✅ resolved markiert: Half-Page-Turn (F-SM-02), Bluetooth-Pedal (F-SM-03), Aushilfen-Zugang (F-SM-06)
- GEMA-Meldung als neuer 🔴-Gap ergänzt — größte verbleibende Lücke
- Dirigenten-Modus Song-Broadcast + Media Links als neue 🟡-Gaps

**SheetHappens-Vergleich (57 Features):**
- 16 ✅ in Sheetstorm-Spec, 11 ⚠️ teilweise, 25 ❌ fehlend, 5 🆕 Sheetstorm-exklusiv
- Wichtigste Erkenntnisse:
  - GEMA-Reporting: gesetzliche Pflicht, SheetHappens hat komplettes Datenmodell
  - Conductor Mode (Song-Broadcast): Killer-Feature für Proben, SheetHappens-Architektur als Referenz
  - Offline-Architektur: nur als Anforderung definiert, nicht architektonisch spezifiziert
  - Server-seitige WebP-Konvertierung: vereinfacht Cross-Platform-Rendering erheblich
- Sheetstorm-Vorteile gegenüber SheetHappens: Auto-Rotation, Auto-Zoom, Schichtplanung, Kalenderansicht, Cloud-Storage-Sync

**PR erstellt:** https://github.com/caol-ila/Sheetstorm/pull/1 — "📊 Anforderungsvergleich: SheetHappens → Sheetstorm"
**Decisions:** `.squad/decisions/inbox/fury-v2-wave2.md`

**Top 10 Empfehlungen (aktueller Stand):**
1. GEMA-Meldung (gesetzliche Pflicht, kein Konkurrent hat es)
2. 1-Klick-Stimmenneuverteilung (Alltags-Workflow)
3. Zweiseitenansicht (kleiner Aufwand, große UX-Wirkung)
4. Chat / Gruppen-Messaging (WhatsApp-Ablösung)
5. Kalender-Sync bidirektional
6. Wiederkehrende Termine
7. Erweiterte Stempel-Bibliothek
8. Media Links (YouTube/Spotify)
9. CSV/Excel-Migrations-Import
10. Dirigenten-Modus Song-Broadcast
