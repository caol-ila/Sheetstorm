# Konkurrenz-UX-Research — Sheetstorm

> **Erstellt:** 2026-03-28  
> **Aktualisiert:** 2026-03-28 (v2 — vollständige Neuerstellung)  
> **Autor:** Fury (Business Analyst)  
> **Quellen:** App Store Beschreibungen, User Guides, YouTube-Tutorials, Support-Dokumentationen, Nutzerbewertungen

---

## Einleitung

Dieses Dokument analysiert die UX der wichtigsten Wettbewerber aus der Perspektive eines Blaskapellen-Musikers. Ziel: Verstehen, was gut funktioniert (übernehmen) und was nervt (vermeiden). Jede Analyse konzentriert sich auf die für Sheetstorm relevanten Flows: Import, Notenanzeige, Annotation, Setlist-Management, Performance-Modus und Ensemble-Koordination.

---

## 1. forScore (iOS/macOS) — Goldstandard Notenanzeige

**Demo/Trial:** https://forscore.co | App Store: $24,99 | User Guide: forscore.co/user-guides/

### 1.1 Kernscreens & Flows

#### Import-Flow
1. Tippen auf das `+`-Symbol in der Bibliothek
2. Quellen-Auswahl: iCloud, Dropbox, Files, direkte URL, Musicnotes-Integration
3. Automatische Metadaten-Vorschau (Titel aus Dateiname)
4. Manuelles Bearbeiten von Titel, Komponist, Genre, Tonart
5. Optional: direkt zu Setlist hinzufügen

**Was gut ist:** Schnell, keine Registrierung, breite Quellen. Der Musicnotes-Import ist nahtlos (kaufen → direkt öffnen in forScore).

**Was nervt:** Kein Batch-Labeling für mehrstückige PDFs. Wenn eine PDF 12 Stücke enthält, muss man 12× manuell aufteilen. Kein AI-gestützte Titelerkennung.

#### Notenanzeige (Reading Mode)
- Vollbild, keine Ablenkung
- Tap rechts → nächste Seite, Tap links → zurück
- Wischgeste ebenfalls möglich
- "Reflow"-Modus: Systeme werden vertikal gestapelt (für kleine Displays)
- Auto-Scroll als Alternative zu manuellen Page-Turns
- Side-by-Side-Modus auf größeren iPads

**Was gut ist:** Extrem sauber. Die Seite füllt den Bildschirm. Keine sichtbaren Controls während des Spielens.

**Was nervt:** Kein Android. Auf iPhone ist die Schrift oft zu klein für echte Performance-Nutzung.

#### Performance-Modus
1. Aktivierung: Doppeltap auf die Seitenmitte ODER Tap auf Grid-Icon → "Performance Mode"
2. Alle UI-Elemente verschwinden
3. Rechts 2/3 des Screens = Forward-Zone (Tap → nächste Seite)
4. Links 1/5 = Backward-Zone
5. Repeat-Links bleiben aktiv (vorher konfiguriert)
6. Exit: Blaues `×` oben rechts

**UX-Insight:** Dieser Modus ist das Herzstück für Live-Auftritte. Der "Page Zone"-Ansatz (verschiedene Bildschirmbereiche = verschiedene Aktionen) ist brillant — erfordert keine genaue Treffsicherheit.

#### Annotation-Flow
1. Stift-Icon antippen (oder Apple Pencil anlegen → sofort aktiv)
2. Toolbar erscheint: Stift, Marker, Highlighter, Text, Stamps, Lineal, Radierer
3. Layers: Verschiedene Ebenen für experimentelle Markierungen
4. Layer ein-/ausblenden
5. Annotationen sind PDF-gebunden, nicht Dateisystem-gebunden

**Was gut ist:** Apple Pencil-Integration ist die beste am Markt. Stift anlegen = sofort Annotieren, kein Menü-Umweg. Undo/Redo. Export als annotiertes PDF möglich.

