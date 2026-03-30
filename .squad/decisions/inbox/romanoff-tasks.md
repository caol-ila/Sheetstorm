# Romanoff — Tasks Frontend Decisions

**Date:** 2026-05-01  
**Feature:** Aufgabenverwaltung (MS3)

## Entscheidungen

### 1. API-Endpoint-Struktur: Deutsche vs. Englische Keys

Die Feature-Spec definiert `/api/v1/kapellen/{id}/aufgaben` mit deutschen snake_case JSON-Keys (`kapelle_id`, `titel`, `faellig_am` etc.). Diese sind im Frontend implementiert — konsistent mit events/communication Features. 

**Achtung:** Die Task-Beschreibung für Romanoff nannte `/api/bands/{bandId}/tasks` mit camelCase. Es wurde entschieden, der Feature-Spec (deutsches API) zu folgen, da diese die Backend-Quelle der Wahrheit ist und mit den anderen Features konsistent ist.

→ **Wenn das Backend camelCase verwendet, müssen die fromJson/toJson-Keys im Task-Service angepasst werden.**

### 2. routes.dart: Kein app_router.dart-Eingriff

Routes sind in `features/tasks/routes.dart` definiert und exportieren `taskRoutes`. Die Integration in `app_router.dart` ist noch ausstehend (per Charter-Policy: kein Direkteingriff in router).

### 3. Out-of-scope für diesen Sprint

Folgendes ist gemäß UX-Spec MS3 OUT OF SCOPE und wurde bewusst nicht implementiert:
- Kommentare (Aufgaben-Kommentar-Thread)
- Push-Notifications
- Zuweisung von Mitgliedern im Create/Edit-Formular (Placeholder vorhanden)
- Erinnerungs-Konfiguration

Diese Features sind im Service/Notifier bereits vorbereitet (updateAssignees(), TaskService.updateAssignees()), aber die UI fehlt.
