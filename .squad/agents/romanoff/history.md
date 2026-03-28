# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

## 2026-03-28 — Issue #8: Flutter Frontend Scaffolding

**Branch:** `squad/8-frontend-scaffolding`  
**Commit:** `368db49`

### Was wurde gebaut

Vollständiges Flutter-Projekt-Scaffolding für `sheetstorm_app/`:

**Struktur (Clean Architecture):**
- `lib/core/` — Theme, Design Tokens, Constants, Routing (go_router)
- `lib/features/` — auth, kapelle, noten, spielmodus, config, annotationen
- `lib/shared/` — AppShell (Bottom Nav), Drift-Datenbank, API-Client (dio)

**Design-Token-System** direkt aus ux-design.md:
- `AppColors` — Light/Dark, Config-Ebenen (blau/grün/orange), Annotation-Layer
- `AppSpacing` — Touch-Targets 44px (min) / 64px (Spielmodus), Border-Radius
- `AppTypography` — Inter-Font, 12–72sp Skala
- `AppDurations`/`AppCurves` — Animation-Tokens

**App Shell:** 4 Bottom-Navigation-Tabs (Bibliothek/Setlists/Kalender/Profil), Material 3, Wakelock-Handling im Spielmodus.

**SpielmodusScreen:** Vollbild (SystemUI immersive), asymmetrische Tap-Zonen (40% zurück / 60% weiter), Kontextmenü max. 5 Optionen.

**Drift DB:** Tabellen für Noten, Stimmen, Annotationen, KonfigurationEintraege.

**Verifiizierte Versionen (alle per web_search):**
- Flutter 3.41.5 / Dart 3.11.0, flutter_riverpod 3.3.1, go_router 17.1.0
- dio 5.9.2, drift 2.32.1, pdfrx 2.2.24, flutter_svg 1.1.6, cached_network_image 3.4.1

### Flutter nicht installiert
Flutter-SDK war auf dem Build-Agenten nicht vorhanden → Projekt-Struktur manuell erstellt. `build_runner` muss nach Flutter-Installation ausgeführt werden, um `.g.dart`-Stubs durch echten generierten Code zu ersetzen:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Noch offen (spätere Issues)
- Platform-spezifische Dateien (android/, ios/, windows/) — werden von `flutter create` generiert
- build_runner generierten Code (`.g.dart` sind Stubs)
- Auth-Provider-Implementierung
- Spielmodus: pdfrx-Integration, Half-Page-Turn-Logik
- Annotationen: SVG-Layer-Implementation
- Config: 3-Ebenen-Override-Logik