**Was nervt:** Layers sind "neutral" — keine semantischen Ebenen (kein "Dirigenten-Layer" vs. "Musiker-Layer"). Keine Echtzeit-Sync der Annotationen im Ensemble. Alle Annotationen privat und lokal.

#### Setlist-Management
- Setlist erstellen → Stücke per Drag & Drop ordnen
- Swipe zum Löschen
- Nahtloser Übergang zwischen Stücken (letztes System von Stück 1 + erstes System von Stück 2)
- Metronom, Tuner, Pitch Pipe pro Setlist konfigurierbar

**Was gut ist:** Der "seamless transition"-Effekt beim Stückwechsel ist einzigartig — kein Umblättern, keine Pause.

**Was nervt:** Keine Gruppen-Setlists (kein "diese Setlist für alle Musiker der Kapelle").

---

### 1.2 UX-Bewertung forScore

| Dimension | Note | Kommentar |
|-----------|------|-----------|
| Notenanzeige | ★★★★★ | Bester Viewer am Markt |
| Import-Flow | ★★★★☆ | Gut, aber kein AI/Batch-Labeling |
| Annotation | ★★★★★ | Apple Pencil-Integration unübertroffen |
| Performance-Modus | ★★★★★ | Industriestandard |
| Setlist | ★★★★☆ | Smooth, aber kein Gruppen-Sharing |
| Ensemble-Features | ★★☆☆☆ | Kaum vorhanden |
| Lernkurve | ★★★★☆ | Für neue User etwas viel |

**Lessons Learned von forScore:**
- ✅ Performance-Modus mit vollständigem UI-Lockdown ist Pflicht
- ✅ Page-Zone-Konzept (Bildschirmregionen = Aktionen) übernehmen
- ✅ Stylus/Pencil = sofort annotieren (kein Menü)
- ✅ Layers für Annotationen sind sinnvoll
- ✅ Seamless Transition zwischen Setlist-Stücken
- ✅ Reflow-Modus für kleine Bildschirme (Innovation für mobile)

---

## 2. MobileSheets (Android/Windows/iOS) — Der Cross-Platform Pragmatiker

**Demo:** Gratis Trial-Version (5 Songs limit) | zubersoft.com | Quick Guide: PDF verfügbar

### 2.1 Kernscreens & Flows

#### Import-Flow
1. Menü → "Import" oder "Batch Import"
2. Quellen: Lokaler Speicher, Dropbox, Google Drive, OneDrive, PC via Companion App
3. Metadaten-Bearbeitung bei jedem Import
4. Batch-Import: Ordner auswählen → alle Dateien importieren → Metadaten-Regeln setzen
5. CSV-Import für Bibliotheken (Power-User-Feature)

**Was gut ist:** Batch-Import über CSV ist für große Bibliotheken sehr mächtig. PC-Companion-App ist clever für Desktop-Bibliotheksverwaltung.

**Was nervt:** UI beim Import ist informationsdicht und für Nicht-Power-User erschlagend. Keine AI-Hilfe bei Titelerkennung.

#### Notenanzeige
- Horizontal/Vertikal Scroll wählbar
- Half-Page-Turn: Implementiert! Untere Hälfte der nächsten Seite sichtbar
- Two-Page (Book Mode): Zwei Seiten nebeneinander
- Auto-Crop: Ränder automatisch abschneiden
- Auto-Scroll mit konfigurierbarer Geschwindigkeit
- Gesichtserkennung für Page-Turn (Android, hands-free)

**Was gut ist:** Half-Page-Turn ist eine der besten Implementierungen. Auto-Crop ist wertvoll für schlecht gescannte Noten.

**Was nervt:** Die schiere Anzahl an Display-Modi macht die Konfiguration schwierig. Zu viele Optionen ohne gute Defaults.

