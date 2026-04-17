import os
from typing import List

import anthropic
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.models.service import Service
from app.models.user import User
from app.utils.dependencies import get_current_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/chat", tags=["AI Chat"])
logger = get_logger("chat")

SYSTEM_PROMPT = """You are GlamBot, a friendly and knowledgeable AI beauty consultant for GlamAI — a premium salon booking app in Nepal.

Your role:
- Help users with beauty, hair, skin, and makeup advice
- Recommend salon services based on user needs
- Answer questions about face shapes, hair types, skin concerns, and beauty trends
- Be warm, encouraging, and professional
- Keep responses concise (2-4 sentences unless more detail is needed)
- Use emojis occasionally to keep the conversation friendly 💅

You must NOT:
- Discuss topics unrelated to beauty, wellness, or salon services
- Make medical diagnoses

When relevant, mention GlamAI's services: Haircut, Facial, Hair Coloring, Makeup, Mehndi, Hair Spa."""


class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]


class ChatResponse(BaseModel):
    reply: str


@router.post("/", response_model=ChatResponse)
def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key or api_key == "your_api_key_here":
        logger.error("ANTHROPIC_API_KEY not configured")
        raise HTTPException(status_code=503, detail="AI service not configured. Please set ANTHROPIC_API_KEY.")

    if not request.messages:
        raise HTTPException(status_code=422, detail="No messages provided")

    logger.info(
        "Chat request from user id=%d (%d messages)",
        current_user.id,
        len(request.messages),
    )

    # Build services context for the system prompt
    services = db.query(Service).all()
    service_list = ", ".join(f"{s.name} (NPR {int(s.price)})" for s in services)
    system = SYSTEM_PROMPT
    if services:
        system += f"\n\nAvailable services at GlamAI: {service_list}."
    system += f"\n\nYou are speaking with {current_user.name}."

    try:
        client = anthropic.Anthropic(api_key=api_key)
        response = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=512,
            system=system,
            messages=[{"role": m.role, "content": m.content} for m in request.messages],
        )
        reply = response.content[0].text
        logger.info("Chat reply sent to user id=%d", current_user.id)
    except anthropic.APIError as e:
        logger.error("Anthropic API error: %s", e)
        raise HTTPException(status_code=502, detail="AI service temporarily unavailable.")

    return ChatResponse(reply=reply)
