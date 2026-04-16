"""Run this script once to populate the database with initial salon services.

Usage:
    cd backend
    source venv/bin/activate
    python seed.py
"""

from app.database import SessionLocal, engine, Base
from app.models.service import Service
from app.models.user import User  # noqa: F401
from app.models.appointment import Appointment  # noqa: F401

Base.metadata.create_all(bind=engine)

SERVICES = [
    {"name": "Haircut", "description": "Professional haircut and styling for all hair types.", "price": 500},
    {"name": "Facial", "description": "Deep cleansing facial treatment for glowing skin.", "price": 800},
    {"name": "Hair Coloring", "description": "Full hair color, highlights, or balayage by expert stylists.", "price": 1500},
    {"name": "Makeup", "description": "Professional makeup for any occasion — bridal, party, or casual.", "price": 1200},
    {"name": "Mehndi", "description": "Traditional and modern mehndi/henna designs for hands and feet.", "price": 600},
    {"name": "Hair Spa", "description": "Nourishing hair spa treatment to repair and strengthen hair.", "price": 900},
]

db = SessionLocal()

existing = db.query(Service).count()
if existing > 0:
    print(f"Database already has {existing} services. Skipping seed.")
else:
    for s in SERVICES:
        db.add(Service(**s))
    db.commit()
    print(f"Seeded {len(SERVICES)} services successfully.")

db.close()
