//! Integration-Tests für die HTTP-API. Greift auf den Router direkt zu
//! (kein TCP-Listener nötig — `tower::ServiceExt::oneshot`).

use axum::body::to_bytes;
use axum::http::{Method, Request, StatusCode};
use omr_labeler::active_learning::{Level, LabelingQueue};
use omr_labeler::api::{router, AppState};
use omr_labeler::persistence::LabelDb;
use std::sync::Arc;
use tower::ServiceExt;

fn make_state() -> Arc<AppState> {
    let db = LabelDb::open_in_memory().unwrap();
    Arc::new(AppState::with_db(db))
}

async fn body_string(resp: axum::response::Response) -> String {
    let bytes = to_bytes(resp.into_body(), 1024 * 1024).await.unwrap();
    String::from_utf8(bytes.to_vec()).unwrap()
}

#[tokio::test]
async fn api_status_returns_counts() {
    let state = make_state();
    let app = router(state);
    let resp = app
        .oneshot(
            Request::builder()
                .method(Method::GET)
                .uri("/api/status")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let body = body_string(resp).await;
    let v: serde_json::Value = serde_json::from_str(&body).unwrap();
    assert_eq!(v["pdfs"], 0);
    assert_eq!(v["systems"], 0);
    assert_eq!(v["elements"], 0);
    assert_eq!(v["labels"], 0);
}

#[tokio::test]
async fn api_queue_next_returns_item() {
    let state = make_state();
    {
        let mut q = state.queue.write().await;
        q.push(Level::Line, "sys-test".into(), None, 0.9);
    }
    let app = router(state);
    let resp = app
        .oneshot(
            Request::builder()
                .method(Method::GET)
                .uri("/api/queue/next?n=1")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v: serde_json::Value = serde_json::from_str(&body_string(resp).await).unwrap();
    assert_eq!(v["items"].as_array().unwrap().len(), 1);
    assert_eq!(v["items"][0]["system_id"], "sys-test");
}

#[tokio::test]
async fn api_queue_answer_persists_label() {
    let state = make_state();
    let id = {
        let mut q = state.queue.write().await;
        q.push(Level::Line, "sys-1".into(), None, 0.9)
    };
    let app = router(state.clone());
    let body = serde_json::json!({
        "item_id": id,
        "level": "line",
        "decision": "yes",
    });
    let resp = app
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/api/queue/answer")
                .header("Content-Type", "application/json")
                .body(axum::body::Body::from(body.to_string()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // Anschließend prüfen, dass das Label persistiert wurde.
    let count = {
        let guard = state.db.lock().expect("db mutex poisoned");
        guard.as_ref().unwrap().count_labels("").unwrap()
    };
    assert_eq!(count, 1);
}

#[tokio::test]
async fn api_export_corpus_returns_json() {
    let state = make_state();
    {
        let mut q = state.queue.write().await;
        let _ = q.push(Level::Line, "sys-1".into(), None, 0.9);
    }
    // Antwort einbringen, damit der Export nicht leer ist.
    let id = state.queue.read().await.items.front().unwrap().id;
    let app = router(state.clone());
    let answer = serde_json::json!({
        "item_id": id,
        "level": "line",
        "decision": "yes",
    });
    let _ = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/api/queue/answer")
                .header("Content-Type", "application/json")
                .body(axum::body::Body::from(answer.to_string()))
                .unwrap(),
        )
        .await
        .unwrap();

    let resp = app
        .oneshot(
            Request::builder()
                .method(Method::GET)
                .uri("/api/export/corpus")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v: serde_json::Value = serde_json::from_str(&body_string(resp).await).unwrap();
    let arr = v.as_array().expect("export muss ein JSON-Array sein");
    assert!(!arr.is_empty(), "export darf nicht leer sein");
    assert_eq!(arr[0]["level"], "line");
    assert_eq!(arr[0]["decision"], "yes");
}

// Sicherstellen, dass die LabelingQueue selbst ohne API getestet wird —
// dies dient als zweites Sicherheits-Netz, falls die API-Wiring bricht.
#[tokio::test]
async fn queue_basic_invariants() {
    let mut q = LabelingQueue::new();
    let a = q.push(Level::Line, "a".into(), None, 0.1);
    let b = q.push(Level::Line, "b".into(), None, 0.9);
    q.re_prioritize();
    let nxt = q.next().unwrap();
    assert_eq!(nxt.id, b);
    q.answer(b, omr_labeler::active_learning::Decision::Yes);
    let nxt = q.next().unwrap();
    assert_eq!(nxt.id, a);
}
