# Funktionale Spezifikation — Notenmanagement-App

> Version: 1.0  
> Status: Entwurf  
> Autor: Stark (Lead / Architect)  
> Datum: 2026-03-28  
> Quelle: docs/anforderungen.md, Thomas (Produktvision)

---

## 1. Einleitung

### 1.1 Zweck

Diese Spezifikation definiert die funktionalen und nicht-funktionalen Anforderungen der Notenmanagement-App für Blaskapellen. Sie dient als verbindliche Referenz für Design, Implementierung und Testing.

### 1.2 Zielgruppe

- Blaskapellen und Musikvereine (primär)
- Einzelne Musiker mit persönlicher Notensammlung
- Musiklehrer und -schüler (Lehre-Modul)

### 1.3 Leitprinzipien

1. **Musiker-Erlebnis first:** Ablenkungsfreier Spielmodus hat höchste Priorität
2. **Touch-first:** Alle Interaktionen müssen touch-optimiert sein
3. **Inkrementelle Wertlieferung:** Jeder Meilenstein liefert nutzbaren Mehrwert
4. **Offline-fähig:** Kernfunktionen ohne Internetverbindung nutzbar
5. **Deutsch first:** UI und Inhalte starten auf Deutsch, i18n-Architektur für spätere Erweiterung

---

## 2. Domänen-Übersicht

| # | Domäne | Beschreibung |
|---|--------|-------------|
| D1 | Notenverwaltung | Import, Labeling, Metadaten, Stimmen, Speicherung |
| D2 | Spielmodus | Notenansicht, Fokus-Modus, Auto-Rotation, Auto-Zoom, Annotationen |
| D3 | Kapellenverwaltung | Kapellen, Mitgliedschaft, Rollen, Instrumente, Register |
| D4 | Setlist-Verwaltung | Zusammenstellung, Sortierung, Konzert-Zuordnung |
| D5 | Vereinsleben | Konzertplanung, Feste, Schichten, Terminplanung |
| D6 | Persönliche Sammlung | Eigene Noten, Cloud-Sync, Geräte-übergreifend |
| D7 | Tools | Tuner, Echtzeit-Metronom, Annotationen |
| D8 | Lehre-Modul | Lehrer/Schüler, Lernpfade, Content-Freischaltung |
| D9 | AI-Integration | OCR/Vision für Metadaten, konfigurierbare Lizenzierung |
| D10 | Plattform & Infrastruktur | Multi-Plattform, Offline, Sync, Sicherheit |

---

## 3. Feature-Spezifikation

### D1 — Notenverwaltung

#### F1.1 Zentrale Notenablage

**Beschreibung:** Jede Kapelle verfügt über eine zentrale Notenablage, in der alle Musikstücke mit zugehörigen Stimmen verwaltet werden. Musiker erhalten automatisch Zugriff auf die für sie relevanten Stimmen.

**User Stories:**
- Als Notenwart möchte ich Noten zentral für die Kapelle hochladen, damit alle Musiker Zugriff haben.
- Als Musiker möchte ich meine Stimme automatisch angezeigt bekommen, wenn ich ein Stück öffne.
- Als Dirigent möchte ich alle Stimmen eines Stücks einsehen können, um die Besetzung zu prüfen.

**Akzeptanzkriterien:**
- [ ] Noten werden pro Kapelle gespeichert und sind nur für Mitglieder sichtbar
- [ ] Jedes Stück kann mehrere Stimmen enthalten
- [ ] Stimmen sind nach Instrument-Kategorie gruppiert
- [ ] Suche nach Titel, Interpret, Stimme, Instrument möglich
- [ ] Paginierte Liste mit Filteroptionen

**Priorität:** Must (MVP)

---

#### F1.2 Noten-Upload & Labeling

**Beschreibung:** Nutzer können Noten als Bilder, PDFs oder direkte Kamera-Fotos hochladen. Ein mehrstufiger Labeling-Prozess ermöglicht die Zuordnung von Seiten zu Stücken, wenn ein Upload mehrere Lieder enthält.

**User Stories:**
- Als Notenwart möchte ich ein PDF mit mehreren Liedern hochladen und die einzelnen Lieder markieren können.
- Als Musiker möchte ich direkt ein Foto meiner Noten machen und hochladen können.
- Als Notenwart möchte ich eine Vorschau aller hochgeladenen Seiten sehen und durch sie navigieren können.

**Akzeptanzkriterien:**
- [ ] Upload von Bildern (JPG, PNG, TIFF), PDFs und Kamera-Fotos
- [ ] Vorschaubilder aller hochgeladenen Seiten werden in einer Galerie angezeigt
- [ ] Labeling-Workflow: Nutzer navigiert durch Seiten und markiert "gleiches Lied" oder "neues Lied"
- [ ] Seitenreihenfolge per Drag & Drop änderbar
- [ ] Einzelne Seiten löschbar
- [ ] Upload-Fortschritt wird angezeigt
- [ ] Maximale Dateigröße pro Upload: konfigurierbar (Standard: 50 MB)
- [ ] Touch-optimierte Labeling-Oberfläche

**Priorität:** Must (MVP)

---

#### F1.3 AI-basierte Metadaten-Erkennung

**Beschreibung:** Nach dem Upload werden AI/Vision-Dienste eingesetzt, um automatisch Metadaten wie Titel, Interpret, Stimme und Tonart aus den Notenblättern zu extrahieren. Erkannte Daten können vom Nutzer bestätigt oder korrigiert werden.

**User Stories:**
- Als Notenwart möchte ich, dass Titel und Stimme automatisch erkannt werden, um Zeit beim Einpflegen zu sparen.
- Als Nutzer möchte ich erkannte Metadaten korrigieren können, falls die AI falsch liegt.
- Als Administrator möchte ich steuern können, welcher AI-Dienst verwendet wird.

**Akzeptanzkriterien:**
- [ ] AI erkennt mindestens: Titel, Interpret/Komponist, Stimme/Instrument, Tonart
- [ ] Erkannte Daten werden als Vorschlag angezeigt, nicht automatisch übernommen
- [ ] Konfidenzwert wird je erkanntem Feld angezeigt
- [ ] Manuelle Eingabe/Korrektur für alle Felder möglich
- [ ] AI-Erkennung ist optional und abschaltbar
- [ ] Verarbeitungsstatus wird angezeigt (Wartend, In Bearbeitung, Fertig, Fehler)

