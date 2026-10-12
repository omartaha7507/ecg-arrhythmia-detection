
import os
import numpy as np
import scipy.io as sio
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv1D, MaxPool1D, Flatten, Dense, Input
from tensorflow.keras.callbacks import ModelCheckpoint
import json
import pickle

# === Parameters ===
DATA_DIR = "./training/input"
SEG_LEN = 300  # Length of ECG beat segment
LEADS = [0, 1]  # Assuming two leads
X = []
y = []

count = 0
for fname in os.listdir(DATA_DIR):
    if not fname.endswith(".mat"):
        continue

    fpath = os.path.join(DATA_DIR, fname)
    try:
        data = sio.loadmat(fpath)

        if "ECG_1" in data:
            ecg1 = data["ECG_1"].squeeze()
        else:
            print(f"⚠️ {fname}: Missing ECG_1")
            continue

        if "ECG_2" in data:
            ecg2 = data["ECG_2"].squeeze()
        else:
            ecg2 = np.zeros_like(ecg1)

        ecg = np.stack([ecg1, ecg2], axis=0)

        if "ANNOTD" in data:
            labels = data["ANNOTD"].squeeze()
        else:
            print(f"⚠️ {fname}: Missing labels")
            continue
        if "ATRTIMED" in data:
            sample_locs = data["ATRTIMED"].squeeze().astype(int)
        else:
            print(f"⚠️ {fname}: Missing sample locations")
            continue

        for label, idx in zip(labels, sample_locs):
            start = max(idx - SEG_LEN // 2, 0)
            end = start + SEG_LEN
            if end > ecg.shape[1]:
                continue
            beat = ecg[:, start:end]
            if beat.shape[1] == SEG_LEN:
                X.append(beat)
                y.append(str(label))
                count += 1

    except Exception as e:
        print(f"❌ Skipping {fname} due to error: {e}")

print(f"✅ Total beats extracted: {count}")
X = np.stack(X, axis=0)  # (N, 2, 300)
X = np.transpose(X, (0, 2, 1))  # (N, 300, 2)

le = LabelEncoder()
y_int = le.fit_transform(y)
y_enc = OneHotEncoder(sparse_output=False).fit_transform(y_int.reshape(-1, 1))

X_train, X_test, y_train, y_test = train_test_split(X, y_enc, test_size=0.2, random_state=42, stratify=y_int)

# === Build CNN ===
model = Sequential([
    Input(shape=(SEG_LEN, 2)),
    Conv1D(32, 5, activation='relu'),
    MaxPool1D(2),
    Conv1D(64, 5, activation='relu'),
    MaxPool1D(2),
    Flatten(),
    Dense(64, activation='relu'),
    Dense(len(le.classes_), activation='softmax')
])
model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

# === Train ===
chk = ModelCheckpoint("ecg_mat_model.h5", save_best_only=True, monitor="val_accuracy")
history = model.fit(X_train, y_train, validation_data=(X_test, y_test), epochs=10, batch_size=64, callbacks=[chk])

# === Save classes and encoder ===
with open("class_mapping.json", "w") as f:
    json.dump({i: cl for i, cl in enumerate(le.classes_)}, f, indent=2)

with open("classes.json", "w") as f:
    json.dump(list(le.classes_), f, indent=2)

with open("label_encoder.pkl", "wb") as f:
    pickle.dump(le, f)

print("✅ Training complete.")
