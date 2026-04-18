import os
from typing import List

from google import genai
from google.genai import types
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
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_key_here":
        logger.error("GEMINI_API_KEY not configured")
        raise HTTPException(status_code=503, detail="AI service not configured. Please set GEMINI_API_KEY.")

    if not request.messages:
        raise HTTPException(status_code=422, detail="No messages provided")

    logger.info(
        "Chat request from user id=%d (%d messages)",
        current_user.id,
        len(request.messages),
    )

    # Build services context
    services = db.query(Service).all()
    service_list = ", ".join(f"{s.name} (NPR {int(s.price)})" for s in services)
    system = SYSTEM_PROMPT
    if services:
        system += f"\n\nAvailable services at GlamAI: {service_list}."
    system += f"\n\nYou are speaking with {current_user.name}."

    try:
        client = genai.Client(api_key=api_key)

        # Build conversation history
        history = []
        for m in request.messages[:-1]:
            role = "user" if m.role == "user" else "model"
            history.append(types.Content(role=role, parts=[types.Part(text=m.content)]))

        last_message = request.messages[-1].content

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=history + [types.Content(role="user", parts=[types.Part(text=last_message)])],
            config=types.GenerateContentConfig(
                system_instruction=system,
                max_output_tokens=512,
            ),
        )
        reply = response.text
        logger.info("Chat reply sent to user id=%d", current_user.id)
    except Exception as e:
        logger.error("Gemini API error: %s", e)
        raise HTTPException(status_code=502, detail="AI service temporarily unavailable.")

    return ChatResponse(reply=reply)
