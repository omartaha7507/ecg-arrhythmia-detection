import io
import json
import numpy as np
import scipy.io as sio
from scipy.signal import butter, filtfilt, find_peaks
from fastapi import FastAPI, UploadFile, File, HTTPException
import tensorflow as tf

# === Config ===
SEG_LEN = 300               # segment length for model (samples)
NUM_LEADS = 2
SAMPLE_RATE = 500           # Hz (as you requested)
MAX_DURATION_MIN = 5
MAX_SAMPLES = SAMPLE_RATE * 60 * MAX_DURATION_MIN  # 150,000 samples

# === Utility: sharp QRS bandpass ===
def bandpass_qrs(signal, fs, lowcut=5.0, highcut=25.0, order=2):
    nyq = 0.5 * fs
    b, a = butter(order, [lowcut/nyq, highcut/nyq], btype='band')
    return filtfilt(b, a, signal)

# === Load model & labels ===
model = tf.keras.models.load_model("ecg_mat_model.h5")
with open("classes.json") as f:
    CLASSES = json.load(f)

# === FastAPI setup ===
app = FastAPI(
    title="ead ECG Arrhythmia API",
    description="Upload .mat files with ECG_1/ECG_2 to classify and measure BPM",
    version="1.0.0"
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/labels")
def labels():
    return {"classes": CLASSES}

@app.post("/predict-mat")
async def predict_mat(file: UploadFile = File(...)):
    try:
        # --- read file ---
        contents = await file.read()
        mat_data = sio.loadmat(io.BytesIO(contents))

        # --- extract & truncate leads ---
        ecg1 = mat_data.get("ECG_1")
        ecg2 = mat_data.get("ECG_2")
        if ecg1 is None or ecg2 is None:
            raise HTTPException(400, "Missing ECG_1 or ECG_2 in .mat")
        ecg1 = ecg1.flatten()[:MAX_SAMPLES]
        ecg2 = ecg2.flatten()[:MAX_SAMPLES]
        ecg = np.stack([ecg1, ecg2], axis=0)

        # --- normalize & bandpass each lead ---
        for i in range(NUM_LEADS):
            lead = ecg[i]
            lead = (lead - lead.mean()) / (lead.std() + 1e-8)
            ecg[i] = bandpass_qrs(lead, fs=SAMPLE_RATE)

        # --- R‐peak detection on lead I ---
        full = ecg[0]
        filtered = full  # already bandpassed 5–25 Hz

        min_dist = int(0.6 * SAMPLE_RATE)
        prom = 0.4 * np.std(filtered)
        peaks, _ = find_peaks(filtered, distance=min_dist, prominence=prom)

        # --- compute & clean RR intervals ---
        times = peaks / SAMPLE_RATE
        rr = np.diff(times)
        valid = (rr >= 0.3) & (rr <= 1.5)
        clean_rr = rr[valid]
        clean_times = times[1:][valid]

        inst_bpm = 60.0 / clean_rr
        avg_bpm  = float(np.mean(inst_bpm)) if len(inst_bpm) else None

        beats_info = [
            {"time": round(t, 2), "instant_BPM": round(b, 1)}
            for t, b in zip(clean_times, inst_bpm)
        ]

        # --- prediction on center segment ---
        center = ecg.shape[1] // 2
        seg_start = max(center - SEG_LEN // 2, 0)
        seg_end = seg_start + SEG_LEN
        segment = ecg[:, seg_start:seg_end].T.reshape(1, SEG_LEN, NUM_LEADS)
        preds = model.predict(segment, verbose=0)[0]
        top_idx = int(np.argmax(preds))

        # --- waveform_xy in original format (0.5s step from lead I) ---
        plot_sig = full[:MAX_SAMPLES]
        step = int(0.5 * SAMPLE_RATE)
        waveform_xy = [
            [round(i / SAMPLE_RATE, 2), float(plot_sig[i])]
            for i in range(0, len(plot_sig), step)
        ]

        return {
            "name": file.filename,
            "predicted_class": CLASSES[top_idx],
            "BPM": round(avg_bpm, 1) if avg_bpm is not None else None,
            "probabilities": {CLASSES[i]: float(p) for i, p in enumerate(preds)},
            "beats": beats_info,
            "waveform_xy": waveform_xy
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Processing error: {e}")