# Anforderungen — Notenmanagement-App für Blaskapellen

> Status: Entwurf — weitere Eingaben folgen
> Erfasst: 2026-03-28
> Quelle: Thomas (Produktvision)

---

## 1. Kernfunktion: Notenverwaltung

### 1.1 Zentrale Notenverwaltung
- Noten werden zentral für eine Kapelle verwaltet
- Musiker erhalten ihre eigenen Stimmen auf ihrem Endgerät
- Unterstützung für verschiedene Stimmen pro Musikstück

### 1.1a Stimmenauswahl & Instrument-Profil
- Jeder Musiker spielt ein oder mehrere Instrumente
- **Standardinstrument/-stimme:** Der Musiker legt fest, welche Stimme er standardmäßig spielt (z.B. "2. Klarinette")
- **Automatische Vorauswahl:** Beim Öffnen eines Stücks wird die Standard-Stimme vorausgewählt
- **Fallback-Logik:** Wenn die exakte Stimme nicht vorhanden ist (z.B. nur "Klarinette" statt "2. Klarinette"), wird automatisch auf die nächstliegende Stimme zurückgefallen (z.B. 1. Klarinette)
- **Stimme wechseln:** Der Musiker kann beim Öffnen jederzeit eine andere Stimme auswählen — die Standardstimme ist nur vorausgewählt, nicht erzwungen
- **Mehrere Instrumente:** Der Musiker kann weitere Instrumente angeben, die er spielt
- **Sortierung der Stimm-Auswahl:** Stimmen der eigenen Instrumente erscheinen in der Auswahlliste ganz oben (priorisiert), andere Stimmen darunter

### 1.2 Noten-Upload & Einpflege (Großes Kernproblem)
- **Upload-Formate:** Bilder, PDFs, Kamera-Fotos direkt vom Endgerät
- **Labeling-Prozess:** Ein hochgeladenes Dokument/mehrere Bilder können mehrere Lieder enthalten
  - Vorschaubilder aller hochgeladenen Seiten werden angezeigt
  - Nutzer klickt sich durch und markiert: "noch gleiches Lied" oder "neues Lied beginnt"
  - Zuordnung: Welches Bild/welche Seite gehört zu welchem Lied
- **Metadaten-Erkennung:**
  - AI-basierte Erkennung von Metadaten (Titel, Interpret, Stimme, etc.)
  - Manche Felder (Titel, Interpret, Stimme) können auch manuell eingegeben werden
  - **AI-Technologien:** Vision/OCR-Modelle, z.B. Azure AI Vision, andere Bildererkennungs-APIs
  - Evaluierung der besten Dienste für Notenblatt-Erkennung nötig

### 1.3 AI-Lizenzierung
- **Pro User:** Jeder Nutzer kann eigene AI-API-Keys hinterlegen
- **Pro Kapelle:** Administrator kann AI-Zugang für die gesamte Kapelle konfigurieren
- Nutzer der Kapelle können dann die zentral konfigurierten AI-Dienste nutzen

### 1.4 Berechtigungen für Noteneinpflege
- Nicht jeder Musiker darf Noten für die gesamte Kapelle hinzufügen
- Konfigurierbar: Wer darf Noten zur Kapelle hinzufügen (z.B. Notenwart, Administrator, Dirigent)
- Jeder Musiker kann Noten zu seiner eigenen persönlichen Sammlung hinzufügen

---

## 2. Setlist-Verwaltung

- Erstellung verschiedener Setlists (z.B. für Konzerte, Auftritte, Proben)
- Zusammenstellung aus dem vorhandenen Notenbestand

---

## 3. Multi-Kapellen-Zugehörigkeit

- Ein Musiker kann mehreren Kapellen angehören
- Jede Kapelle hat eigene Noten, Setlists, Verwaltung
- Wechsel zwischen Kapellen in der App

---

## 4. Eigene Notensammlung (Persönlich)

- Jeder Musiker hat eine persönliche Notensammlung
- Funktioniert wie eine "spezielle Kapelle" (gleiche Mechanismen)
- Noten liegen lokal auf dem Gerät
- **ODER** Synchronisation über Cloud-Storage (OneDrive, Dropbox, etc.)
- Synchronisation über verschiedene Geräte hinweg

