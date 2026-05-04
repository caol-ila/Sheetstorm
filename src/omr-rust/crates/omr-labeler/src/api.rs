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
//! - `GET  /api/system/{id}/image     ` → System-PNG (gesamte Notenzeile)
//! - `GET  /api/element/{id}/image    ` → Element-PNG (nur das Patch)
//! - `GET  /api/element/{id}/context  ` → Element im System-Kontext mit
//!                                        rotem Highlight-Rahmen
//! - `GET  /api/element/{id}/info     ` → Element-Metadaten (system_id, bbox,
//!                                        suggested_class, ...)
//! - `GET  /api/stats                 ` → Fortschritts-Stats
//! - `GET  /api/export/corpus         ` → JSON-Export aller Labels

use crate::active_learning::{Decision, LabelingQueue, Level, QueueItem};
use crate::frontend::{ANNOTATE_HTML, ANNOTATE_JS, APP_JS, INDEX_HTML, STYLE_CSS};
use crate::persistence::{Annotation, Label, LabelDb};
use crate::pipeline::{encode_png, encode_png_rgb, PipelineState};
use axum::{
    body::Body,
    extract::{Path as AxumPath, Query, State},
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use image::{ImageBuffer, Rgb, RgbImage};
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
        .route("/annotate", get(annotate_html))
        .route("/annotate.html", get(annotate_html))
        .route("/annotate.js", get(annotate_js))
        .route("/api/status", get(api_status))
        .route("/api/classes", get(api_classes))
        .route("/api/classes/drilldown/:group_id", get(api_classes_drilldown))
        .route("/api/classes/recent", get(api_classes_recent))
        .route("/api/queue/next", get(api_queue_next))
        .route("/api/queue/answer", post(api_queue_answer))
        .route("/api/queue/skip", post(api_queue_skip))
        .route("/api/queue/undo", post(api_queue_undo))
        .route("/api/system/:id/image", get(api_system_image))
        .route("/api/element/:id/image", get(api_element_image))
        .route("/api/element/:id/context", get(api_element_context))
        .route("/api/element/:id/info", get(api_element_info))
        .route("/api/stats", get(api_stats))
        .route("/api/export/corpus", get(api_export_corpus))
        .route("/api/annotation/systems", get(api_annotation_systems))
        .route("/api/annotation/system/:id", get(api_annotation_for_system))
        .route("/api/annotation/box", post(api_annotation_create))
        .route("/api/annotation/box/:id", axum::routing::patch(api_annotation_update).delete(api_annotation_delete))
        .route("/api/annotation/export", get(api_annotation_export))
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

async fn annotate_html() -> impl IntoResponse {
    Response::builder()
        .header(header::CONTENT_TYPE, "text/html; charset=utf-8")
        .body(Body::from(ANNOTATE_HTML))
        .unwrap()
}

async fn annotate_js() -> impl IntoResponse {
    Response::builder()
        .header(header::CONTENT_TYPE, "application/javascript; charset=utf-8")
        .body(Body::from(ANNOTATE_JS))
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

/// Eintrag in der Recent-Klassen-Liste: ein User-Label mit Count.
#[derive(Serialize)]
pub struct RecentClass {
    pub id: String,
    pub display_name: String,
    pub count: u64,
    /// `true` wenn die Klasse vom User selbst eingegeben wurde
    /// (d.h. nicht in der eingebauten Hierarchie steht).
    pub custom: bool,
}

#[derive(Deserialize)]
pub struct RecentQuery {
    #[serde(default)]
    pub limit: Option<u32>,
}

/// Liefert die meistgenutzten Class-Labels aus der DB inkl. eigener
/// User-Klassen. Wird vom Frontend genutzt, um die Top-5-Vorschlaege
/// und die Suchliste mit Custom-Klassen anzureichern.
async fn api_classes_recent(
    State(state): State<Arc<AppState>>,
    Query(q): Query<RecentQuery>,
) -> Result<Json<Vec<RecentClass>>, (StatusCode, String)> {
    let limit = q.limit.unwrap_or(20).min(200);
    let recent = {
        let guard = state.db.lock().expect("db mutex poisoned");
        match guard.as_ref() {
            Some(db) => db.recent_class_decisions(limit).map_err(internal)?,
            None => Vec::new(),
        }
    };
    // Built-in-Klassen-Map fuer Custom-Detection + display_name.
    let known: HashMap<String, String> = crate::classes::all_classes()
        .into_iter()
        .map(|c| (c.id, c.display_name))
        .collect();
    let out: Vec<RecentClass> = recent
        .into_iter()
        .map(|(id, count)| {
            let (display_name, custom) = match known.get(&id) {
                Some(name) => (name.clone(), false),
                None => (id.clone(), true),
            };
            RecentClass {
                id,
                display_name,
                count,
                custom,
            }
        })
        .collect();
    Ok(Json(out))
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

    // Original-Item zwischenspeichern, bevor die Queue es entfernt.
    // Wir brauchen es spaeter fuer die Auto-Promotion (Element-Yes -> Class-Item).
    let original_item: Option<QueueItem> = {
        let queue = state.queue.read().await;
        queue
            .items
            .iter()
            .find(|it| it.id == req.item_id)
            .cloned()
    };

    let item_ref = original_item
        .as_ref()
        .map(|it| {
            it.element_id
                .clone()
                .unwrap_or_else(|| it.system_id.clone())
        })
        .unwrap_or_else(|| format!("item-{}", req.item_id));

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

    // Auto-Promotion: wenn der User ein Element mit "Yes" bestaetigt hat,
    // schieben wir automatisch ein Class-Level-Item hinterher, damit der
    // naechste Klick sofort die Klassifikations-Frage stellt. Dadurch
    // bleibt der Workflow ohne Pause: Element=Yes -> "Was ist es?".
    //
    // Top-K kommt dabei aus den haeufig genutzten User-Klassen (inkl.
    // Custom-Klassen wie "Gitarrenakkord"). Faellt zurueck auf
    // Blasmusik-Default, wenn der User noch keine Klassen gelabelt hat.
    if let Some(item) = original_item.as_ref() {
        if item.level == Level::Element
            && matches!(dec, Decision::Yes)
            && item.element_id.is_some()
        {
            let top_k = top_k_for_class_item(state.as_ref());
            let mut queue = state.queue.write().await;
            queue.push_item(QueueItem {
                id: 0,
                level: Level::Class,
                uncertainty: 0.95,
                system_id: item.system_id.clone(),
                element_id: item.element_id.clone(),
                suggested_class: None,
                top_k,
            });
        }
    }

    Ok(Json(serde_json::json!({ "ok": true })))
}

/// Liefert die Top-5 fuer ein neues Class-Item.
///
/// Strategie:
/// 1. Falls in der DB schon Class-Labels existieren -> die haeufigsten
///    User-Klassen (mit Custom-Klassen wie "Gitarrenakkord") nehmen.
/// 2. Andernfalls die statischen Blasmusik-Defaults
///    (`default_class_top_k`).
///
/// Synchron, blockiert kurz auf der DB-Mutex (keine `await`-Punkte).
pub fn top_k_for_class_item(state: &AppState) -> Vec<(String, f32)> {
    let recent: Vec<(String, u64)> = {
        let guard = state.db.lock().expect("db mutex poisoned");
        match guard.as_ref() {
            Some(db) => db.recent_class_decisions(5).unwrap_or_default(),
            None => Vec::new(),
        }
    };
    if recent.is_empty() {
        return default_class_top_k();
    }
    // Score = Anteil an Gesamt-Labels (0..1), nur als Anzeigewert.
    let total: u64 = recent.iter().map(|(_, c)| *c).sum::<u64>().max(1);
    recent
        .into_iter()
        .map(|(id, count)| (id, count as f32 / total as f32))
        .collect()
}

/// Default-Top-5 fuer Class-Items ohne trainierten Classifier und ohne
/// User-Historie: die haeufigsten Blasmusik-Ton-Ereignisse. Wird ersetzt,
/// sobald der User Klassen gelabelt hat oder ein Embedding-Index vorliegt.
pub fn default_class_top_k() -> Vec<(String, f32)> {
    vec![
        ("ton/viertel".to_string(), 0.0),
        ("ton/achtel".to_string(), 0.0),
        ("balken/2_noten".to_string(), 0.0),
        ("balken/4_noten".to_string(), 0.0),
        ("akkord/2_noten".to_string(), 0.0),
    ]
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

#[derive(Deserialize, Default)]
pub struct ContextQuery {
    /// Padding in Pixeln links und rechts vom Element.
    /// Default 350px (~5cm bei 200dpi).
    #[serde(default)]
    pub padding: Option<u32>,
    /// Vertikales Padding (oben/unten) — kann negativ wirken: 0 = ganzes System.
    #[serde(default)]
    pub padding_y: Option<u32>,
}

/// Liefert das **Page-Bild im Kontext um das Element herum**, mit einem
/// roten Highlight-Rechteck um die Element-Bbox. Default-Padding 350px
/// horizontal (~5cm bei 200dpi) und 200px vertikal (oben + unten),
/// damit man Pausen vs. Notenkoepfe richtig einordnen kann.
async fn api_element_context(
    State(state): State<Arc<AppState>>,
    AxumPath(id): AxumPath<String>,
    Query(q): Query<ContextQuery>,
) -> Result<Response, (StatusCode, String)> {
    let pipeline = state.pipeline.read().await;
    let elt = pipeline
        .elements
        .iter()
        .find(|e| e.id == id)
        .ok_or((StatusCode::NOT_FOUND, "Element nicht gefunden".to_string()))?;
    let sys = pipeline
        .systems
        .iter()
        .find(|s| s.id == elt.system_id)
        .ok_or((StatusCode::NOT_FOUND, "System nicht gefunden".to_string()))?;

    let pad_x = q.padding.unwrap_or(350);
    let pad_y = q.padding_y.unwrap_or(200);

    // Page-Bild: vollständiges Page in Page-Koordinaten.
    // Element-bbox ist in CROP-Koordinaten (rel. zum System-Crop) →
    // konvertiere via sys.page_top zurück nach Page-Koordinaten.
    let page = &sys.page_image;
    let pw = page.width();
    let ph = page.height();
    let bb = &elt.bbox;
    let elt_page_y = bb.y + sys.page_top;

    let crop_x0 = bb.x.saturating_sub(pad_x);
    let crop_x1 = (bb.x + bb.w + pad_x).min(pw);
    let crop_w = crop_x1.saturating_sub(crop_x0).max(1);

    let crop_y0 = elt_page_y.saturating_sub(pad_y);
    let crop_y1 = (elt_page_y + bb.h + pad_y).min(ph);
    let crop_h = crop_y1.saturating_sub(crop_y0).max(1);

    let mut rgb: RgbImage = ImageBuffer::new(crop_w, crop_h);
    for yy in 0..crop_h {
        for xx in 0..crop_w {
            let sx = crop_x0 + xx;
            let sy = crop_y0 + yy;
            let p = page.get_pixel(sx, sy)[0];
            rgb.put_pixel(xx, yy, Rgb([p, p, p]));
        }
    }

    // Draw red border around the element bbox (3px thick).
    let bx0 = bb.x.saturating_sub(crop_x0);
    let by0 = elt_page_y.saturating_sub(crop_y0);
    let bx1 = (bb.x + bb.w).saturating_sub(crop_x0).min(crop_w.saturating_sub(1));
    let by1 = (elt_page_y + bb.h).saturating_sub(crop_y0).min(crop_h.saturating_sub(1));
    let border_color = Rgb([255u8, 64, 64]);
    let thickness = 3u32;
    for t in 0..thickness {
        for x in bx0..=bx1 {
            if by0 + t < crop_h {
                rgb.put_pixel(x, by0 + t, border_color);
            }
            if by1 >= t && by1 - t < crop_h {
                rgb.put_pixel(x, by1 - t, border_color);
            }
        }
        for y in by0..=by1 {
            if bx0 + t < crop_w {
                rgb.put_pixel(bx0 + t, y, border_color);
            }
            if bx1 >= t && bx1 - t < crop_w {
                rgb.put_pixel(bx1 - t, y, border_color);
            }
        }
    }

    let png = encode_png_rgb(&rgb).map_err(internal)?;
    Ok(Response::builder()
        .header(header::CONTENT_TYPE, "image/png")
        .body(Body::from(png))
        .unwrap())
}

#[derive(Serialize)]
pub struct ElementInfo {
    pub id: String,
    pub system_id: String,
    pub bbox: [u32; 4],
    pub system_size: [u32; 2],
    pub suggested_class: Option<String>,
    pub patch_size: [u32; 2],
}

async fn api_element_info(
    State(state): State<Arc<AppState>>,
    AxumPath(id): AxumPath<String>,
) -> Result<Json<ElementInfo>, (StatusCode, String)> {
    let pipeline = state.pipeline.read().await;
    let elt = pipeline
        .elements
        .iter()
        .find(|e| e.id == id)
        .ok_or((StatusCode::NOT_FOUND, "Element nicht gefunden".to_string()))?;
    let sys = pipeline
        .systems
        .iter()
        .find(|s| s.id == elt.system_id);
    let system_size = sys
        .map(|s| [s.image.width(), s.image.height()])
        .unwrap_or([0, 0]);
    Ok(Json(ElementInfo {
        id: elt.id.clone(),
        system_id: elt.system_id.clone(),
        bbox: [elt.bbox.x, elt.bbox.y, elt.bbox.w, elt.bbox.h],
        system_size,
        suggested_class: elt.suggested_class.clone(),
        patch_size: [elt.patch.width(), elt.patch.height()],
    }))
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

// ---- Annotation-API (User-gezogene Boxen) -----------------------------------

#[derive(Serialize)]
pub struct AnnotationSystemInfo {
    pub system_id: String,
    pub width: u32,
    pub height: u32,
    pub annotation_count: u64,
    /// Anzahl auto-erkannter Elemente in diesem System (zur Orientierung).
    pub auto_element_count: u64,
}

#[derive(Serialize)]
pub struct AnnotationSystemsResponse {
    pub systems: Vec<AnnotationSystemInfo>,
}

/// Liefert eine Liste aller Systeme mit Annotation-Counts. Sortiert nach
/// `annotation_count` aufsteigend (am wenigsten annotiert zuerst), damit
/// der User schnell unbearbeitete Systeme findet.
async fn api_annotation_systems(
    State(state): State<Arc<AppState>>,
) -> Result<Json<AnnotationSystemsResponse>, (StatusCode, String)> {
    let counts: HashMap<String, u64> = {
        let guard = state.db.lock().expect("db mutex poisoned");
        match guard.as_ref() {
            Some(db) => db
                .annotation_counts_per_system()
                .map_err(internal)?
                .into_iter()
                .collect(),
            None => HashMap::new(),
        }
    };
    let pipeline = state.pipeline.read().await;
    let mut auto_counts: HashMap<String, u64> = HashMap::new();
    for elt in &pipeline.elements {
        *auto_counts.entry(elt.system_id.clone()).or_insert(0) += 1;
    }
    let mut systems: Vec<AnnotationSystemInfo> = pipeline
        .systems
        .iter()
        .map(|s| AnnotationSystemInfo {
            system_id: s.id.clone(),
            width: s.image.width(),
            height: s.image.height(),
            annotation_count: counts.get(&s.id).copied().unwrap_or(0),
            auto_element_count: auto_counts.get(&s.id).copied().unwrap_or(0),
        })
        .collect();
    // unbearbeitete zuerst, danach nach system_id
    systems.sort_by(|a, b| {
        a.annotation_count
            .cmp(&b.annotation_count)
            .then_with(|| a.system_id.cmp(&b.system_id))
    });
    Ok(Json(AnnotationSystemsResponse { systems }))
}

#[derive(Serialize)]
pub struct AnnotationForSystemResponse {
    pub system_id: String,
    pub annotations: Vec<Annotation>,
    /// Auto-Boxen des Systems (Element-Bboxes aus der Pipeline) — koennen
    /// als Vorschlag fuer die manuelle Annotation verwendet werden.
    pub auto_boxes: Vec<AutoBox>,
}

#[derive(Serialize)]
pub struct AutoBox {
    pub element_id: String,
    pub x: u32,
    pub y: u32,
    pub w: u32,
    pub h: u32,
    pub suggested_class: Option<String>,
}

async fn api_annotation_for_system(
    State(state): State<Arc<AppState>>,
    AxumPath(system_id): AxumPath<String>,
) -> Result<Json<AnnotationForSystemResponse>, (StatusCode, String)> {
    let annotations = {
        let guard = state.db.lock().expect("db mutex poisoned");
        match guard.as_ref() {
            Some(db) => db.annotations_for_system(&system_id).map_err(internal)?,
            None => Vec::new(),
        }
    };
    let pipeline = state.pipeline.read().await;
    let auto_boxes: Vec<AutoBox> = pipeline
        .elements
        .iter()
        .filter(|e| e.system_id == system_id)
        .map(|e| AutoBox {
            element_id: e.id.clone(),
            x: e.bbox.x,
            y: e.bbox.y,
            w: e.bbox.w,
            h: e.bbox.h,
            suggested_class: e.suggested_class.clone(),
        })
        .collect();
    Ok(Json(AnnotationForSystemResponse {
        system_id,
        annotations,
        auto_boxes,
    }))
}

#[derive(Deserialize)]
pub struct AnnotationCreateRequest {
    pub system_id: String,
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
    pub class_id: String,
}

async fn api_annotation_create(
    State(state): State<Arc<AppState>>,
    Json(req): Json<AnnotationCreateRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    if req.w <= 0 || req.h <= 0 {
        return Err((StatusCode::BAD_REQUEST, "w/h must be positive".to_string()));
    }
    if req.class_id.trim().is_empty() {
        return Err((StatusCode::BAD_REQUEST, "class_id required".to_string()));
    }
    let id = {
        let guard = state.db.lock().expect("db mutex poisoned");
        match guard.as_ref() {
            Some(db) => {
                let ann = Annotation::new(
                    req.system_id.clone(),
                    req.x,
                    req.y,
                    req.w,
                    req.h,
                    req.class_id.clone(),
                );
                db.save_annotation(&ann).map_err(internal)?
            }
            None => 0,
        }
    };
    Ok(Json(serde_json::json!({ "ok": true, "id": id })))
}

#[derive(Deserialize)]
pub struct AnnotationUpdateRequest {
    pub class_id: String,
}

async fn api_annotation_update(
    State(state): State<Arc<AppState>>,
    AxumPath(id): AxumPath<i64>,
    Json(req): Json<AnnotationUpdateRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let guard = state.db.lock().expect("db mutex poisoned");
    if let Some(db) = guard.as_ref() {
        db.update_annotation_class(id, &req.class_id)
            .map_err(internal)?;
    }
    Ok(Json(serde_json::json!({ "ok": true })))
}

async fn api_annotation_delete(
    State(state): State<Arc<AppState>>,
    AxumPath(id): AxumPath<i64>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let guard = state.db.lock().expect("db mutex poisoned");
    if let Some(db) = guard.as_ref() {
        db.delete_annotation(id).map_err(internal)?;
    }
    Ok(Json(serde_json::json!({ "ok": true })))
}

async fn api_annotation_export(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<Annotation>>, (StatusCode, String)> {
    let guard = state.db.lock().expect("db mutex poisoned");
    let out = match guard.as_ref() {
        Some(db) => db.get_all_annotations().map_err(internal)?,
        None => Vec::new(),
    };
    Ok(Json(out))
}

fn internal<E: std::fmt::Display>(e: E) -> (StatusCode, String) {
    (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
}
