//! HTTP-Routen für den SIG-Editor-Layer.
//!
//! Ermöglicht das Laden, Bearbeiten und Persistieren eines Symbol Interpretation
//! Graph (SIG) über eine REST-API. Alle Edits werden via Op-Log protokolliert und
//! sind mit Undo/Redo rückgängig zu machen.
//!
//! ## State-Management
//! Ein `SigState`-Singleton (via `axum::Extension`) hält:
//! - den aktiven `SigStore` (SQLite-Persistenz + R*-Tree)
//! - die aktuelle `Sig`-In-Memory-Repräsentation
//! - Undo- und Redo-Stacks für interaktive Editierung

use axum::{
    extract::{Extension, Path, Query},
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::{delete, get, post},
    Json, Router,
};
use omr_core::Rect;
use omr_sig::{
    inter::{Inter, InterId, InterMeta},
    relation::{ExclusionCause, Relation, RelationKind, RelationVariant, SupportImpacts, SupportKind},
    EditOperationKind, Grade, InterKind, Provenance, Sig,
};
use omr_sig_store::SigStore;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{info, warn};

// ─── State ────────────────────────────────────────────────────────────────────

/// Globaler SIG-Zustand (Singleton pro Server-Instanz).
pub struct SigState {
    bundle: Mutex<Option<StoreBundle>>,
}

struct StoreBundle {
    store: SigStore,
    sig: Sig,
    /// Undo-Stack: jedes Paar (inverse_step, forward_step).
    /// Beim Undo wird `inverse_step` angewendet.
    undo_stack: Vec<(UndoStep, UndoStep)>,
    /// Redo-Stack: jedes Paar (inverse_step, forward_step).
    /// Beim Redo wird `forward_step` angewendet.
    redo_stack: Vec<(UndoStep, UndoStep)>,
}

/// Eine atomare Rückgängig-/Wiederhol-Operation.
#[derive(Debug, Clone)]
enum UndoStep {
    /// Setzt das `frozen`-Flag auf den gegebenen Wert.
    SetFrozen { id: u64, value: bool },
    /// Setzt ein benanntes Feld der InterMeta auf den gegebenen Wert.
    SetField { id: u64, field: String, value: serde_json::Value },
    /// Entfernt Inter (force=true, auch frozen).
    RemoveInter { id: u64 },
    /// Stellt einen Inter aus gespeicherter InterMeta wieder her.
    RestoreInter { meta_json: String },
    /// Entfernt eine Relation (erste Match von from→to).
    RemoveRelation { from_id: u64, to_id: u64 },
    /// Fügt eine vollständige Relation wieder hinzu.
    AddRelation { relation_json: String },
    /// Keine Operation (Platzhalter).
    Noop,
}

impl SigState {
    /// Erstellt einen leeren SIG-Zustand (kein aktiver Store).
    pub fn new() -> Self {
        Self {
            bundle: Mutex::new(None),
        }
    }
}

// ─── Minimaler Inter für Restore-Operationen ──────────────────────────────────

#[derive(Debug)]
struct SimpleInter {
    meta: InterMeta,
}

impl Inter for SimpleInter {
    fn meta(&self) -> &InterMeta {
        &self.meta
    }
    fn meta_mut(&mut self) -> &mut InterMeta {
        &mut self.meta
    }
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
        self
    }
}

// ─── Request-/Response-Typen ──────────────────────────────────────────────────

#[derive(Deserialize)]
struct PathQuery {
    path: String,
}

#[derive(Deserialize)]
struct LimitQuery {
    #[serde(default = "default_limit")]
    limit: usize,
}

fn default_limit() -> usize {
    20
}

#[derive(Deserialize)]
struct SpatialQuery {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
}

#[derive(Deserialize)]
struct ModifyBody {
    field: String,
    value: serde_json::Value,
}

#[derive(Deserialize)]
struct AddInterBody {
    kind: InterKind,
    bbox_x: u32,
    bbox_y: u32,
    bbox_w: u32,
    bbox_h: u32,
    grade: Option<f64>,
    frozen: Option<bool>,
    system_idx: Option<u32>,
    staff_idx: Option<u32>,
    measure_number: Option<u32>,
    voice: Option<u8>,
}

#[derive(Deserialize)]
struct AddRelationBody {
    from_id: u64,
    to_id: u64,
    kind: RelationKind,
    /// `"support"` oder `"exclusion"`.
    variant: String,
    source_ratio: Option<f64>,
    target_ratio: Option<f64>,
    cause: Option<ExclusionCause>,
}

