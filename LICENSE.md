# Sheetstorm — License

Copyright © 2026 Sheetstorm contributors.

This is the license header for the **Sheetstorm application code** that lives
in this repository (everything *except* the contents of `docker/audiveris/`,
which is licensed separately, see below).

## Sheetstorm application code

The Sheetstorm application — Backend (.NET / Blazor / EF Core), Frontend
assets, Domain model, mobile wrapper, documentation, build scripts — is
licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0-only).

See [LICENSE.AGPL.txt](./LICENSE.AGPL.txt) for the full license text.

> **Why AGPL?**
> Sheetstorm uses [Audiveris](https://github.com/Audiveris/audiveris), an
> AGPL-3.0 OMR engine, in a separate sidecar container. Although the FSF's
> guidance on `at-arms-length` communication suggests Sheetstorm itself is
> not a derivative work of Audiveris when it only talks to it via HTTP, we
> license the whole project under AGPL anyway to keep the licensing story
> simple and to encourage contributions back to the music-association
> open-source ecosystem.

## docker/audiveris/

The contents of `docker/audiveris/` (the Audiveris HTTP wrapper, Dockerfile
and helper scripts) are also licensed **AGPL-3.0-only** and bundle Audiveris
binaries that are themselves AGPL-3.0. See
[`docker/audiveris/LICENSE.AGPL.txt`](./docker/audiveris/LICENSE.AGPL.txt).

## Third-Party Software

A non-exhaustive list of third-party components is in
[THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md).

## Source-Code Availability

If you operate Sheetstorm as a **network service** (e.g. SaaS, internal
self-hosted instance with users beyond the operator), the AGPL requires
that you make the source code of your modified version available to those
users. The simplest way is to keep this repository (or your fork) public
and link to it from your deployed app's footer / imprint.
