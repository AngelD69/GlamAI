import os
from typing import Optional

import anthropic
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.models.service import Service
from app.models.user import User
from app.utils.dependencies import get_current_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/recommendations", tags=["AI Recommendations"])
logger = get_logger("recommendation")


class RecommendationRequest(BaseModel):
    face_shape: Optional[str] = None
    hair_type: Optional[str] = None
    occasion: Optional[str] = None
    current_concerns: Optional[str] = None


class RecommendationResponse(BaseModel):
    user_name: str
    recommendations: str


@router.post("/", response_model=RecommendationResponse)
def get_recommendation(
    request: RecommendationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    logger.info(
        "Recommendation request from user id=%d (face=%s, hair=%s, occasion=%s)",
        current_user.id,
        request.face_shape,
        request.hair_type,
        request.occasion,
    )

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key or api_key == "your_api_key_here":
        logger.error("ANTHROPIC_API_KEY is not configured")
        raise HTTPException(status_code=500, detail="ANTHROPIC_API_KEY is not configured")

    services = db.query(Service).all()
    if not services:
        logger.warning("No services in DB — cannot generate recommendation")
        raise HTTPException(status_code=404, detail="No services available to recommend from")

    service_list = "\n".join(
        f"- {s.name} (NPR {s.price}): "
        f"{s.description or 'No description'}"
        for s in services
    )

    user_details = f"Name: {current_user.name}"
    if request.face_shape:
        user_details += f"\nFace shape: {request.face_shape}"
    if request.hair_type:
        user_details += f"\nHair type: {request.hair_type}"
    if request.occasion:
        user_details += f"\nOccasion: {request.occasion}"
    if request.current_concerns:
        user_details += f"\nCurrent concerns: {request.current_concerns}"

    prompt = f"""You are a professional beauty and salon consultant for GlamAI, a salon app in Nepal.

A customer has come to you for personalized salon service recommendations.

Customer details:
{user_details}

Available salon services:
{service_list}

Based on the customer's details, recommend the most suitable services from the list above.
Explain why each recommended service suits them. Keep your response friendly, practical, and under 200 words."""

    try:
        client = anthropic.Anthropic(api_key=api_key)
        message = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=400,
            messages=[{"role": "user", "content": prompt}],
        )
        recommendation_text = message.content[0].text
        logger.info("Recommendation generated for user id=%d", current_user.id)
    except anthropic.APIError as e:
        logger.error("Anthropic API error for user id=%d: %s", current_user.id, e)
        raise HTTPException(
            status_code=502,
            detail="AI service is temporarily unavailable. Please try again later.",
        )

    return RecommendationResponse(
        user_name=current_user.name,
        recommendations=recommendation_text,
    )