**Priorität:** Must (MVP)

---

#### F1.4 AI-Lizenzierung & Konfiguration

**Beschreibung:** AI-Dienste können auf zwei Ebenen konfiguriert werden: pro Nutzer (eigener API-Key) oder pro Kapelle (zentral durch Administrator). Nutzer können wählen, welchen Dienst sie verwenden.

**User Stories:**
- Als Musiker möchte ich meinen eigenen AI-API-Key hinterlegen können.
- Als Administrator möchte ich einen zentralen AI-Zugang für die gesamte Kapelle einrichten.
- Als Musiker möchte ich den Kapellen-AI-Dienst nutzen können, ohne einen eigenen Key zu benötigen.

**Akzeptanzkriterien:**
- [ ] API-Keys werden verschlüsselt gespeichert
- [ ] Fallback-Reihenfolge: Persönlicher Key → Kapellen-Key → Kein AI
- [ ] Unterstützte Dienste: Azure AI Vision, weitere konfigurierbar
- [ ] Nutzungsstatistik pro Kapelle einsehbar (für Administrator)
- [ ] Validierung des API-Keys beim Speichern

**Priorität:** Must (MVP)

---

#### F1.5 Stimmenauswahl & Instrument-Profil

**Beschreibung:** Jeder Musiker definiert sein(e) Instrument(e) und eine Standardstimme. Beim Öffnen eines Stücks wird die passende Stimme automatisch vorausgewählt. Eine intelligente Fallback-Logik greift, wenn die exakte Stimme nicht vorhanden ist.

**User Stories:**
- Als Musiker möchte ich mein Standardinstrument festlegen, damit ich nicht bei jedem Stück die Stimme auswählen muss.
- Als Musiker möchte ich mehrere Instrumente angeben können, falls ich z.B. Klarinette und Saxophon spiele.
- Als Musiker möchte ich bei der Stimmauswahl meine Instrumente oben sehen, damit ich schnell die richtige Stimme finde.

**Akzeptanzkriterien:**
- [ ] Musiker kann ein oder mehrere Instrumente in seinem Profil hinterlegen
- [ ] Ein Standardinstrument/-stimme kann festgelegt werden
- [ ] Beim Öffnen eines Stücks wird die Standard-Stimme vorausgewählt
- [ ] Fallback: Wenn exakte Stimme nicht vorhanden → nächstliegende Stimme (z.B. "Klarinette" statt "2. Klarinette")
- [ ] Stimm-Auswahlliste: Eigene Instrumente oben, andere Stimmen darunter
- [ ] Stimme jederzeit wechselbar — Standard ist nur Vorauswahl, nicht Zwang

**Priorität:** Must (MVP)

---

#### F1.6 Berechtigungen für Noteneinpflege

**Beschreibung:** Wer Noten zur Kapelle hinzufügen darf, ist konfigurierbar. Standardmäßig dürfen nur bestimmte Rollen (Notenwart, Administrator, Dirigent) Noten einpflegen. Jeder Musiker kann immer Noten zu seiner persönlichen Sammlung hinzufügen.

**User Stories:**
- Als Administrator möchte ich festlegen können, welche Rollen Noten für die Kapelle einpflegen dürfen.
- Als Musiker möchte ich immer Noten zu meiner persönlichen Sammlung hinzufügen können.

**Akzeptanzkriterien:**
- [ ] Upload-Berechtigung für Kapelle ist rollenbasiert konfigurierbar
- [ ] Standard: Notenwart, Administrator, Dirigent dürfen hochladen
- [ ] Persönliche Sammlung: jeder Musiker kann immer eigene Noten hinzufügen
- [ ] Fehlermeldung bei unberechtigtem Upload-Versuch

**Priorität:** Must (MVP)

---

### D2 — Spielmodus (Notenansicht)

#### F2.1 Fokus-Modus

**Beschreibung:** Ein ablenkungsfreier Vollbildmodus zum Spielen. Keine UI-Elemente, die vom Notenblatt ablenken. Minimale, kontextuelle Steuerung (Seitenwechsel, Zoom).

**User Stories:**
- Als Musiker möchte ich im Fokus-Modus nur meine Noten sehen, ohne abgelenkt zu werden.
- Als Musiker möchte ich durch Wischen oder Tippen zur nächsten Seite blättern können.
- Als Musiker möchte ich den Fokus-Modus einfach verlassen können.

**Akzeptanzkriterien:**
- [ ] Vollbildansicht ohne sichtbare Navigation, Menüs oder Statusleiste
- [ ] Seitenwechsel per Swipe (Touch) oder Tastatur (Pfeil-Tasten, Leertaste)
- [ ] Transparente Touch-Zonen am Seitenrand für Vor/Zurück
- [ ] Tap in die Mitte zeigt kurzzeitig minimale Controls (Exit, Seitenübersicht)
- [ ] Bildschirm bleibt aktiv (kein Auto-Lock/Screen-Timeout)
- [ ] Orientierung folgt der Noten-Ausrichtung

**Priorität:** Must (MVP)

---

#### F2.2 Auto-Rotation

**Beschreibung:** Noten werden automatisch so gedreht, dass die Notenlinien horizontal dargestellt werden, unabhängig davon, wie das Originalfoto aufgenommen wurde.

**User Stories:**
- Als Musiker möchte ich, dass schräg fotografierte Noten automatisch gerade ausgerichtet werden.

**Akzeptanzkriterien:**
- [ ] Erkennung der Notenlinien-Ausrichtung im Bild
- [ ] Automatische Rotation bis die Linien horizontal sind
- [ ] Manuelle Korrektur der Rotation möglich
- [ ] Rotation wird pro Seite gespeichert

**Priorität:** Must (MVP)

---

#### F2.3 Auto-Zoom

