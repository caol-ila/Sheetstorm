//! Eingebettete Frontend-Assets.
//!
//! Die Web-Dateien werden zur Compile-Zeit in das Binary geschrieben,
//! damit der `omr-labeler`-Prozess wirklich self-contained ist und ohne
//! externe Datei-Abhängigkeiten ausgeliefert werden kann.

pub const INDEX_HTML: &str = include_str!("../web/index.html");
pub const APP_JS: &str = include_str!("../web/app.js");
pub const STYLE_CSS: &str = include_str!("../web/style.css");