#### Annotation-Flow
1. Annotation-Icon tippen → Toolbar erscheint
2. Stift, Highlighter, Text, Shapes, Stamps, Layers
3. Multiple Annotation-Ebenen (aber ohne semantische Bedeutung)
4. Export des annotierten PDFs

**Was nervt:** Annotation-UI ist funktional aber nicht elegant. Stylus-Erkennung nicht so präzise wie forScore auf Apple-Geräten.

#### Setlist-Management
1. "Setlists"-Tab → "+" → Name eingeben
2. Split-Screen: Links Library, Rechts Setlist
3. Songs per Tap hinzufügen, per Drag & Drop ordnen
4. Export: Setlist-File (Referenzen) oder mit allen Noten

**Was gut ist:** Split-Screen für Setlist-Building ist sehr praktisch — man sieht Library und Setlist gleichzeitig.

**Was nervt:** Keine Gruppen-Setlists, kein Zuweisen an Kapellen-Mitglieder.

#### Ensemble-Sync
- WiFi-Sync: Mehrere Tablets im lokalen Netz verbinden → synchronisiertes Umblättern
- Bluetooth-Sync ebenfalls möglich
- Kein Cloud-Sync in Echtzeit

**Was gut ist:** WiFi-Sync zwischen Tablets ist ein solides Ensemble-Feature.

**Was nervt:** Jedes Gerät muss separat konfiguriert werden. Kein zentrales "Kapellen-Management" — es ist Peer-to-Peer.

---

### 2.2 UX-Bewertung MobileSheets

| Dimension | Note | Kommentar |
|-----------|------|-----------|
| Notenanzeige | ★★★★☆ | Half-Page-Turn top, UI etwas überladen |
| Import-Flow | ★★★★☆ | Mächtig, aber komplex |
| Annotation | ★★★☆☆ | Funktional, nicht elegant |
| Performance-Modus | ★★★★☆ | Vorhanden, nicht so poliert wie forScore |
| Setlist | ★★★★☆ | Split-Screen-Builder ist gut |
| Ensemble-Features | ★★★☆☆ | Peer-to-Peer WiFi-Sync |
| Lernkurve | ★★☆☆☆ | Sehr steil für neue Nutzer |

**Lessons Learned von MobileSheets:**
- ✅ Half-Page-Turn implementieren (forScore + MobileSheets = Industriestandard)
- ✅ Auto-Crop für schlecht gescannte PDFs
- ✅ Split-Screen für Setlist-Building
- ✅ Auto-Scroll als Alternative zu manuellen Page-Turns
- ⚠️ Nicht zu viele Display-Modi anbieten — gute Defaults setzen

---

## 3. Newzik (iOS/Web) — Der Ensemble-Innovator

**Demo:** Web-App kostenlos testbar (3 Scores) | newzik.com | Support: support.newzik.com

### 3.1 Kernscreens & Flows

#### Onboarding
1. Account-Registrierung (E-Mail oder Apple/Google)
2. Geführte Tour: "Importiere dein erstes Stück"
3. Bibliothek-View direkt nach Onboarding sichtbar
4. "+" Floating-Button prominent in jeder Hauptansicht

**Was gut ist:** Onboarding ist guided und nicht überfordernd. Sofortige Bibliotheks-Ansicht gibt Orientierung.

#### Import-Flow
1. Tap auf "+" → Quellen-Auswahl
2. Quellen: Gerät, iCloud, Dropbox, Google Drive, Scanner (Kamera), IMSLP (Public Domain)
3. PDF oder MusicXML auswählen
4. Titel + Metadaten eingeben
5. Optional: Als "Piece" kombinieren (Stück = mehrere Parts)
6. Optional: Direkt zu Setlist hinzufügen

**Was gut ist:** IMSLP-Integration ist brillant — man kann direkt aus dem größten Public-Domain-Archiv importieren. Kamera-Scanner direkt aus der App.