**Beschreibung:** Der Zoom wird automatisch so eingestellt, dass der Noteninhalt maximal sichtbar ist, ohne dass relevante Bereiche abgeschnitten werden.

**User Stories:**
- Als Musiker möchte ich, dass die Noten automatisch so gezoomt werden, dass ich alles gut lesen kann.

**Akzeptanzkriterien:**
- [ ] Erkennung des Notenbereichs im Bild (Ränder ausschneiden)
- [ ] Automatische Anpassung an Bildschirmgröße und -orientierung
- [ ] Pinch-to-Zoom für manuellen Zoom
- [ ] Zoom-Level wird pro Seite und Gerät gespeichert
- [ ] Double-Tap zum Zurücksetzen auf Auto-Zoom

**Priorität:** Must (MVP)

---

#### F2.4 Annotationen & Markierungen

**Beschreibung:** Musiker können Notizen, Markierungen, Hervorhebungen und Streichungen in die Noten einfügen. Drei Sichtbarkeitsebenen erlauben private, stimmen-spezifische und orchesterweite Annotationen.

**User Stories:**
- Als Musiker möchte ich persönliche Markierungen in meinen Noten machen können (Dynamik, Einsätze).
- Als Registerführer möchte ich Annotationen für alle Musiker meiner Stimme machen können.
- Als Dirigent möchte ich Anweisungen für das gesamte Orchester in die Noten schreiben können.

**Akzeptanzkriterien:**
- [ ] Zeichenwerkzeuge: Freihand, Highlighter, Text, Symbole (Dynamik, Atemzeichen etc.)
- [ ] Farben wählbar (min. 6 Farben)
- [ ] Drei Sichtbarkeitsebenen:
  - Lokal/Privat: Nur für den Musiker sichtbar
  - Stimmen-Sync: Für alle Musiker derselben Stimme synchronisiert
  - Orchester-weit: Für alle Mitglieder sichtbar
- [ ] Annotationen sind löschbar und editierbar
- [ ] Annotationen werden als Layer über den Noten dargestellt (Originalnote bleibt unverändert)
- [ ] Undo/Redo für Annotationen
- [ ] Sichtbarkeitsebene kann nachträglich geändert werden (mit entsprechender Berechtigung)
- [ ] Touch- und Stift-optimiert (Apple Pencil, Surface Pen etc.)

**Priorität:** Must (MVP)

---

### D3 — Kapellenverwaltung

#### F3.1 Kapelle erstellen & verwalten

**Beschreibung:** Kapellen (Blasorchester, Musikvereine) können erstellt und verwaltet werden. Jede Kapelle hat eigene Mitglieder, Rollen, Noten und Konfigurationen.

**User Stories:**
- Als Musiker möchte ich eine neue Kapelle erstellen können.
- Als Administrator möchte ich die Kapelleneinstellungen verwalten können (Name, Logo, Kontaktdaten).

**Akzeptanzkriterien:**
- [ ] Kapelle erstellen mit Name, optional Logo und Beschreibung
- [ ] Einstellungen bearbeitbar durch Administrator
- [ ] Einladung neuer Mitglieder per Link oder E-Mail
- [ ] Mitglieder-Übersicht mit Rollen und Instrumenten
- [ ] Kapelle kann archiviert (nicht gelöscht) werden

**Priorität:** Must (MVP)

---

#### F3.2 Multi-Kapellen-Zugehörigkeit

**Beschreibung:** Ein Musiker kann Mitglied in mehreren Kapellen sein und einfach zwischen ihnen wechseln. Jede Kapelle hat eigene, getrennte Daten.

**User Stories:**
- Als Musiker möchte ich zwischen meinen Kapellen wechseln können, ohne mich neu anzumelden.
- Als Musiker möchte ich sehen, in welcher Kapelle ich gerade aktiv bin.

**Akzeptanzkriterien:**
- [ ] Kapellen-Wechsler in der Hauptnavigation (prominent, nicht versteckt)
- [ ] Persönliche Sammlung immer sichtbar (unabhängig von aktiver Kapelle)
- [ ] Daten der Kapellen sind strikt getrennt
- [ ] Benachrichtigungen können pro Kapelle konfiguriert werden

**Priorität:** Must (MVP)

---

#### F3.3 Rollen & Mitgliederverwaltung

**Beschreibung:** Innerhalb einer Kapelle werden Mitgliedern Rollen zugewiesen, die ihre Berechtigungen bestimmen. Ein Mitglied kann mehrere Rollen haben.

**User Stories:**
- Als Administrator möchte ich Mitgliedern Rollen zuweisen und entziehen können.
- Als Registerführer möchte ich die Musiker meines Registers verwalten können.

**Akzeptanzkriterien:**
- [ ] Rollen: Administrator, Dirigent, Notenwart, Registerführer, Musiker
- [ ] Ein Mitglied kann mehrere Rollen haben
- [ ] Rollen-Zuweisung nur durch Administrator
- [ ] Mindestens ein Administrator pro Kapelle
- [ ] Registerführer wird einem Register (Instrumentengruppe) zugeordnet

**Priorität:** Must (MVP)

---

### D4 — Setlist-Verwaltung

#### F4.1 Setlist erstellen & verwalten

**Beschreibung:** Setlists sind geordnete Zusammenstellungen von Stücken aus dem Kapellen-Notenbestand. Sie können für Konzerte, Proben oder andere Anlässe erstellt werden.

**User Stories:**
- Als Dirigent möchte ich eine Setlist für ein Konzert zusammenstellen können.
- Als Musiker möchte ich die Setlist eines bevorstehenden Konzerts einsehen und die Stücke der Reihe nach durchspielen können.
- Als Dirigent möchte ich die Reihenfolge der Stücke in der Setlist per Drag & Drop ändern können.

**Akzeptanzkriterien:**
- [ ] Setlist erstellen mit Titel, Beschreibung, optionalem Datum/Anlass
- [ ] Stücke aus dem Notenbestand zur Setlist hinzufügen
- [ ] Reihenfolge per Drag & Drop ändern
- [ ] Stücke aus der Setlist entfernen
- [ ] Im Spielmodus: automatischer Übergang zum nächsten Stück in der Setlist
- [ ] Setlist kann mit einem Termin/Konzert verknüpft werden
- [ ] Setlist kann dupliziert werden

