# Third-Party Notices

Sheetstorm uses the following third-party components. Each line contains
the component name, license, and where to find the full license text.

## Server / Backend

| Component | License | Source |
|---|---|---|
| ASP.NET Core / Blazor / EF Core 10 | MIT | https://github.com/dotnet/aspnetcore |
| Microsoft .NET runtime | MIT | https://github.com/dotnet/runtime |
| Npgsql / Npgsql.EntityFrameworkCore | PostgreSQL License | https://github.com/npgsql/npgsql |
| MailKit | MIT | https://github.com/jstedfast/MailKit |
| WebPush (.NET) | MIT | https://github.com/web-push-libs/webpush-csharp |
| PDFtoImage | MIT | https://github.com/sungaila/PDFtoImage |
| SkiaSharp | MIT | https://github.com/mono/SkiaSharp |

## Frontend / Browser libraries

| Component | License | Source |
|---|---|---|
| Bootstrap 5 | MIT | https://github.com/twbs/bootstrap |
| OpenSheetMusicDisplay (OSMD) | BSD-3-Clause | https://github.com/opensheetmusicdisplay/opensheetmusicdisplay |

## Mobile (Capacitor wrapper)

| Component | License | Source |
|---|---|---|
| Capacitor 6 (`@capacitor/core`, `android`, `ios`, `app`, `network`, `preferences`, `push-notifications`) | MIT | https://github.com/ionic-team/capacitor |
| `@capacitor-community/bluetooth-le` | Apache-2.0 | https://github.com/capacitor-community/bluetooth-le |

## OMR Sidecar — `docker/audiveris/`

| Component | License | Source |
|---|---|---|
| **Audiveris** (OMR engine) | **AGPL-3.0-only** | https://github.com/Audiveris/audiveris |
| Tesseract OCR | Apache-2.0 | https://github.com/tesseract-ocr/tesseract |
| Eclipse Temurin (OpenJDK) | GPL-2.0-with-classpath-exception | https://adoptium.net/ |
| Flask | BSD-3-Clause | https://github.com/pallets/flask |
| Waitress | ZPL-2.1 | https://github.com/Pylons/waitress |

> **Audiveris is AGPL-3.0.** This is the reason Sheetstorm itself is
> distributed under AGPL-3.0 — see [LICENSE.md](./LICENSE.md). Operators of
> the Sheetstorm SaaS must make their source code available to users per
> the AGPL network clause.

## Test tooling (dev-only, not shipped)

| Component | License | Source |
|---|---|---|
| Playwright | Apache-2.0 | https://github.com/microsoft/playwright |
| xUnit / FluentAssertions | Apache-2.0 / MIT | https://xunit.net/ |
