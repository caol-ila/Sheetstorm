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

# CNN-Feature ist OPT-IN: Baue mit `--build-arg ENABLE_CNN=1` um
# tract-onnx-Inferenz für Symbol-Klassifikation zu aktivieren.
ARG ENABLE_CNN=0

# U-Net Staff-Removal ist OPT-IN: Baue mit `--build-arg ENABLE_UNET=1` um
# tract-onnx-Inferenz für Staff-Removal zu aktivieren. Kann zusammen mit
# ENABLE_CNN=1 genutzt werden.
ARG ENABLE_UNET=0

RUN if [ "$ENABLE_CNN" = "1" ] && [ "$ENABLE_UNET" = "1" ]; then \
        cargo build --release --bin omr-server -p omr-server --features "cnn,unet"; \
    elif [ "$ENABLE_CNN" = "1" ]; then \
        cargo build --release --bin omr-server -p omr-server --features cnn; \
    elif [ "$ENABLE_UNET" = "1" ]; then \
        cargo build --release --bin omr-server -p omr-server --features unet; \
    else \
        cargo build --release --bin omr-server -p omr-server; \
    fi

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
# CNN-Modell wird mitkopiert wenn vorhanden (assets-Folder im Repo).
# Wenn ENABLE_CNN=1 gebaut wurde, lädt der Server das Modell beim Start.
COPY src/omr-rust/crates/omr-symbols/assets/cnn-model.onnx /app/cnn-model.onnx
# U-Net Staff-Removal-Modell (optional, muss vor dem Build-Schritt in
# src/omr-rust/crates/omr-staff/assets/staff-unet.onnx abgelegt werden).
# Wenn ENABLE_UNET=1 gebaut wurde und OMR_UNET_MODEL auf eine valide Datei
# zeigt, nutzt die Pipeline U-Net-Removal, sonst klassisches RLE-Removal.
COPY src/omr-rust/crates/omr-staff/assets/ /app/staff-assets/
ENV OMR_HOST=0.0.0.0
ENV OMR_PORT=8091
ENV OMR_RUST_LOG=info
ENV OMR_CNN_MODEL=/app/cnn-model.onnx
ENV OMR_UNET_MODEL=/app/staff-assets/staff-unet.onnx
EXPOSE 8091
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -fsS http://localhost:8091/health || exit 1
CMD ["/app/omr-server"]
