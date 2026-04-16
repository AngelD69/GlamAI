from pydantic import BaseModel
from typing import Optional


class ServiceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float


class ServiceResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    price: float

    class Config:
        from_attributes = True