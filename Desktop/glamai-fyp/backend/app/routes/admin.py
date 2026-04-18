from sqlalchemy import func, extract
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends

from app.models.appointment import Appointment
from app.models.feedback import Feedback
from app.models.service import Service
from app.models.user import User
from app.schemas.admin import (
    DashboardResponse,
    DayCount,
    HourCount,
    RecentAppointment,
    ServiceBookingCount,
    SentimentCount,
    StatusCount,
)
from app.utils.dependencies import get_admin_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/admin", tags=["Admin"])
logger = get_logger("admin")

_DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]


@router.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(
    _: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    logger.info("Admin dashboard requested")

    # ── Totals ──────────────────────────────────────────────────────────────────
    total_users = db.query(func.count(User.id)).scalar() or 0
    total_bookings = db.query(func.count(Appointment.id)).scalar() or 0

    # ── Average rating ───────────────────────────────────────────────────────────
    avg_rating_raw = db.query(func.avg(Feedback.rating)).scalar()
    average_rating = round(float(avg_rating_raw), 2) if avg_rating_raw else None

    # ── Bookings by service ──────────────────────────────────────────────────────
    by_service_rows = (
        db.query(Service.name, func.count(Appointment.id).label("count"))
        .join(Appointment, Appointment.service_id == Service.id)
        .group_by(Service.name)
        .order_by(func.count(Appointment.id).desc())
        .all()
    )
    bookings_by_service = [
        ServiceBookingCount(service_name=row[0], count=row[1]) for row in by_service_rows
    ]

    # ── Status breakdown ─────────────────────────────────────────────────────────
    status_rows = (
        db.query(Appointment.status, func.count(Appointment.id).label("count"))
        .group_by(Appointment.status)
        .all()
    )
    status_breakdown = [StatusCount(status=row[0], count=row[1]) for row in status_rows]

    # ── Sentiment summary ────────────────────────────────────────────────────────
    sentiment_rows = (
        db.query(Feedback.sentiment_label, func.count(Feedback.id).label("count"))
        .group_by(Feedback.sentiment_label)
        .all()
    )
    sentiment_summary = [
        SentimentCount(sentiment_label=row[0], count=row[1]) for row in sentiment_rows
    ]

    # ── Bookings by hour of day ──────────────────────────────────────────────────
    hour_rows = (
        db.query(
            extract("hour", Appointment.appointment_time).label("hour"),
            func.count(Appointment.id).label("count"),
        )
        .group_by("hour")
        .order_by("hour")
        .all()
    )
    bookings_by_hour = [HourCount(hour=int(row[0]), count=row[1]) for row in hour_rows]

    # ── Bookings by day of week ──────────────────────────────────────────────────
    dow_rows = (
        db.query(
            extract("dow", Appointment.appointment_date).label("dow"),
            func.count(Appointment.id).label("count"),
        )
        .group_by("dow")
        .order_by("dow")
        .all()
    )
    bookings_by_day = [
        DayCount(
            day_of_week=int(row[0]),
            day_name=_DAY_NAMES[int(row[0])],
            count=row[1],
        )
        for row in dow_rows
    ]

    # ── Recent appointments (last 10) ────────────────────────────────────────────
    recent_rows = (
        db.query(Appointment, User.name.label("user_name"), Service.name.label("service_name"))
        .join(User, User.id == Appointment.user_id)
        .join(Service, Service.id == Appointment.service_id)
        .order_by(Appointment.created_at.desc())
        .limit(10)
        .all()
    )
    recent_appointments = [
        RecentAppointment(
            id=row.Appointment.id,
            user_name=row.user_name,
            service_name=row.service_name,
            appointment_date=str(row.Appointment.appointment_date),
            appointment_time=str(row.Appointment.appointment_time),
            status=row.Appointment.status,
        )
        for row in recent_rows
    ]

    logger.info(
        "Dashboard built: users=%d bookings=%d avg_rating=%s",
        total_users,
        total_bookings,
        average_rating,
    )

    return DashboardResponse(
        total_users=total_users,
        total_bookings=total_bookings,
        average_rating=average_rating,
        bookings_by_service=bookings_by_service,
        status_breakdown=status_breakdown,
        sentiment_summary=sentiment_summary,
        bookings_by_hour=bookings_by_hour,
        bookings_by_day=bookings_by_day,
        recent_appointments=recent_appointments,
    )
