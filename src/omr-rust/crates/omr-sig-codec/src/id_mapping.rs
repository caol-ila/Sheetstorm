//! Stabiles ID-Mapping zwischen MusicXML `<note id="..."/>` und `InterId`.
//!
//! Das Mapping wird beim Import aufgebaut und kann anschliessend genutzt
//! werden, um MusicXML-IDs zu Sig-Inters aufzul├╢sen und umgekehrt.

use omr_sig::inter::InterId;
use std::collections::HashMap;

/// Bidirektionales Mapping: MusicXML-ID Γåö InterId.
#[derive(Debug, Default, Clone)]
pub struct IdMapping {
    inter_to_xml: HashMap<InterId, String>,
    xml_to_inter: HashMap<String, InterId>,
}

impl IdMapping {
    /// Leeres Mapping.
    pub fn new() -> Self {
        Self::default()
    }

    /// Registriert eine Zuordnung.
    pub fn insert(&mut self, inter_id: InterId, xml_id: impl Into<String>) {
        let xml_id = xml_id.into();
        self.xml_to_inter.insert(xml_id.clone(), inter_id);
        self.inter_to_xml.insert(inter_id, xml_id);
    }

    /// XML-ID f├╝r einen Inter (falls vorhanden).
    pub fn xml_id_for(&self, id: InterId) -> Option<&str> {
        self.inter_to_xml.get(&id).map(String::as_str)
    }

    /// InterId f├╝r eine XML-ID (falls vorhanden).
    pub fn inter_id_for(&self, xml_id: &str) -> Option<InterId> {
        self.xml_to_inter.get(xml_id).copied()
    }

    /// Anzahl eingetragener Paare.
    pub fn len(&self) -> usize {
        self.inter_to_xml.len()
    }

    /// Leer?
    pub fn is_empty(&self) -> bool {
        self.inter_to_xml.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn insert_and_lookup_both_directions() {
        let mut m = IdMapping::new();
        let id = InterId(42);
        m.insert(id, "n7");
        assert_eq!(m.xml_id_for(id), Some("n7"));
        assert_eq!(m.inter_id_for("n7"), Some(id));
        assert_eq!(m.len(), 1);
    }

    #[test]
    fn missing_key_returns_none() {
        let m = IdMapping::new();
        assert!(m.xml_id_for(InterId(1)).is_none());
        assert!(m.inter_id_for("nX").is_none());
    }
}
