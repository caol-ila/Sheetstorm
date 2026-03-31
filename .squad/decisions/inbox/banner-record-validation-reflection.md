# Decision: Model-Validation-Tests für positional Records — Reflection statt Validator

**Von:** Banner (Backend Dev)
**Datum:** 2026-03-30
**Kontext:** Task #109 — MaxLength-Attribute in Request-Modellen

## Entscheidung

Model-Validation-Tests für positional C# Records verwenden **Reflection via PropertyInfo.GetCustomAttribute<T>()**, nicht Validator.TryValidateObject().

## Begründung

Validator.TryValidateObject() verwendet TypeDescriptor.GetProperties(), der Attribute auf positional record constructor parameters nicht vollständig aufnimmt. ASP.NET Core's model binding verwendet hingegen PropertyInfo.GetCustomAttributes() direkt (via ModelAttributes.GetAttributesForProperty). Tests sollten dasselbe Mechanismus verwenden wie die Runtime.

## Alternativen

- [property: StringLength(...)] Syntax: Würde TypeDescriptor-Problem lösen, erfordert aber Änderung aller Domain-Models (50+ Attribute).
- WebApplicationFactory-Integrationstests: Korrekt aber aufwändig für reine Attribut-Presence-Tests.

## Konsequenzen

- Reflection-Tests in Sheetstorm.Tests/Validation/RequestModelValidationTests.cs verifizieren Attribut-Presence.
- Poll-Option-Text-Länge kann nicht als Annotation auf IReadOnlyList<string> gesetzt werden → Service-Level-Validierung in PollService.CreateAsync.
