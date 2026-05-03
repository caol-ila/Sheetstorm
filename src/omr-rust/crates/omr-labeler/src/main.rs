//! `omr-labeler` — CLI + HTTP-Server-Einstieg.
//!
//! Startet einen lokalen axum-Server, scannt im Hintergrund den Filestore
//! nach PDFs, lädt einen optionalen synthetischen Warmup-Corpus und öffnet
//! standardmäßig den Browser auf der UI.

use clap::Parser;
use omr_labeler::active_learning::{LabelingQueue, Level, QueueItem};
use omr_labeler::api::{default_class_top_k, router, AppState};
use omr_labeler::persistence::LabelDb;
use omr_labeler::pipeline::PipelineState;
use omr_labeler::synthetic_warmup::{load_synthetic_corpus, seed_queue_with_synthetic};
use std::collections::HashSet;
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

            // Bereits persistierte Labels aus der DB lesen, damit wir
            // nicht doppelt fragen. Wir brauchen drei Sets:
            //  * line_done    : System-IDs mit Line-Label (yes/no)
            //  * element_done : Element-IDs mit Element-Label (yes/no)
            //  * yes_elements : Element-IDs, die Element=Yes bekommen haben
            //  * class_done   : Element-IDs mit Class-Label
            let (line_done, element_done, yes_elements, class_done) = {
                let guard = state_bg.db.lock().expect("db mutex poisoned");
                match guard.as_ref() {
                    Some(db) => match db.get_all_labels() {
                        Ok(all) => {
                            let mut line_done = HashSet::new();
                            let mut element_done = HashSet::new();
                            let mut yes_elements = HashSet::new();
                            let mut class_done = HashSet::new();
                            for l in all {
                                match l.level.as_str() {
                                    "line" => {
                                        line_done.insert(l.item_ref.clone());
                                    }
                                    "element" => {
                                        element_done.insert(l.item_ref.clone());
                                        if l.decision == "yes" {
                                            yes_elements.insert(l.item_ref.clone());
                                        }
                                    }
                                    "class" => {
                                        class_done.insert(l.item_ref.clone());
                                    }
                                    _ => {}
                                }
                            }
                            (line_done, element_done, yes_elements, class_done)
                        }
                        Err(e) => {
                            warn!("Konnte bestehende Labels nicht lesen: {}", e);
                            (
                                HashSet::new(),
                                HashSet::new(),
                                HashSet::new(),
                                HashSet::new(),
                            )
                        }
                    },
                    None => (
                        HashSet::new(),
                        HashSet::new(),
                        HashSet::new(),
                        HashSet::new(),
                    ),
                }
            };
            info!(
                "Bestehende Labels: line={} element={} yes_elements={} class={}",
                line_done.len(),
                element_done.len(),
                yes_elements.len(),
                class_done.len()
            );

            // Initial-Items der Queue:
            //  * ein Line-Item pro System ohne Line-Label
            //  * ein Element-Item pro Element ohne Element-Label
            //  * ein Class-Item pro yes-Element ohne Class-Label
            let mut q = state_bg.queue.write().await;
            let p = state_bg.pipeline.read().await;
            let mut q_owned = std::mem::take(&mut *q);
            let mut line_pushed = 0usize;
            let mut element_pushed = 0usize;
            let mut class_pushed = 0usize;
            for sys in &p.systems {
                if line_done.contains(&sys.id) {
                    continue;
                }
                q_owned.push(Level::Line, sys.id.clone(), None, 0.5);
                line_pushed += 1;
            }
            for elt in &p.elements {
                if !element_done.contains(&elt.id) {
                    q_owned.push(
                        Level::Element,
                        elt.system_id.clone(),
                        Some(elt.id.clone()),
                        0.7,
                    );
                    element_pushed += 1;
                }
                // Backfill: yes-Elemente ohne Class-Label bekommen ein Class-Item.
                if yes_elements.contains(&elt.id) && !class_done.contains(&elt.id) {
                    q_owned.push_item(QueueItem {
                        id: 0,
                        level: Level::Class,
                        uncertainty: 0.95,
                        system_id: elt.system_id.clone(),
                        element_id: Some(elt.id.clone()),
                        suggested_class: None,
                        top_k: default_class_top_k(),
                    });
                    class_pushed += 1;
                }
            }
            info!(
                "Queue gefuellt: line+={} element+={} class+={} (gesamt {} items)",
                line_pushed,
                element_pushed,
                class_pushed,
                q_owned.len()
            );
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