#[derive(Serialize)]
struct SigSnapshotResponse {
    inter_count: usize,
    relation_count: usize,
    inters: Vec<InterMetaResponse>,
}

#[derive(Serialize)]
struct InterMetaResponse {
    id: u64,
    kind: InterKind,
    bbox_x: u32,
    bbox_y: u32,
    bbox_w: u32,
    bbox_h: u32,
    grade: f64,
    contextual: Option<f64>,
    frozen: bool,
    provenance: Provenance,
    system_idx: Option<u32>,
    staff_idx: Option<u32>,
    measure_number: Option<u32>,
    voice: Option<u8>,
}

#[derive(Serialize)]
struct OpLogEntry {
    id: u64,
    kind_json: String,
    timestamp: String,
    author: String,
}

#[derive(Serialize)]
struct SpatialQueryResponse {
    inter_ids: Vec<u64>,
}

#[derive(Serialize)]
struct OkResponse {
    ok: bool,
}

#[derive(Serialize)]
struct ErrorMsg {
    ok: bool,
    error: String,
}

// ─── Router ───────────────────────────────────────────────────────────────────

/// Erstellt den SIG-Editor-Router. Erfordert `Extension(Arc<SigState>)`.
///
/// Der Typ-Parameter `S` ermöglicht das Mergen mit anderen Routers
/// (z.B. dem Main-App-Router) unabhängig von deren State-Typ.
pub fn router<S: Clone + Send + Sync + 'static>() -> Router<S> {
    Router::new()
        .route("/sig/load", get(load_sig))
        .route("/sig/save", post(save_sig_handler))
        .route("/sig/inter/:id/freeze", post(freeze_inter))
        .route("/sig/inter/:id/unfreeze", post(unfreeze_inter))
        .route("/sig/inter/:id/modify", post(modify_inter))
        .route("/sig/inter", post(add_inter))
        .route("/sig/inter/:id", delete(delete_inter))
        .route("/sig/relation", post(add_relation))
        .route("/sig/relation/:from/:to", delete(delete_relation))
        .route("/sig/history", get(get_history))
        .route("/sig/undo", post(undo_handler))
        .route("/sig/redo", post(redo_handler))
        .route("/sig/inters/at", get(inters_at))
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

fn extract_author(headers: &HeaderMap) -> String {
    headers
        .get("x-author")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("user-via-http")
        .to_string()
}

fn validate_path(path: &str) -> Result<(), String> {
    if path.contains("..") {
        return Err("path traversal not allowed".to_string());
    }
    Ok(())
}

fn not_loaded_resp() -> Response {
    (
        StatusCode::PRECONDITION_FAILED,
        Json(ErrorMsg {
            ok: false,
            error: "no sig loaded — call GET /sig/load first".to_string(),
        }),
    )
        .into_response()
}

fn not_found_resp(msg: &str) -> Response {
    (
        StatusCode::NOT_FOUND,
        Json(ErrorMsg {
            ok: false,
            error: msg.to_string(),
        }),
    )
        .into_response()
}

fn bad_request_resp(msg: &str) -> Response {
    (
        StatusCode::BAD_REQUEST,
        Json(ErrorMsg {
            ok: false,
            error: msg.to_string(),
        }),
    )
        .into_response()
}

fn internal_error(msg: &str) -> Response {
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ErrorMsg {
            ok: false,
            error: msg.to_string(),
        }),
    )
        .into_response()
}

fn inter_to_response(inter: &dyn Inter) -> InterMetaResponse {
    let m = inter.meta();
    InterMetaResponse {
        id: m.id.0,
        kind: m.kind,
        bbox_x: m.bounds.x,
        bbox_y: m.bounds.y,
        bbox_w: m.bounds.w,
        bbox_h: m.bounds.h,
        grade: m.grade.value(),
        contextual: m.contextual.map(|g| g.value()),
        frozen: m.frozen,
        provenance: m.provenance,
        system_idx: m.system_idx,
        staff_idx: m.staff_idx,
        measure_number: m.measure_number,
        voice: m.voice,
    }
}

