//! HTTP-API (axum) für das Labeling-Tool.
//!
//! Liefert die folgenden Endpoints:
//!
//! - `GET  /                          ` → eingebettete index.html
//! - `GET  /app.js                    ` → eingebettetes JS
//! - `GET  /style.css                 ` → eingebettetes CSS
//! - `GET  /api/status                ` → aktuelle Counts
//! - `GET  /api/queue/next?level=&n=  ` → nächste Items aus der Queue
//! - `POST /api/queue/answer          ` → Antwort persistieren + Queue
//! - `POST /api/queue/skip            ` → Item überspringen
//! - `POST /api/queue/undo            ` → letztes Label entfernen
//! - `GET  /api/system/{id}/image     ` → System-PNG
//! - `GET  /api/element/{id}/image    ` → Element-PNG
//! - `GET  /api/stats                 ` → Fortschritts-Stats
//! - `GET  /api/export/corpus         ` → JSON-Export aller Labels

use crate::active_learning::{Decision, LabelingQueue, Level, QueueItem};
use crate::frontend::{APP_JS, INDEX_HTML, STYLE_CSS};
use crate::persistence::{Label, LabelDb};
use crate::pipeline::{encode_png, PipelineState};
use axum::{
    body::Body,
    extract::{Path as AxumPath, Query, State},
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;

/// Globaler App-State, geteilt über alle Handler.
///
/// Hinweise zur Synchronisation:
/// - `pipeline` und `queue` sind reine Datenstrukturen → `tokio::RwLock`.
/// - `db` umschließt eine `rusqlite::Connection`, die nicht `Sync` ist
///   (sie hat einen internen `RefCell`-Statement-Cache). Daher
///   verwenden wir `std::sync::Mutex`, das `Sync` bereitstellt für
///   `T: Send`. Die Datenbankoperationen sind kurz und blockierend,
///   sodass das Halten des Mutex über `await`-Punkte vermieden wird.
#[derive(Default)]
pub struct AppState {
    pub pipeline: RwLock<PipelineState>,
    pub queue: RwLock<LabelingQueue>,
    pub db: Mutex<Option<LabelDb>>,
}

impl AppState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_db(db: LabelDb) -> Self {
        Self {
            pipeline: RwLock::new(PipelineState::new()),
            queue: RwLock::new(LabelingQueue::new()),
            db: Mutex::new(Some(db)),
        }
    }
}

#[derive(Serialize)]
pub struct StatusResponse {
    pub pdfs: usize,
    pub systems: usize,
    pub elements: usize,
    pub labels: u64,
}

#[derive(Deserialize)]
pub struct NextQuery {
    #[serde(default)]
    pub level: Option<String>,
    #[serde(default)]
    pub n: Option<usize>,
}

#[derive(Serialize)]
pub struct NextResponse {
    pub items: Vec<QueueItem>,
    pub remaining: usize,
}

#[derive(Deserialize)]
pub struct AnswerRequest {
    pub item_id: u64,
    pub level: String,
    pub decision: String,
    #[serde(default)]
    pub value: Option<String>,
}

#[derive(Deserialize)]
pub struct SkipRequest {
    pub item_id: u64,
}

#[derive(Serialize)]
pub struct StatsResponse {
    pub total: usize,
    pub labeled: usize,
    pub remaining: usize,
    pub last_resort: usize,
    pub progress: f32,
    pub by_level: HashMap<String, u64>,
}

/// Erzeugt den Axum-Router mit allen Endpoints und CORS.
pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/", get(index_html))
        .route("/index.html", get(index_html))
        .route("/app.js", get(app_js))
        .route("/style.css", get(style_css))
        .route("/api/status", get(api_status))
        .route("/api/classes", get(api_classes))
        .route("/api/classes/drilldown/:group_id", get(api_classes_drilldown))
        .route("/api/queue/next", get(api_queue_next))
        .route("/api/queue/answer", post(api_queue_answer))
        .route("/api/queue/skip", post(api_queue_skip))
        .route("/api/queue/undo", post(api_queue_undo))
        .route("/api/system/:id/image", get(api_system_image))
        .route("/api/element/:id/image", get(api_element_image))
        .route("/api/stats", get(api_stats))
        .route("/api/export/corpus", get(api_export_corpus))
        .with_state(state)
        .layer(CorsLayer::permissive())
}

