import os
import time

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import SQLAlchemyError

from app.database import Base, engine
from app.models.appointment import Appointment  # noqa: F401 – needed for table creation
from app.models.service import Service  # noqa: F401
from app.models.user import User  # noqa: F401
from app.routes.appointment import router as appointment_router
from app.routes.auth import router as auth_router
from app.routes.face_shape import router as face_shape_router
from app.routes.chat import router as chat_router
from app.routes.recommendation import router as recommendation_router
from app.routes.service import router as service_router
from app.routes.user import router as user_router
from app.utils.logger import get_logger

logger = get_logger("main")

app = FastAPI(title="GlamAI API")

os.makedirs("uploads/profile_pictures", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

Base.metadata.create_all(bind=engine)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth_router)
app.include_router(appointment_router)
app.include_router(service_router)
app.include_router(user_router)
app.include_router(chat_router)
app.include_router(recommendation_router)
app.include_router(face_shape_router)


# ── Request / response logging middleware ─────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    logger.info("→ %s %s", request.method, request.url.path)
    response = await call_next(request)
    elapsed = (time.perf_counter() - start) * 1000
    logger.info(
        "← %s %s [%d] %.1fms",
        request.method,
        request.url.path,
        response.status_code,
        elapsed,
    )
    return response


# ── Global exception handlers ─────────────────────────────────────────────────
@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    logger.error(
        "Database error on %s %s: %s",
        request.method,
        request.url.path,
        exc,
        exc_info=True,
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "A database error occurred. Please try again later."},
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(
        "Unhandled exception on %s %s: %s",
        request.method,
        request.url.path,
        exc,
        exc_info=True,
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred."},
    )


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/")
def root():
    logger.debug("Health check called")
    return {"message": "GlamAI Backend Running"}
