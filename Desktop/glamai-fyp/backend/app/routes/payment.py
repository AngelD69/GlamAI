import random
import string
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.appointment import Appointment
from app.models.payment import Payment
from app.models.user import User
from app.schemas.payment import PaymentCreate, PaymentResponse
from app.utils.dependencies import get_current_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/payments", tags=["Payments"])
logger = get_logger("payment")

_ALLOWED_METHODS = {"esewa", "khalti", "cash"}


def _generate_ref() -> str:
    suffix = "".join(random.choices(string.digits, k=6))
    ts = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    return f"TXN-{ts}-{suffix}"


@router.post("/", response_model=PaymentResponse, status_code=201)
def record_payment(
    payload: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    logger.info(
        "User id=%d recording payment for appointment id=%d via %s",
        current_user.id,
        payload.appointment_id,
        payload.payment_method,
    )

    if payload.payment_method.lower() not in _ALLOWED_METHODS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid payment method. Choose from: {', '.join(_ALLOWED_METHODS)}",
        )

    appointment = db.query(Appointment).filter(
        Appointment.id == payload.appointment_id,
        Appointment.user_id == current_user.id,
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if appointment.status == "cancelled":
        raise HTTPException(status_code=400, detail="Cannot pay for a cancelled appointment")

    existing = db.query(Payment).filter(
        Payment.appointment_id == payload.appointment_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Payment already recorded for this appointment")

    # Pull price from the related service
    amount = appointment.service.price

    payment = Payment(
        appointment_id=payload.appointment_id,
        user_id=current_user.id,
        amount=amount,
        payment_method=payload.payment_method.lower(),
        payment_status="completed",
        transaction_ref=_generate_ref(),
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    logger.info(
        "Payment recorded: id=%d ref=%s amount=%.2f",
        payment.id,
        payment.transaction_ref,
        payment.amount,
    )
    return payment


@router.get("/my", response_model=list[PaymentResponse])
def get_my_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    payments = db.query(Payment).filter(Payment.user_id == current_user.id).all()
    logger.debug("User id=%d fetched %d payment records", current_user.id, len(payments))
    return payments
