# Copilot CLI vom Handy steuern – Setup-Anleitung

> Basierend auf [Tamir Dresher: "Your Copilot CLI on Your Phone"](https://www.tamirdresher.com/blog/2026/02/26/squad-remote-control)  
> Tool: [cli-tunnel](https://github.com/tamirdresher/cli-tunnel) v1.1.0  
> Eingerichtet für das Sheetstorm-Projekt

---

## Was wurde eingerichtet?

Zwei Tools wurden global installiert, die es ermöglichen, Copilot CLI in Echtzeit vom Handy zu bedienen:

| Tool | Version | Zweck |
|------|---------|-------|
| `cli-tunnel` | 1.1.0 | Startet ein PTY-Terminal, streamt es über WebSocket ans Handy |
| `devtunnel` (Microsoft Dev Tunnels) | 1.0.1516 | Stellt einen authentifizierten HTTPS-Relay-Tunnel bereit – ohne offene Ports |

**Wie es funktioniert:**  
`cli-tunnel` startet Copilot CLI in einem Pseudo-Terminal (PTY). Die vollständige Terminal-Ausgabe – inklusive ANSI-Farben, Diff-Ansichten und interaktiven Prompts – wird über WebSocket gestreamt und im Browser des Handys durch `xterm.js` pixelgenau dargestellt. Die Verbindung läuft über Microsoft Dev Tunnels und ist **nur für dein Microsoft/GitHub-Konto** zugänglich.

---

## Einmalige Einrichtung (einmalig nötig!)

### 1. devtunnel authentifizieren

Öffne ein Terminal und führe aus:

```powershell
devtunnel user login
```

Ein Browser öffnet sich. Melde dich mit deinem **Microsoft- oder GitHub-Konto** an.  
Das ist **einmalig** nötig – danach bleibt die Session gespeichert.

---

## Copilot CLI vom Handy starten

### Methode 1 – Direkter Start (empfohlen)

```powershell
cli-tunnel copilot --yolo
```

oder mit einem bestimmten Modell:

```powershell
cli-tunnel copilot --model claude-sonnet-4 --yolo
```

### Methode 2 – Convenience-Skript

Im Projektverzeichnis liegt ein fertiges Skript:

```powershell
.\scripts\start-remote-copilot.ps1
```

### Was passiert nach dem Start?

1. `cli-tunnel` startet Copilot CLI im Hintergrund
2. Ein **devtunnel-URL** und ein **QR-Code** erscheinen im Terminal
3. Scanne den QR-Code mit dem Handy **oder** öffne die URL im Handy-Browser
4. Beim ersten Zugriff erscheint eine Microsoft-Sicherheitsseite – einmal bestätigen
5. Das vollständige Copilot CLI Terminal erscheint auf dem Handy!

---

## Bedienung auf dem Handy

| Element | Funktion |
|---------|----------|
| Terminal-Bereich | Vollständiges Copilot CLI – Eingaben möglich |
| Key Bar (unten) | ↑ ↓ → ← Tab Enter Esc Ctrl+C |
| ⏺ Aufnahme-Button | Terminal-Session als .webm Video aufzeichnen |
| Sessions-Button | Alle aktiven cli-tunnel Sessions anzeigen |

**Tipp:** Handy im Querformat drehen für breiteres Terminal.

---

## Sessions-Dashboard (Hub Mode)

Mehrere Sessions gleichzeitig verwalten:

```powershell
cli-tunnel
```

(Ohne Befehl gestartet öffnet das Hub-Dashboard – alle aktiven Sessions auf allen Geräten werden angezeigt.)

---

## Sicherheit

- **Privat by default**: Nur dein Microsoft/GitHub-Konto kann die Session öffnen
- **Keine offenen Ports**: Nur ausgehende HTTPS-Verbindungen
- **Kein zentraler Server**: Der Tunnel läuft über Microsofts Infrastruktur
- **Audit-Log**: Alle Remote-Eingaben werden geloggt in `~/.cli-tunnel/audit/`
- **Automatisches Ablaufen**: Sessions laufen nach 4 Stunden ab

---

## Session beenden

- Im Terminal: **Ctrl+C** drücken (beendet Copilot CLI und den Tunnel)
- Alternativ im PowerShell: Das Fenster schließen

---

## Troubleshooting

| Problem | Lösung |
|---------|--------|
| `devtunnel not recognized` | Neues Terminal öffnen (PATH wurde aktualisiert) |
| devtunnel-Authentifizierung abgelaufen | `devtunnel user login` erneut ausführen |
| QR-Code nicht lesbar | URL aus Terminal kopieren und manuell im Handy-Browser öffnen |
| Erste Seite zeigt Microsoft-Warnung | Einmal bestätigen – nur beim ersten Zugriff pro Tunnel |
| Terminal zu schmal auf Handy | Handy drehen (Querformat) |

---

## Relevante Links

- 📖 [Artikel: Tamir Dresher – Your Copilot CLI on Your Phone](https://www.tamirdresher.com/blog/2026/02/26/squad-remote-control)
- 🔧 [cli-tunnel auf GitHub](https://github.com/tamirdresher/cli-tunnel)
- 🔐 [Microsoft Dev Tunnels Dokumentation](https://aka.ms/devtunnels/doc)