// --- Static handlers ---

async fn index_html() -> impl IntoResponse {
    Response::builder()
        .header(header::CONTENT_TYPE, "text/html; charset=utf-8")
        .body(Body::from(INDEX_HTML))
        .unwrap()
}

async fn app_js() -> impl IntoResponse {
    Response::builder()
        .header(header::CONTENT_TYPE, "application/javascript; charset=utf-8")
        .body(Body::from(APP_JS))
        .unwrap()
}

async fn style_css() -> impl IntoResponse {
    Response::builder()
        .header(header::CONTENT_TYPE, "text/css; charset=utf-8")
        .body(Body::from(STYLE_CSS))
        .unwrap()
}

// --- API ---

async fn api_status(State(state): State<Arc<AppState>>) -> Json<StatusResponse> {
    let pipeline = state.pipeline.read().await;
    let labels = {
        let guard = state.db.lock().expect("db mutex poisoned");
        match guard.as_ref() {
            Some(db) => db.count_labels("").unwrap_or(0),
            None => 0,
        }
    };
    Json(StatusResponse {
        pdfs: pipeline.pdf_paths.len(),
        systems: pipeline.systems.len(),
        elements: pipeline.elements.len(),
        labels,
    })
}

/// Liefert die hierarchische Klassen-Liste fuer das Klassifikations-Dropdown.
/// Default: nur Top-Level (`group/...`) — die direkt waehlbaren Klassen.
/// `?include_atoms=1` liefert zusaetzlich die atomaren Klassen.
#[derive(Deserialize)]
pub struct ClassesQuery {
    #[serde(default)]
    pub include_atoms: Option<u8>,
    #[serde(default)]
    pub include_phrases: Option<u8>,
}

async fn api_classes(Query(q): Query<ClassesQuery>) -> Json<Vec<crate::classes::ClassEntry>> {
    use crate::classes::{all_classes, ClassLevel};
    let include_atoms = q.include_atoms.unwrap_or(0) != 0;
    let include_phrases = q.include_phrases.unwrap_or(0) != 0;
    let classes: Vec<_> = all_classes()
        .into_iter()
        .filter(|c| match c.level {
            ClassLevel::Group => true,
            ClassLevel::Atom => include_atoms,
            ClassLevel::Phrase => include_phrases,
        })
        .collect();
    Json(classes)
}

/// Drill-Down einer Group-Klasse zu ihren atomaren Sub-Klassen.
async fn api_classes_drilldown(
    AxumPath(group_id): AxumPath<String>,
) -> Json<Vec<crate::classes::ClassEntry>> {
    Json(crate::classes::drill_down(&group_id))
}

async fn api_queue_next(
    State(state): State<Arc<AppState>>,
    Query(q): Query<NextQuery>,
) -> Json<NextResponse> {
    let queue = state.queue.write().await;
    let want = q.n.unwrap_or(1).max(1).min(20);
    let level_filter = q.level.as_deref().and_then(parse_level);
    let mut taken = Vec::new();
    // Iteriere über Queue, sammle bis zu `want` matching items, ohne sie
    // zu entfernen.
    for it in queue.items.iter() {
        if queue.labeled.contains(&it.id) {
            continue;
        }
        if let Some(lf) = level_filter {
            if it.level != lf {
                continue;
            }
        }
        taken.push(it.clone());
        if taken.len() >= want {
            break;
        }
    }
    let remaining = queue
        .items
        .iter()
        .filter(|it| !queue.labeled.contains(&it.id))
        .count();
    Json(NextResponse {
        items: taken,
        remaining,
    })
}

fn parse_level(s: &str) -> Option<Level> {
    match s.to_ascii_lowercase().as_str() {
        "line" => Some(Level::Line),
        "element" => Some(Level::Element),
        "class" => Some(Level::Class),
        _ => None,
    }
}

