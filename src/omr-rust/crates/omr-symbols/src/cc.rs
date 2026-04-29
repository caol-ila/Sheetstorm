// Connected-Components-Labeling — 2-Pass-Algorithmus mit Union-Find.
//
// Output: Liste aller schwarzen Komponenten mit BBox und Pixel-Count.

use omr_core::{Binary, Rect};

pub struct ConnectedComponent {
    pub bbox: Rect,
    pub pixel_count: u32,
    /// Optional: Pixel-Liste für nachgelagerte Analysen.
    pub pixels: Vec<(u32, u32)>,
}

pub fn connected_components(bin: &Binary) -> Vec<ConnectedComponent> {
    let w = bin.w as usize;
    let h = bin.h as usize;

    // Pass 1: vorläufige Labels mit 4-Connectivity. Union-Find für Equivalences.
    let mut labels = vec![0u32; w * h];
    let mut uf = UnionFind::new(1); // 0 = unlabeled; labels start at 1
    let mut next_label = 1u32;

    for y in 0..h {
        for x in 0..w {
            let idx = y * w + x;
            if bin.data[idx] == 0 {
                continue;
            }
            let left = if x > 0 { labels[idx - 1] } else { 0 };
            let up = if y > 0 { labels[idx - w] } else { 0 };
            match (left, up) {
                (0, 0) => {
                    labels[idx] = next_label;
                    uf.add();
                    next_label += 1;
                }
                (l, 0) | (0, l) => labels[idx] = l,
                (l, u) => {
                    let m = l.min(u);
                    labels[idx] = m;
                    uf.union(l, u);
                }
            }
        }
    }

    // Pass 2: Resolve labels.
    let n_labels = next_label as usize;
    let mut bb_min_x = vec![u32::MAX; n_labels];
    let mut bb_min_y = vec![u32::MAX; n_labels];
    let mut bb_max_x = vec![0u32; n_labels];
    let mut bb_max_y = vec![0u32; n_labels];
    let mut count = vec![0u32; n_labels];

    for y in 0..h {
        for x in 0..w {
            let idx = y * w + x;
            let l = labels[idx];
            if l == 0 { continue; }
            let r = uf.find(l);
            labels[idx] = r;
            let r = r as usize;
            count[r] += 1;
            if (x as u32) < bb_min_x[r] { bb_min_x[r] = x as u32; }
            if (y as u32) < bb_min_y[r] { bb_min_y[r] = y as u32; }
            if (x as u32) > bb_max_x[r] { bb_max_x[r] = x as u32; }
            if (y as u32) > bb_max_y[r] { bb_max_y[r] = y as u32; }
        }
    }

    let mut result = Vec::new();
    let mut label_to_index = std::collections::HashMap::new();
    for l in 1..n_labels {
        if count[l] == 0 { continue; }
        let bbox = Rect {
            x: bb_min_x[l],
            y: bb_min_y[l],
            w: bb_max_x[l] - bb_min_x[l] + 1,
            h: bb_max_y[l] - bb_min_y[l] + 1,
        };
        label_to_index.insert(l as u32, result.len());
        result.push(ConnectedComponent {
            bbox,
            pixel_count: count[l],
            pixels: Vec::new(),
        });
    }

    // Optional: pixels nur sammeln wenn benötigt — hier weglassen für Speed.
    let _ = label_to_index;
    let _ = labels;
    result
}

struct UnionFind {
    parent: Vec<u32>,
}

impl UnionFind {
    fn new(n: usize) -> Self {
        Self { parent: (0..n as u32).collect() }
    }
    fn add(&mut self) -> u32 {
        let id = self.parent.len() as u32;
        self.parent.push(id);
        id
    }
    fn find(&mut self, mut x: u32) -> u32 {
        while self.parent[x as usize] != x {
            let p = self.parent[x as usize];
            self.parent[x as usize] = self.parent[p as usize];
            x = self.parent[x as usize];
        }
        x
    }
    fn union(&mut self, a: u32, b: u32) {
        let ra = self.find(a);
        let rb = self.find(b);
        if ra != rb {
            let (small, large) = if ra < rb { (ra, rb) } else { (rb, ra) };
            self.parent[large as usize] = small;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_two_components() {
        let mut bin = Binary::new(20, 20);
        // Komponente A: 3x3 oben links
        for y in 1..4 { for x in 1..4 { bin.set(x, y, 1); } }
        // Komponente B: 2x2 unten rechts
        for y in 15..17 { for x in 15..17 { bin.set(x, y, 1); } }
        let ccs = connected_components(&bin);
        assert_eq!(ccs.len(), 2);
        assert_eq!(ccs[0].pixel_count, 9);
        assert_eq!(ccs[1].pixel_count, 4);
    }
}
