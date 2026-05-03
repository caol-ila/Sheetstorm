//! Synthetic Cold-Start: lädt einen kleinen, klassen-balancierten
//! Sample-Vorrat aus einem Verzeichnis von Klassen-Subdirs und seedet
//! die Labeling-Queue damit. Damit kann der Active-Learner bereits in
//! der ersten Sitzung qualitativ relevante Antworten einsammeln.

use crate::active_learning::{LabelingQueue, Level, QueueItem};
use std::path::{Path, PathBuf};

/// Ein synthetisches Sample mit Klassen-Label und Pfad zur Bilddatei.
#[derive(Debug, Clone)]
pub struct SyntheticSample {
    pub class: String,
    pub image_path: PathBuf,
}

const IMAGE_EXTS: [&str; 5] = ["png", "jpg", "jpeg", "bmp", "tiff"];

/// Liest `dir` und liefert bis zu 5 verschiedene Klassen mit je einem
/// Sample (Round-Robin, Round 1). Wenn `dir` nicht existiert oder leer
/// ist, kommt ein leeres Vec zurück.
/// Liest alle PNGs aus dem Verzeichnisbaum unter `dir` rekursiv und
/// klassifiziert sie über den **relativen Pfad ohne Datei-Extension** —
/// d.h. das synthetic_corpus_v1 mit der Struktur
/// `single/noteheads/filled_quarter/000001.png` liefert die Klasse
/// `single/noteheads/filled_quarter`.
fn collect_images_recursive(root: &Path) -> Vec<(String, PathBuf)> {
    fn walk(base: &Path, dir: &Path, out: &mut Vec<(String, PathBuf)>) {
        let entries = match std::fs::read_dir(dir) {
            Ok(e) => e,
            Err(_) => return,
        };
        for entry in entries.flatten() {
            let p = entry.path();
            if p.is_dir() {
                walk(base, &p, out);
                continue;
            }
            let ext = p
                .extension()
                .and_then(|s| s.to_str())
                .map(|s| s.to_ascii_lowercase());
            let Some(ext) = ext else { continue };
            if !IMAGE_EXTS.contains(&ext.as_str()) {
                continue;
            }
            // Klasse = Eltern-Verzeichnis relativ zum Korpus-Root.
            let parent = match p.parent() {
                Some(par) => par,
                None => continue,
            };
            let rel = parent.strip_prefix(base).unwrap_or(parent);
            let class = rel
                .components()
                .filter_map(|c| c.as_os_str().to_str())
                .collect::<Vec<_>>()
                .join("/");
            if class.is_empty() {
                continue;
            }
            out.push((class, p));
        }
    }
    let mut out = Vec::new();
    walk(root, root, &mut out);
    out
}

/// Liest den synthetischen Korpus aus dem angegebenen Verzeichnis.
///
/// Erwartete Struktur (eine oder mehrere Hierarchie-Ebenen):
///   <dir>/<class>/...png
///   <dir>/single/noteheads/filled_quarter/000001.png   →  class = "single/noteheads/filled_quarter"
///
/// Falls der Pfad nicht existiert oder kein passendes Material gefunden
/// ist, kommt ein leeres Vec zurück.
pub fn load_synthetic_corpus(dir: &Path) -> Vec<SyntheticSample> {
    if !dir.exists() {
        return Vec::new();
    }
    let images = collect_images_recursive(dir);
    if images.is_empty() {
        return Vec::new();
    }
    // Group by class
    let mut by_class: std::collections::BTreeMap<String, Vec<PathBuf>> = std::collections::BTreeMap::new();
    for (class, p) in images {
        by_class.entry(class).or_default().push(p);
    }

    // Round-Robin: pro Klasse genau ein Sample, max. 5 Klassen.
    let mut out = Vec::new();
    for (class, mut images) in by_class.into_iter().take(5) {
        images.sort();
        if let Some(p) = images.into_iter().next() {
            out.push(SyntheticSample {
                class,
                image_path: p,
            });
        }
    }
    out
}

/// Seedet die Queue mit den ersten 5 synthetischen Samples (oder weniger,
/// falls der Corpus kleiner ist). Diese Samples bekommen hohe
/// Unsicherheit (1.0), damit sie als erste behandelt werden.
pub fn seed_queue_with_synthetic(queue: &mut LabelingQueue, samples: &[SyntheticSample]) {
    for (i, s) in samples.iter().take(5).enumerate() {
        let item = QueueItem {
            id: 0, // wird von push_item überschrieben
            level: Level::Class,
            uncertainty: 1.0,
            system_id: format!("synthetic#{}", i),
            element_id: Some(format!("synthetic#{}", i)),
            suggested_class: Some(s.class.clone()),
            top_k: vec![(s.class.clone(), 1.0)],
        };
        queue.push_item(item);
    }
    queue.re_prioritize();
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::File;
    use std::io::Write;

    fn make_test_dir(suffix: &str) -> std::path::PathBuf {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        let dir = std::env::temp_dir().join(format!("omr-labeler-test-{}-{}", suffix, nanos));
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn load_empty_dir_returns_empty() {
        let dir = make_test_dir("synth-empty");
        assert!(load_synthetic_corpus(&dir).is_empty());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn load_missing_dir_returns_empty() {
        assert!(load_synthetic_corpus(Path::new("Z:/no/such/dir-12345")).is_empty());
    }

    #[test]
    fn load_corpus_with_classes() {
        let dir = make_test_dir("synth-classes");
        for cls in ["notehead", "rest", "clef"] {
            let d = dir.join(cls);
            std::fs::create_dir_all(&d).unwrap();
            let mut f = File::create(d.join("a.png")).unwrap();
            f.write_all(&[0u8; 8]).unwrap();
        }
        let samples = load_synthetic_corpus(&dir);
        assert_eq!(samples.len(), 3);
        let mut classes: Vec<_> = samples.iter().map(|s| s.class.clone()).collect();
        classes.sort();
        assert_eq!(classes, vec!["clef", "notehead", "rest"]);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn seed_pushes_into_queue() {
        let mut q = LabelingQueue::new();
        let samples = vec![
            SyntheticSample {
                class: "notehead".into(),
                image_path: PathBuf::from("/x/n.png"),
            },
            SyntheticSample {
                class: "rest".into(),
                image_path: PathBuf::from("/x/r.png"),
            },
        ];
        seed_queue_with_synthetic(&mut q, &samples);
        assert_eq!(q.len(), 2);
    }
}
