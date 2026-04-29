# Sheetstorm OMR-Engine — Container für Aspire.
# Build:
#   docker build -t sheetstorm-omr:dev -f docker/sheetstorm-omr/Dockerfile .
# Run (manuell):
#   docker run -p 8091:8091 sheetstorm-omr:dev
#
# Multi-Stage: Rust-Build im Builder, kleines Runtime-Image mit pdfium.

FROM rust:1.95-slim AS builder
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY src/omr-rust/Cargo.toml src/omr-rust/Cargo.lock ./
COPY src/omr-rust/crates ./crates

RUN cargo build --release --bin omr-server

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Pdfium-Binary herunterladen (wird zur Laufzeit benötigt).
RUN curl -sSL https://github.com/bblanchon/pdfium-binaries/releases/latest/download/pdfium-linux-x64.tgz \
    | tar -xz -C /tmp \
    && mv /tmp/lib/libpdfium.so /usr/local/lib/libpdfium.so \
    && ldconfig

WORKDIR /app
COPY --from=builder /build/target/release/omr-server /app/omr-server
ENV OMR_HOST=0.0.0.0
ENV OMR_PORT=8091
ENV OMR_RUST_LOG=info
EXPOSE 8091
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -fsS http://localhost:8091/health || exit 1
CMD ["/app/omr-server"]
