from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class FeedbackCreate(BaseModel):
    appointment_id: int
    rating: int = Field(..., ge=1, le=5)
    review_text: str = Field(..., min_length=5, max_length=1000)


class FeedbackResponse(BaseModel):
    id: int
    appointment_id: int
    user_id: int
    rating: int
    review_text: str
    sentiment_label: str
    sentiment_score: float
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