**Priorität:** Should (Meilenstein 2)

---

### D5 — Vereinsleben & Organisation

#### F5.1 Konzertplanung

**Beschreibung:** Verwaltung von Konzerten und Auftritten mit Zu-/Absage-Funktion für Musiker.

**User Stories:**
- Als Dirigent/Administrator möchte ich Konzerte anlegen können mit Datum, Ort und Setlist.
- Als Musiker möchte ich für ein Konzert zu- oder absagen können.
- Als Administrator möchte ich sehen, wer für ein Konzert zugesagt hat.

**Akzeptanzkriterien:**
- [ ] Konzert erstellen mit Datum, Uhrzeit, Ort, Beschreibung
- [ ] Setlist einem Konzert zuordnen
- [ ] Zu-/Absage pro Musiker
- [ ] Teilnehmerübersicht mit Anwesenheitsstatus
- [ ] Erinnerung konfigurierbar (Push-Notification)
- [ ] Übersicht nach Registern (welche Instrumente fehlen)

**Priorität:** Should (Meilenstein 2)

---

#### F5.2 Feste & Schichtplanung

**Beschreibung:** Verwaltung von Festen und Veranstaltungen des Vereins mit Schichtplanung für Arbeitseinsätze.

**User Stories:**
- Als Administrator möchte ich ein Fest anlegen und Arbeitsschichten definieren können.
- Als Musiker möchte ich mich für Schichten eintragen können.
- Als Administrator möchte ich sehen, welche Schichten noch unbesetzt sind.

**Akzeptanzkriterien:**
- [ ] Fest/Veranstaltung erstellen mit Datum, Ort, Beschreibung
- [ ] Schichten definieren: Zeitraum, benötigte Anzahl Helfer, Bezeichnung (z.B. "Ausschank", "Aufbau")
- [ ] Musiker können sich für Schichten eintragen
- [ ] Übersicht: Besetzte / offene Schichten
- [ ] Schichttausch zwischen Musikern möglich
- [ ] Erinnerung vor Schichtbeginn

**Priorität:** Should (Meilenstein 2)

---

#### F5.3 Allgemeine Terminplanung

**Beschreibung:** Kalenderübersicht aller Termine (Proben, Konzerte, Feste, sonstige Events) mit Filterfunktion.

**User Stories:**
- Als Musiker möchte ich alle Termine meiner Kapelle(n) in einer Kalenderübersicht sehen.
- Als Administrator möchte ich allgemeine Termine (z.B. Ausflug) anlegen können.

**Akzeptanzkriterien:**
- [ ] Kalenderansicht (Monat/Woche/Agenda)
- [ ] Filterbar nach Kapelle, Termin-Typ
- [ ] Termine exportierbar (iCal)
- [ ] Push-Benachrichtigungen für anstehende Termine
- [ ] Zu-/Absage-Funktion für alle Termin-Typen

**Priorität:** Should (Meilenstein 2)

---

### D6 — Persönliche Sammlung

#### F6.1 Eigene Notensammlung

**Beschreibung:** Jeder Musiker hat eine persönliche Notensammlung, die unabhängig von Kapellen funktioniert. Die Mechanismen (Upload, Labeling, Ansicht) sind identisch mit der Kapellen-Notenablage.

**User Stories:**
- Als Musiker möchte ich eigene Noten hochladen und verwalten können, die nur mir gehören.
- Als Musiker möchte ich meine persönlichen Noten auf verschiedenen Geräten nutzen können.

**Akzeptanzkriterien:**
- [ ] Gleiche Upload- und Labeling-Funktionalität wie bei Kapellen-Noten
- [ ] Zugriff nur durch den Besitzer
- [ ] Persönliche Sammlung ist immer erreichbar (unabhängig von aktiver Kapelle)
- [ ] Lokale Speicherung auf dem Gerät

**Priorität:** Must (MVP)

---

#### F6.2 Cloud-Storage-Synchronisation

**Beschreibung:** Persönliche Noten können optional über Cloud-Dienste (OneDrive, Dropbox) synchronisiert werden, um auf mehreren Geräten verfügbar zu sein.

**User Stories:**
- Als Musiker möchte ich meine persönlichen Noten über OneDrive/Dropbox synchronisieren, damit ich sie auf Handy und Tablet habe.

**Akzeptanzkriterien:**
- [ ] Integration mit OneDrive und Dropbox (OAuth2-Authentifizierung)
- [ ] Bidirektionale Synchronisation
- [ ] Konfliktbehandlung bei gleichzeitiger Änderung
- [ ] Sync-Status sichtbar pro Datei
- [ ] Manuelles Auslösen der Synchronisation möglich
- [ ] Konfiguration des Cloud-Dienstes in den persönlichen Einstellungen

**Priorität:** Could (Meilenstein 3)

---

### D7 — Tools

#### F7.1 Stimmgerät (Tuner)

**Beschreibung:** Integriertes chromatisches Stimmgerät, das über das Gerätemikrofon den gespielten Ton erkennt und die Abweichung vom Soll-Ton anzeigt.

**User Stories:**
- Als Musiker möchte ich mein Instrument in der App stimmen können, ohne ein separates Stimmgerät zu benötigen.

**Akzeptanzkriterien:**
- [ ] Chromatische Tonerkennung über Mikrofon
- [ ] Anzeige: Erkannter Ton, Abweichung in Cent, visuelles Feedback (zu hoch/zu tief)
- [ ] Kammerton (A4) einstellbar (Standard: 442 Hz, konfigurierbar 430–450 Hz)
- [ ] Transposition einstellbar (für Bb, Eb, F-Instrumente etc.)
- [ ] Niedrige Latenz (<100ms Update-Rate)
- [ ] Funktioniert offline

**Priorität:** Could (Meilenstein 3)

---

#### F7.2 Echtzeit-Klick / Metronom

**Beschreibung:** Ein Metronom, dessen Taktschlag in Echtzeit bei allen verbundenen Musikern synchron angezeigt wird. Erfordert minimale Latenz für musikalische Präzision.

