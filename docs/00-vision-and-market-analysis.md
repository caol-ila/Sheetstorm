# 00 — Vision & Marktanalyse

## Vision

**Sheetstorm** ist die zentrale Plattform für Blasmusik­vereine im
deutschsprachigen Raum: Sie vereint zentrale Notenverwaltung,
KI-gestützte Digitalisierung, Live-Synchronisation zwischen Dirigent
und Musikern sowie Vereinsorganisation (Termine, Mitglieder, Rollen)
in einer einzigen plattformübergreifenden App.

Sheetstorm will **kein** weiteres Notenanzeige-Tool sein. Die These
ist, dass der Markt zwei Lager hat — Vereinsorganisation
(Konzertmeister) und Noten­anzeige (forScore, Newzik, Marschpat,
MobileSheets) — und niemand beides gut macht. Sheetstorm schließt
diese Lücke.

### Leitprinzipien

1. **Deutschsprachig zuerst.** UI-Texte, Terminologie (Stimme,
   Register, Probe, Helfer­einsatz) und DSGVO-konforme Datenhaltung
   sind Default. Internationalisierung ist vorbereitet, aber nicht
   Tag-1-Ziel.
2. **Plattform­übergreifend.** PWA als Standard, native Capabilities
   (Bluetooth, HID) wo verfügbar. Kein iOS-only.
3. **Verein als First-Class Bürger.** Daten gehören dem Verein, nicht
   einzelnen Musikern. Wechselnde Dirigenten/Mitglieder ändern nichts
   am Bibliotheksbestand.
4. **Offline-fähig.** Musiker müssen ohne Netz spielen können. Sync
   passiert vorab über klare User-Intents („offline verfügbar
   machen").
5. **Pragmatischer KI-Einsatz.** OMR und Auto-Tagging als Komfort,
   nicht als Pflicht. Manuelle Korrektur immer möglich.

## Konkurrenz­analyse

| App | Stärke | Schwäche | Preis |
|---|---|---|---|
| **Konzertmeister** | DACH-Markt, Termine + Anwesenheit + Chat, DSGVO/DE-Hosting | Keine echte Notenverwaltung, nur Datei-Anhänge | Freemium |
| **Marschpat** | Blasmusik-Fokus, Dirigenten-Master, PocketBook-Hardware | Hauptsächlich Verlags­content, eigene Noten begrenzt, teuer in Gruppen | 76 €/J Solo, 151 €/J / 5 Mitglieder |
| **forScore** | Beste UI/Annotation auf iPad, „Cue" = Master-Page-Turn | iOS-only, kein Verein/Termine, manuelle Verteilung | ~25 € einmalig + Pro-Sub |
| **Newzik** | Cloud-Sharing, Echtzeit-Sync, OMR (LiveScore), Auto-Transponieren | iOS-only, Subscription, kein Vereinskontext | 9,99 $/Mo oder 179 $ einmalig |
| **MobileSheets Pro** | Cross-Platform (Android/Win/iOS), Bibliotheks­tiefe | Utilitarian-UI, keine Vereinsfunktionen, Sync nur via WiFi | ~13–30 € einmalig |
| **PiaScore** | Bluetooth Page-Turner | Keine Gruppen­funktionen | Free/Premium |

### Was wir besser machen wollen

* **Konzertmeister + Marschpat in einem.** Ein Login, eine Datenbasis,
  Termine + Noten + Konzert-Setlist verschmelzen.
* **Echtes Cross-Platform.** PWA + Desktop + Android + iOS. Keine
  Apple-Lock-In-Geschichte.
* **Conductor-Sync mit Sicherheit.** Andere Apps (forScore Cue,
  Marschpat) verschicken Page-Turns ohne ernsthafte
  Authentifizierung. Wir signieren Broadcasts mit
  Event-spezifischem Schlüssel (siehe Spec 05).
* **Stimm­wahl-UX.** Ein Klick: bevorzugte Stimme, sortierte
  Alternativen darunter, dann „andere". Kein Suchen.
* **AI-OMR ohne Vendor-Lock.** Audiveris als Backbone, Wert in
  unserer Pipeline und Korrektur-UX.
* **Faires Pricing.** Open-Core / Self-Hostable Option für Vereine,
  Cloud-Hosting als Komfort.

## Zielgruppen & Personas

### P1 — Maria, Musikerin (Klarinette, B-Stimme)
* Will: Eigene Noten griffbereit, offline beim Konzert, Annotationen,
  Probetermine im Kalender.
* Frust mit Status quo: PDFs in WhatsApp, Stimme manuell suchen,
  keine Annotation-Sync.

### P2 — Thomas, Dirigent
* Will: Schnell Stück aufrufen, sieht eigene Partitur, alle Musiker
  springen mit. Setlist für Konzert vorbereiten. Probe planen.
* Frust: Aktuelle Tools erzwingen iPad-only oder Wifi-Setup, das im
  Festzelt nicht funktioniert.

### P3 — Andrea, Vereins-Admin
* Will: Mitglieder einladen, Stimmen zuordnen, Bibliothek pflegen,
  Konzerte organisieren, Helfer für Festle koordinieren.
* Frust: Excel + WhatsApp + Dropbox + Konzertmeister parallel.

### P4 — Stefan, Lehrer (Jugend­ausbildung)
* Will: Schüler eigene kleine Bibliothek geben, Übe-Material teilen,
  Fortschritt sehen.
* Frust: Keine ausbildungs­geeignete Lösung im Vereinskontext.

## Nicht-Ziele

* Keine Komposition / Notensatz (MuseScore-Ersatz).
* Keine eigene Verlags­plattform (kein Verkauf von Noten).
* Keine Buchhaltung / Mitglieds­beiträge (separate Vereins-Software).
* Keine Live-Audio-Streams oder Latenz-kritisches Mitspielen.
