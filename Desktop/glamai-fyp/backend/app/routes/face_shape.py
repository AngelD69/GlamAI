import io
import os
from functools import lru_cache
from typing import Optional

import numpy as np
from fastapi import APIRouter, File, HTTPException, UploadFile
from PIL import Image
from pydantic import BaseModel

from app.utils.logger import get_logger

router = APIRouter(prefix="/face-shape", tags=["Face Shape Detection"])
logger = get_logger("face_shape")

MODEL_PATH = os.getenv(
    "FACE_SHAPE_MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "../../../dataset/face_shape_model.keras"),
)

# Classes must match the order ImageDataGenerator assigned them (alphabetical)
CLASSES = ["Heart", "Oblong", "Oval", "Round", "Square"]
IMG_SIZE = (224, 224)


class FaceShapeResult(BaseModel):
    face_shape: str
    confidence: float
    all_scores: dict[str, float]


@lru_cache(maxsize=1)
def _load_model():
    """Load model once and cache it for the lifetime of the process."""
    import tensorflow as tf  # imported lazily so server starts even without TF installed

    model_path = os.path.abspath(MODEL_PATH)
    if not os.path.exists(model_path):
        logger.error("Model file not found at: %s", model_path)
        return None
    logger.info("Loading face shape model from %s", model_path)
    model = tf.keras.models.load_model(model_path)
    logger.info("Face shape model loaded successfully")
    return model


def _preprocess(image_bytes: bytes) -> np.ndarray:
    """Resize and normalise image to model input format."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize(IMG_SIZE)
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)  # shape: (1, 224, 224, 3)


def _get_model():
    model = _load_model()
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Face shape model is not available yet. Please try again after training completes.",
        )
    return model


@router.post("/detect", response_model=FaceShapeResult)
async def detect_face_shape(file: UploadFile = File(...)):
    allowed_types = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic", "image/heif"}
    allowed_exts = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif"}
    ext = os.path.splitext(file.filename or "")[1].lower()
    if file.content_type not in allowed_types and ext not in allowed_exts:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, or WEBP images are allowed")

    logger.info("Face shape detection request — file=%s type=%s", file.filename, file.content_type)

    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    try:
        arr = _preprocess(image_bytes)
    except Exception as e:
        logger.error("Image preprocessing failed: %s", e)
        raise HTTPException(status_code=422, detail="Could not read the uploaded image")

    model = _get_model()
    predictions = model.predict(arr, verbose=0)[0]  # shape: (5,)

    scores = {cls: float(round(predictions[i] * 100, 2)) for i, cls in enumerate(CLASSES)}
    top_idx = int(np.argmax(predictions))
    face_shape = CLASSES[top_idx]
    confidence = float(round(predictions[top_idx] * 100, 2))

    logger.info("Detected face shape: %s (%.1f%%)", face_shape, confidence)
    return FaceShapeResult(face_shape=face_shape, confidence=confidence, all_scores=scores)


@router.get("/status")
def model_status():
    """Check whether the face shape model is loaded and ready."""
    model_path = os.path.abspath(MODEL_PATH)
    exists = os.path.exists(model_path)
    loaded: Optional[bool] = None
    if exists:
        try:
            loaded = _load_model() is not None
        except Exception:
            loaded = False
    return {
        "model_path": model_path,
        "file_exists": exists,
        "model_loaded": loaded,
        "classes": CLASSES,
    }