**User Stories:**
- Als Dirigent möchte ich einen Klick starten, den alle Musiker gleichzeitig sehen/hören.
- Als Musiker möchte ich den synchronen Klick als visuelles und/oder akustisches Signal empfangen.

**Akzeptanzkriterien:**
- [ ] Tempo einstellbar (BPM: 30–300)
- [ ] Taktart einstellbar (z.B. 4/4, 3/4, 6/8)
- [ ] Visuelles Feedback (Puls, Lichtblitz) und akustisches Signal
- [ ] Synchronisation über alle verbundenen Geräte
- [ ] Maximale Latenz zwischen Geräten: <20ms (Zielwert)
- [ ] Funktioniert über lokales Netzwerk (WiFi)
- [ ] Optional: Internet-basierter Fallback (höhere Latenz akzeptabel)
- [ ] Dirigent kontrolliert Start/Stop/Tempo

**Priorität:** Could (Meilenstein 3)

**Technologie-Optionen (zu evaluieren):**

| Technologie | Latenz | Reichweite | Anforderung |
|-------------|--------|-----------|-------------|
| WiFi UDP Broadcast | ~1–5ms | Lokales Netzwerk | Gleicher Router |
| Bluetooth LE | ~5–20ms | ~30m | Bluetooth-fähig |
| WebRTC | ~10–50ms | Internet | Browser-Support |
| WebSockets | ~20–100ms | Internet | Server nötig |

**Architektur-Empfehlung:** Primär WiFi UDP für Proben/Konzerte (niedrigste Latenz), WebSocket/WebRTC als Fallback für Remote-Szenarien. Clock-Synchronisation via NTP-ähnlichem Protokoll.

---

### D8 — Lehre-Modul

#### F8.1 Lehrer-/Schüler-Rollen

**Beschreibung:** Zusätzliche Rollen für den Musikunterricht. Lehrer können Noten für Schüler freischalten und Lernpfade erstellen.

**User Stories:**
- Als Lehrer möchte ich Schüler anlegen und ihnen gezielt Noten freischalten können.
- Als Schüler möchte ich nur die Noten sehen, die mein Lehrer für mich freigeschaltet hat.

**Akzeptanzkriterien:**
- [ ] Rolle "Lehrer" mit Schüler-Verwaltung
- [ ] Rolle "Schüler" mit eingeschränktem Zugriff
- [ ] Lehrer kann Stücke pro Schüler freischalten
- [ ] Lehrer kann Freigeschaltetes wieder sperren
- [ ] Schüler sieht nur freigeschaltete Stücke

**Priorität:** Could (Meilenstein 4)

---

#### F8.2 Lernpfade

**Beschreibung:** Lehrer können strukturierte Lernpfade erstellen — geordnete Abfolgen von Stücken und Übungen, die Schüler durcharbeiten.

**User Stories:**
- Als Lehrer möchte ich einen Lernpfad mit aufeinander aufbauenden Stücken erstellen.
- Als Schüler möchte ich meinen Fortschritt im Lernpfad sehen.

**Akzeptanzkriterien:**
- [ ] Lernpfad erstellen mit Titel, Beschreibung, geordneten Stücken
- [ ] Stücke werden stufenweise freigeschaltet (sequenziell oder manuell durch Lehrer)
- [ ] Fortschrittsanzeige für Schüler
- [ ] Lehrer kann Fortschritt des Schülers einsehen
- [ ] Lernpfade können dupliziert und angepasst werden

**Priorität:** Could (Meilenstein 4)

---

### D9 — AI-Integration

#### F9.1 AI-Architektur

**Beschreibung:** Die AI-Integration ist als austauschbarer Service konzipiert. Verschiedene AI-Provider können per Adapter angebunden werden.

**Architektur:**

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Upload-Flow   │────▶│  AI-Service      │────▶│  AI-Provider    │
│                 │     │  (Abstraktion)   │     │  (Adapter)      │
│  Bild/PDF       │     │                  │     │                 │
│  hochladen      │     │  - extractMeta() │     │  - Azure Vision │
│                 │     │  - detectLines() │     │  - OpenAI GPT-V │
│                 │     │  - rotateImage() │     │  - Google Vision │
│                 │     │                  │     │  - Custom       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

**Konfiguration:**
- Pro User: eigener API-Key → nutzt eigenen Account
- Pro Kapelle: zentraler Key → Administrator verwaltet
- Fallback-Kette: User-Key → Kapellen-Key → keine AI
- Rate-Limiting pro Key konfigurierbar

**Priorität:** Must (MVP, grundlegende Erkennung), Could (erweiterte Features in Meilenstein 5)

---

## 4. Datenmodell

### 4.1 Entity-Relationship-Übersicht

```
┌──────────┐    N:M     ┌───────────────┐    1:N     ┌──────────┐
│  Musiker  │◄──────────▶│ Mitgliedschaft │──────────▶│  Kapelle  │
│           │            │ (+ Rollen)     │           │           │
└────┬──────┘            └───────────────┘           └────┬──────┘
     │                                                     │
     │ 1:N                                                 │ 1:N
     ▼                                                     ▼
┌──────────────┐                                   ┌──────────────┐
│ Instrument-  │                                   │    Stück      │
│ Profil       │                                   │ (Musikstück)  │
└──────────────┘                                   └────┬──────────┘
                                                        │ 1:N
                                                        ▼
                                                   ┌──────────────┐
                                                   │   Stimme      │
                                                   │ (Voice/Part)  │
                                                   └────┬──────────┘
                                                        │ 1:N
                                                        ▼
                                                   ┌──────────────┐
                                                   │  Notenblatt   │
                                                   │ (Seite/Bild)  │
                                                   └──────────────┘
```

### 4.2 Kern-Entitäten