**Was nervt:** Kein Batch-Labeling (mehrere Stücke in einer PDF trennen). Kein AI-gestützte Titelerkennung. Für große Bibliotheken mühsam.

#### LiveScore AI (Kern-Differenzierer)
1. PDF hochladen → "Convert to LiveScore"
2. AI verarbeitet (Wartezeit je nach Länge)
3. Ergebnis: Interaktive, spielbare Partitur
4. Features: Playback, Transposition, Cursorfunktion (folgt der Musik), MIDI-Export
5. Sektions-Navigation (direkt zu Takt X springen)

**Was gut ist:** Das ist die Zukunft des Notenlesens. Transposition in Echtzeit ohne Neudruck. Cursor der der Musik folgt = Lehrer-Tool.

**Was nervt:** Genauigkeit variiert stark (handgeschriebene Noten, schlechte Scans). Blasmusik-spezifische Notationen (Trios, Marsch-Strukturen) werden nicht immer korrekt erkannt. Erfordert Internet-Verbindung.

#### Echtzeit-Kollaboration
1. Projekt erstellen → Mitglieder einladen (E-Mail oder Link)
2. Annotationen werden in Echtzeit synchronisiert
3. Admin kann Noten-Versionen pushen (alle sehen sofort das Update)
4. Permissions: Wer darf was sehen/editieren

**Was gut ist:** Real-time Annotation Sync ist einzigartig. Wenn der Dirigent etwas markiert, sehen alle Musiker es sofort.

**Was nervt:** Nur 2 Ebenen (Privat/Geteilt) — keine stimmen-spezifischen Annotationen. Ensemble-Preise intransparent.

#### Setlist-Management
- Setlists erstellen, ordnen per Drag & Drop
- Stücke aus Bibliothek hinzufügen
- Setlist mit Ensemble teilen (alle sehen dieselbe Reihenfolge)
- Nahtloser Wechsel zwischen Stücken

**Was gut ist:** Ensemble-Setlist-Sharing ist das Missing Link, das forScore fehlt.

---

### 3.2 UX-Bewertung Newzik

| Dimension | Note | Kommentar |
|-----------|------|-----------|
| Notenanzeige | ★★★★☆ | Sehr gut, LiveScore ist Zukunft |
| Import-Flow | ★★★★☆ | IMSLP-Integration excellent |
| Annotation | ★★★★☆ | Echtzeit-Sync ist Game-Changer |
| Performance-Modus | ★★★★☆ | Half-Page-Turn + Face-Gesture vorhanden |
| Setlist | ★★★★★ | Ensemble-Sharing ist Top |
| Ensemble-Features | ★★★★★ | Bester am Markt |
| Lernkurve | ★★★☆☆ | Moderate Kurve, gut erklärt |

**Lessons Learned von Newzik:**
- ✅ Web = Admin/Verwaltung; App = Performance (Architektur-Prinzip)
- ✅ IMSLP-Integration (Public Domain direkt importieren)
- ✅ Echtzeit Annotation-Sync im Ensemble
- ✅ Ensemble-Setlist-Sharing
- ✅ AI-Konvertierung als Premium-Feature positionieren
- ⚠️ Intransparente Preise für Ensembles erzeugen Misstrauen → Sheetstorm sollte klar kommunizieren

---

## 4. Konzertmeister (iOS/Android/Web) — Der Vereins-Champion

**Demo:** 30-Tage-Test kostenlos | konzertmeister.app | YouTube: @konzertmeister9730

### 4.1 Kernscreens & Flows

#### Hauptnavigation
- Bottom-Navigation: Termine / Nachrichten / Mitglieder / Noten / Einstellungen
- Terminliste als Startscreen (chronologisch, mit Status: offen/zugesagt/abgesagt)
- Push-Badge zeigt offene Einladungen

**Was gut ist:** Der Terminus-fokussierte Startscreen ist richtig für Blaskapellen — das Nächste Ereignis ist immer der wichtigste Context.

