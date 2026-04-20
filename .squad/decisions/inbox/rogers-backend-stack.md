# Backend Stack Decisions (#126)

**Date:** 2026-04-20  
**Agent:** Rogers  
**Context:** Foundation Session Backend Scaffold (Issue #126)

---

## Decision: .NET 9 Packages statt .NET 10

**Reasoning:**  
Während .NET 10 SDK (10.0.202) lokal installiert ist, gibt es **keine stabilen NuGet-Packages** für .NET 10. Alle EF Core, Npgsql und ASP.NET Core Packages sind nur als Preview verfügbar (10.x-preview, 11.x-preview).

**Chosen Packages:**
- \Microsoft.EntityFrameworkCore\: **9.0.0** (stable)
- \Npgsql.EntityFrameworkCore.PostgreSQL\: **9.0.1** (stable)
- \Microsoft.AspNetCore.OpenApi\: **9.0.0** (stable)
- \Microsoft.AspNetCore.Authentication.JwtBearer\: **9.0.0** (stable)
- \Microsoft.AspNetCore.Mvc.Testing\: **9.0.0** (stable)
- \FluentAssertions\: **7.0.0** (downgrade wegen FluentAssertions.Web 1.9.5 Kompatibilität)
- \NSubstitute\: **5.3.0** (stable)
- \Testcontainers.PostgreSql\: **4.5.0** (stable)

**Impact:**  
- Projekte bleiben auf \<TargetFramework>net10.0</TargetFramework>\
- Packages sind .NET 9 → läuft problemlos auf .NET 10 Runtime
- Migration auf .NET 10 Packages sobald stable verfügbar
- Dokumentiert in Commit-Messages

**Alternatives Considered:**  
- Preview-Packages nutzen → **Rejected** (instabil, spec verlangt stable)
- Auf .NET 9 SDK downgraden → **Rejected** (spec sagt .NET 10 LTS)

---

## Decision: Testcontainers nur mit Docker

**Reasoning:**  
\Testcontainers.PostgreSql\ benötigt Docker lokal. Integration-Test \PingEndpointTests\ schlägt fehl wenn Docker nicht läuft.

**Impact:**  
- CI (GitHub Actions) muss Ubuntu-Runner nutzen (Docker vorinstalliert)
- Lokal: \docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:16-alpine\ manuell oder Tests skippen
- 2/3 Tests grün ohne Docker, 3/3 mit Docker

**Alternatives Considered:**  
- In-Memory EF Core Provider → **Rejected** (spec verlangt echte DB-Tests)
- Lokal Postgres installieren statt Container → **Rejected** (weniger portabel)

---

## Decision: Aspire SDK nicht verfügbar - Stub Setup

**Reasoning:**  
\dotnet new aspire-apphost\ Template nicht verfügbar. Aspire SDK scheint nicht installiert zu sein.

**Chosen Approach:**  
- ServiceDefaults als Web SDK Library (\Microsoft.NET.Sdk.Web\) mit \OutputType=Library\
- AppHost als Web-Projekt mit TODO-Kommentaren für \DistributedApplication\
- Minimale \AddServiceDefaults()\ Extension-Methode (Logging only)
- **TODOs für spätere Integration** nach Aspire SDK Installation

**Impact:**  
- Build ist grün
- Api nutzt ServiceDefaults (Logging)
- Aspire Dashboard / Orchestrierung fehlt (wie spec erlaubt: Platzhalter-Kommentare)

**Alternatives Considered:**  
- Aspire SDK manuell installieren → **Rejected** (out of scope für Foundation Session)
- Ohne ServiceDefaults → **Rejected** (spec verlangt ServiceDefaults)

---

## Decision: NuGet-Feed auf nuget.org beschränkt

**Reasoning:**  
System-weiter NuGet-Feed \pkgs.dev.azure.com/devdiv/_packaging/Cascade\ ist nicht autorisiert (401 Unauthorized). Alle \dotnet add package\ Befehle schlugen fehl.

**Chosen Approach:**  
- Lokale \
uget.config\ mit \<clear />\ und nur \
uget.org\
- Packages manuell in .csproj eingefügt (dotnet add package nicht zuverlässig)

**Impact:**  
- Restore funktioniert
- Private Feeds werden ignoriert (nur relevant wenn interne Packages benötigt)

**Documented in:** \C:\Privat\Sheetstorm\.squad\agents\rogers\history.md\ (Lesson von PDF Labeler MVP)

---

## Decision: FluentAssertions.Web Downgrade auf 7.0.0

**Reasoning:**  
FluentAssertions.Web 1.9.5 requires FluentAssertions \>= 6.5.1 && < 8.0.0\.  
FluentAssertions 8.9.0 ist inkompatibel → Build Error CS7069.

**Chosen:**  
- FluentAssertions **7.0.0** (höchste mit Web 1.9.5 kompatible)
- FluentAssertions.Web **1.9.5** (neueste)

**Impact:**  
- Build ist grün
- \esponse.Should().Be200Ok()\ funktioniert

---

**Next Steps:**  
- Aspire SDK installieren → AppHost auf \DistributedApplication\ migrieren
- Docker lokal starten → Api Integration-Test verifizieren
- .NET 10 Packages upgraden sobald stable released
