// Bild-Buffer-Wrapper.

use image::{GrayImage, ImageBuffer, Luma, Rgba as RgbaPx};

pub type Gray = GrayImage;
pub type Rgba = ImageBuffer<RgbaPx<u8>, Vec<u8>>;

/// Binärbild (0=weiß=Hintergrund, 1=schwarz=Notenobjekt).
pub struct Binary {
    pub w: u32,
    pub h: u32,
    pub data: Vec<u8>,
}

impl Binary {
    pub fn new(w: u32, h: u32) -> Self {
        Self { w, h, data: vec![0u8; (w * h) as usize] }
    }

    pub fn threshold_global(gray: &Gray, threshold: u8) -> Self {
        let (w, h) = (gray.width(), gray.height());
        let mut out = Self::new(w, h);
        for (i, p) in gray.pixels().enumerate() {
            out.data[i] = if p[0] < threshold { 1 } else { 0 };
        }
        out
    }

    pub fn get(&self, x: u32, y: u32) -> u8 {
        if x >= self.w || y >= self.h { return 0; }
        self.data[(y * self.w + x) as usize]
    }
    pub fn set(&mut self, x: u32, y: u32, v: u8) {
        if x >= self.w || y >= self.h { return; }
        self.data[(y * self.w + x) as usize] = v;
    }

    pub fn count(&self) -> usize {
        self.data.iter().filter(|&&v| v != 0).count()
    }

    pub fn to_gray(&self) -> Gray {
        let mut g = ImageBuffer::new(self.w, self.h);
        for (i, &v) in self.data.iter().enumerate() {
            let x = (i as u32) % self.w;
            let y = (i as u32) / self.w;
            g.put_pixel(x, y, Luma([if v == 0 { 255 } else { 0 }]));
        }
        g
    }

    pub fn row_density(&self) -> Vec<u32> {
        (0..self.h).map(|y| {
            let row_start = (y * self.w) as usize;
            let row_end = row_start + self.w as usize;
            self.data[row_start..row_end].iter().map(|&v| v as u32).sum()
        }).collect()
    }

    pub fn col_density(&self) -> Vec<u32> {
        let mut cols = vec![0u32; self.w as usize];
        for y in 0..self.h {
            for x in 0..self.w {
                cols[x as usize] += self.get(x, y) as u32;
            }
        }
        cols
    }
}