#### Termin-Flow (Kern-Use-Case)
1. Admin erstellt Termin: Datum, Zeit, Ort, Typ (Probe/Konzert/Fest)
2. Stücke können dem Termin als Setlist zugeordnet werden
3. Musiker erhalten Push-Notification
4. Mitglieder tippen: ✓ Zusagen / ✗ Absagen / ? Vielleicht
5. Admin sieht in Echtzeit: Wer kommt, wer nicht
6. Kommentarfeld für Sonderinfos (z.B. Dresscode)

**Was gut ist:** Das 1-Klick Zu-/Absage-System ist das Herzstück und perfekt gelöst. Einfacher als WhatsApp-Polls, strukturierter als E-Mail.

**Was nervt:** Beim Absagen gibt es keine automatische "Wer könnte einspringen?"-Logik. Das ist eine verpasste Chance.

#### Notenverwaltung (Schwäche des Systems)
- Noten als Dateien hochladen (PDF, Bilder)
- Stücken Terminen zuweisen
- Kein professioneller PDF-Viewer
- Metadaten nachträglich schwierig editierbar
- Kein Stimmen-Mapping

**Was nervt:** Die Notenverwaltung ist eine offensichtliche Schwachstelle. Noten werden als Dateien verwaltet, nicht als strukturierte Musikstücke mit Stimmen. Das ist Konzertmeisters größte Lücke — und Sheetstorms Chance.

#### Mitglieder & Register
1. Mitglied anlegen → Instrument → Register zuweisen
2. Register = Gruppe von Musikern desselben Instruments
3. Chat-Funktionen nach Register
4. Rollen: Admin, Dirigent, Registerführer, Mitglied

**Was gut ist:** Register-Konzept ist gut und kompatibel mit Blaskapellen-Struktur. Registerführer-Rolle ist realistisch.

**Was nervt:** Kein automatisches Stimmen-Mapping basierend auf Register. Kein "wenn Musiker X absagt, diese Stimme neu zuweisen"-Feature.

---

### 4.2 UX-Bewertung Konzertmeister

| Dimension | Note | Kommentar |
|-----------|------|-----------|
| Terminverwaltung | ★★★★★ | Bester am Markt |
| Zu-/Absage-System | ★★★★★ | Perfekt gelöst |
| Kommunikation | ★★★★☆ | Chat + Push sehr gut |
| Notenverwaltung | ★★☆☆☆ | Datei-Ablage, kein echter Viewer |
| Notenanzeige | ★☆☆☆☆ | Nicht vorhanden als Feature |
| Mitgliederverwaltung | ★★★★☆ | Register-Konzept gut |
| Lernkurve | ★★★★☆ | Sehr intuitiv |

**Lessons Learned von Konzertmeister:**
- ✅ Termin-fokussierter Startscreen für Blaskapellen
- ✅ 1-Klick Zu-/Absage ist Pflicht
- ✅ Register-Konzept (Gruppen nach Instrument)
- ✅ Push-Notifications für Termine
- ✅ Kalender-Export (ICS)
- ⚠️ Notenverwaltung als Datei-Ablage ist nicht ausreichend — Sheetstorm muss hier 5× besser sein

---

## 5. Marschpat (iOS/Android/Web/E-Reader) — Der Blasmusik-Spezialist

**Demo:** Freemium (5 Noten kostenlos) | marschpat.com | App Store verfügbar

### 5.1 Kernscreens & Flows

#### Digitale Notenmappe
1. Notenbuch erstellen (= Mappe mit mehreren Stücken)
2. Stücke aus Verlagsbibliothek (500+) oder eigene PDFs hinzufügen
3. Stimme auswählen (z.B. "2. Klarinette Bb")
4. Offline-Sync für alle Noten des Notenbuchs

**Was gut ist:** Das Notenbuch-Konzept ist für Blaskapellen intuitiv — es entspricht dem physischen Marschbuch. Verlagsbibliothek spart Zeit beim Einpflegen.

