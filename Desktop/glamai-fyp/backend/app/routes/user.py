import os
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserProfileUpdate, UserResponse
from app.utils.dependencies import get_current_user, get_db
from app.utils.logger import get_logger

UPLOAD_DIR = "uploads/profile_pictures"
os.makedirs(UPLOAD_DIR, exist_ok=True)

router = APIRouter(prefix="/users", tags=["Users"])
logger = get_logger("user")


@router.get("/me", response_model=UserResponse)
def get_my_profile(current_user: User = Depends(get_current_user)):
    logger.debug("Profile fetched for user id=%d", current_user.id)
    return current_user


@router.put("/me", response_model=UserResponse)
def update_my_profile(
    updates: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    fields = updates.model_dump(exclude_unset=True)
    logger.info("User id=%d updating profile fields=%s", current_user.id, list(fields.keys()))
    for field, value in fields.items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    logger.info("Profile updated for user id=%d", current_user.id)
    return current_user


@router.post("/me/upload-picture", response_model=UserResponse)
def upload_profile_picture(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    if file.content_type not in allowed_types:
        logger.warning(
            "User id=%d uploaded invalid image type: %s", current_user.id, file.content_type
        )
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, or WEBP images are allowed")

    extension = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    with open(file_path, "wb") as f:
        f.write(file.file.read())

    current_user.profile_picture = f"/uploads/profile_pictures/{filename}"
    db.commit()
    db.refresh(current_user)
    logger.info("Profile picture uploaded for user id=%d → %s", current_user.id, filename)
    return current_user
