# ECG Arrhythmia Detection

Bachelor thesis project, German University in Cairo, 2025.

A Flutter app uploads a two-lead ECG recording (`.mat` file) to a FastAPI server. A 1D CNN on the server classifies heartbeats, and the server also estimates heart rate.

## Repository layout

- `app/` is the Flutter client. You pick a `.mat` file and the app sends it to the server's `/predict-mat` endpoint. The result screen shows the record ID, heart rate (BPM), the predicted beat class and an animated ECG chart.
- `backend/` contains:
  - `trainModel.py`, the training script. It takes 300-sample, two-lead beat segments centred on the annotated beat positions, trains a 1D CNN (Keras/TensorFlow) and saves `ecg_mat_model.h5`, `classes.json`, `class_mapping.json` and `label_encoder.pkl`.
  - `appApi.py`, the FastAPI server. Its endpoints are `GET /health`, `GET /labels` and `POST /predict-mat`. For each upload it normalises and band-pass filters both leads, detects R-peaks to compute BPM, classifies the centre segment and returns the class probabilities, per-beat BPM and a downsampled waveform.
  - `httpTest.py`, a small script that sends a `.mat` file to the running server.
  - The trained model and label files, plus `requirements.txt`.

## Running

Backend (run from inside `backend/`, because the model and labels are loaded by relative path):

```bash
pip install -r requirements.txt
uvicorn appApi:app --host 0.0.0.0 --port 8000
```

App:

```bash
cd app
flutter pub get
flutter run
```

The app sends requests to `http://10.0.2.2:8000/predict-mat`, which is the host machine as seen from the Android emulator. To use a different server, change `serverUrl` in `app/lib/Widgets/mat-file-uploader.dart`.

## Data

The model was trained on the [MIT-BIH Arrhythmia Database](https://physionet.org/content/mitdb/) from PhysioNet. The data is not included in this repository. `trainModel.py` reads `.mat` files from `backend/training/input/`. Each file must contain the variables `ECG_1`, `ECG_2`, `ANNOTD` (beat labels) and `ATRTIMED` (beat sample positions).