**Was nervt:** Keine automatische Stimmen-Fallback-Logik. Kein AI-Upload.

#### Dirigenten-Masterfunktion
1. Dirigent wählt "Mastermodus"
2. Dirigent blättert um → alle Musiker sehen dasselbe
3. Synchronisierung über WiFi oder Internet

**Was gut ist:** Diese Funktion ist für Blaskapellen essential und einzigartig unter den Wettbewerbern.

**Was nervt:** Erfordert stabile Internetverbindung oder lokales WiFi — bei Outdoor-Auftritten problematisch.

#### E-Reader-Integration
- Spezielle PocketBook-Geräte unterstützt
- E-Ink-Display: Kein Blenden in der Sonne
- Offline-Synchronisation der Noten

**Was gut ist:** E-Reader für Outdoor/Marsch ist eine intelligente Hardware-Strategie. Sonne = Problem für Tablets.

**Was nervt:** Hardware-Kauf erforderlich (Zusatzkosten). App-Funktionalität auf E-Readern eingeschränkt.

---

### 5.2 UX-Bewertung Marschpat

| Dimension | Note | Kommentar |
|-----------|------|-----------|
| Blasmusik-Fokus | ★★★★★ | Verständnis der Zielgruppe |
| Notenanzeige | ★★★☆☆ | Funktional, nicht elegant |
| Stimmen-Management | ★★★☆☆ | Vorhanden, ohne Fallback-Logik |
| Dirigenten-Sync | ★★★★☆ | Gut, aber WiFi-abhängig |
| E-Reader-Integration | ★★★★☆ | Innovativ für Outdoor |
| Annotation | ★★☆☆☆ | Sehr begrenzt |
| Vereinsverwaltung | ★★☆☆☆ | Rudimentär |

**Lessons Learned von Marschpat:**
- ✅ Notenbuch-Konzept (physische Mappe = digitale Metapher) ist intuitiv
- ✅ Dirigenten-Masterfunktion als Sync-Methode
- ✅ Offline-First für Outdoor-Auftritte
- ✅ Stimmen-Auswahl als Kernfeature
- ⚠️ E-Reader-Strategie: Sheetstorm sollte auf Tablet-Displays + hohe Helligkeit setzen

---

## 6. BAND App — Der Kommunikations-Champion

**Demo:** Kostenlos | band.us

### 6.1 UX-Flow

#### Gruppen-Management
- Schnelle Gruppe erstellen (30 Sekunden)
- Mitglieder per Link einladen (ohne Registrierung möglich)
- Separate "Subgruppen" für Register
- Admin-Controls: Posting-Regeln, Moderations-Level

**Was gut ist:** Der virale Einladungs-Link (kein Account erforderlich für Empfänger) ist ein UX-Muster, das Sheetstorm für Aushilfen übernehmen sollte.

#### Kalender & Events
1. Event erstellen: Datum, Zeit, Ort
2. RSVP mit "Going / Not Going / Maybe"
3. Push-Benachrichtigung an alle Mitglieder
4. Event-Kommentare, Datei-Anhänge

**Was gut ist:** Sehr niedrige Schwelle. Auch technisch-unerfahrene Blasmusiker verstehen es sofort.

**Was nervt:** Keine Struktur für Musikvereine (kein Register-System, keine Stimmenzuweisung). Kein DSGVO-konformer Betrieb nach EU-Standard.

---

## 7. notabl (iOS/Android/Web) — Der Aufsteiger

**Info:** notabl.de | Kostenlos für Mitglieder

### 7.1 UX-Flow

#### Digitale Konzertmappe
1. Konzert erstellen + Stücke hinzufügen
2. Stücke mit Stimmen versehen
3. Musiker sehen automatisch "ihre" Stimme in der Konzertmappe
4. 1-Klick Stimmenneuverteilung wenn Musiker absagt

