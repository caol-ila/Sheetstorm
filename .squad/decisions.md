# Squad Decisions

## Active Decisions

### PDF Raster Rendering with Docnet.Core

**Scope:** PDF → PNG conversion for GPT-4o Vision (#124)  
**Owner:** Rogers (Backend Dev)  
**Status:** ACTIVE (implemented & verified)

Replace text-only `PdfFirstPageRenderer` with **Docnet.Core** for true raster-based PDF rendering.

**Rationale:**
- Text-only approach (PdfPig + SkiaSharp) fails entirely on scanned PDFs (image-only, no text layer)
- Scanned PDFs are the primary real-world use case for Blaskapelle sheet music
- Docnet.Core uses native PDFium renderer with .NET wrapper (MIT license)
- Cross-platform support (Windows, Linux, macOS)
- Aspire-compatible (pure library, containerization-ready)

**Implementation:**
- 300 DPI raster rendering for quality AI vision input
- PNG output via SkiaSharp post-processing
- Vision optimization: Auto-resize to max 1600×1600 px (reduces GPT-4o tokens while preserving readability)
- Proper IDisposable pattern for native PDFium handle cleanup
- Custom PdfRenderingException for corrupted/encrypted PDFs

**Alternatives Considered:**
1. PDFtoImage — viable fallback if Docnet doesn't build on .NET 10
2. PdfSharpCore — GPL license (commercial incompatibility)
3. Ghostscript.NET — AGPL license, requires external install
4. ImageMagick/Magick.NET — heavyweight, licensing complexity

**Consequences:**
- ✅ Handles scanned + digital PDFs (text, graphics, images, fonts)
- ✅ MIT license (no GPL contamination)
- ✅ Cross-platform deployment
- ⚠️ Native PDFium dependency (binaries bundled in NuGet)
- ⚠️ Larger package footprint

**Supersedes:** `rogers-pdf-renderer-approach.md` — text-only approach is obsolete; native raster rendering is now primary path.

---

### WinUI 3 MVVM Stack for PDF Labeler Desktop

**Scope:** Architecture for WinUI 3 Desktop UI (#124, UI-Teil)  
**Owner:** Pepper (Desktop Dev)  
**Status:** ACTIVE (pending approval)

Use **CommunityToolkit.Mvvm** with source generators for Desktop ViewModel architecture.

**Rationale:**
- Consistent with community best practice for WinUI 3 apps
- Source-generated Observable properties eliminate boilerplate
- Integrates cleanly with x:Bind XAML compiler
- Reduces manual INotifyPropertyChanged noise
- DI via Microsoft.Extensions.Hosting (already used in backend)

**Alternatives Considered:**
1. Manual INotifyPropertyChanged — More verbose, but no source generator dependency
2. Prism MVVM — Heavier framework, adds complexity for MVP
3. ReactiveUI — Functional approach, steeper learning curve for team

**Implications:**
- All Desktop ViewModels inherit from ObservableObject (source-generated)
- Test fixtures must handle COM initialization for UI-layer tests
- Version pinning: CommunityToolkit.Mvvm ↔ CommunityToolkit.Mvvm.SourceGenerators must match

**Risks:**
- x:Bind Compilation: Version mismatch between toolkit packages can cause compiler errors
- Test COM Initialization: WinUI 3 tests require Windows Runtime setup
- Source Generator Variability: Generated code depends on exact toolkit version

**Blockers:** XAML x:Bind compiler errors, COM init in Desktop tests, CredentialStore ownership TBD

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
