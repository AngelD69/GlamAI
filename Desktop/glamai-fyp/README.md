# GlamAI — AI-Powered Salon Booking App

Final Year Project (FYP) — Flutter mobile app with FastAPI backend and ML-based face shape detection.

## Project Structure

```
glamai-fyp/
├── backend/          # FastAPI + PostgreSQL backend
├── mobile_app/       # Flutter mobile app
├── dataset/          # ML model training (MobileNetV2)
└── documentation/    # Project docs
```

---

## Backend Setup

**Requirements:** Python 3.10+, PostgreSQL

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**Configure environment:**
```bash
cp .env.example .env
# Edit .env and fill in your values
```

**Create the database:**
```bash
createdb glamai_db
```

**Run the server:**
```bash
uvicorn app.main:app --reload --port 8000
```

API docs available at: `http://localhost:8000/docs`

---

## Mobile App Setup

**Requirements:** Flutter 3.x, Android Studio or Xcode

```bash
cd mobile_app
flutter pub get
```

**Run on Android emulator:**
```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000
```

**Run on physical device** (replace with your machine's local IP):
```bash
flutter run --dart-define=BASE_URL=http://192.168.x.x:8000
```

**Build APK:**
```bash
flutter build apk --debug --dart-define=BASE_URL=http://10.0.2.2:8000
```

---

## ML Model

The face shape classifier uses MobileNetV2 transfer learning (5 classes: Heart, Oblong, Oval, Round, Square).

**Train the model:**
```bash
cd dataset
python train.py
```

The trained model (`face_shape_model.keras`) should be placed in the `dataset/` folder. It is loaded lazily by the backend on first request.

---

## Features

- User registration and login (JWT auth)
- Browse and book salon services
- View and cancel appointments
- AI face shape detection from photo (MobileNetV2)
- AI beauty recommendations (Claude claude-haiku-4-5-20251001)
- Profile management with photo upload
