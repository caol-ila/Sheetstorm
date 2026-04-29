# Audiveris HTTP Wrapper — License

This directory contains:

- **The Audiveris OMR engine** (downloaded at Docker-build time from the
  upstream release). Audiveris is licensed under
  **GNU Affero General Public License v3.0** (AGPL-3.0-only).
  See https://github.com/Audiveris/audiveris and
  [LICENSE.AGPL.txt](./LICENSE.AGPL.txt) for the full text.

- **A small Python HTTP wrapper** (`server.py`) that exposes Audiveris
  through a `/recognize` endpoint. The wrapper is original Sheetstorm code
  but is licensed under the same **AGPL-3.0-only** to make the licensing
  of the resulting container image consistent with Audiveris.

## How Audiveris is integrated into Sheetstorm

- The wrapper image runs as a separate container (Aspire sidecar), reachable
  via HTTP only.
- Sheetstorm's main application code does not link against Audiveris and
  does not include any Audiveris source files.
- The HTTP boundary keeps both projects independent in terms of derivative-
  work analysis, but Sheetstorm chooses AGPL-3.0 for the whole project to
  make the operator's compliance obligations simple.

## Operator Obligations

If you deploy this container as part of a network service:

1. Provide users a link to the source code of the **modified** Audiveris
   (none in our case — we use the upstream release verbatim) and of this
   wrapper (your fork of Sheetstorm).
2. Keep the Sheetstorm app footer link to the source repository visible.