/// Liefert den aktuellen Wert eines benannten InterMeta-Felds als JSON-Value.
fn get_field_value(meta: &InterMeta, field: &str) -> serde_json::Value {
    match field {
        "grade" => serde_json::json!(meta.grade.value()),
        "frozen" => serde_json::json!(meta.frozen),
        "voice" => meta.voice.map(|v| serde_json::json!(v)).unwrap_or(serde_json::Value::Null),
        "system_idx" => meta.system_idx.map(|v| serde_json::json!(v)).unwrap_or(serde_json::Value::Null),
        "staff_idx" => meta.staff_idx.map(|v| serde_json::json!(v)).unwrap_or(serde_json::Value::Null),
        "measure_number" => meta
            .measure_number
            .map(|v| serde_json::json!(v))
            .unwrap_or(serde_json::Value::Null),
        _ => serde_json::Value::Null,
    }
}

/// Wendet einen benannten Feldwert auf eine `InterMeta` an.
fn apply_field_to_meta(
    meta: &mut InterMeta,
    field: &str,
    value: &serde_json::Value,
) -> Result<(), String> {
    match field {
        "grade" => {
            let v = value.as_f64().ok_or_else(|| "grade must be a number".to_string())?;
            meta.grade = Grade::new(v);
            Ok(())
        }
        "frozen" => {
            let v = value.as_bool().ok_or_else(|| "frozen must be a boolean".to_string())?;
            meta.frozen = v;
            Ok(())
        }
        "voice" => {
            if value.is_null() {
                meta.voice = None;
            } else {
                let v = value.as_u64().ok_or_else(|| "voice must be a number".to_string())? as u8;
                meta.voice = Some(v);
            }
            Ok(())
        }
        "system_idx" => {
            if value.is_null() {
                meta.system_idx = None;
            } else {
                let v = value.as_u64().ok_or_else(|| "system_idx must be a number".to_string())? as u32;
                meta.system_idx = Some(v);
            }
            Ok(())
        }
        "staff_idx" => {
            if value.is_null() {
                meta.staff_idx = None;
            } else {
                let v = value.as_u64().ok_or_else(|| "staff_idx must be a number".to_string())? as u32;
                meta.staff_idx = Some(v);
            }
            Ok(())
        }
        "measure_number" => {
            if value.is_null() {
                meta.measure_number = None;
            } else {
                let v = value
                    .as_u64()
                    .ok_or_else(|| "measure_number must be a number".to_string())? as u32;
                meta.measure_number = Some(v);
            }
            Ok(())
        }
        _ => Err(format!("unknown field: {}", field)),
    }
}

/// Wendet einen `UndoStep` auf die `Sig`-Instanz an.
fn apply_step(step: &UndoStep, sig: &mut Sig) -> Result<(), String> {
    match step {
        UndoStep::SetFrozen { id, value } => {
            let inter_id = InterId(*id);
            if let Some(inter) = sig.get_mut(inter_id) {
                inter.meta_mut().frozen = *value;
                if *value {
                    inter.meta_mut().provenance = Provenance::User;
                }
                Ok(())
            } else {
                Err(format!("inter {} not found", id))
            }
        }
        UndoStep::SetField { id, field, value } => {
            let inter_id = InterId(*id);
            if let Some(inter) = sig.get_mut(inter_id) {
                apply_field_to_meta(inter.meta_mut(), field, value)
            } else {
                Err(format!("inter {} not found", id))
            }
        }
        UndoStep::RemoveInter { id } => {
            sig.remove_inter(InterId(*id), true);
            Ok(())
        }
        UndoStep::RestoreInter { meta_json } => {
            let meta: InterMeta =
                serde_json::from_str(meta_json).map_err(|e| e.to_string())?;
            sig.add_inter(Box::new(SimpleInter { meta }));
            Ok(())
        }
        UndoStep::RemoveRelation { from_id, to_id } => {
            sig.remove_relation(InterId(*from_id), InterId(*to_id));
            Ok(())
        }
        UndoStep::AddRelation { relation_json } => {
            let relation: Relation =
                serde_json::from_str(relation_json).map_err(|e| e.to_string())?;
            sig.add_relation(relation);
            Ok(())
        }
        UndoStep::Noop => Ok(()),
    }
}

// ─── Handlers ─────────────────────────────────────────────────────────────────

