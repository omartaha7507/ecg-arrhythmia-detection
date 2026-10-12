FILE_PATH = "./training/200_ECG_0_1800.mat"
from scipy.io import loadmat

mat = loadmat(FILE_PATH)
import requests

API_URL = "http://127.0.0.1:8000/predict-mat"

with open(FILE_PATH, "rb") as f:
    files = {"file": (FILE_PATH, f, "application/octet-stream")}
    response = requests.post(API_URL, files=files)

print("Status Code:", response.status_code)
print("Response:", response.json())
print("Prediction:", response.json()["predicted_class"])