---

## 5. Vereinsleben & Organisation

### 5.1 Konzertplanung
- Welche Konzerte/Auftritte finden statt
- Wer nimmt an welchem Konzert teil (Zu-/Absage)

### 5.2 Feste & Veranstaltungen
- Arbeitsschichten auf Festen verwalten
- Schichtplanung und -zuweisung

### 5.3 Terminplanung
- Allgemeine Events und Termine
- Kalenderübersicht

---

## 6. Rollen & Berechtigungen

| Rolle | Beschreibung | Berechtigungen |
|-------|-------------|----------------|
| **Administrator** | Vorstand des Vereins | Volle Verwaltung, Konfiguration, AI-Lizenzen |
| **Dirigent** | Musikalisch verantwortlich | Noten verwalten, Setlists erstellen, musikalische Entscheidungen |
| **Notenwart** | Pflegt Noten ein | Noten hochladen, Metadaten pflegen, Labeling |
| **Registerführer** | Verantwortlich für ein Register (z.B. alle Klarinetten) | Register-spezifische Verwaltung |
| **Musiker** | Normales Mitglied | Eigene Noten, Setlists ansehen, Termine, eigene Sammlung |
| **Lehrer** | Musiklehrer (Lehre-Modul) | Noten freischalten, Lernpfade erstellen, Schüler verwalten |
| **Schüler** | Musikschüler (Lehre-Modul) | Freigeschaltete Noten nutzen, Lernpfade durcharbeiten |

---

## 7. Zusätzliche Tools

### 7.1 Stimmgerät (Tuner)
- Integriertes Stimmgerät zum Stimmen des Instruments

### 7.2 Echtzeit-Klick / Metronom (Sync)
- Taktschlag wird in Echtzeit bei allen Musikern gleichzeitig angezeigt
- Erfordert ein effizientes Echtzeitsystem mit minimaler Latenz
- **Mögliche Technologien (zu evaluieren):**
  - Bluetooth Broadcast
  - WiFi Broadcast über UDP
  - WebSockets / WebRTC
  - Weitere Optionen identifizieren und vergleichen
- Synchronisation muss präzise genug für musikalische Zwecke sein

### 7.3 Annotationen & Markierungen in Noten
- Musiker können Notizen, Markierungen, Streichungen etc. in die Noten einfügen
- **Drei Sichtbarkeits-Ebenen:**
  1. **Lokal / Privat:** Nur für den einzelnen Musiker sichtbar
  2. **Stimmen-Sync:** Für alle Musiker derselben Stimme synchronisiert
  3. **Orchester-weit:** Für das gesamte Orchester sichtbar (z.B. Dirigenten-Anweisungen)

### 7.4 Auto-Rotation & Auto-Zoom
- **Auto-Rotation:** Noten werden automatisch so gedreht, dass Notenlinien horizontal sind
- **Auto-Zoom:** Zoom wird automatisch so eingestellt, dass möglichst viel der Noten sichtbar ist und nichts abgeschnitten wird
- Optimale Darstellung auf verschiedenen Bildschirmgrößen

---

## 8. Lehre-Modul (Details folgen)

- Zusätzliche Rollen: **Lehrer** und **Schüler**
- Lehrer kann Noten für Schüler freischalten
- Lehrer kann Lernpfade erstellen (geführte Abfolge von Stücken/Übungen)
- Genauere Spezifikationen folgen später

---

## 9. Offene Fragen / Noch zu klären

- [ ] Welche AI/Vision-Dienste eignen sich am besten für Notenblatt-Erkennung?
- [ ] Genaue Cloud-Storage-Integration (OneDrive, Dropbox, etc.)
- [ ] Offline-Fähigkeit der App?
- [ ] Zielplattformen (iOS, Android, Web, Desktop)?
- [ ] Echtzeit-Klick: Welche Technologie bietet die beste Latenz/Zuverlässigkeit?
- [ ] Lehre-Modul: Detaillierte Spezifikation der Lernpfade
- [ ] Weitere Eingaben von Thomas ausstehend

---

*Dieses Dokument wird fortlaufend ergänzt.*
