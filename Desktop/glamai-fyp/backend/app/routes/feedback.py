from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

from app.models.appointment import Appointment
from app.models.feedback import Feedback
from app.models.user import User
from app.schemas.feedback import FeedbackCreate, FeedbackResponse
from app.utils.dependencies import get_current_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/feedback", tags=["Feedback"])
logger = get_logger("feedback")

_analyzer = SentimentIntensityAnalyzer()


def _analyse(text: str) -> tuple[str, float]:
    """Return (label, compound_score) for the given review text."""
    compound = _analyzer.polarity_scores(text)["compound"]
    if compound >= 0.05:
        label = "positive"
    elif compound <= -0.05:
        label = "negative"
    else:
        label = "neutral"
    return label, round(compound, 4)


@router.post("/", response_model=FeedbackResponse, status_code=201)
def submit_feedback(
    payload: FeedbackCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    logger.info(
        "User id=%d submitting feedback for appointment id=%d",
        current_user.id,
        payload.appointment_id,
    )

    appointment = db.query(Appointment).filter(
        Appointment.id == payload.appointment_id,
        Appointment.user_id == current_user.id,
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if appointment.status == "cancelled":
        raise HTTPException(status_code=400, detail="Cannot review a cancelled appointment")

    if appointment.appointment_date > date.today():
        raise HTTPException(status_code=400, detail="Cannot review a future appointment")

    existing = db.query(Feedback).filter(
        Feedback.appointment_id == payload.appointment_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="You have already reviewed this appointment")

    sentiment_label, sentiment_score = _analyse(payload.review_text)
    logger.info(
        "Sentiment for appointment id=%d: %s (%.4f)",
        payload.appointment_id,
        sentiment_label,
        sentiment_score,
    )

    feedback = Feedback(
        appointment_id=payload.appointment_id,
        user_id=current_user.id,
        rating=payload.rating,
        review_text=payload.review_text,
        sentiment_label=sentiment_label,
        sentiment_score=sentiment_score,
    )
    db.add(feedback)
    db.commit()
    db.refresh(feedback)
    logger.info("Feedback created: id=%d", feedback.id)
    return feedback


@router.get("/my", response_model=list[FeedbackResponse])
def get_my_feedback(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    feedbacks = db.query(Feedback).filter(Feedback.user_id == current_user.id).all()
    logger.debug("User id=%d fetched %d feedback records", current_user.id, len(feedbacks))
    return feedbacks


@router.get("/appointment/{appointment_id}", response_model=FeedbackResponse)
def get_appointment_feedback(
    appointment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    feedback = db.query(Feedback).filter(
        Feedback.appointment_id == appointment_id,
        Feedback.user_id == current_user.id,
    ).first()
    if not feedback:
        raise HTTPException(status_code=404, detail="No feedback found for this appointment")
    return feedback
