# sheetstorm_app

Flutter-Frontend für Sheetstorm — Notenmanagement für Blaskapellen.

## Stack

| Komponente | Technologie | Version |
|------------|-------------|---------|
| Framework | Flutter / Dart | 3.41.5 / 3.11.0 |
| State | flutter_riverpod | 3.3.1 |
| Routing | go_router | 17.1.0 |
| HTTP | dio | 5.9.2 |
| Client-DB | drift (SQLite) | 2.32.1 |
| PDF | pdfrx | 2.2.24 |
| UI | flutter_svg, cached_network_image | 1.1.6 / 3.4.1 |
| BLE | flutter_blue_plus | 1.34.5 |

## Ordnerstruktur

```
lib/
├── main.dart
├── core/
│   ├── constants/      app_constants.dart
│   ├── routing/        app_router.dart (go_router)
│   ├── theme/          app_theme.dart, app_colors.dart, app_tokens.dart
│   └── utils/
├── features/
│   ├── auth/           Login
│   ├── kapelle/        Kapellenverwaltung
│   ├── noten/          Bibliothek
│   ├── spielmodus/     Performance-Modus (Vollbild, Half-Page-Turn)
│   ├── config/         3-Ebenen-Konfiguration
│   └── annotationen/   SVG-Annotationen (Privat/Stimme/Orchester)
└── shared/
    ├── database/       Drift-Datenbank
    ├── models/
    ├── services/       API-Client (dio)
    └── widgets/        AppShell (Bottom-Navigation)
```

## Code generieren

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Tests

```bash
flutter test
```