**Was gut ist:** Das "Konzertmappe"-Konzept ist für Blaskapellen-Dirigenten perfekt verständlich. Der 1-Klick-Ersatz bei Absagen ist brillant.

**Was nervt:** Keine erweiterten Annotationen. Keine AI-Features. UI wirkt nicht ausgereift.

---

## 8. Synthese: Lessons Learned

### 8.1 UX-Patterns die Sheetstorm übernehmen MUSS

| Pattern | Quelle | Begründung | Priorität |
|---------|--------|-----------|-----------|
| **Performance-Modus mit vollständigem UI-Lockdown** | forScore | Standard bei Professionals — ohne das ist Sheetstorm nicht bühnentauglich | P0 |
| **Half-Page-Turn** | forScore, MobileSheets, Newzik | #1 Feature-Request bei Notenlese-Apps. Verhindert "Page Jump Schock" | P0 |
| **Bluetooth-Pedal-Support** | forScore, MobileSheets | Blasmusiker haben beide Hände besetzt — ohne Pedal ist die App im Konzert nicht nutzbar | P0 |
| **1-Klick Zu-/Absage** | Konzertmeister | Herzstück der Vereinsorganisation. Einfacher als WhatsApp, strukturierter als E-Mail | P0 |
| **Stylus-First Annotation** | forScore | Stift anlegen = sofort annotieren, kein Menü. Für Probe essentiell | P0 |
| **Register-Konzept** | Konzertmeister | Blaskapellen denken in Registern (Holz/Blech/Schlagwerk) | P0 |
| **Dirigenten-Masterfunktion** | Marschpat | Zentrales Umblättern für Marsch/Outdoor-Auftritte | P1 |
| **Ensemble-Setlist-Sharing** | Newzik | Dirigent definiert Setlist → alle sehen sie | P1 |
| **Einladungslink ohne Registrierung** | BAND App | Aushilfen brauchen Zugang ohne Account-Zwang | P1 |
| **Web = Admin / App = Performance** | Newzik | Notenwart verwaltet am PC, Musiker spielt am Tablet | P1 |
| **Split-Screen Setlist-Builder** | MobileSheets | Library links + Setlist rechts = effizient | P2 |
| **Auto-Crop für PDFs** | MobileSheets | Ränder bei schlecht gescannten Noten entfernen | P2 |
| **IMSLP-Integration** | Newzik | Kostenlosen Noten-Pool direkt zugänglich machen | P3 |

### 8.2 Anti-Patterns — Was Sheetstorm NICHT tun darf

| Anti-Pattern | Wo gesehen | Warum problematisch |
|-------------|-----------|---------------------|
| **Zu viele Display-Modi ohne gute Defaults** | MobileSheets | Überfordert neue Nutzer. Lösung: Sinnvolle Defaults, erweiterte Optionen versteckt |
| **Notenverwaltung als reine Datei-Ablage** | Konzertmeister | Noten sind strukturierte Musikstücke mit Stimmen — keine Ordner-Dateien |
| **Preis nur auf Anfrage** | Newzik Ensemble, notabl | Erzeugt Misstrauen. Sheetstorm: Klare, öffentliche Preise |
| **iOS-Only** | forScore, OnSong | In Blaskapellen werden auch Android-Geräte genutzt |
| **Kein Offline-Modus** | Cloud-first Apps | Bei Outdoor-Auftritten ist kein WLAN vorhanden |
| **Annotationen ohne semantische Ebenen** | forScore, MobileSheets | Nur "Layer 1/2/3" macht für Dirigenten keinen Sinn |
| **Metadaten nachträglich schwer editierbar** | Konzertmeister | Frustrations-Quelle Nr. 1 laut Nutzerbewertungen |
| **Steep Learning Curve ohne Onboarding** | MobileSheets | Neue Blasmusiker (oft 50+) brauchen geführtes Onboarding |
| **Sync-Abhängigkeit von stabilem Internet** | Newzik, Marschpat Dirigent | Live-Performance braucht Offline-Fallback |
| **App-Absturz während Performance** | Allgemein beklagtes Problem | Perftest + Offline-first = Vertrauen aufbauen |