/// Lädt einen SIG aus einer `.sigstore`-Datei (oder In-Memory mit `path=:memory:`).
async fn load_sig(
    Extension(state): Extension<Arc<SigState>>,
    Query(params): Query<PathQuery>,
) -> Response {
    let path = &params.path;

    if path != ":memory:" {
        if let Err(e) = validate_path(path) {
            return bad_request_resp(&e);
        }
    }

    let store = if path == ":memory:" {
        match SigStore::open_in_memory() {
            Ok(s) => s,
            Err(e) => return internal_error(&e.to_string()),
        }
    } else {
        match SigStore::open(std::path::Path::new(path)) {
            Ok(s) => s,
            Err(e) => return internal_error(&e.to_string()),
        }
    };

    let sig = match store.load_sig() {
        Ok(s) => s,
        Err(e) => return internal_error(&e.to_string()),
    };

    let inter_count = sig.inter_count();
    let relation_count = sig.relation_count();
    let inters: Vec<InterMetaResponse> = sig.inters().map(inter_to_response).collect();

    let response = SigSnapshotResponse {
        inter_count,
        relation_count,
        inters,
    };

    *state.bundle.lock().await = Some(StoreBundle {
        store,
        sig,
        undo_stack: Vec::new(),
        redo_stack: Vec::new(),
    });

    info!(path = %path, inter_count, "sig loaded");
    (StatusCode::OK, Json(response)).into_response()
}

/// Persistiert den aktuellen SIG-Zustand in eine `.sigstore`-Datei.
async fn save_sig_handler(
    Extension(state): Extension<Arc<SigState>>,
    Query(params): Query<PathQuery>,
) -> Response {
    if let Err(e) = validate_path(&params.path) {
        return bad_request_resp(&e);
    }
    if params.path == ":memory:" {
        return bad_request_resp("cannot save to :memory:");
    }

    let guard = state.bundle.lock().await;
    let bundle = match guard.as_ref() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let mut file_store = match SigStore::open(std::path::Path::new(&params.path)) {
        Ok(s) => s,
        Err(e) => return internal_error(&e.to_string()),
    };

    if let Err(e) = file_store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }

    info!(path = %params.path, "sig saved");
    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Markiert einen Inter als `frozen` (User-bestätigt).
