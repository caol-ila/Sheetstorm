# Audiveris-Container für Sheetstorm
#
# Startet einen kleinen HTTP-Server, der POST /recognize annimmt:
# - Erwartet PDF als multipart/form-data
# - Ruft Audiveris-CLI auf (-batch -export -output)
# - Antwortet mit MusicXML (oder JSON-Fehler)
#
# Größe: ~800 MB (Java + Audiveris). Erst-Build dauert mehrere Minuten.

FROM eclipse-temurin:21-jre-jammy

ARG AUDIVERIS_VERSION=5.6.1

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        unzip \
        python3 \
        python3-pip \
        libfreetype6 \
        fontconfig \
        tesseract-ocr \
        tesseract-ocr-deu \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir flask waitress --break-system-packages

# Audiveris herunterladen + entpacken
WORKDIR /opt
RUN wget -q https://github.com/Audiveris/audiveris/releases/download/${AUDIVERIS_VERSION}/Audiveris-${AUDIVERIS_VERSION}.zip \
    && unzip -q Audiveris-${AUDIVERIS_VERSION}.zip \
    && rm Audiveris-${AUDIVERIS_VERSION}.zip \
    && ln -s /opt/Audiveris-${AUDIVERIS_VERSION}/bin/Audiveris /usr/local/bin/audiveris

WORKDIR /app
COPY server.py /app/server.py

ENV PORT=8080
EXPOSE 8080

CMD ["python3", "/app/server.py"]