---

## 9. UX-Designprinzipien für Sheetstorm (abgeleitet)

### 9.1 Für die Notenanzeige

> **Prinzip: "Das Notenblatt ist König"**
> 
> Im Performance-Modus existiert keine UI. Nur Noten. Kein Logo, kein Status, keine Notifications. Das Notenblatt füllt den Bildschirm — horizontal ausgerichtet, mit Auto-Zoom auf maximale Lesbarkeit.

### 9.2 Für den Import

> **Prinzip: "Ein Bild, ein Stück — oder ein Klick mehr"**  
>
> Standard-Import: Jede Datei = ein Stück. Wenn der Nutzer mehrere Stücke in einer Datei hat, startet der Labeling-Flow — visuell, mit Thumbnails aller Seiten, und AI-Vorschlägen für Stücktrennung und Titelerkennung.

### 9.3 Für Annotationen

> **Prinzip: "Drei Hüte, eine Seite"**  
>
> Jede Annotation gehört zu einer Ebene: Mein Hut (privat), Stimmen-Hut (alle 2. Klarinetten sehen das), Dirigenten-Hut (alle sehen das). Die Ebene ist beim Annotieren wählbar — die visuelle Unterscheidung ist klar (z.B. Farbe: Blau = Privat, Grün = Stimme, Rot = Orchester).

### 9.4 Für Vereinsverwaltung

> **Prinzip: "Ein Klick bis zur Antwort"**  
>
> Probe nächste Woche? Musiker öffnet App → sieht sofort die offene Einladung → tippt ✓ oder ✗. Fertig. Kein Navigieren, kein Suchen.

### 9.5 Für Stimmen-Management

> **Prinzip: "Die richtige Note, automatisch"**  
>
> Musiker konfiguriert einmal sein Standardinstrument (z.B. "2. Klarinette"). Bei jedem Stück erscheint sofort die richtige Stimme. Wenn sie fehlt: automatisch die nächste passende Stimme (Fallback). Kein manuelles Suchen.

---

## 10. Priorisierte UX-Empfehlungen nach Meilenstein

### Meilenstein 1 (MVP)
- [ ] Performance-Modus (UI-Lockdown, Page-Zones)
- [ ] Half-Page-Turn
- [ ] Drei-Ebenen-Annotationen (Privat/Stimme/Orchester)
- [ ] Stylus-First-Annotation (Stift anlegen = sofort aktiv)
- [ ] 1-Klick Zu-/Absage für Termine
- [ ] Stimmen-Auswahl + automatische Vorauswahl basierend auf Instrumentenprofil
- [ ] Geführtes Onboarding (5-Minuten bis erste Note angezeigt)
- [ ] Offline-Unterstützung für heruntergeladene Noten

### Meilenstein 2
- [ ] Bluetooth-Pedal-Support
- [ ] Ensemble-Setlist-Sharing (Dirigent definiert, alle sehen)
- [ ] Dirigenten-Masterfunktion (zentrales Umblättern)
- [ ] Aushilfen-Link ohne Registrierung
- [ ] Auto-Crop für schlecht gescannte PDFs
- [ ] Split-Screen Setlist-Builder (Web)

### Meilenstein 3+
- [ ] AI-Upload mit Labeling-Flow
- [ ] BYOK für AI-Dienste
- [ ] IMSLP-Integration
- [ ] Echtzeit-Annotationssync im Ensemble
- [ ] Echtzeit-Metronom-Sync

---

*Dokument fertiggestellt. Nächster Schritt: Wanda (UX Designer) nutzt diese Erkenntnisse für Wireframes.*
