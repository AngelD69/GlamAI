from pydantic import BaseModel
from typing import Optional


class ServiceBookingCount(BaseModel):
    service_name: str
    count: int


class StatusCount(BaseModel):
    status: str
    count: int


class SentimentCount(BaseModel):
    sentiment_label: str
    count: int


class HourCount(BaseModel):
    hour: int           # 0–23
    count: int


class DayCount(BaseModel):
    day_of_week: int    # 0=Sunday … 6=Saturday (PostgreSQL DOW)
    day_name: str
    count: int


class RecentAppointment(BaseModel):
    id: int
    user_name: str
    service_name: str
    appointment_date: str
    appointment_time: str
    status: str


class DashboardResponse(BaseModel):
    total_users: int
    total_bookings: int
    average_rating: Optional[float]
    bookings_by_service: list[ServiceBookingCount]
    status_breakdown: list[StatusCount]
    sentiment_summary: list[SentimentCount]
    bookings_by_hour: list[HourCount]
    bookings_by_day: list[DayCount]
    recent_appointments: list[RecentAppointment]
