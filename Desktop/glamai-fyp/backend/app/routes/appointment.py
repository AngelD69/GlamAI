from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.appointment import Appointment
from app.models.service import Service
from app.models.user import User
from app.schemas.appointment import AppointmentCreate, AppointmentResponse
from app.utils.dependencies import get_current_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/appointments", tags=["Appointments"])
logger = get_logger("appointment")


@router.post("/", response_model=AppointmentResponse, status_code=201)
def create_appointment(
    appointment: AppointmentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    logger.info(
        "User id=%d booking service id=%d on %s at %s",
        current_user.id,
        appointment.service_id,
        appointment.appointment_date,
        appointment.appointment_time,
    )
    service = db.query(Service).filter(Service.id == appointment.service_id).first()
    if not service:
        logger.warning("Service not found: id=%d", appointment.service_id)
        raise HTTPException(status_code=404, detail="Service not found")

    existing = db.query(Appointment).filter(
        Appointment.appointment_date == appointment.appointment_date,
        Appointment.appointment_time == appointment.appointment_time,
    ).first()
    if existing:
        logger.warning(
            "Slot already booked: date=%s time=%s",
            appointment.appointment_date,
            appointment.appointment_time,
        )
        raise HTTPException(status_code=400, detail="This appointment slot is already booked")

    new_appointment = Appointment(
        user_id=current_user.id,
        service_id=appointment.service_id,
        appointment_date=appointment.appointment_date,
        appointment_time=appointment.appointment_time,
        notes=appointment.notes,
        status="pending",
    )
    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)
    logger.info("Appointment created: id=%d for user id=%d", new_appointment.id, current_user.id)
    return new_appointment


@router.get("/mine", response_model=list[AppointmentResponse])
def get_my_appointments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    appointments = db.query(Appointment).filter(Appointment.user_id == current_user.id).all()
    logger.debug("User id=%d fetched %d appointments", current_user.id, len(appointments))
    return appointments


@router.delete("/{appointment_id}", status_code=204)
def cancel_appointment(
    appointment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    logger.info("User id=%d cancelling appointment id=%d", current_user.id, appointment_id)
    appointment = db.query(Appointment).filter(
        Appointment.id == appointment_id,
        Appointment.user_id == current_user.id,
    ).first()
    if not appointment:
        logger.warning(
            "Appointment not found or not owned: id=%d user id=%d",
            appointment_id,
            current_user.id,
        )
        raise HTTPException(status_code=404, detail="Appointment not found")
    db.delete(appointment)
    db.commit()
    logger.info("Appointment cancelled: id=%d", appointment_id)
