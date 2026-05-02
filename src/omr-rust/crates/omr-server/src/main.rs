// HTTP-Server: Drop-in-kompatibel mit Audiveris-Container.
//
// Endpoints:
//   GET  /health     → JSON { ok: bool, version, capabilities }
//   POST /recognize  → multipart 'file' (PDF oder Bild)  → MusicXML body
//                      OR  application/json error
//
// Konfiguration via Env:
//   OMR_HOST  (default 0.0.0.0)
//   OMR_PORT  (default 8091)
//   OMR_RUST_LOG (default info)

use anyhow::Context;
use axum::{
    body::Bytes,
    extract::{DefaultBodyLimit, Multipart, State},
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use omr_core::PipelineOptions;
use serde::Serialize;
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::trace::TraceLayer;
use tracing::{error, info, warn};

#[derive(Clone)]
struct AppState {
    started_at: std::time::Instant,
}

#[derive(Serialize)]
struct HealthResponse {
    ok: bool,
    engine: &'static str,
    version: &'static str,
    capabilities: Vec<&'static str>,
    uptime_seconds: u64,
}

#[derive(Serialize)]
struct ErrorResponse {
    ok: bool,
    kind: &'static str,
    message: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let log_level = std::env::var("OMR_RUST_LOG").unwrap_or_else(|_| "info".into());
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::new(log_level))
        .init();

    let host = std::env::var("OMR_HOST").unwrap_or_else(|_| "0.0.0.0".into());
    let port: u16 = std::env::var("OMR_PORT").unwrap_or_else(|_| "8091".into()).parse().unwrap_or(8091);

    let state = Arc::new(AppState { started_at: std::time::Instant::now() });

    let app = Router::new()
        .route("/health", get(health))
        .route("/recognize", post(recognize))
        .route("/detections", post(detections))
        .layer(DefaultBodyLimit::max(50 * 1024 * 1024)) // 50 MB
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    let addr: SocketAddr = format!("{}:{}", host, port).parse()?;
    info!("Sheetstorm OMR Engine starting on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.context("bind")?;
    axum::serve(listener, app.into_make_service()).await?;
    Ok(())
}

async fn health(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    Json(HealthResponse {
        ok: true,
        engine: "sheetstorm-omr",
        version: env!("CARGO_PKG_VERSION"),
        capabilities: vec!["pdf", "png", "jpeg", "musicxml-4.0"],
        uptime_seconds: state.started_at.elapsed().as_secs(),
    })
}

async fn recognize(mut multipart: Multipart) -> Response {
    let mut filename = String::new();
    let mut bytes: Option<Bytes> = None;

    loop {
        match multipart.next_field().await {
            Ok(Some(field)) => {
                let name = field.name().unwrap_or("").to_string();
                if name == "file" {
                    filename = field.file_name().unwrap_or("upload").to_string();
                    match field.bytes().await {
                        Ok(b) => bytes = Some(b),
                        Err(e) => {
                            warn!("multipart read error: {}", e);
                            return error_resp(StatusCode::BAD_REQUEST, "multipart-error", e.to_string());
                        }
                    }
                }
            }
            Ok(None) => break,
            Err(e) => {
                warn!("multipart next field: {}", e);
                return error_resp(StatusCode::BAD_REQUEST, "multipart-error", e.to_string());
            }
        }
    }

    let bytes = match bytes {
        Some(b) => b,
        None => return error_resp(StatusCode::BAD_REQUEST, "missing-file", "feld 'file' fehlt".into()),
    };

    info!(filename = %filename, size = bytes.len(), "recognize start");
    let started = std::time::Instant::now();

    // Schreibe in temp-Datei (PDF-Render erwartet Pfad).
    let suffix = std::path::Path::new(&filename)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("bin")
        .to_string();
    let tmp = std::env::temp_dir().join(format!("ssomr-{}.{}", uuid_like(), suffix));
    if let Err(e) = std::fs::write(&tmp, &bytes) {
        return error_resp(StatusCode::INTERNAL_SERVER_ERROR, "io", e.to_string());
    }

    let opts = PipelineOptions::default();
    let unet_path = std::env::var("OMR_UNET_MODEL")
        .ok()
        .map(std::path::PathBuf::from)
        .filter(|p| p.exists());
    let opts = PipelineOptions {
        unet_model_path: unet_path,
        ..opts
    };
    let path = tmp.clone();
    let result = tokio::task::spawn_blocking(move || {
        let lower = filename.to_lowercase();
        if lower.ends_with(".pdf") {
            omr_pipeline::process_pdf(&path, &opts)
        } else {
            omr_pipeline::process_image(&path, &opts)
        }
    })
    .await;

    let _ = std::fs::remove_file(&tmp);

    match result {
        Ok(Ok(res)) => {
            info!(
                elapsed_ms = started.elapsed().as_millis() as u64,
                n_systems = res.stats.n_systems,
                n_noteheads = res.stats.n_noteheads,
                "recognize ok"
            );
            (
                StatusCode::OK,
                [
                    (header::CONTENT_TYPE, "application/vnd.recordare.musicxml+xml; charset=utf-8"),
                    (header::HeaderName::from_static("x-omr-engine"), "sheetstorm"),
                ],
                res.musicxml,
            )
                .into_response()
        }
        Ok(Err(e)) => {
            error!("pipeline error: {}", e);
            error_resp(StatusCode::INTERNAL_SERVER_ERROR, "pipeline", e.to_string())
        }
        Err(e) => {
            error!("join error: {}", e);
            error_resp(StatusCode::INTERNAL_SERVER_ERROR, "join", e.to_string())
        }
    }
}

fn error_resp(status: StatusCode, kind: &'static str, message: String) -> Response {
    (
        status,
        Json(ErrorResponse { ok: false, kind, message }),
    )
        .into_response()
}

/// Endpoint für das Annotation-/Trainings-Tool.
///
/// Multipart-Upload: gleiches Schema wie /recognize, aber Response ist
/// JSON mit `DetectionsResult` (alle NHs, Stems, Beams, Bars, Measures
/// mit Bbox, Pitch, Duration, Plausibility-Status).
async fn detections(mut multipart: Multipart) -> Response {
    let mut filename = String::new();
    let mut bytes: Option<Bytes> = None;

    loop {
        match multipart.next_field().await {
            Ok(Some(field)) => {
                let name = field.name().unwrap_or("").to_string();
                if name == "file" {
                    filename = field.file_name().unwrap_or("upload").to_string();
                    match field.bytes().await {
                        Ok(b) => bytes = Some(b),
                        Err(e) => {
                            warn!("multipart read error: {}", e);
                            return error_resp(StatusCode::BAD_REQUEST, "multipart-error", e.to_string());
                        }
                    }
                }
            }
            Ok(None) => break,
            Err(e) => {
                warn!("multipart next field: {}", e);
                return error_resp(StatusCode::BAD_REQUEST, "multipart-error", e.to_string());
            }
        }
    }

    let bytes = match bytes {
        Some(b) => b,
        None => return error_resp(StatusCode::BAD_REQUEST, "missing-file", "feld 'file' fehlt".into()),
    };

    info!(filename = %filename, size = bytes.len(), "detections start");
    let started = std::time::Instant::now();

    let suffix = std::path::Path::new(&filename)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("bin")
        .to_string();
    let tmp = std::env::temp_dir().join(format!("ssomr-det-{}.{}", uuid_like(), suffix));
    if let Err(e) = std::fs::write(&tmp, &bytes) {
        return error_resp(StatusCode::INTERNAL_SERVER_ERROR, "io", e.to_string());
    }

    let opts = PipelineOptions {
        collect_detections: true,
        unet_model_path: std::env::var("OMR_UNET_MODEL")
            .ok()
            .map(std::path::PathBuf::from)
            .filter(|p| p.exists()),
        ..Default::default()
    };
    let path = tmp.clone();
    let result = tokio::task::spawn_blocking(move || {
        let lower = filename.to_lowercase();
        if lower.ends_with(".pdf") {
            omr_pipeline::process_pdf(&path, &opts)
        } else {
            omr_pipeline::process_image(&path, &opts)
        }
    })
    .await;

    let _ = std::fs::remove_file(&tmp);

    match result {
        Ok(Ok(res)) => {
            let dump = match res.detections {
                Some(d) => d,
                None => {
                    return error_resp(
                        StatusCode::INTERNAL_SERVER_ERROR,
                        "missing-detections",
                        "Pipeline lieferte keine Detections (collect_detections=true sollte das aktivieren)".into(),
                    );
                }
            };
            info!(
                elapsed_ms = started.elapsed().as_millis() as u64,
                n_pages = dump.pages.len(),
                "detections ok"
            );
            (
                StatusCode::OK,
                [
                    (header::CONTENT_TYPE, "application/json; charset=utf-8"),
                    (header::HeaderName::from_static("x-omr-engine"), "sheetstorm"),
                ],
                Json(dump),
            )
                .into_response()
        }
        Ok(Err(e)) => {
            error!("pipeline error: {}", e);
            error_resp(StatusCode::INTERNAL_SERVER_ERROR, "pipeline", e.to_string())
        }
        Err(e) => {
            error!("join error: {}", e);
            error_resp(StatusCode::INTERNAL_SERVER_ERROR, "join", e.to_string())
        }
    }
}

fn uuid_like() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let n = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or(0);
    format!("{:x}", n)
}
