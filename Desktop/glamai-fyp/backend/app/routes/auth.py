from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, UserResponse
from app.utils.dependencies import get_db
from app.utils.logger import get_logger
from app.utils.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication"])
logger = get_logger("auth")


@router.post("/register", response_model=UserResponse)
def register(user: UserRegister, db: Session = Depends(get_db)):
    logger.info("Register attempt for email=%s", user.email)
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        logger.warning("Register failed — email already exists: %s", user.email)
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = User(
        name=user.name,
        email=user.email,
        password=hash_password(user.password),
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    logger.info("User registered: id=%d email=%s", new_user.id, new_user.email)
    return new_user


@router.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    logger.info("Login attempt for email=%s", user.email)
    existing_user = db.query(User).filter(User.email == user.email).first()

    if not existing_user:
        logger.warning("Login failed — user not found: %s", user.email)
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(user.password, existing_user.password):
        logger.warning("Login failed — wrong password for user id=%d", existing_user.id)
        raise HTTPException(status_code=401, detail="Invalid password")

    token = create_access_token(existing_user.id)
    logger.info("Login successful for user id=%d", existing_user.id)
    return {
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": existing_user.id,
            "name": existing_user.name,
            "email": existing_user.email,
        },
    }
