//! build.rs for omr-embed
//!
//! Sets `has_embedded_model` cfg flag when assets/symbol_encoder_v1.onnx exists.
//! If the flag is set, OnnxCnnEncoder::embedded() will include the model bytes.
//! Generate the model with: python tools/training/train_embedding.py

fn main() {
    let model_path = std::path::Path::new("assets/symbol_encoder_v1.onnx");
    if model_path.exists() && model_path.metadata().map(|m| m.len() > 0).unwrap_or(false) {
        println!("cargo:rustc-cfg=has_embedded_model");
        println!("cargo:warning=omr-embed: embedded model found ({} bytes)", model_path.metadata().unwrap().len());
    } else {
        println!("cargo:warning=omr-embed: no embedded model found at assets/symbol_encoder_v1.onnx");
        println!("cargo:warning=omr-embed: run `python tools/training/train_embedding.py` to generate it");
    }
    println!("cargo:rerun-if-changed=assets/symbol_encoder_v1.onnx");
    println!("cargo:rerun-if-changed=build.rs");
}