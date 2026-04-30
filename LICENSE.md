# Sheetstorm — License

Copyright © 2026 Sheetstorm contributors.

## Sheetstorm application code: Apache License 2.0

The **Sheetstorm application code** (this repository, *except* `docker/audiveris/`)
is licensed under the **Apache License, Version 2.0**.

See [LICENSE-APACHE-2.0.txt](./LICENSE-APACHE-2.0.txt) for the full license text.

This includes:
- Backend (.NET / Aspire / EF Core / ASP.NET Core)
- Frontend (Flutter, Blazor, web assets)
- Mobile wrapper, documentation, build scripts
- **Sheetstorm OMR Engine** in `src/omr-rust/` (our own Rust implementation,
  no Audiveris code, no AGPL dependencies in the produced binary)
- Plugins, tooling, schemas

> **Why we switched from AGPL to Apache-2.0** (2026-04-30)
> Sheetstorm originally was AGPL because it bundled Audiveris (an AGPL OMR
> engine). We have since written our own clean-room Rust OMR engine in
> `src/omr-rust/` that does not derive from Audiveris in any way. The
> Audiveris sidecar is now an *optional* component, kept in `docker/audiveris/`
> for backward compatibility, and is the **only** part of the repository that
> remains AGPL-licensed. The rest of the repo can therefore be Apache-2.0,
> which makes Sheetstorm friendly to any downstream user (commercial, OSS,
> mixed) and lets us reuse permissive third-party code (MIT/Apache/BSD/OFL)
> without licensing issues.

## docker/audiveris/ (optional sidecar — AGPL-3.0)

The contents of `docker/audiveris/` (the Audiveris HTTP wrapper, Dockerfile
and helper scripts) are licensed **AGPL-3.0-only** because they bundle
Audiveris binaries that are AGPL-3.0. See
[`docker/audiveris/LICENSE.AGPL.txt`](./docker/audiveris/LICENSE.AGPL.txt).

If you do not use the Audiveris sidecar (i.e. you rely on the bundled Rust
OMR engine in `src/omr-rust/`), you are free of any AGPL obligation.

## Third-Party Software

A non-exhaustive list of third-party components and their licenses is in
[THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md).

## Apache-2.0 — Quick Notes

- **Patent grant**: Apache-2.0 includes an explicit patent license from contributors.
- **NOTICE file**: If you redistribute Sheetstorm, you must keep the `NOTICE`
  file (if present) and the Apache-2.0 license text.
- **Modifications**: You can modify, sublicense, even commercialize without
  source-code-disclosure obligations.
- **Trademark**: Apache-2.0 does *not* grant you the right to use the
  "Sheetstorm" name or logo in your derivative work.

## Source-Code Availability

We strongly encourage upstreaming improvements (PRs welcome), but Apache-2.0
does not require it.