async fn api_queue_answer(
    State(state): State<Arc<AppState>>,
    Json(req): Json<AnswerRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let dec = match req.decision.to_ascii_lowercase().as_str() {
        "yes" => Decision::Yes,
        "no" => Decision::No,
        "skip" => Decision::Skip,
        "class" => Decision::Class(req.value.clone().unwrap_or_default()),
        other => {
            return Err((
                StatusCode::BAD_REQUEST,
                format!("Unbekannte decision: {}", other),
            ))
        }
    };

    // Item-Ref ermitteln (system_id oder element_id) bevor die Queue
    // den Eintrag entfernt.
    let item_ref = {
        let queue = state.queue.read().await;
        queue
            .items
            .iter()
            .find(|it| it.id == req.item_id)
            .map(|it| {
                it.element_id
                    .clone()
                    .unwrap_or_else(|| it.system_id.clone())
            })
            .unwrap_or_else(|| format!("item-{}", req.item_id))
    };

    {
        let mut queue = state.queue.write().await;
        queue.answer(req.item_id, dec.clone());
        if queue.labeled_count % 10 == 0 {
            queue.re_prioritize();
        }
    }

    {
        let guard = state.db.lock().expect("db mutex poisoned");
        if let Some(db) = guard.as_ref() {
            let label = Label::new(&req.level, dec.as_str(), item_ref);
            db.save_label(&label).map_err(internal)?;
        }
    }

    Ok(Json(serde_json::json!({ "ok": true })))
}

async fn api_queue_skip(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SkipRequest>,
) -> Json<serde_json::Value> {
    let mut queue = state.queue.write().await;
    queue.skip(req.item_id);
    Json(serde_json::json!({ "ok": true }))
}
async fn api_queue_undo(
    State(state): State<Arc<AppState>>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let popped = {
        let guard = state.db.lock().expect("db mutex poisoned");
        if let Some(db) = guard.as_ref() {
            db.pop_last_label().map_err(internal)?
        } else {
            None
        }
    };
    Ok(Json(serde_json::json!({
        "ok": true,
        "popped": popped,
    })))
}

async fn api_system_image(
    State(state): State<Arc<AppState>>,
    AxumPath(id): AxumPath<String>,
) -> Result<Response, (StatusCode, String)> {
    let pipeline = state.pipeline.read().await;
    let sys = pipeline
        .systems
        .iter()
        .find(|s| s.id == id)
        .ok_or((StatusCode::NOT_FOUND, "System nicht gefunden".to_string()))?;
    let png = encode_png(&sys.image).map_err(internal)?;
    Ok(Response::builder()
        .header(header::CONTENT_TYPE, "image/png")
        .body(Body::from(png))
        .unwrap())
}

async fn api_element_image(
    State(state): State<Arc<AppState>>,
    AxumPath(id): AxumPath<String>,
) -> Result<Response, (StatusCode, String)> {
    let pipeline = state.pipeline.read().await;
    let elt = pipeline
        .elements
        .iter()
        .find(|e| e.id == id)
        .ok_or((StatusCode::NOT_FOUND, "Element nicht gefunden".to_string()))?;
    let png = encode_png(&elt.patch).map_err(internal)?;
    Ok(Response::builder()
        .header(header::CONTENT_TYPE, "image/png")
        .body(Body::from(png))
        .unwrap())
}

async fn api_stats(State(state): State<Arc<AppState>>) -> Json<StatsResponse> {
    let queue = state.queue.read().await;
    let total = queue.items.len() + queue.labeled_count;
    let labeled = queue.labeled_count;
    let remaining = queue.items.len();
    let last_resort = queue.last_resort;
    let progress = if total > 0 {
        labeled as f32 / total as f32
    } else {
        0.0
    };

    let mut by_level: HashMap<String, u64> = HashMap::new();
    {
        let guard = state.db.lock().expect("db mutex poisoned");
        if let Some(db) = guard.as_ref() {
            for lvl in ["line", "element", "class"] {
                let c = db.count_labels(lvl).unwrap_or(0);
                by_level.insert(lvl.to_string(), c);
            }
        }
    }
    Json(StatsResponse {
        total,
        labeled,
        remaining,
        last_resort,
        progress,
        by_level,
    })
}

async fn api_export_corpus(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<Label>>, (StatusCode, String)> {
    let labels = {
        let guard = state.db.lock().expect("db mutex poisoned");
        if let Some(db) = guard.as_ref() {
            db.get_all_labels().map_err(internal)?
        } else {
            Vec::new()
        }
    };
    Ok(Json(labels))
}

fn internal<E: std::fmt::Display>(e: E) -> (StatusCode, String) {
    (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
}
