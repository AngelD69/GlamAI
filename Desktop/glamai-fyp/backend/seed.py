"""Run this script once to populate the database with initial data.

Usage:
    cd backend
    source venv/bin/activate
    python seed.py
"""

from app.database import SessionLocal, engine, Base
from app.models.appointment import Appointment  # noqa: F401
from app.models.feedback import Feedback  # noqa: F401
from app.models.service import Service
from app.models.user import User
from app.utils.security import hash_password

Base.metadata.create_all(bind=engine)

SERVICES = [
    {"name": "Haircut", "description": "Professional haircut and styling for all hair types.", "price": 500},
    {"name": "Facial", "description": "Deep cleansing facial treatment for glowing skin.", "price": 800},
    {"name": "Hair Coloring", "description": "Full hair color, highlights, or balayage by expert stylists.", "price": 1500},
    {"name": "Makeup", "description": "Professional makeup for any occasion — bridal, party, or casual.", "price": 1200},
    {"name": "Mehndi", "description": "Traditional and modern mehndi/henna designs for hands and feet.", "price": 600},
    {"name": "Hair Spa", "description": "Nourishing hair spa treatment to repair and strengthen hair.", "price": 900},
]

ADMIN_EMAIL = "admin@glamai.com"
ADMIN_PASSWORD = "Admin@1234"
ADMIN_NAME = "GlamAI Admin"

db = SessionLocal()

# ── Services ──────────────────────────────────────────────────────────────────
existing_services = db.query(Service).count()
if existing_services > 0:
    print(f"[services] Already have {existing_services} services — skipping.")
else:
    for s in SERVICES:
        db.add(Service(**s))
    db.commit()
    print(f"[services] Seeded {len(SERVICES)} services.")

# ── Admin user ────────────────────────────────────────────────────────────────
existing_admin = db.query(User).filter(User.email == ADMIN_EMAIL).first()
if existing_admin:
    print(f"[admin] Admin user already exists (id={existing_admin.id}) — skipping.")
else:
    admin = User(
        name=ADMIN_NAME,
        email=ADMIN_EMAIL,
        password=hash_password(ADMIN_PASSWORD),
        is_admin=True,
    )
    db.add(admin)
    db.commit()
    print(f"[admin] Admin user created — email: {ADMIN_EMAIL}  password: {ADMIN_PASSWORD}")

db.close()
