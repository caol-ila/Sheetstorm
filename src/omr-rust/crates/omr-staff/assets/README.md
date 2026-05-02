# omr-staff assets

## staff-unet.onnx

Das ONNX-Modell für U-Net-basiertes Staff-Removal.

**Nicht im Repository enthalten** — muss lokal trainiert oder heruntergeladen werden.

### Training

```powershell
cd tools/training
# 1. Trainingsdaten generieren
.venv\Scripts\python.exe generate_unet_training_data.py --output-dir data/unet --n-pairs 800

# 2. Modell trainieren
.venv\Scripts\python.exe train_staff_unet.py `
    --input-dir data/unet/input `
    --target-dir data/unet/target `
    --output models/staff_unet --epochs 20 --cpu

# 3. ONNX exportieren
.venv\Scripts\python.exe export_onnx.py --model unet `
    --weights models/staff_unet.pt `
    --output ..\..\src\omr-rust\crates\omr-staff\assets\staff-unet.onnx
```

### Modell-Interface

- **Input**: `[1, 1, H, W]` — f32, 0.0=weiß, 1.0=schwarz (Notenpixel)
- **Output**: `[1, 1, H, W]` — f32 Sigmoid-Maske, Werte > 0.5 = Stafflinie
- **Architektur**: leichtgewichtiges U-Net (~250k Parameter)
- **Opset**: 14
