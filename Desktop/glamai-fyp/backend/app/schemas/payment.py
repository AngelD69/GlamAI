from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class PaymentCreate(BaseModel):
    appointment_id: int
    payment_method: str  # esewa | khalti | cash


class PaymentResponse(BaseModel):
    id: int
    appointment_id: int
    user_id: int
    amount: float
    payment_method: str
    payment_status: str
    transaction_ref: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
