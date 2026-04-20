# Marktanalyse: Noten- & Vereinsverwaltung für Blaskapellen

> **Stand:** April 2026
> **Zweck:** Grundlage für Sheetstorm-Roadmap und MVP-Scope
> **Methodik:** Desk-Research via Hersteller-Webseiten, App-Store-Listings und öffentliche Vergleiche. Wo Informationen nicht verifizierbar waren, ist dies explizit ausgewiesen („nicht verifiziert").

---

## 1. Executive Summary

Der Markt für Musiker-Software zerfällt heute sauber in zwei **disjunkte Welten**:

1. **Digitale Notenständer** (forScore, MobileSheetsPro, Newzik, Piascore, OnSong) — technisch reif, iPad-zentriert, aber **primär Einzelplatz-Werkzeuge**. Collaboration beschränkt sich auf Library-Sync oder das Weiterreichen von PDFs. Kein Produkt kennt das Konzept „Verein + Register + Stimme" nativ.
2. **Vereins-/Probenverwaltung** (Konzertmeister, BandHelper, Muzodo, Groupanizer) — organisatorisch stark (Zu-/Absagen, Termine, Mitgliederverwaltung), aber bei Noten auf **Dateianhänge oder leichte Setlist-Verwaltung** beschränkt. Konzertmeister ist in DACH-Blasmusik de facto Marktführer für Organisation, liefert aber keinen digitalen Notenständer.

**Die zentrale Marktlücke:** Es gibt kein Produkt, das die **Stimmenverteilung einer Blaskapelle** (Flügelhorn 1, Tenorhorn 2, Posaune 3, …) als First-Class-Konzept modelliert und sie an den digitalen Notenständer jedes einzelnen Musikers ausliefert — mit Offline-Fähigkeit, Rollen, Archivpflege und Probenplanung in **einem** System.

**Empfehlung für Sheetstorm:** Ansetzen am **Zusammenspiel** der beiden Welten — konkret: das **Verein → Stück → Stimme → Musiker → Gerät**-Modell als Kern, nicht der Annotation-Editor (dort ist forScore uneinholbar) und nicht die Termin-Umfrage (dort ist Konzertmeister uneinholbar). Der USP ist die **kuratierte, register-basierte Stimmenverteilung mit Offline-Auslieferung** an iPad/Android/Web. Alles andere (Annotation, Pedal-Umblättern, Setlist) muss nur „gut genug" sein, um als Ersatz für forScore zu taugen, muss aber nicht besser sein.

---

## 2. Marktübersicht Notenverwaltung

### 2.1 Produkt-Matrix

| Produkt | Plattformen | Preis (Stand 04/2026) | Zielgruppe | Stärken | Schwächen |
|---|---|---|---|---|---|
| **forScore** | iOS, iPadOS, macOS, visionOS | Einmalkauf 24,99 USD + optional „forScore Pro" 14,99 USD/Jahr | Klassik/Solisten auf iPad, Profi-Musiker | Reifste Annotation-UX (Apple Pencil), schnelle Seitenwechsel, iCloud-Sync, riesiges Ökosystem (Pedale, MIDI) | Nur Apple, kein Ensemble-Modell, kein Register-/Stimmenkonzept |
| **MobileSheetsPro** | Android, iOS, Windows, e-Ink (BOOX) | Einmalkauf ~14–20 EUR pro Gerät (je Store) | Plattformübergreifende Vielfalt, Orchester mit gemischten Geräten | Einzige ernstzunehmende Cross-Platform-Lösung, Library-Sync, Tablet-Paar-Modus (Bookmode), MIDI, Pedal | UI weniger poliert als forScore, Sync via WiFi/Cloud ist fummelig, keine Ensemble-Features auf Server-Seite |
| **Newzik** | iOS, iPadOS, Web | Abo: Essentials ~6–8 EUR/Monat, Premium ~12–15 EUR/Monat, Lifetime einmalig (nicht verifiziert) | Orchester, Institutionen, Ensembles | **LiveScore** (PDF→MusicXML per OMR), Transposition, MIDI-Playback, **Collaborative Projects** (echte Team-Bibliothek), Web-App | Abomodell, iOS-only für mobiles Spielen, LiveScore-Qualität nicht verifiziert |
| **Piascore** | iOS, iPadOS | Kern-App kostenlos, In-App-Käufe für Features (nicht verifiziert) | Japan-fokussiert, Solisten | Kostenlos-Einstieg, Pedal-Support, Roland-Digitalpiano-Integration | Schwache Dokumentation außerhalb Japans, keine Ensemble-Features |
| **OnSong** | iOS | Abo (nicht verifiziert, Website-Fehler zum Zeitpunkt der Recherche) | Bands, ChordPro-Nutzer (Rock/Pop/Kirche) | ChordPro-first, Live-Transposition, Setlist-Teilen | Für Blasmusik kaum relevant (kein PDF-Fokus, keine Stimmensätze) |
| **Notion Mobile / Notateme** | iOS, iPadOS, Android | Freemium + Abo | Komponisten, Notation-Editoren | Notation erstellen, nicht nur anzeigen | Kein Digital-Music-Stand-Fokus |
| **Henle Library App** | iOS, Android | Freemium; pro Werk ca. 2–20 EUR Kauf, inkl. digitaler Edition | Klassik-Solisten | Verlagsgeprüfte Urtext-Editionen | Kein Blasmusikrepertoire, kein Ensemble-Modus |
| **nkoda** | iOS, Android, Web | Abo ~10–15 EUR/Monat privat, Institutionslizenzen | Institutionen, Studierende | 100k+ Titel lizenziert von Bärenreiter, Boosey, Ricordi etc. | Abo-Bibliothek (keine eigenen Scans), Blasmusik schwach vertreten |
| **Konzertmeister** (Notenteil) | iOS, Android, Web | siehe Vereinsverwaltung | Blasmusik/Chöre in DACH | Stücke und Setlists an Termine hängbar, gespielte Stücke protokollierbar | Kein vollwertiger Notenständer (keine Annotation, kein Pedal), PDFs nur als Anhang |

### 2.2 Tiefenanalyse je Produkt

#### forScore
- **Kern-Features:** PDF-Anzeige, Apple-Pencil-Annotation (ohne Modus-Wechsel), Setlists, Metadaten-Bibliothek („Dynamic Library", keine Ordner), Bookmarks, Reflow für iPhone, Multi-Window, Metronom, Stimmgerät, Klaviertastatur, MIDI.
- **Workflows:**
  - *Import:* PDF aus Mail/Safari teilen → forScore → Metadaten vergeben → iCloud-Sync.
  - *Annotation:* Pencil auf Seite → Stift-Auswahl aus HUD → Layer (z. B. „meine Notizen" vs. „Stimme") getrennt ein-/ausblendbar.
  - *Setlist:* Stücke drag-and-droppen, in Reihenfolge abspielen.
  - *Seitenumblättern:* Tap links/rechts, Bluetooth-Pedal, MIDI-Commands, oder „Cue" aus verlinktem Audio-Track (forScore merkt sich, wann geblättert wird, und kann's wiederholen).
- **Datenmodell:** PDF-only, Metadaten in SQLite lokal + iCloud-Sync. MusicXML wird nicht konsumiert.
- **Collaboration:** Ad-hoc „Cue"-Remote-Control zwischen nahen Geräten (WLAN) für synchrones Umblättern. Echte Team-Library gibt es **nicht**.
- **Offline:** Vollständig offline nach Download.
- **Preis:** 24,99 USD einmalig (ca. 23 EUR) + optional Pro-Abo 14,99 USD/Jahr (Zusatzfeatures, Cloud-Quota).

#### MobileSheetsPro
- **Kern-Features:** PDF/Bild/TXT/ChordPro, mehrere Display-Modi (horizontal scroll, vertical scroll, half-page, two-up), Annotation mit Stylus, Setlists, Audio-Playback mit Loop, Pedal-Support, **Tablet-Paar-Modus** (Leader steuert bis zu 7 Follower via BT/WiFi).
- **Workflows:**
  - *Import:* Integrierter Cloud-Browser (Dropbox, GDrive, OneDrive) oder Standard-File-Picker.
  - *Sync:* **Library-Synchronisation** zwischen Geräten via WiFi oder Cloud-Ordner. Wählbar, welche Felder synchron sein sollen (so kann jeder seine eigenen Annotationen behalten, aber die gleichen PDFs bekommen).
  - *Bookmode:* Zwei Tablets nebeneinander = ein großer Notenständer. Seite 1+2, dann Tap → Seite 3+4 (oder alternierend).
- **Datenmodell:** PDF/Bild/ChordPro. Metadaten lokal (SQLite). Export als gepackte Datei inkl. Annotationen.
- **Collaboration:** Tablet-Paar (Leader/Follower), Library-Sync über gemeinsamen Cloud-Ordner. Kein zentraler Server, keine Rollen, keine Rechte.
- **Offline:** Ja, vollständig.
- **Preis:** Einmalkauf pro Store (iOS-Version in Apple-Familie teilbar, Android/Windows pro Lizenzkey/Gerät). Größenordnung 14–20 EUR.

#### Newzik
- **Kern-Features:** PDF-Anzeige + **LiveScore** (OMR-Konvertierung PDF → interaktive/MusicXML-ähnliche Partitur), Transposition, MIDI-Begleitung, Section-Navigation, **Collaborative Projects** (geteilte Bibliotheken mit mehreren Musikern), Gesichtserkennung zum Umblättern (Premium).
- **Workflows:**
  - *LiveScore:* PDF hochladen → Cloud-OMR → bearbeitbare, transponierbare Partitur.
  - *Collaboration:* Projekt anlegen, Musiker einladen, Partituren + Annotations teilen.
- **Datenmodell:** PDF + (intern) LiveScore/MusicXML. Export MusicXML/MIDI in höheren Tiers.
- **Collaboration:** **Echte Team-Bibliothek** — einer der wenigen Player mit diesem Feature.
- **Offline:** Ja, nach Download. Grund-Bibliothek in Essentials auf 1000 Stücke begrenzt.
- **Preis:** Abo-Staffel Essentials / Premium / Lifetime. Essentials ~6–8 EUR/Monat, Premium ~12–15 EUR/Monat (nicht exakt verifiziert).

#### Piascore
- **Kern-Features:** PDF-Anzeige, Pedal-Support, Kamera-Gesten zum Umblättern, Metronom, Tuner.
- **Workflows:** Standard Import → Anzeige → Annotation.
- **Datenmodell:** PDF.
- **Collaboration:** Keine verifiziert.
- **Offline:** Ja.
- **Preis:** Kostenlose Basis-App; diverse In-App-Käufe (nicht verifiziert).

#### OnSong
- **Kern-Features:** ChordPro-first, Transposition, Audio/Backing Tracks, Setlist-Sharing.
- **Zielgruppe:** Pop-/Rock-/Worship-Bands, **nicht** primär Blasmusik.
- **Relevanz für Blasmusik:** Gering. ChordPro ist für Melodie+Akkord optimiert, Stimmenauszüge einer Blaskapelle passen nicht ins Modell.

### 2.3 Gemeinsame Ablauf-Muster (Notenverwaltung)

Aus den Top-4 Produkten ergeben sich wiederkehrende Workflows, die Sheetstorm als **Hygiene-Standard** erfüllen muss:

1. **Import:** PDF per Share-Extension, Cloud-Browser, oder File-Picker. Bulk-Import mehrerer Dateien. Automatische Metadaten (Titel aus Dateiname).
2. **Metadaten-Pflege:** Titel, Komponist, Genre, Tonart, Tempo, Tags, benutzerdefinierte Felder. **Keine Ordner**, stattdessen Filter/Smart-Lists.
3. **Anzeige:** Vollbild, Crop/Margin-Trimming, 2-Seiten-Modus, Vertical-Scroll, Half-Page-Turn in Portrait.
4. **Annotation:** Stift + Marker + Text + Stempel auf Layern. Layer ein-/ausblendbar. Apple Pencil ohne Modus-Wechsel ist Premium-Standard.
5. **Setlist:** Stücke in Reihenfolge bringen, durchblättern, während Auftritt nicht unterbrechbar.
6. **Seite umblättern:** Tap, BT-Pedal (AirTurn, PageFlip), MIDI-Trigger, Gesten (Blink/Kopfbewegung in Premium-Abo).
7. **Sync:** Entweder iCloud (Apple-exklusiv), Cloud-Ordner (MobileSheets), oder eigener Server (Newzik).
8. **Offline:** Alle Produkte funktionieren offline — **Pflicht für Bühne/Probenlokal ohne WLAN**.
9. **Export:** PDF mit eingebrannten Annotationen zum Teilen.

---

## 3. Marktübersicht Vereinsverwaltung

### 3.1 Produkt-Matrix

| Produkt | Plattform | Preis | Zielgruppe | Stärken | Schwächen |
|---|---|---|---|---|---|
| **Konzertmeister** | iOS, Android, Web | Freemium; Vereinsabo ~3–10 EUR/Monat je nach Staffel (nicht exakt verifiziert) | **DACH-Blasmusik (Marktführer)**, Chöre, Orchester | Register-/Rollenmodell, Termin-Zu-/Absage, Pinnwand, Umfragen, Musikstück-Archiv mit Setlists, Anwesenheitsstatistik, DSGVO-konform (AT/DE) | Noten-Anzeige kein vollwertiger Ständer; Stücke nur als PDF-Anhang |
| **BandHelper** | iOS, Android, Web | 2,25 USD/Mo (Solo Basic) bis 40 USD/Mo (101–500 User Pro) | Bands (Rock/Pop), Booking-fokussiert | Finanzen, Invoices, Stage Plots, Checklists, Gig-Kommunikation, pro Musiker skalierend | Kein Register-Konzept, Band-Logik (alle spielen gleiches Material), nicht auf Orchestergrößen 50+ optimiert |
| **Muzodo** | Web | Basic kostenlos, Premium Abo (nicht verifiziert, Bereich ~2–5 EUR/Monat) | Kleine bis mittlere Ensembles, Chöre | Sehr einfach, E-Mail-basiert, kein App-Zwang, DSGVO (Server DE) | Minimaler Funktionsumfang, nur Termine und Antworten, keine Noten |
| **Groupanizer / Choir Genius** | Web | Abo (nicht verifiziert, 3-stellig/Jahr institutionell) | Chöre | Lernmaterial, Mitglieder-Portal, Beiträge, Marketing-Tools | Chor-zentriert, nicht Blasmusik, keine Stimmregister in Blasmusik-Terminologie |
| **ChurchTools** | Web | Lizenz für Gemeinden | Kirchengemeinden, Gospel/Worship | Ganzheitlich: Gruppen, Termine, Ressourcen, Finanzen, Songs | Gemeinde-Kontext, für säkulare Blaskapelle overkill |
| **SPG-Verein / Campai / Easyverein** | Web | Abo | Generische Vereine (alle Sparten) | Mitglieder, Beiträge, Buchhaltung, DATEV-Export | Keinerlei Musik-/Proben-/Notenspezifika |
| **WhatsApp + Doodle + Google Kalender** (Baseline) | Mobile | Kostenlos | Status quo Kapellen | Niedrigste Hürde, alle haben's schon | Keine Rollen, keine Archivierung, keine Besetzungs-Übersicht, Datenschutz-fragwürdig, Notenversand über Chat = chaotisch |

### 3.2 Tiefenanalyse: Konzertmeister (Marktführer DACH-Blasmusik)

**Rolle im Markt:** Konzertmeister ist in Österreich und Bayern das De-facto-Standardwerkzeug für Musikvereine mittlerer Größe (30–150 Mitglieder). Zitate auf der Landingpage u. a. von *Bayerische Brass Band Akademie* und *Grenzlandkapelle Hardegg* bestätigen die Blasmusik-Positionierung.

- **Mitgliederverwaltung:**
  - Vereins- und Registerstruktur mit flexiblen Rollen.
  - Mitglieder per E-Mail einladen; Selbst-Registrierung möglich.
  - Anwesenheitsstatistiken mit Export.
- **Terminplanung / Zu-/Absagen:**
  - Terminerstellung in < 1 Minute inkl. Vorlage, Wiederholung, Register-Filter.
  - Zu-/Absage mit einem Klick (Push/E-Mail/SMS-Benachrichtigung).
  - **Rückmeldefristen + automatische Erinnerungen.**
  - Absagebenachrichtigung an Kapellmeister.
  - Kalender-Sync (iCal-Feed in persönlichen Kalender).
- **Noten / Musikstücke:**
  - „Musikstücke" als Vereinsentität anlegen (Titel, Metadaten, Dateianhang).
  - Setlists bauen, an Termine hängen.
  - Protokollierung gespielter Stücke + Export/Auswertung.
  - **Kein** digitaler Notenständer (keine Annotation, kein Pedal-Support).
- **Kommunikation:**
  - Pinnwand je Termin.
  - Kommentare zu Rückmeldungen.
  - Nachrichten mit Anhängen, Antwort-Funktion.
  - Mailversand an gefilterte Gruppen.
- **Umfragen:** Mehrere Antworttypen, Auswertung.
- **Aufgaben:** Einmalig/wiederkehrend, Subtasks, Zuweisung, Fälligkeiten.
- **Rollen & Rechte:** Flexibel je Register (z. B. „Flügelhorn-Registerführer" darf eigenes Register planen).
- **Beitrags-/Kassenführung:** Nicht zentral; Datei-/Onlinespeicher-Funktion ersetzt keine Buchhaltung. Vereine nutzen hier oft parallel SPG-Verein o. ä.
- **DSGVO:** Konforme Anbieter-Struktur (AT-Unternehmen), EU-Server. Auftragsverarbeitungsvertrag verfügbar (nicht verifiziert, aber marktüblich).

**Fazit Konzertmeister:** Stark in Organisation, schwach in Notenständer-Funktionen. Genau hier ist die **Ansatzstelle** für Sheetstorm — entweder komplementär (Integration) oder als Komplettlöser mit Fokus Noten.

### 3.3 Gemeinsame Ablauf-Muster (Vereinsverwaltung)

1. **Termin erstellen** (mit Register-Filter, Vorlage, Wiederholung, Rückmeldefrist).
2. **Einladung verschicken** (Push/E-Mail).
3. **Musiker antwortet** Ja/Nein/Vielleicht (1 Klick, auch ohne Account).
4. **Leitung sieht Besetzung** live (wer fehlt, welches Register unterbesetzt).
5. **Erinnerung** automatisch an Nicht-Antworter.
6. **Termin-Pinnwand** für Rückfragen.
7. **Anwesenheit** beim Termin festhalten → Statistik.
8. **Gespielte Stücke** protokollieren → Jahresauswertung (GEMA, Chronik).

---

## 4. Kombinierte Lösungen (Noten + Verein)

**Gibt es sie?** Im Ansatz, aber **nicht vollständig**. Die drei realistischsten Kandidaten:

| Produkt | Noten-Tiefe | Vereins-Tiefe | Lücke |
|---|---|---|---|
| **Konzertmeister** | Flach (PDF-Anhang, Setlist, Protokoll) | Tief | Kein Notenständer, keine Stimmenverteilung pro Register → Musiker |
| **BandHelper** | Mittel (Repertoire, Audio, Lyrics, Transposition) | Mittel (Gig-Orga, Finanzen) | Kein Register-Modell, skaliert schlecht auf Orchester 50+ |
| **Newzik** (mit Collaborative Projects) | Tief | Flach (nur gemeinsame Bibliothek) | Keine Termine, keine Zu-/Absagen, keine Mitgliederrollen |

**Warum macht das kaum jemand?**
- Die zwei Welten haben **unterschiedliche Nutzertypen**: Notenständer = Endnutzer-Gerät auf der Bühne, Vereinsverwaltung = Admin-Arbeit am Laptop.
- Notenständer-Apps sind **iOS-first + lokal-first**; Vereinssoftware ist **Web-first + server-zentral**. Die Architektur-Diskrepanz ist groß.
- Der Markt für reine Notenständer-Apps ist **individuell bezahlt** (jeder Musiker zahlt forScore selbst), Vereinssoftware ist **Vereins-bezahlt**. Verschiedene Einkaufs-Workflows.
- **Stimmenverteilung register-genau** erfordert ein präzises Datenmodell (Werk → Arrangement → Stimme → Register → Musiker → Gerät), das bisher kein Produkt sauber abbildet.

**Hypothese Sheetstorm-USP:** Genau dieses Datenmodell ist das Kernprodukt. Alles andere ist Commodity.

---

## 5. Lücken im Markt (Opportunity-Analyse)

### 5.1 Durchgängig fehlend
- **Register-basierte Stimmenverteilung:** Kein Notenständer versteht „Ich bin 2. Flügelhorn, zeig mir meine Stimme von *Böhmischer Traum* ". Heute wird die richtige Stimme vom Notenwart manuell als PDF pro Musiker zugewiesen.
- **Ensemble-Bibliothek mit Rollen:** Newzik ist der einzige, der echte Shared Libraries hat — aber ohne Register/Rollen.
- **Notenarchiv-Pflege:** Wo liegt Original? Wer hat welche Stimme als Papier mitgenommen? Wann wurde ein Stück zuletzt gespielt? Konzertmeister protokolliert Gespielt-Status, aber nicht den Archiv-Standort der Papier-Stimmen.
- **Vertretungs-Workflow:** „Flügelhorn 1 ist krank, gib seine Stimme an seinen Vertreter" — in keinem Produkt abgebildet.
- **Proben-Fokus-Mode:** Kapellmeister will heute nur Takt 32–56 proben, alle Musiker springen synchron dorthin. Nur in MobileSheetsPro-Bookmode halbwegs umgesetzt.

### 5.2 Blasmusik-spezifisch schlecht abgedeckt
- **Marsch-Buch-Logik:** Blaskapellen nutzen Marschbücher (kleines Heft am Instrument). Kein Notenständer hat einen „Marschbuch-Modus" (kompakter Layout, Quick-Jump nach Nummer).
- **Stimmumfänge & Transposition nach Instrument:** B-Klarinette vs. Es-Klarinette, F-Horn vs. Es-Horn — Stimmenauszug muss das richtige Transpositions-Stimm-PDF liefern. Heute manuell.
- **Notenmappen-Verleih:** Wer hat die Mappe mit? Wann kommt sie zurück? Papierverwaltung.
- **Probenlokal-Kontext:** Offline-Pflicht, da viele Probenräume keinen WLAN-Empfang haben. Alle Top-Notenständer können das, aber Vereins-Apps (Konzertmeister, BandHelper) brauchen Verbindung.
- **Dirigentenpartitur vs. Stimmenauszug:** Dirigent sieht Gesamt, Musiker nur seine Stimme. Kein Produkt löst das mit einem geteilten Datenmodell.

### 5.3 Mehrstimmigkeit / Stimmenauszüge heute
- **Papier:** Notenwart druckt aus Partitur-PDF (oder aus Verlagssatz) die Einzelstimmen, ordnet sie in Mappen. Dominanter Status quo.
- **E-Mail / Cloud-Ordner:** „Hier sind die PDFs für Samstag" — pro Register eine Zip-Datei, Musiker lädt runter, legt in forScore ab. Bruchstelle: zwei Systeme.
- **Konzertmeister-Anhang:** Stück anlegen, PDF dranhängen. Keine Stimmentrennung, der Musiker zieht selbst raus, was er braucht.
- **Newzik Collaborative Projects:** Dirigent legt Partitur-Bundle an, Musiker markiert sich seine Seiten. Näher dran, aber immer noch manuell.

---

## 6. High-Level-Anforderungen für Sheetstorm

### Legende
- **MUST**: Ohne das kein akzeptiertes Produkt (Hygiene)
- **SHOULD**: Differenzierender Mehrwert
- **COULD**: Nice-to-have
- **WON'T (MVP)**: Bewusst nicht gebaut

### MUST — Hygiene-Faktoren

| ID | Anforderung | Herkunft | Begründung |
|---|---|---|---|
| R-001 | PDF-Anzeige in Vollbild, schnelle Seitenwechsel (< 100 ms) | forScore, MobileSheetsPro | Ohne das ist Sheetstorm kein Notenständer |
| R-002 | Offline-Verfügbarkeit aller heruntergeladenen Stimmen | Alle Notenständer | Probenraum ohne WLAN ist Realität |
| R-003 | Authentifizierung + Rollen (Musiker, Registerführer, Notenwart, Kapellmeister, Vorstand) | Konzertmeister | Vereinskontext verlangt Rechtetrennung |
| R-004 | Mitglieder-Register-Modell (Musiker → primäres Instrument/Stimme → Register) | Konzertmeister | Blaskapellen-Grundkonzept |
| R-005 | Werk-/Stück-Entität mit Metadaten (Titel, Komponist, Arrangeur, Genre, Besetzung) | Alle | Navigierbare Bibliothek |
| R-006 | Stimmenauszug als eigene Entität unterhalb des Stücks | Lücke im Markt | Kernunterscheidung |
| R-007 | Stimmenzuweisung Stimme → Musiker (manuell + per Register-Template) | Lücke | Hauptnutzen für Notenwart |
| R-008 | PDF-Upload mit Bulk-Import und automatischer Stimm-Erkennung (mindestens heuristisch aus Dateinamen) | Lücke | Notenwart muss nicht 30 Dateien einzeln taggen |
| R-009 | Termine mit Zu-/Absage-Workflow (Push, Erinnerung, Auswertung) | Konzertmeister | Ersatz für „Umstieg von Konzertmeister" realistisch machen |
| R-010 | Setlist pro Termin (Stücke in Reihenfolge, synchron abrufbar) | forScore, Konzertmeister | Auftrittsvorbereitung |
| R-011 | DSGVO-konformes Hosting, AV-Vertrag, Auskunft/Löschung | Konzertmeister | Vereinsvorstand muss das unterschreiben können |
| R-012 | Multi-Plattform: iOS, Android, Web-Admin (Flutter erlaubt das) | Blasmusik-Realität (gemischte Geräte) | Blaskapellen haben 20% iPads, 60% Android-Tablets, 20% Papier-Holdouts |
| R-013 | Pedal-Support (AirTurn, PageFlip) zum Umblättern | forScore, MobileSheets | Ohne Pedal = kein Ersatz für forScore |

### SHOULD — Differenzierender Mehrwert

| ID | Anforderung | Herkunft | Begründung |
|---|---|---|---|
| R-020 | Register-Template: „Stück X wird an alle Flügelhorn 1+2 und alle Tenorhörner verteilt" | Lücke | Notenwart-Workflow 10x schneller |
| R-021 | Vertretungs-Modus: temporäre Stimmzuweisung an Vertreter mit Ablaufdatum | Lücke | Reale Probenorganisation |
| R-022 | Gespielt-Protokoll je Stück (wann, wo, wie oft) mit Jahresauswertung | Konzertmeister | GEMA-Meldung, Vereinschronik |
| R-023 | Papier-Notenarchiv-Verwaltung (Standort im Regal, Ausleihstatus) | Lücke | Der Notenwart hat physische Noten — die App soll sie mitverwalten |
| R-024 | Dirigenten-Modus: Kapellmeister sieht Partitur, Musiker sehen ihre Stimme, **Cue-sync** bei Seitenwechsel/Takt-Sprung | Newzik/forScore Ansätze | Kernnutzen Probe |
| R-025 | Marschbuch-Modus (kleines Layout, Quick-Jump nach Nummer) | Lücke, Blasmusik-spezifisch | Reale Marschauftritte |
| R-026 | Annotation auf persönlichem Layer (sichtbar nur für Musiker) + auf Vereins-Layer (vom Notenwart gepflegt) | forScore (Layer), Lücke (Trennung) | Persönliche Fingersätze dürfen Vereins-Edits nicht überschreiben |
| R-027 | Transpositions-Varianten je Stimme (B-Klarinette vs. Es-Klarinette liefert korrekte Datei automatisch) | Lücke, Blasmusik | Vermeidet Notenwart-Fehler |
| R-028 | Pinnwand + Kommentare je Termin/Stück | Konzertmeister | Kommunikationskanal im Kontext |
| R-029 | Anwesenheitsprotokoll + Statistik-Export | Konzertmeister | Vorstandsbericht |
| R-030 | Verbands-/Repertoire-Import (ÖBV/BDB-Werkelisten, falls öffentlich zugänglich — nicht verifiziert) | Blasmusik-spezifisch | Metadaten-Startbestand |

### COULD — Nice-to-have

| ID | Anforderung | Herkunft | Begründung |
|---|---|---|---|
| R-040 | OMR (PDF → MusicXML) | Newzik | Beeindruckend, aber teuer zu bauen/lizenzieren |
| R-041 | MIDI-Playback der Stimme zum Üben | Newzik | Übungsunterstützung |
| R-042 | Gesichts-/Gestensteuerung zum Umblättern | Newzik Premium | Premium-Gimmick |
| R-043 | Beitrags-/Kassenverwaltung | SPG-Verein | Vereine haben oft eigene Lösung |
| R-044 | Stage Plots | BandHelper | Für Konzertbühne, weniger Blasmusik-relevant |
| R-045 | Verlags-/Shop-Integration | nkoda, Henle | Lizenzrechtlich komplex |

### WON'T (MVP) — Bewusst ausgeschlossen

| ID | Ausschluss | Begründung |
|---|---|---|
| R-900 | Keine Beitrags-/Buchhaltung | Konkurrenz zu SPG-Verein wäre Scope-Explosion |
| R-901 | Kein eigener Notations-Editor (MuseScore-Ersatz) | Ist ein eigenes Produkt |
| R-902 | Keine öffentliche Noten-Shop-Integration im MVP | Lizenzvertragsaufwand zu hoch |
| R-903 | Keine ChordPro-First-Architektur | Blasmusik ist PDF-Welt, nicht Akkordblatt-Welt |
| R-904 | Keine Websocket-Live-Annotation à la „wir sehen den Stift des Dirigenten live" | Technisch cool, Nutzen-Aufwand-Verhältnis schlecht |

---

## 7. Top-5-Features mit höchstem Mehrwert

In absteigender Priorität, **mit Begründung**. Das ist die Diskussionsgrundlage für die nächste Arbeitssession.

### 1. Register-basierte Stimmenverteilung (R-007, R-020, R-027)
**Warum #1:** Einzigartig im Markt. Löst das größte Alltagsproblem des Notenwarts. Direkte Konsequenz des Datenmodells Werk → Stimme → Register → Musiker. Ohne das bleibt Sheetstorm ein weiterer Notenständer.

### 2. Offline-fähiger Notenständer mit Pedal-Support (R-001, R-002, R-013)
**Warum #2:** Ohne gleichwertige Alternative zu forScore/MobileSheets wird kein Musiker wechseln. Commodity, aber Pflicht. Flutter + lokales SQLite (Drift) + PDF-Rendering muss bühnenreif sein.

### 3. Termin- + Zu-/Absage-Workflow inkl. Setlist-Kopplung (R-009, R-010)
**Warum #3:** Macht den Wechsel von Konzertmeister möglich — ohne Ersatz dieses Features bleibt Konzertmeister als zweites Tool parallel. Bonus: Setlist wird **direkt** im Notenständer jedes Musikers sichtbar, ein Medienbruch entfällt.

### 4. Dirigenten-Modus mit Cue-Sync (R-024)
**Warum #4:** Probenproduktivität. „Takt 32" sagen, alle Tablets springen hin. Synchrone Annotationen vom Pult. Das ist ein echtes „Wow"-Feature in der Probe, das in keinem Produkt rund gelöst ist.

### 5. Persönliche + Vereins-Annotation-Layer (R-026)
**Warum #5:** Entschärft den größten politischen Konflikt: „Der Notenwart hat meine Fingersätze überschrieben." Saubere Trennung ermöglicht parallele Pflege ohne Streit.

---

## 8. Empfehlung: Reihenfolge der Spec-Vertiefung

Der User vermutet **„Notenverwaltung + Anzeige zuerst"**. **Teil-Widerlegung:** Die reine *Anzeige* kann später — aber die *Datenmodell-Entscheidung* für Werk/Stimme/Register/Musiker muss **zuerst** stehen, sonst baut man zwei Mal. Konkret:

### Thema 1 (zuerst): **Datenmodell Werk → Stimme → Musiker → Gerät**
- **Warum zuerst:** Jede andere Entscheidung (Sync, Offline, Rollen, UI-Screens) hängt von diesem Modell ab. Wenn hier Fehler sind, wird die erste Migration schmerzhaft. Es ist auch das Feature, das Sheetstorm differenziert — also genau das, was validiert werden muss, bevor man Mühe in Anzeige/Annotation steckt.
- **Zu entscheiden:**
  - Entität „Arrangement" vs. „Werk" — ein Werk kann mehrere Arrangements haben (gleiches Stück, andere Besetzung).
  - Stimme als eigene Entität vs. nur Tag am PDF.
  - Register als globale Taxonomie oder pro Verein konfigurierbar (Vorschlag: pro Verein, mit Vorlagen aus ÖBV/BDB).
  - Instrument-Transpositions-Varianten: eine PDF pro Transposition, oder eine MusicXML mit Render-Pipeline?
  - Wie wird die Zuordnung Stimme ↔ Musiker versioniert? (Vertretung, Wechsel zwischen Registern.)
- **Offene Fragen an den User:**
  - Wie groß ist die Zielkapelle im MVP? (30 vs. 150 Mitglieder ändert Annahmen.)
  - Gibt es einen existierenden Notenarchiv-Bestand, den wir importieren wollen? In welcher Form (Excel, Papier, reiner PDF-Ordner)?
  - Sollen Nebenbesetzungen (Musiker spielt mal Flügelhorn, mal Trompete) abgebildet werden?

### Thema 2: **Sync- & Offline-Architektur**
- **Warum jetzt:** Entscheidet über Tech-Stack (Drift ja, aber welche Sync-Strategie? Server-authoritative, CRDT, Event-Sourcing?) und die gesamte UX in schlechtem Empfang.
- **Zu entscheiden:**
  - Sync-Modell: Pull-only bei App-Start, Push bei Änderung, oder CRDT für Offline-Bearbeitung? (Empfehlung: Server-authoritative + Pull mit Etag/Last-Modified. CRDT ist für Annotationen overkill, solange Annotationen pro-Musiker-privat sind.)
  - Umfang Offline-Schreibbarkeit: Zu-/Absagen offline möglich? Annotationen ja (privater Layer).
  - Konfliktlösung: Last-Writer-Wins für Vereins-Content, Per-User-Layer für privaten Content.
  - Große PDFs (100+ MB-Partituren): Delta-Download? Seitenweise Lazy-Load?
- **Offene Fragen:**
  - Wie viel GB Notenarchiv erwartest du pro Verein? (Dimensioniert S3/Blob-Kosten.)
  - Soll Sheetstorm ohne Internet auf Proben installierbar sein (Self-Hosted-Option)?

### Thema 3: **Rollen- & Rechtemodell + Onboarding-Flow**
- **Warum jetzt:** Ohne das kein Pilot-Verein-Test möglich. Konzertmeister zeigt, dass flexible Registerrollen der Knackpunkt sind.
- **Zu entscheiden:**
  - Rollen-Hierarchie: System-Admin, Vereins-Admin, Notenwart, Kapellmeister, Registerführer, Musiker, Gast.
  - Rechte-Matrix: Wer darf Stücke hochladen, zuweisen, löschen, Termine anlegen, Mitglieder einladen, Kassenzugriff.
  - Einladungsflow: E-Mail + Code? SSO (Google/Apple)? Magic Link?
  - Jugendkapelle: minderjährige Mitglieder → Elternzustimmung, DSGVO für Minderjährige.
- **Offene Fragen:**
  - Gibt es Überlappungen mit Konzertmeister-Nutzer-Accounts? Import-Schnittstelle sinnvoll?
  - Welcher Pilot-Verein steht bereit?

**Nicht jetzt vertiefen (bewusst später):**
- Annotation-Engine-Details (erst wenn Datenmodell + Sync stehen)
- OMR/MusicXML (Later-Stage-COULD)
- Marschbuch-Modus (spezialisiert, nicht MVP-kritisch)
- Finanzen/Beiträge (WON'T im MVP)

---

## 9. Quellen

- https://forscore.co/
- https://apps.apple.com/us/app/forscore/id363738376
- https://www.zubersoft.com/mobilesheets/
- https://www.zubersoft.com/mobilesheets/features/collaboration/
- https://newzik.com/
- https://piascore.com/
- https://onsongapp.com/ (Seite lieferte PHP-Fehler zum Zeitpunkt der Recherche)
- https://www.konzertmeister.app/
- https://www.konzertmeister.app/de/preise-features
- https://bandhelper.com/
- https://bandhelper.com/main/pricing.html
- https://www.muzodo.com/
- https://groupanizer.com/
- https://nkoda.com/

**Nicht erreichbar zum Zeitpunkt der Recherche (April 2026):** `forscore.co/about-price/`, `en.wikipedia.org/wiki/ForScore`, `www.henle.de/en/henle-library-app/`, `www.blasmusik.de/`, `piascore.com/apps`. Dort gemachte Aussagen stützen sich auf andere Quellen oder sind als „nicht verifiziert" gekennzeichnet.
