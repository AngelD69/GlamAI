from pydantic import BaseModel
from datetime import date, datetime, time
from typing import Optional

from app.schemas.service import ServiceResponse


class AppointmentCreate(BaseModel):
    service_id: int
    appointment_date: date
    appointment_time: time
    notes: Optional[str] = None


class AppointmentResponse(BaseModel):
    id: int
    user_id: int
    service_id: int
    service: ServiceResponse
    appointment_date: date
    appointment_time: time
    notes: Optional[str] = None
    status: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
