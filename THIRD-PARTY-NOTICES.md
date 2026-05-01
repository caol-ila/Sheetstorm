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

> **Audiveris is AGPL-3.0** but is now an **optional** sidecar.
> Sheetstorm's main app code is Apache-2.0 (see [LICENSE.md](./LICENSE.md))
> and the bundled Rust OMR engine in `src/omr-rust/` is also Apache-2.0,
> clean-room with no Audiveris derivation. The Audiveris sidecar in
> `docker/audiveris/` remains AGPL-3.0; if you do not deploy that sidecar,
> none of the AGPL obligations apply to your deployment.

## Sheetstorm OMR Engine (`src/omr-rust/`)

| Component | License | Source |
|---|---|---|
| `image` | MIT | https://github.com/image-rs/image |
| `imageproc` | MIT | https://github.com/image-rs/imageproc |
| `rayon` | MIT or Apache-2.0 | https://github.com/rayon-rs/rayon |
| `tracing` | MIT | https://github.com/tokio-rs/tracing |
| `quick-xml` | MIT | https://github.com/tafia/quick-xml |
| `axum` | MIT | https://github.com/tokio-rs/axum |
| `pdfium-render` | Apache-2.0 | https://github.com/ajrcarey/pdfium-render |
| `serde` / `serde_json` | MIT or Apache-2.0 | https://github.com/serde-rs/serde |
| Bravura font (template generation) | SIL OFL 1.1 | https://github.com/steinbergmedia/bravura |

## Test tooling (dev-only, not shipped)

| Component | License | Source |
|---|---|---|
| Playwright | Apache-2.0 | https://github.com/microsoft/playwright |
| xUnit / FluentAssertions | Apache-2.0 / MIT | https://xunit.net/ |

## Optional research datasets (NOT shipped, NOT redistributed)

The following datasets can be **manually** placed by individual developers
into `tests/fixtures/` for local OMR-accuracy benchmarking. They are
**NEVER** included in source distributions, container images, or any
released artifact, because their licenses are incompatible with Apache-2.0.

| Dataset | License | Source |
|---|---|---|
| MUSCIMA++ (MuNG annotations) | **CC-BY-NC-SA 4.0** (NonCommercial) | https://github.com/OMR-Research/muscima-pp |
| CVC-MUSCIMA (page images) | **CC-BY-NC-SA 4.0** (NonCommercial) | http://www.cvc.uab.es/cvcmuscima/ |

> **NonCommercial-Lizenz:** Diese Datensätze dürfen lokal für nicht-kommerzielle
> Forschungs- und Testzwecke verwendet werden, **niemals** aber von Sheetstorm
> redistribuiert werden (weder im Source-Tree, noch in Builds, noch in
> Docker-Images). Versehentliches Einchecken wird durch
> `tests/fixtures/muscima_plus/.gitignore` blockiert. Details:
> `tests/fixtures/muscima_plus/README.md`.
