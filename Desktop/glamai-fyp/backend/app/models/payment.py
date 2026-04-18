from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.database import Base


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    appointment_id = Column(Integer, ForeignKey("appointments.id"), nullable=False, unique=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    payment_method = Column(String, nullable=False)   # esewa | khalti | cash
    payment_status = Column(String, nullable=False, default="completed")
    transaction_ref = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    appointment = relationship("Appointment")
    user = relationship("User")
