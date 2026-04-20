# Squad Decisions

## Active Decisions

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
