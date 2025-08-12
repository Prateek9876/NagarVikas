# ml_model/model_inference.py
import io
import os
from PIL import Image
import torch
import torch.nn as nn
from torchvision import transforms, models

THIS_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(THIS_DIR, "best_mobilenet_model.pth")  # ensure .pth sits here
CLASS_NAMES = ["invalid", "valid"]   
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# -------------------------------------------------------

def build_model(num_classes=len(CLASS_NAMES)):
    model = models.mobilenet_v2(pretrained=False)
    model.classifier = nn.Sequential(
        nn.Linear(1280, 512),
        nn.ReLU(),
        nn.Dropout(0.3),
        nn.Linear(512, num_classes)
    )
    return model

preprocess = transforms.Compose([
    transforms.Lambda(lambda img: img.convert("RGB")),
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225])
])

_model = None
def load_model():
    global _model
    if _model is not None:
        return _model
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")
    model = build_model()
    state = torch.load(MODEL_PATH, map_location=DEVICE)
    model.load_state_dict(state)
    model.to(DEVICE)
    model.eval()
    _model = model
    return _model

def classify_image(image_bytes):
    """
    Args:
      image_bytes: raw bytes (for example file.read() from an upload)
    Returns:
      dict: {"label": "valid"|"invalid", "score": float, "probs": [...]}
    Raises:
      ValueError if bytes are not a valid image.
    """
    model = load_model()
    try:
        img = Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        raise ValueError(f"Invalid image data: {e}")

    x = preprocess(img).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        logits = model(x)
        probs = torch.nn.functional.softmax(logits, dim=1).squeeze(0)
        score, idx = torch.max(probs, dim=0)
        return {
            "label": CLASS_NAMES[int(idx)],
            "score": float(score),
            "probs": [float(p) for p in probs.cpu().numpy()]
        }