| Entität | Beschreibung | Wichtige Attribute |
|---------|-------------|-------------------|
| **Musiker** | Benutzer der App | ID, Name, E-Mail, Passwort-Hash, Profilbild, Einstellungen |
| **Kapelle** | Musikverein/Orchester | ID, Name, Logo, Beschreibung, Einstellungen, AI-Konfiguration |
| **Mitgliedschaft** | Verbindung Musiker↔Kapelle | ID, Musiker-ID, Kapelle-ID, Rollen[], Beitrittsdatum, Status |
| **Instrument** | Stammdaten Instrumente | ID, Name, Kategorie (Holz, Blech, Schlag), Transposition |
| **InstrumentProfil** | Instrumente eines Musikers | ID, Musiker-ID, Instrument-ID, Standardstimme, Reihenfolge |
| **Stück** | Musikstück/Lied | ID, Kapelle-ID (oder Musiker-ID bei persönlich), Titel, Interpret, Tonart, Tempo, Genre, Tags |
| **Stimme** | Eine Stimme eines Stücks | ID, Stück-ID, Instrument-ID, Bezeichnung (z.B. "2. Klarinette"), Sortierung |
| **Notenblatt** | Einzelne Seite | ID, Stimme-ID, Seitennummer, Bild-URL, Rotation, Zoom-Einstellungen |
| **Annotation** | Markierung auf einem Notenblatt | ID, Notenblatt-ID, Musiker-ID, Typ, Daten (JSON), Sichtbarkeit (lokal/stimme/orchester), Stimme-ID |
| **Setlist** | Stücke-Zusammenstellung | ID, Kapelle-ID, Titel, Beschreibung, Erstelldatum |
| **SetlistEintrag** | Stück in einer Setlist | ID, Setlist-ID, Stück-ID, Position |
| **Termin** | Kalender-Eintrag | ID, Kapelle-ID, Typ (Probe/Konzert/Fest/Sonstig), Titel, Datum, Ort, Beschreibung |
| **Teilnahme** | Zu-/Absage für Termin | ID, Termin-ID, Musiker-ID, Status (zugesagt/abgesagt/offen), Kommentar |
| **Fest** | Veranstaltung mit Schichten | ID, Termin-ID, Beschreibung |
| **Schicht** | Arbeitsschicht auf einem Fest | ID, Fest-ID, Bezeichnung, Startzeit, Endzeit, Soll-Anzahl |
| **SchichtZuteilung** | Zuweisung Musiker↔Schicht | ID, Schicht-ID, Musiker-ID, Status |
| **AIKonfiguration** | AI-Zugang | ID, Typ (user/kapelle), Owner-ID, Provider, API-Key (verschlüsselt), Einstellungen |
| **Lernpfad** | Geführter Lernweg | ID, Lehrer-ID, Titel, Beschreibung |
| **LernpfadSchritt** | Stück in einem Lernpfad | ID, Lernpfad-ID, Stück-ID, Position, Freigeschaltet |
| **LernpfadZuweisung** | Schüler↔Lernpfad | ID, Lernpfad-ID, Schüler-ID, Fortschritt |

---

## 5. Rollen & Berechtigungsmatrix

### 5.1 Kapellen-Rollen

| Berechtigung | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|-------------|:-----:|:--------:|:---------:|:-------------:|:-------:|
| Kapelle verwalten | ✅ | ❌ | ❌ | ❌ | ❌ |
| Mitglieder einladen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Rollen zuweisen | ✅ | ❌ | ❌ | ❌ | ❌ |
| AI-Konfiguration | ✅ | ❌ | ❌ | ❌ | ❌ |
| Noten hochladen (Kapelle) | ✅ | ✅ | ✅ | ❌* | ❌* |
| Noten löschen (Kapelle) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Noten ansehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Setlist erstellen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Setlist ansehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Termin erstellen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Termin ansehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Zu-/Absage | ✅ | ✅ | ✅ | ✅ | ✅ |
| Schichten verwalten | ✅ | ❌ | ❌ | ❌ | ❌ |
| Schicht eintragen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Annotation (lokal) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Annotation (stimme) | ✅ | ✅ | ❌ | ✅ | ❌ |
| Annotation (orchester) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Register verwalten | ✅ | ❌ | ❌ | ✅ | ❌ |

\* Konfigurierbar: Upload-Berechtigung kann auf weitere Rollen ausgeweitet werden.

### 5.2 Lehre-Rollen

| Berechtigung | Lehrer | Schüler |
|-------------|:------:|:-------:|
| Schüler verwalten | ✅ | ❌ |
| Noten freischalten | ✅ | ❌ |
| Lernpfad erstellen | ✅ | ❌ |
| Lernpfad ansehen | ✅ | ✅ |
| Freigeschaltete Noten nutzen | ✅ | ✅ |
| Fortschritt markieren | ❌ | ✅ |

### 5.3 Persönliche Sammlung

Jeder Musiker hat volle Kontrolle über seine persönliche Sammlung (Upload, Löschen, Annotation, Cloud-Sync).

---

## 6. API-Struktur

### 6.1 Architektur-Prinzipien

- RESTful API mit JSON
- Versionierung: `/api/v1/...`
- Authentifizierung: JWT (Bearer Token)
- Rate-Limiting pro API-Key/User
- Pagination: Cursor-basiert für Listen
- HATEOAS für Navigierbarkeit (optional, für spätere Erweiterung)

### 6.2 API-Gruppen