async fn freeze_inter(
    Path(id): Path<u64>,
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let inter_id = InterId(id);
    if bundle.sig.get(inter_id).is_none() {
        return not_found_resp(&format!("inter {} not found", id));
    }

    let was_frozen = bundle.sig.get(inter_id).map(|i| i.is_frozen()).unwrap_or(false);

    if let Some(inter) = bundle.sig.get_mut(inter_id) {
        inter.meta_mut().frozen = true;
        inter.meta_mut().provenance = Provenance::User;
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) = bundle.store.record_op(EditOperationKind::Freeze { id: inter_id }, &author) {
        warn!("record_op freeze failed: {}", e);
    }

    bundle.undo_stack.push((
        UndoStep::SetFrozen { id, value: was_frozen },
        UndoStep::SetFrozen { id, value: true },
    ));
    bundle.redo_stack.clear();

    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Entfernt das `frozen`-Flag von einem Inter.
async fn unfreeze_inter(
    Path(id): Path<u64>,
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let inter_id = InterId(id);
    if bundle.sig.get(inter_id).is_none() {
        return not_found_resp(&format!("inter {} not found", id));
    }

    let was_frozen = bundle.sig.get(inter_id).map(|i| i.is_frozen()).unwrap_or(true);

    if let Some(inter) = bundle.sig.get_mut(inter_id) {
        inter.meta_mut().frozen = false;
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) = bundle.store.record_op(EditOperationKind::Unfreeze { id: inter_id }, &author) {
        warn!("record_op unfreeze failed: {}", e);
    }

    bundle.undo_stack.push((
        UndoStep::SetFrozen { id, value: was_frozen },
        UndoStep::SetFrozen { id, value: false },
    ));
    bundle.redo_stack.clear();

    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Modifiziert ein benanntes Feld der InterMeta.
///
/// Body: `{ "field": "<field>", "value": <json-value> }`
///
/// Unterstützte Felder: `grade`, `frozen`, `voice`, `system_idx`,
/// `staff_idx`, `measure_number`.
async fn modify_inter(
    Path(id): Path<u64>,
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
    Json(body): Json<ModifyBody>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let inter_id = InterId(id);
    if bundle.sig.get(inter_id).is_none() {
        return not_found_resp(&format!("inter {} not found", id));
    }

    let old_value = bundle
        .sig
        .get(inter_id)
        .map(|i| get_field_value(i.meta(), &body.field))
        .unwrap_or(serde_json::Value::Null);

    if let Some(inter) = bundle.sig.get_mut(inter_id) {
        if let Err(e) = apply_field_to_meta(inter.meta_mut(), &body.field, &body.value) {
            return bad_request_resp(&e);
        }
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) = bundle.store.record_op(
        EditOperationKind::ModifyInter {
            id: inter_id,
            field: body.field.clone(),
            before: old_value.clone(),
            after: body.value.clone(),
        },
        &author,
    ) {
        warn!("record_op modify failed: {}", e);
    }

    bundle.undo_stack.push((
        UndoStep::SetField { id, field: body.field.clone(), value: old_value },
        UndoStep::SetField { id, field: body.field, value: body.value },
    ));
    bundle.redo_stack.clear();

    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Fügt einen neuen Inter zum aktiven SIG hinzu.
async fn add_inter(
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
    Json(body): Json<AddInterBody>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let inter_id = bundle.sig.next_inter_id();
    let bounds = Rect { x: body.bbox_x, y: body.bbox_y, w: body.bbox_w, h: body.bbox_h };
    let grade = Grade::new(body.grade.unwrap_or(0.5));
    let mut meta = InterMeta::new(inter_id, body.kind, bounds, grade);
    meta.provenance = Provenance::User;
    meta.frozen = body.frozen.unwrap_or(false);
    if meta.frozen {
        // Frozen-Inters vom User behalten die User-Provenance
    }
    meta.system_idx = body.system_idx;
    meta.staff_idx = body.staff_idx;
    meta.measure_number = body.measure_number;
    meta.voice = body.voice;

    let meta_json = serde_json::to_string(&meta).unwrap_or_default();
    let raw_id = inter_id.0;

    bundle.sig.add_inter(Box::new(SimpleInter { meta }));

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) = bundle.store.record_op(EditOperationKind::AddInter { id: inter_id }, &author) {
        warn!("record_op add_inter failed: {}", e);
    }

    bundle.undo_stack.push((
        UndoStep::RemoveInter { id: raw_id },
        UndoStep::RestoreInter { meta_json },
    ));
    bundle.redo_stack.clear();

    (
        StatusCode::CREATED,
        Json(serde_json::json!({ "ok": true, "id": raw_id })),
    )
        .into_response()
}

/// Entfernt einen Inter. Gibt 403 zurück wenn der Inter `frozen` ist.
async fn delete_inter(
    Path(id): Path<u64>,
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let inter_id = InterId(id);

    let is_frozen = bundle.sig.get(inter_id).map(|i| i.is_frozen()).unwrap_or(false);
    if is_frozen {
        return (
            StatusCode::FORBIDDEN,
            Json(ErrorMsg {
                ok: false,
                error: "inter is frozen — unfreeze first".to_string(),
            }),
        )
            .into_response();
    }

    let meta_json = bundle
        .sig
        .get(inter_id)
        .and_then(|i| serde_json::to_string(i.meta()).ok());

    if bundle.sig.remove_inter(inter_id, false).is_none() {
        return not_found_resp(&format!("inter {} not found", id));
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) =
        bundle.store.record_op(EditOperationKind::RemoveInter { id: inter_id }, &author)
    {
        warn!("record_op remove_inter failed: {}", e);
    }

    if let Some(mj) = meta_json {
        bundle.undo_stack.push((
            UndoStep::RestoreInter { meta_json: mj },
            UndoStep::RemoveInter { id },
        ));
    }
    bundle.redo_stack.clear();

    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Fügt eine Relation zwischen zwei Inters hinzu.
async fn add_relation(
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
    Json(body): Json<AddRelationBody>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let from_id = InterId(body.from_id);
    let to_id = InterId(body.to_id);

    if bundle.sig.get(from_id).is_none() || bundle.sig.get(to_id).is_none() {
        return not_found_resp("from_id or to_id not found in sig");
    }

    let variant = match body.variant.as_str() {
        "support" => {
            let impacts = SupportImpacts {
                source_ratio: body.source_ratio.unwrap_or(1.0),
                target_ratio: body.target_ratio.unwrap_or(1.0),
                kind: SupportKind::Structural,
            };
            RelationVariant::Support(impacts)
        }
        "exclusion" => {
            let cause = body.cause.unwrap_or(ExclusionCause::AlternativeHypotheses);
            RelationVariant::Exclusion(cause)
        }
        _ => return bad_request_resp("variant must be 'support' or 'exclusion'"),
    };

    let relation = Relation {
        kind: body.kind,
        from: from_id,
        to: to_id,
        extra: Vec::new(),
        variant,
        provenance: Provenance::User,
        frozen: false,
    };

    let relation_json = serde_json::to_string(&relation).unwrap_or_default();

    bundle.sig.add_relation(relation);

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) = bundle.store.record_op(
        EditOperationKind::AddRelation {
            from: from_id,
            to: to_id,
            kind: format!("{:?}", body.kind),
        },
        &author,
    ) {
        warn!("record_op add_relation failed: {}", e);
    }

    bundle.undo_stack.push((
        UndoStep::RemoveRelation { from_id: body.from_id, to_id: body.to_id },
        UndoStep::AddRelation { relation_json },
    ));
    bundle.redo_stack.clear();

    (StatusCode::CREATED, Json(OkResponse { ok: true })).into_response()
}

/// Entfernt eine Relation zwischen zwei Inters.
async fn delete_relation(
    Path((from, to)): Path<(u64, u64)>,
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let from_id = InterId(from);
    let to_id = InterId(to);

    let relation_json = bundle
        .sig
        .relations()
        .find(|r| r.from == from_id && r.to == to_id)
        .and_then(|r| serde_json::to_string(r).ok());

    if !bundle.sig.remove_relation(from_id, to_id) {
        return not_found_resp(&format!("relation {}->{} not found", from, to));
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }
    if let Err(e) = bundle.store.record_op(
        EditOperationKind::RemoveRelation {
            from: from_id,
            to: to_id,
            kind: "user-delete".to_string(),
        },
        &author,
    ) {
        warn!("record_op remove_relation failed: {}", e);
    }

    if let Some(rj) = relation_json {
        bundle.undo_stack.push((
            UndoStep::AddRelation { relation_json: rj },
            UndoStep::RemoveRelation { from_id: from, to_id: to },
        ));
    }
    bundle.redo_stack.clear();

    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Liefert die letzten `limit` Op-Log-Einträge.
async fn get_history(
    Extension(state): Extension<Arc<SigState>>,
    Query(params): Query<LimitQuery>,
) -> Response {
    let guard = state.bundle.lock().await;
    let bundle = match guard.as_ref() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let ops = match bundle.store.ops() {
        Ok(ops) => ops,
        Err(e) => return internal_error(&e.to_string()),
    };

    let result: Vec<OpLogEntry> = ops
        .into_iter()
        .rev()
        .take(params.limit)
        .map(|(op_id, kind, ts, author)| OpLogEntry {
            id: op_id.0,
            kind_json: serde_json::to_string(&kind).unwrap_or_default(),
            timestamp: ts,
            author,
        })
        .collect();

    (StatusCode::OK, Json(result)).into_response()
}

/// Wendet die letzte Operation rückgängig an.
async fn undo_handler(
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let Some((undo_step, redo_step)) = bundle.undo_stack.pop() else {
        return (
            StatusCode::OK,
            Json(serde_json::json!({ "ok": true, "message": "nothing to undo" })),
        )
            .into_response();
    };

    if let Err(e) = apply_step(&undo_step, &mut bundle.sig) {
        return internal_error(&format!("undo failed: {}", e));
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }

    // Op-Log-Eintrag für das Undo
    let _ = bundle
        .store
        .record_op(EditOperationKind::BatchBegin { label: Some("undo".to_string()) }, &author);

    bundle.redo_stack.push((undo_step, redo_step));
    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Wiederholt die zuletzt rückgängig gemachte Operation.
async fn redo_handler(
    headers: HeaderMap,
    Extension(state): Extension<Arc<SigState>>,
) -> Response {
    let author = extract_author(&headers);
    let mut guard = state.bundle.lock().await;
    let bundle = match guard.as_mut() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let Some((undo_step, redo_step)) = bundle.redo_stack.pop() else {
        return (
            StatusCode::OK,
            Json(serde_json::json!({ "ok": true, "message": "nothing to redo" })),
        )
            .into_response();
    };

    if let Err(e) = apply_step(&redo_step, &mut bundle.sig) {
        return internal_error(&format!("redo failed: {}", e));
    }

    if let Err(e) = bundle.store.save_sig(&bundle.sig) {
        return internal_error(&e.to_string());
    }

    let _ = bundle
        .store
        .record_op(EditOperationKind::BatchBegin { label: Some("redo".to_string()) }, &author);

    bundle.undo_stack.push((undo_step, redo_step));
    (StatusCode::OK, Json(OkResponse { ok: true })).into_response()
}

/// Liefert alle Inters, deren Bounding-Box das angegebene Rechteck schneidet.
async fn inters_at(
    Extension(state): Extension<Arc<SigState>>,
    Query(params): Query<SpatialQuery>,
) -> Response {
    let guard = state.bundle.lock().await;
    let bundle = match guard.as_ref() {
        Some(b) => b,
        None => return not_loaded_resp(),
    };

    let ids = bundle.store.inters_in_rect(params.x, params.y, params.w, params.h);
    let inter_ids: Vec<u64> = ids.iter().map(|i| i.0).collect();

    (StatusCode::OK, Json(SpatialQueryResponse { inter_ids })).into_response()
}

// ─── Integration-Tests ────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::Body,
        http::{Request, StatusCode},
    };
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    /// Baut den Test-Router mit frischem SigState auf.
    fn test_app() -> axum::Router {
        let state = Arc::new(SigState::new());
        router::<()>().layer(Extension(state))
    }

    async fn body_bytes(body: Body) -> Vec<u8> {
        BodyExt::collect(body).await.unwrap().to_bytes().to_vec()
    }

    async fn body_json(body: Body) -> serde_json::Value {
        let bytes = body_bytes(body).await;
        serde_json::from_slice(&bytes).unwrap()
    }

    /// Lädt einen In-Memory-SIG und gibt den App-State zurück.
    async fn app_with_loaded_sig() -> axum::Router {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK, "load must succeed");

        app
    }

    /// Fügt einem geladenen SIG einen Test-Inter hinzu und liefert dessen ID.
    async fn add_test_inter(app: &axum::Router, kind: &str) -> u64 {
        let body = serde_json::json!({
            "kind": kind,
            "bbox_x": 10, "bbox_y": 20, "bbox_w": 30, "bbox_h": 40,
            "grade": 0.8
        });
        let req = Request::builder()
            .method("POST")
            .uri("/sig/inter")
            .header("content-type", "application/json")
            .body(Body::from(body.to_string()))
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::CREATED);
        let json = body_json(resp.into_body()).await;
        json["id"].as_u64().unwrap()
    }

    // ─── Test 1 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn load_creates_in_memory_store() {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();

        assert_eq!(resp.status(), StatusCode::OK);
        let json = body_json(resp.into_body()).await;
        assert_eq!(json["inter_count"], 0);
        assert_eq!(json["relation_count"], 0);

        // State muss jetzt gesetzt sein
        assert!(state.bundle.lock().await.is_some());
    }

    // ─── Test 2 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn freeze_and_check_op_log_has_entry() {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        // Laden
        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // Inter hinzufügen
        let inter_id = add_test_inter(&app, "Head").await;

        // Freeze
        let req = Request::builder()
            .method("POST")
            .uri(format!("/sig/inter/{}/freeze", inter_id))
            .body(Body::empty())
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);

        // Op-Log prüfen
        let req = Request::builder()
            .method("GET")
            .uri("/sig/history?limit=10")
            .body(Body::empty())
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);
        let json = body_json(resp.into_body()).await;
        let ops = json.as_array().unwrap();
        // Mindestens AddInter + Freeze im Log
        assert!(ops.len() >= 2, "expected at least 2 op-log entries");
        let has_freeze = ops
            .iter()
            .any(|o| o["kind_json"].as_str().unwrap_or("").contains("Freeze"));
        assert!(has_freeze, "Freeze op must be in op-log");
    }

    // ─── Test 3 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn modify_inter_updates_meta() {
        let app = app_with_loaded_sig().await;
        let inter_id = add_test_inter(&app, "Stem").await;

        let body = serde_json::json!({ "field": "grade", "value": 0.42 });
        let req = Request::builder()
            .method("POST")
            .uri(format!("/sig/inter/{}/modify", inter_id))
            .header("content-type", "application/json")
            .body(Body::from(body.to_string()))
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);

        // History muss ModifyInter enthalten
        let req = Request::builder()
            .method("GET")
            .uri("/sig/history?limit=5")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        let json = body_json(resp.into_body()).await;
        let ops = json.as_array().unwrap();
        let has_modify = ops
            .iter()
            .any(|o| o["kind_json"].as_str().unwrap_or("").contains("ModifyInter"));
        assert!(has_modify, "ModifyInter must appear in history");
    }

    // ─── Test 4 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn undo_reverts_freeze() {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        // Laden + Inter hinzufügen
        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        let inter_id = add_test_inter(&app, "Head").await;

        // Freeze
        let req = Request::builder()
            .method("POST")
            .uri(format!("/sig/inter/{}/freeze", inter_id))
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // Prüfen: frozen=true im State
        {
            let guard = state.bundle.lock().await;
            let bundle = guard.as_ref().unwrap();
            let is_frozen = bundle.sig.get(InterId(inter_id)).map(|i| i.is_frozen()).unwrap_or(false);
            assert!(is_frozen, "inter should be frozen after freeze");
        }

        // Undo
        let req = Request::builder()
            .method("POST")
            .uri("/sig/undo")
            .body(Body::empty())
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);

        // Prüfen: frozen=false nach undo
        {
            let guard = state.bundle.lock().await;
            let bundle = guard.as_ref().unwrap();
            let is_frozen = bundle.sig.get(InterId(inter_id)).map(|i| i.is_frozen()).unwrap_or(true);
            assert!(!is_frozen, "inter should be unfrozen after undo");
        }
    }

    // ─── Test 5 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn redo_reapplies() {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        let inter_id = add_test_inter(&app, "Head").await;

        // Freeze
        let req = Request::builder()
            .method("POST")
            .uri(format!("/sig/inter/{}/freeze", inter_id))
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // Undo (unfreeze)
        let req = Request::builder()
            .method("POST")
            .uri("/sig/undo")
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // Redo (re-freeze)
        let req = Request::builder()
            .method("POST")
            .uri("/sig/redo")
            .body(Body::empty())
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);

        // frozen=true nach redo
        {
            let guard = state.bundle.lock().await;
            let bundle = guard.as_ref().unwrap();
            let is_frozen =
                bundle.sig.get(InterId(inter_id)).map(|i| i.is_frozen()).unwrap_or(false);
            assert!(is_frozen, "inter should be frozen again after redo");
        }
    }

    // ─── Test 6 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn spatial_query_returns_inters_in_box() {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // Inter bei (10,20,30,40)
        let inter_id = add_test_inter(&app, "Bar").await;

        // Query die die Box überlappt
        let req = Request::builder()
            .method("GET")
            .uri("/sig/inters/at?x=5&y=15&w=50&h=50")
            .body(Body::empty())
            .unwrap();
        let resp = app.clone().oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);
        let json = body_json(resp.into_body()).await;
        let ids = json["inter_ids"].as_array().unwrap();
        assert!(
            ids.iter().any(|v| v.as_u64() == Some(inter_id)),
            "spatial query must find the inter"
        );

        // Query die nicht überlappt
        let req = Request::builder()
            .method("GET")
            .uri("/sig/inters/at?x=1000&y=1000&w=5&h=5")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        let json = body_json(resp.into_body()).await;
        let ids = json["inter_ids"].as_array().unwrap();
        assert!(ids.is_empty(), "query far away must return empty");
    }

    // ─── Test 7 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn delete_frozen_inter_returns_403() {
        let state = Arc::new(SigState::new());
        let app = router::<()>().layer(Extension(Arc::clone(&state)));

        let req = Request::builder()
            .method("GET")
            .uri("/sig/load?path=:memory:")
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        let inter_id = add_test_inter(&app, "Clef").await;

        // Freeze
        let req = Request::builder()
            .method("POST")
            .uri(format!("/sig/inter/{}/freeze", inter_id))
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // DELETE → muss 403 liefern
        let req = Request::builder()
            .method("DELETE")
            .uri(format!("/sig/inter/{}", inter_id))
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);
    }

    // ─── Test 8 ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn history_returns_recent_ops() {
        let app = app_with_loaded_sig().await;

        // Mehrere Operationen
        let id1 = add_test_inter(&app, "Head").await;
        let id2 = add_test_inter(&app, "Stem").await;
        let _ = id2;

        // Freeze des ersten Inters
        let req = Request::builder()
            .method("POST")
            .uri(format!("/sig/inter/{}/freeze", id1))
            .body(Body::empty())
            .unwrap();
        app.clone().oneshot(req).await.unwrap();

        // History abrufen
        let req = Request::builder()
            .method("GET")
            .uri("/sig/history?limit=5")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);
        let json = body_json(resp.into_body()).await;
        let ops = json.as_array().unwrap();

        // Mindestens 3 Einträge: AddInter × 2 + Freeze
        assert!(ops.len() >= 3, "expected at least 3 ops, got {}", ops.len());

        // Alle Einträge haben id, kind_json, timestamp, author
        for op in ops {
            assert!(op["id"].as_u64().is_some(), "op.id must be a u64");
            assert!(op["kind_json"].as_str().is_some(), "op.kind_json must be a string");
            assert!(op["timestamp"].as_str().is_some(), "op.timestamp must be a string");
            assert!(op["author"].as_str().is_some(), "op.author must be a string");
        }
    }
}
