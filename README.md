# Doctors Recommendation System

BCA Final Year Project — PHP + Python ML web application that recommends doctors to patients based on symptom input using a Random Forest classifier and a weighted doctor ranking algorithm.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, Bootstrap 5 |
| Backend | PHP 8.x |
| Machine Learning | Python 3.x, scikit-learn |
| Database | MySQL 8.x |
| Local Server | XAMPP (Apache + MySQL) |

## Quick Start

### 1. Clone and place in XAMPP

```
C:\xampp\htdocs\doctors-recommendation-system\
```

### 2. Database setup

Import `database/schema.sql` into phpMyAdmin.

### 3. Python ML setup

```bash
pip install -r ml/requirements.txt
python ml/train_model.py
```

### 4. Configure

Copy `config/database.php` template and set your DB credentials.
Edit `config/app.php` to set your Python executable path if needed.

### 5. Visit

```
http://localhost/doctors-recommendation-system/
```

Default admin: `admin@drs.local` / `password` — **change after first login**.

## Project Structure

```
├── config/          # DB connection and app constants (not web-accessible)
├── includes/        # Shared PHP includes: auth guards, header, footer, ranking (not web-accessible)
├── assets/          # CSS and images
├── auth/            # Login and registration pages (all roles)
├── patient/         # Patient dashboard and feature pages
├── doctor/          # Doctor dashboard and feature pages
├── admin/           # Admin dashboard and management pages
├── ml/              # Python ML pipeline: training, prediction, Flask API
├── database/        # SQL schema
├── errors/          # Error pages (403, etc.)
└── docs/            # FRS and implementation plans
```

## Documentation

- **FRS:** `Doctors_Recommendation_System_FRS.md`
- **Implementation Plans:** `docs/implementation-plan/`
  - `python/` — ML pipeline
  - `backend/` — Database, auth, all modules, recommendation engine
  - `frontend/` — Layout, patient/doctor/admin pages
