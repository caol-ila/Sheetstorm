//! `omr-labeler` — CLI + HTTP-Server-Einstieg.
//!
//! Startet einen lokalen axum-Server, scannt im Hintergrund den Filestore
//! nach PDFs, lädt einen optionalen synthetischen Warmup-Corpus und öffnet
//! standardmäßig den Browser auf der UI.

use clap::Parser;
use omr_labeler::active_learning::LabelingQueue;
use omr_labeler::api::{router, AppState};
use omr_labeler::embedding_corpus::EmbeddingState;
use omr_labeler::persistence::LabelDb;
use omr_labeler::pipeline::PipelineState;
use omr_labeler::synthetic_warmup::{load_synthetic_corpus, seed_queue_with_synthetic};
use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;
use tracing::{info, warn};

#[derive(Parser, Debug)]
#[command(name = "omr-labeler", about = "Active-Learning Symbol Labeling Tool for OMR")]
pub struct Cli {
    /// Filestore-Pfad mit den zu labelnden PDFs.
    #[arg(long, default_value = "src/.filestore/parts")]
    pub filestore: PathBuf,
    /// Verzeichnis mit synthetischen Klassen-Subdirs für den Cold-Start.
    #[arg(long, default_value = "tools/training/data/synthetic_corpus_v1")]
    pub synthetic_corpus: PathBuf,
    /// SQLite-Datei, in der Labels persistiert werden.
    #[arg(long, default_value = "labeler.db")]
    pub db: PathBuf,
    /// Lokaler Port, auf dem der Server läuft.
    #[arg(long, default_value_t = 8095)]
    pub port: u16,
    /// Wenn gesetzt, wird der Browser NICHT automatisch geöffnet.
    #[arg(long)]
    pub no_browser: bool,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let cli = Cli::parse();
    info!(
        "Starte omr-labeler — Port {} | Filestore {} | DB {}",
        cli.port,
        cli.filestore.display(),
        cli.db.display()
    );

    // Datenbank initialisieren.
    let db = match LabelDb::open(&cli.db) {
        Ok(db) => db,
        Err(e) => {
            warn!("Konnte Datenbank nicht öffnen ({}): {}", cli.db.display(), e);
            warn!("Falle zurück auf In-Memory-Datenbank.");
            LabelDb::open_in_memory()?
        }
    };
    let state = Arc::new(AppState::with_db(db));

    // PDFs scannen.
    {
        let pdfs = PipelineState::scan_filestore(&cli.filestore);
        info!("Filestore-Scan: {} PDFs gefunden in {}", pdfs.len(), cli.filestore.display());
        let mut p = state.pipeline.write().await;
        p.pdf_paths = pdfs;
    }

    // Im Hintergrund: PDFs verarbeiten (best effort).
    {
        let state_bg = state.clone();
        tokio::spawn(async move {
            let pdfs = state_bg.pipeline.read().await.pdf_paths.clone();
            for pdf in pdfs {
                let mut p = state_bg.pipeline.write().await;
                if let Err(e) = p.pre_process_pdf(&pdf) {
                    warn!("PDF-Vorverarbeitung fehlgeschlagen ({}): {}", pdf.display(), e);
                }
            }
            // Initial-Items der Queue: ein Line-Item pro System.
            let mut q = state_bg.queue.write().await;
            let p = state_bg.pipeline.read().await;
            let mut q_owned = std::mem::take(&mut *q);
            for sys in &p.systems {
                q_owned.push(
                    omr_labeler::active_learning::Level::Line,
                    sys.id.clone(),
                    None,
                    0.5,
                );
            }
            for elt in &p.elements {
                q_owned.push(
                    omr_labeler::active_learning::Level::Element,
                    elt.system_id.clone(),
                    Some(elt.id.clone()),
                    0.7,
                );
            }
            q_owned.re_prioritize();
            *q = q_owned;
        });
    }

    // Synthetic Warmup.
    let samples = load_synthetic_corpus(&cli.synthetic_corpus);
    if samples.is_empty() {
        warn!(
            "Kein synthetischer Corpus unter {} — Cold-Start ohne Seed-Items.",
            cli.synthetic_corpus.display()
        );
    } else {
        info!("Synthetischer Corpus: {} Klassen geladen.", samples.len());
        let mut q = state.queue.write().await;
        let mut q_owned = std::mem::take(&mut *q);
        seed_queue_with_synthetic(&mut q_owned, &samples);
        *q = q_owned;
    }

    // Embedding-Corpus initialisieren (aus demselben Pfad wie synthetischer Corpus).
    match EmbeddingState::from_corpus_dir(&cli.synthetic_corpus) {
        Ok(emb) => {
            info!(
                "Embedding-Corpus geladen ({}). Index-Größe: {}",
                cli.synthetic_corpus.display(),
                {
                    let stats = emb.corpus_stats();
                    stats.get("index_size")
                        .and_then(|v| v.as_u64())
                        .unwrap_or(0)
                }
            );
            state.set_embedding(emb).await;
        }
        Err(e) => {
            warn!(
                "Embedding-Corpus konnte nicht geladen werden ({}): {} — Active-Learning deaktiviert.",
                cli.synthetic_corpus.display(),
                e
            );
        }
    }

    let app = router(state.clone());
    let addr = SocketAddr::from(([127, 0, 0, 1], cli.port));
    info!("HTTP-Server bereit auf http://{}", addr);

    if !cli.no_browser {
        let url = format!("http://127.0.0.1:{}/", cli.port);
        if let Err(e) = open_browser(&url) {
            warn!("Konnte Browser nicht öffnen: {}", e);
        }
    }

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}

#[cfg(target_os = "windows")]
fn open_browser(url: &str) -> std::io::Result<()> {
    std::process::Command::new("cmd")
        .args(["/C", "start", "", url])
        .spawn()
        .map(|_| ())
}

#[cfg(target_os = "macos")]
fn open_browser(url: &str) -> std::io::Result<()> {
    std::process::Command::new("open").arg(url).spawn().map(|_| ())
}

#[cfg(all(not(target_os = "windows"), not(target_os = "macos")))]
fn open_browser(url: &str) -> std::io::Result<()> {
    std::process::Command::new("xdg-open")
        .arg(url)
        .spawn()
        .map(|_| ())
}

// Sicherstellen, dass die Tests aus `LabelingQueue` & co. zur Compile-
// Zeit korrekt sind, auch wenn `lib`-Reexporte ungenutzt erscheinen.
#[allow(dead_code)]
fn _ensure_used(_q: LabelingQueue) {}
