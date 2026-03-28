# Getting Started — Sheetstorm

Quick-start guide for developers joining the Sheetstorm project.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| .NET SDK | 10+ | [dot.net/download](https://dot.net/download) |
| Flutter SDK | 3.35+ | [flutter.dev/get-started](https://flutter.dev/docs/get-started/install) |
| Dart | (bundled with Flutter) | — |
| PostgreSQL | 18+ | [postgresql.org/download](https://www.postgresql.org/download/) |
| PowerShell | 7+ | [github.com/PowerShell/PowerShell](https://github.com/PowerShell/PowerShell) |
| Git | 2.40+ | [git-scm.com](https://git-scm.com/) |

**Optional** (for storage features):
- MinIO — S3-compatible object storage for local dev (`localhost:9000`)

## Setup (One-time)

```powershell
# 1. Clone the repo
git clone https://github.com/<org>/sheetstorm.git
cd sheetstorm

# 2. Run setup (restores deps, installs tools, runs migrations, generates code)
.\setup.ps1
```

The setup script will:
- Verify that `dotnet`, `flutter`, and `dart` are installed
- Restore .NET NuGet packages
- Install `dotnet-ef` as a local tool (if not present)
- Apply EF Core migrations to the PostgreSQL database
- Run `flutter pub get` for the Flutter app
- Run `build_runner` for code generation (Freezed, Riverpod, Drift, JSON serialization)

### Database setup

Make sure PostgreSQL is running with a database and user matching the connection string in `src/Sheetstorm.Api/appsettings.json`:

```
Host=localhost;Port=5432;Database=sheetstorm;Username=sheetstorm;Password=CHANGE_ME
```

Create the database and user if needed:

```sql
CREATE USER sheetstorm WITH PASSWORD 'sheetstorm_dev';
CREATE DATABASE sheetstorm OWNER sheetstorm;
```

## Daily Workflow

```powershell
# Start everything (backend + Flutter app)
.\start.ps1

# Backend only
.\start.ps1 -BackendOnly

# Frontend only (backend already running)
.\start.ps1 -FrontendOnly

# Flutter in Chrome
.\start.ps1 -Web
```

The start script launches the ASP.NET Core backend as a background job, waits for the health check (`/health`), then starts the Flutter app.

## Running Tests

```powershell
# .NET tests (from repo root)
dotnet test Sheetstorm.slnx

# Flutter tests
cd sheetstorm_app
flutter test
```

## Project Structure

```
sheetstorm/
├── src/
│   ├── Sheetstorm.Api/          # ASP.NET Core Web API (entry point)
│   ├── Sheetstorm.Domain/       # Domain models & interfaces
│   ├── Sheetstorm.Infrastructure/ # EF Core, persistence, external services
│   └── Sheetstorm.Tests/        # Backend unit tests
├── tests/
│   └── Sheetstorm.Tests/        # Backend integration tests
├── sheetstorm_app/              # Flutter frontend (Dart)
│   ├── lib/                     # App source code
│   ├── test/                    # Widget & unit tests
│   └── pubspec.yaml             # Dart dependencies
├── docs/                        # Documentation
├── scripts/                     # Utility scripts
├── Sheetstorm.slnx              # .NET solution file
├── Directory.Build.props         # Shared .NET build properties
├── setup.ps1                    # One-time dev setup
└── start.ps1                    # Start backend + frontend
```

### Key layers

- **API** (`Sheetstorm.Api`) — Controllers, middleware, Program.cs configuration
- **Domain** (`Sheetstorm.Domain`) — Entities, value objects, domain services, interfaces
- **Infrastructure** (`Sheetstorm.Infrastructure`) — EF Core DbContext, migrations, repository implementations
- **Flutter App** (`sheetstorm_app`) — Cross-platform UI (web, iOS, Android, desktop)

### Tech stack

- **Backend:** ASP.NET Core 10 (.NET 10 LTS), PostgreSQL 18, EF Core
- **Frontend:** Flutter 3.35 (Dart), Riverpod, Freezed, Drift (SQLite client cache)
- **Realtime:** SignalR (WebSocket), BLE Broadcast (metronome)
- **Auth:** JWT (access + refresh tokens)
- **Storage:** S3-compatible (MinIO for local dev)

## Configuration

The backend uses the standard ASP.NET Core configuration hierarchy:

| File | Purpose | Committed? |
|------|---------|------------|
| `appsettings.json` | Base config (connection strings, JWT defaults) | ✅ |
| `appsettings.Development.json` | Dev overrides (verbose logging) | ✅ |
| `appsettings.Production.json` | Production secrets | ❌ (gitignored) |

Override settings for local dev by editing `appsettings.Development.json` or using .NET user secrets:

```powershell
cd src/Sheetstorm.Api
dotnet user-secrets set "Jwt:Key" "YourLocalDevKeyAtLeast32Characters!!"
```

## Troubleshooting

### `dotnet ef` command not found

Run `dotnet tool restore` from the repo root, or re-run `.\setup.ps1`.

### Database connection refused

Make sure PostgreSQL is running on `localhost:5432` and the `sheetstorm` database exists. Check `appsettings.json` for the connection string.

### Flutter build_runner fails

```powershell
cd sheetstorm_app
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Backend starts but health check fails

Check that migrations have been applied:

```powershell
dotnet ef database update --project src/Sheetstorm.Infrastructure --startup-project src/Sheetstorm.Api
```

### Port already in use

The backend defaults to `https://localhost:5001`. If that port is in use, set a different port:

```powershell
cd src/Sheetstorm.Api
dotnet run --urls "https://localhost:5099"
```