```
/api/v1/
├── auth/
│   ├── POST   /register
│   ├── POST   /login
│   ├── POST   /refresh
│   └── POST   /logout
│
├── users/
│   ├── GET    /me
│   ├── PUT    /me
│   ├── GET    /me/instruments
│   ├── PUT    /me/instruments
│   └── PUT    /me/ai-config
│
├── kapellen/
│   ├── POST   /                        (Kapelle erstellen)
│   ├── GET    /                        (Meine Kapellen)
│   ├── GET    /:id
│   ├── PUT    /:id
│   ├── GET    /:id/members
│   ├── POST   /:id/members/invite
│   ├── PUT    /:id/members/:memberId
│   ├── DELETE /:id/members/:memberId
│   ├── PUT    /:id/ai-config
│   │
│   ├── /stuecke/                       (Stücke/Noten)
│   │   ├── GET    /
│   │   ├── POST   /
│   │   ├── GET    /:stueckId
│   │   ├── PUT    /:stueckId
│   │   ├── DELETE /:stueckId
│   │   └── GET    /:stueckId/stimmen
│   │
│   ├── /stimmen/                       (Stimmen)
│   │   ├── POST   /                    (Upload)
│   │   ├── GET    /:stimmeId
│   │   ├── GET    /:stimmeId/blaetter  (Notenblätter)
│   │   └── POST   /:stimmeId/blaetter  (Seiten hinzufügen)
│   │
│   ├── /setlists/
│   │   ├── GET    /
│   │   ├── POST   /
│   │   ├── GET    /:setlistId
│   │   ├── PUT    /:setlistId
│   │   ├── DELETE /:setlistId
│   │   └── PUT    /:setlistId/eintraege
│   │
│   ├── /termine/
│   │   ├── GET    /
│   │   ├── POST   /
│   │   ├── GET    /:terminId
│   │   ├── PUT    /:terminId
│   │   ├── DELETE /:terminId
│   │   ├── POST   /:terminId/teilnahme
│   │   └── GET    /:terminId/teilnahmen
│   │
│   └── /feste/
│       ├── POST   /
│       ├── GET    /:festId
│       ├── POST   /:festId/schichten
│       ├── PUT    /:festId/schichten/:schichtId
│       └── POST   /:festId/schichten/:schichtId/eintragen
│
├── sammlung/                           (Persönliche Sammlung)
│   ├── GET    /stuecke
│   ├── POST   /stuecke
│   ├── GET    /stuecke/:id
│   ├── PUT    /stuecke/:id
│   ├── DELETE /stuecke/:id
│   └── POST   /sync                   (Cloud-Sync auslösen)
│
├── annotationen/
│   ├── POST   /                        (Annotation erstellen)
│   ├── PUT    /:id
│   ├── DELETE /:id
│   └── GET    /blatt/:blattId          (Alle Annotationen für ein Blatt)
│
├── ai/
│   ├── POST   /analyze                 (Bild analysieren)
│   ├── GET    /status/:jobId           (Job-Status)
│   └── GET    /providers               (Verfügbare Provider)
│
├── tools/
│   ├── WS     /metronom                (WebSocket für Echtzeit-Klick)
│   └── GET    /tuner/config            (Tuner-Konfiguration)
│
└── lehre/
    ├── GET    /schueler
    ├── POST   /schueler/:id/freischalten
    ├── GET    /lernpfade
    ├── POST   /lernpfade
    ├── GET    /lernpfade/:id
    ├── PUT    /lernpfade/:id
    └── PUT    /lernpfade/:id/fortschritt
```

---

## 7. Plattform & Technologie

### 7.1 Zielplattformen

| Plattform | Anforderung | Details |
|-----------|------------|---------|
| **Web (Browser)** | Must | Chrome, Firefox, Safari, Edge (aktuelle 2 Versionen) |
| **Mobile App (iOS)** | Must | iOS 16+ (iPhone & iPad) |
| **Mobile App (Android)** | Must | Android 12+ (Smartphone & Tablet) |
| **Desktop** | Should | Windows 10+, macOS 12+ (kann PWA oder Electron sein) |

### 7.2 Touch-Support

Touch-Unterstützung ist **Pflicht** auf allen Plattformen:
- Swipe für Seitennavigation
- Pinch-to-Zoom für Notenansicht
- Drag & Drop für Sortierung (mit Touch-Fallback: Long-Press + Drag)
- Stift-Unterstützung für Annotationen (Apple Pencil, Surface Pen, S Pen)
- Touch-Zonen für den Fokus-Modus

### 7.3 Responsive Design

- Breakpoints: Mobile (<768px), Tablet (768–1024px), Desktop (>1024px)
- Orientierung: Portrait und Landscape (insbesondere wichtig für Notenansicht)
- Adaptive Layouts: Unterschiedliche Ansichten je nach Geräteklasse

### 7.4 Technologie-Stack (Empfehlung)

> Stack-Entscheidung noch offen. Empfehlung folgt nach Evaluierung.

**Kriterien für Stack-Wahl:**
- Cross-Platform Code-Sharing maximieren
- Native Performance für Tuner und Metronom
- Offline-Fähigkeit
- Touch- und Stift-Support
- Bestehende Libraries für Audio-Processing

---

## 8. Offline-Fähigkeit

### 8.1 Anforderungen

| Feature | Offline-Verfügbar | Sync bei Verbindung |
|---------|:-----------------:|:-------------------:|
| Noten ansehen (heruntergeladen) | ✅ | — |
| Fokus-Modus | ✅ | — |
| Annotationen (lokal) | ✅ | ✅ |
| Annotationen (stimme/orchester) | ✅ (lokal cachen) | ✅ |
| Noten hochladen | ❌ (Queue) | ✅ |
| AI-Erkennung | ❌ | ✅ |
| Setlist ansehen | ✅ (wenn gecacht) | ✅ |
| Termine ansehen | ✅ (wenn gecacht) | ✅ |
| Zu-/Absage | ✅ (Queue) | ✅ |
| Tuner | ✅ | — |
| Metronom (lokal) | ✅ | — |
| Metronom (sync) | ❌ | — |

### 8.2 Sync-Strategie

- **Offline-First:** App funktioniert primär lokal, synchronisiert bei Verbindung
- **Conflict Resolution:** Last-Write-Wins für einfache Daten, Merge für Annotationen
- **Download-Management:** Nutzer wählt, welche Stücke/Setlists offline verfügbar sein sollen
- **Speicher-Management:** Anzeige des genutzten Speicherplatzes, Möglichkeit zum Freigeben

---

## 9. Annotationssystem — Architektur

### 9.1 Datenstruktur

```json
{
  "id": "uuid",
  "notenblattId": "uuid",
  "musikerId": "uuid",
  "stimmeId": "uuid",
  "sichtbarkeit": "lokal | stimme | orchester",
  "typ": "freihand | text | symbol | highlight | streichung",
  "daten": {
    "punkte": [[x1,y1], [x2,y2], ...],
    "farbe": "#FF0000",
    "strichstaerke": 2,
    "text": "optional",
    "symbol": "optional (crescendo, decrescendo, atemzeichen, ...)"
  },
  "position": { "x": 0.5, "y": 0.3 },
  "erstelltAm": "ISO-8601",
  "geaendertAm": "ISO-8601"
}
```

