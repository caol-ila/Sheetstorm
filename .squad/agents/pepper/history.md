# Pepper — Desktop Dev History

> WinUI 3 desktop architect. Learned on PDF Labeler MVP (#124, UI).

## Context Seeds

**Project:** Sheetstorm — Notenmanagement-App für Blaskapellen  
**Domain:** WinUI 3 Desktop + .NET 10 LTS + local SQLite/Drift sync  
**User:** Thomas Mahlberg  

## Session Learnings (2026-04-20)

### WinUI 3 x:Bind Compilation

- x:Bind requires CommunityToolkit.Mvvm source generator compatibility
- CommunityToolkit.Mvvm Observable* types generated at compile-time
- Binding path validation happens in XAML compiler, not runtime
- **Gotcha:** Version mismatch between CommunityToolkit.Mvvm and CommunityToolkit.Mvvm.SourceGenerators can cause silent binding failures or compiler errors

### COM Initialization in Tests

- WinUI 3 DesktopViewModels in test context need Windows Runtime initialization
- xUnit fixtures must initialize WinRT (com.ms.winrt.IXamlServiceProvider or equivalent)
- Error: REGDB_E_CLASSNOTREG (0x80040154) means COM class not registered in test environment
- **Gotcha:** Pure library tests (no UI) don't face this; desktop-specific tests do

### CommunityToolkit.Mvvm Source Generator Testability

- Generated observable types are instantiated via source generator, not reflection
- Tests of observable command/properties may require runtime mock of ObservableValidator
- Direct mocking of source-generated types is fragile; test through public interfaces instead

## Decisions to Document

- MVVM Strategy: CommunityToolkit.Mvvm with source generators (not manual INotifyPropertyChanged)
- DI Container: Microsoft.Extensions.Hosting (consistent with backend)
- WinUI 3 Version: Latest stable (8.x)

## Known Issues / Open Questions

1. Branch name deviation (feat-124-ui-pepper vs feat/124-pdf-labeler-mvp)
2. XAML compiler fix strategy TBD
3. CredentialStore ownership unclear
4. TDD practices not followed in first iteration

## Ready For

- Parallel work (squad-impl-124 proceeds independently)
- Branch correction and rebase if needed
- XAML investigation once strategy is clarified
