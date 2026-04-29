# Audiveris-Container für Sheetstorm
#
# Installiert Audiveris 5.10.2 aus dem offiziellen Ubuntu-.deb und
# stellt einen kleinen FastAPI-Server bereit, der POST /recognize annimmt.
#
# Build-Zeit: ~5-10 min (Java + Audiveris + Tesseract). Image-Größe: ~1 GB.
# Erst-Build benötigt Internet, danach ist alles lokal.
#
# Aufruf des CLI: `Audiveris -batch -export -output <dir> <pdf>`
# (Audiveris 5.10 installiert sich nach /opt/audiveris/, Launcher unter
#  /opt/audiveris/bin/Audiveris).

FROM ubuntu:24.04

ARG AUDIVERIS_VERSION=5.10.2
ARG DEBIAN_FRONTEND=noninteractive

# Java + Tesseract + Python + Tools für .deb-Install
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-21-jre-headless \
        tesseract-ocr \
        tesseract-ocr-deu \
        tesseract-ocr-eng \
        tesseract-ocr-fra \
        tesseract-ocr-ita \
        libfreetype6 \
        fontconfig \
        wget \
        ca-certificates \
        python3 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Audiveris .deb herunterladen + extrahieren.
# Wir nutzen `dpkg-deb -x` statt `apt-get install`, weil das post-install-
# Skript des .deb (`xdg-desktop-menu install`) in einer headless Containerumgebung
# fehlschlaegt (kein /usr/share/applications + xdg-utils). Die eigentlichen
# Binaries unter /opt/audiveris werden korrekt entpackt.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libasound2t64 libxrender1 libxtst6 libfontconfig1 dpkg \
    && rm -rf /var/lib/apt/lists/* \
    && wget -q -O /tmp/audiveris.deb \
        "https://github.com/Audiveris/audiveris/releases/download/${AUDIVERIS_VERSION}/Audiveris-${AUDIVERIS_VERSION}-ubuntu24.04-x86_64.deb" \
    && dpkg-deb -x /tmp/audiveris.deb / \
    && rm /tmp/audiveris.deb \
    && ln -sf /opt/audiveris/bin/Audiveris /usr/local/bin/Audiveris \
    && /opt/audiveris/bin/Audiveris -help >/dev/null 2>&1 || true

# Python-Wrapper-Deps
RUN pip3 install --no-cache-dir --break-system-packages \
        flask==3.0.3 \
        waitress==3.0.0

WORKDIR /app
COPY server.py /app/server.py

# TESSDATA_PREFIX wird vom Audiveris-Wrapper benoetigt
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata/
ENV PORT=8080
EXPOSE 8080

# Healthcheck — wartet bis der HTTP-Server antwortet
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q -O- http://127.0.0.1:8080/health || exit 1

CMD ["python3", "/app/server.py"]