### 9.2 Sichtbarkeitslogik

1. **Lokal:** Gespeichert auf dem Gerät und im User-Account. Nur der Ersteller sieht sie.
2. **Stimme:** Synchronisiert an alle Musiker, die derselben Stimme zugeordnet sind. Ersteller und Stimme werden gespeichert.
3. **Orchester:** Sichtbar für alle Mitglieder der Kapelle. Nur Dirigent und Administrator dürfen diese erstellen.

### 9.3 Rendering

- Annotationen als SVG-Layer über dem Notenbild
- Positionsangaben relativ (Prozent), nicht absolut (Pixel) → skalierbar
- Sichtbarkeitsebenen können einzeln ein-/ausgeblendet werden

---

## 10. Echtzeit-Synchronisation (Metronom)

### 10.1 Architektur

```
┌──────────────┐    Start/Stop/Tempo    ┌──────────────────┐
│  Dirigent     │──────────────────────▶│  Sync-Server      │
│  (Controller) │                       │  (Clock-Master)   │
└──────────────┘                       └────────┬──────────┘
                                                │ Broadcast
                                    ┌───────────┼───────────┐
                                    ▼           ▼           ▼
                              ┌──────────┐ ┌──────────┐ ┌──────────┐
                              │ Musiker 1│ │ Musiker 2│ │ Musiker N│
                              └──────────┘ └──────────┘ └──────────┘
```

### 10.2 Synchronisations-Protokoll

1. **Clock-Sync:** Vor Session-Start wird eine Clock-Synchronisation durchgeführt (NTP-ähnlich)
2. **Beat-Timing:** Beats werden als Timestamps der Master-Clock gesendet, nicht als "jetzt spielen"-Kommandos
3. **Local Playback:** Jeder Client berechnet den nächsten Beat aus dem empfangenen Timing + lokaler Clock-Korrektur
4. **Adaptive Latency:** Client misst RTT zum Server und kompensiert

### 10.3 Netzwerk-Modi

- **Lokal (WiFi):** UDP Multicast für minimale Latenz
- **Remote (Internet):** WebSocket mit Clock-Sync
- **Standalone:** Lokales Metronom ohne Sync (offline)

---

## 11. Internationalisierung (i18n)

### 11.1 Strategie

- **Phase 1 (MVP):** Deutsch als einzige Sprache. Alle UI-Strings in i18n-Ressourcen-Dateien (kein Hardcoding).
- **Phase 2 (später):** Englisch als zweite Sprache
- **Phase 3 (optional):** Community-basierte Übersetzungen

### 11.2 Architektur

- Alle UI-Texte über Key-Value-Ressourcen (z.B. JSON-Dateien pro Sprache)
- Datums-/Uhrzeitformate über Locale
- Pluralisierung unterstützt
- RTL-Unterstützung nicht für MVP geplant
- API-Antworten: Sprachunabhängig (IDs, Codes), UI-Texte nur im Client

---

## 12. Sicherheit & Datenschutz

### 12.1 Authentifizierung

- Registrierung mit E-Mail und Passwort
- Passwort-Anforderungen: Min. 8 Zeichen, Komplexitätsregeln
- JWT für API-Authentifizierung (Access Token + Refresh Token)
- Optional: Social Login (Google, Apple) in späterem Meilenstein
- Optional: 2FA (TOTP) für Administratoren

### 12.2 Datenschutz (DSGVO)

- Datensparsamkeit: Nur notwendige Daten erheben
- Einwilligung für AI-Verarbeitung (Noten werden an Drittanbieter gesendet)
- Recht auf Datenlöschung: Account und alle Daten löschbar
- Datenexport: Eigene Daten als ZIP exportierbar
- Datenschutzerklärung und Nutzungsbedingungen
- Datenverarbeitung in der EU (oder EU-konforme Verträge)

### 12.3 Datensicherheit

- Verschlüsselung in Transit: TLS 1.3
- Verschlüsselung at Rest: AES-256 für sensible Daten (API-Keys, Passwörter)
- API-Keys werden nie im Klartext gespeichert
- RBAC (Role-Based Access Control) auf API-Ebene
- Input-Validierung und Sanitization
- Rate-Limiting gegen Brute-Force und Abuse
- CORS korrekt konfiguriert
- CSP (Content Security Policy) für Web

### 12.4 Notenblatt-Urheberrecht

- Hinweis in der App: Nutzer ist für die Rechtmäßigkeit der hochgeladenen Noten verantwortlich
- Kein öffentliches Teilen von Noten (nur innerhalb der Kapelle)
- Wasserzeichen-Option für hochgeladene Noten (optional, später)

---

## 13. Code Review Policy

Gemäß Directive von Thomas:

- Alle Code-Änderungen werden von **3 verschiedenen Reviewern** geprüft:
  1. Claude Sonnet 4.6
  2. Claude Opus 4.6
  3. GPT 5.4
- **Lead (Stark)** überprüft die Reviews und entscheidet über:
  - Umsetzung (sofort)
  - Verschiebung (späterer Meilenstein)
  - Verwerfung (mit Begründung)

---

## 14. Nicht-funktionale Anforderungen

| Kategorie | Anforderung | Zielwert |
|-----------|------------|----------|
| **Performance** | Seitenwechsel im Spielmodus | <100ms |
| **Performance** | App-Start (Cold Start) | <3s |
| **Performance** | Noten-Upload (10 Seiten) | <30s |
| **Verfügbarkeit** | Uptime | 99.5% |
| **Skalierbarkeit** | Gleichzeitige Nutzer pro Kapelle | 200+ |
| **Skalierbarkeit** | Stücke pro Kapelle | 10.000+ |
| **Accessibility** | WCAG 2.1 Level AA | Basis-Konformität |
| **Speicher** | Offline-Cache pro Gerät | Konfigurierbar, Standard 1 GB |

---

*Dieses Dokument wird fortlaufend ergänzt und ist die verbindliche Referenz für die Implementierung.*
