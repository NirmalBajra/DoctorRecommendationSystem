# Implementation Checklist & Flow Guide

> **For any AI assistant:** Read this entire file before writing a single line of code.
> Every task references an exact plan file. Open that file and follow the steps precisely.

---

## Project Context (share this with any AI)

**Project:** Doctors Recommendation System — BCA Final Year Project  
**Stack:** PHP 8.x · MySQL 8.x · Python 3.x · Bootstrap 5 · XAMPP (localhost)  
**Root path on XAMPP:** `C:\xampp\htdocs\doctors-recommendation-system\`  
**GitHub:** https://github.com/NirmalBajra/DoctorRecommendationSystem  

**What the system does:**
1. Patient enters symptoms → Python ML (Random Forest) predicts disease + specialization
2. PHP ranks matching doctors using a weighted scoring formula (specialization 35%, rating 20%, experience 15%, availability 10%, location 10%, fee 10%)
3. Patient books appointment → Doctor approves/rejects → Patient reviews

**Three roles:** Patient · Doctor (requires admin approval) · Admin  
**Key files already created (skeleton only — no implementation):**
- `config/app.php` — Python path constants (`PYTHON_BIN`, `ML_DIR`)
- `config/database.php` — DB credentials (fill in your own)
- `database/schema.sql` — Full MySQL schema, ready to import
- `ml/requirements.txt` — Python dependencies
- `assets/css/style.css` — Full CSS already implemented
- All PHP and Python files exist as skeletons with `// TODO` comments

**Where to find full task details with code:**
```
docs/implementation-plan/
├── python/   01-ml-pipeline.md
├── backend/  01-database-and-auth.md
│             02-patient-module.md
│             03-recommendation-engine.md
│             04-doctor-module.md
│             05-admin-module.md
└── frontend/ 01-base-layout.md
              02-patient-pages.md
              03-doctor-pages.md
              04-admin-pages.md
```

---

## How to Use This With an AI Assistant

### Prompt template (paste this + the relevant plan section)

```
You are implementing a PHP + Python doctor recommendation system for a BCA final year project.

PROJECT CONTEXT:
- Stack: PHP 8.x, MySQL, Python 3.x, Bootstrap 5, XAMPP
- Root: C:\xampp\htdocs\doctors-recommendation-system\
- All files exist as skeletons. Replace the TODO comment with real implementation.
- Use MySQLi prepared statements for ALL database queries.
- Escape all HTML output with htmlspecialchars().
- Use password_hash(PASSWORD_BCRYPT) for passwords.
- Session guards (requirePatient, requireDoctor, requireAdmin) are in includes/auth_check.php.

TASK:
[Paste the specific task from the plan file here — include the file path, description, and all code steps]

Implement ONLY this task. Do not modify files not listed in the task.
```

### Tips for best results
- **One task at a time.** Paste one task section, not the whole plan.
- **Paste the exact code** from the plan into your prompt — tell the AI to follow it.
- **After each task**, check the verification steps before moving to the next.
- **Cursor / GitHub Copilot:** Open the skeleton file + the plan file side by side, then ask the AI to fill in the skeleton following the plan.
- **ChatGPT / Claude:** Paste the file content + the plan task. Ask it to rewrite the file with the implementation.

---

## Implementation Phases

Work through phases **in order**. Phases 1 and 2 can be done in parallel (Python is independent of PHP).

---

## Phase 1 — Python ML Pipeline
**Plan file:** `docs/implementation-plan/python/01-ml-pipeline.md`  
**Why first:** Fully independent of PHP. Train the model once; PHP just calls it.

- [ ] **P1-T1** Setup Python environment — create `ml/` folder, install `requirements.txt`
- [ ] **P1-T2** Prepare dataset — download Kaggle symptom-disease CSV, save to `ml/dataset.csv`
- [ ] **P1-T3** Train and save model — implement `ml/train_model.py`, run it, verify `model.pkl` created
- [ ] **P1-T4** Build prediction script — implement `ml/predict.py`, test with `python ml/predict.py "fever,cough"`
- [ ] **P1-T5** *(Optional)* Flask API — implement `ml/app.py` if you prefer HTTP over shell_exec

**Phase 1 done when:** `python ml/predict.py "fever,cough,headache"` returns valid JSON with `predicted_disease` and `confidence`.

---

## Phase 2 — Database and Foundation
**Plan file:** `docs/implementation-plan/backend/01-database-and-auth.md`  
**Why second:** Everything else depends on the DB schema and config.

- [ ] **P2-T1** Import database schema — run `database/schema.sql` in phpMyAdmin
- [ ] **P2-T2** Security config — verify `config/.htaccess`, `includes/.htaccess`, `ml/.htaccess` block web access; implement `errors/403.php`
- [ ] **P2-T3** DB connection — implement `config/database.php` (MySQLi connection)
- [ ] **P2-T4** Auth helpers — implement `includes/auth_check.php` (`requirePatient`, `requireDoctor`, `requireAdmin`, `isLoggedIn`, `currentUserId`, `currentRole`)

**Phase 2 done when:** Visiting `http://localhost/doctors-recommendation-system/config/database.php` returns 403, and a test page with `require_once 'config/database.php'` prints "DB OK".

---

## Phase 3 — Authentication (All Roles)
**Plan file:** `docs/implementation-plan/backend/01-database-and-auth.md`  
**Why third:** All dashboard pages depend on working login sessions.

- [ ] **P3-T1** Patient registration — implement `auth/patient_register.php`
- [ ] **P3-T2** Patient login — implement `auth/patient_login.php`
- [ ] **P3-T3** Doctor registration — implement `auth/doctor_register.php` (stores with `pending` status)
- [ ] **P3-T4** Doctor login — implement `auth/doctor_login.php` (checks `approval_status`)
- [ ] **P3-T5** Admin login — implement `auth/admin_login.php`
- [ ] **P3-T6** Logout — implement `auth/logout.php`

**Phase 3 done when:**
- Patient can register, login, and is redirected to `patient/dashboard.php`
- Doctor login before approval shows "pending" error
- Admin can login with `admin@drs.local` / `password`

---

## Phase 4 — Base Frontend Layout
**Plan file:** `docs/implementation-plan/frontend/01-base-layout.md`  
**Why fourth:** Header/footer used by every page.

- [ ] **P4-T1** *(CSS already done)* — verify `assets/css/style.css` loads in browser
- [ ] **P4-T2** Header and footer — implement `includes/header.php` (role-aware nav) and `includes/footer.php`
- [ ] **P4-T3** Home page — implement `index.php` (hero section, how it works, feature list)

**Phase 4 done when:** Visiting `http://localhost/doctors-recommendation-system/` shows the home page with a blue navbar.

---

## Phase 5 — Recommendation Engine (Core Feature)
**Plan file:** `docs/implementation-plan/backend/03-recommendation-engine.md`  
**Why fifth:** Patient symptom flow is the central feature; implement it before the full patient module.

- [ ] **P5-T1** Ranking function — implement `includes/ranking.php` (`rankDoctors()` with 6 weighted components)
- [ ] **P5-T2** Recommendation page — implement `patient/recommendations.php` (calls Python via `shell_exec`, ranks doctors, saves history record)
- [ ] **P5-T3** Manual search — implement `patient/search.php` (filter by specialization, city, rating, fee)

**Phase 5 done when:** Selecting symptoms and submitting shows ranked doctor cards with a score and confidence percentage.

---

## Phase 6 — Patient Module
**Plan file:** `docs/implementation-plan/backend/02-patient-module.md`  
**Also see:** `docs/implementation-plan/frontend/02-patient-pages.md`

- [ ] **P6-T1** Dashboard — implement `patient/dashboard.php`
- [ ] **P6-T2** Profile management — implement `patient/profile.php`
- [ ] **P6-T3** Symptom input page — implement `patient/symptoms.php` (checklist from DB)
- [ ] **P6-T4** Appointment booking — implement `patient/book_appointment.php`
- [ ] **P6-T5** Appointment history — implement `patient/appointments.php` (with cancel action)
- [ ] **P6-T6** Review submission — implement `patient/review.php` (only after completed appointment)
- [ ] **P6-T7** Recommendation history — implement `patient/recommendation_history.php`
- [ ] **P6-T8** *(Frontend polish)* Add live symptom search filter to `patient/symptoms.php`
- [ ] **P6-T9** *(Frontend polish)* Add score breakdown bars to `patient/recommendations.php`

**Phase 6 done when:** A patient can go from symptoms → recommendation → book → view history → review.

---

## Phase 7 — Doctor Module
**Plan file:** `docs/implementation-plan/backend/04-doctor-module.md`  
**Also see:** `docs/implementation-plan/frontend/03-doctor-pages.md`

- [ ] **P7-T1** Dashboard — implement `doctor/dashboard.php`
- [ ] **P7-T2** Profile management — implement `doctor/profile.php`
- [ ] **P7-T3** Availability management — implement `doctor/availability.php` (add/remove slots)
- [ ] **P7-T4** Appointment management — implement `doctor/appointments.php` (approve/reject/complete)

**Phase 7 done when:** A doctor can add availability slots, approve a patient booking, and mark it completed.

---

## Phase 8 — Admin Module
**Plan file:** `docs/implementation-plan/backend/05-admin-module.md`  
**Also see:** `docs/implementation-plan/frontend/04-admin-pages.md`

- [ ] **P8-T1** Seed reference data — add specializations, symptoms, diseases, mappings (SQL in plan Task 1)
- [ ] **P8-T2** Dashboard — implement `admin/dashboard.php`
- [ ] **P8-T3** Doctor approval — implement `admin/approve_doctors.php`
- [ ] **P8-T4** Manage patients — implement `admin/manage_patients.php`
- [ ] **P8-T5** Manage doctors — implement `admin/manage_doctors.php`
- [ ] **P8-T6** Manage specializations — implement `admin/manage_specializations.php`
- [ ] **P8-T7** Manage symptoms — implement `admin/manage_symptoms.php`
- [ ] **P8-T8** Manage diseases + mappings — implement `admin/manage_diseases.php`
- [ ] **P8-T9** Monitor appointments — implement `admin/manage_appointments.php` (with admin complete action)
- [ ] **P8-T10** Review moderation — implement `admin/manage_reviews.php`

**Phase 8 done when:** Admin can approve a doctor, manage all content, monitor appointments, and remove reviews.

---

## Phase 9 — Final System Test
**Plan file:** `docs/implementation-plan/frontend/04-admin-pages.md — Task 6`

Run the full end-to-end smoke test:

- [ ] **P9-T1** Register new patient
- [ ] **P9-T2** Register new doctor
- [ ] **P9-T3** Admin approves doctor
- [ ] **P9-T4** Doctor adds availability slots
- [ ] **P9-T5** Patient enters symptoms → gets recommendations
- [ ] **P9-T6** Patient books appointment
- [ ] **P9-T7** Doctor approves appointment
- [ ] **P9-T8** Doctor marks appointment completed
- [ ] **P9-T9** Patient leaves review
- [ ] **P9-T10** Admin verifies appointment and review in admin panel

**System complete when:** All 10 smoke test steps pass with no PHP errors.

---

## Progress Tracker

Copy this table into a Notion page, Google Doc, or GitHub issue to track your progress:

| Phase | Tasks | Status |
|---|---|---|
| Phase 1 — Python ML | 5 tasks | ⬜ Not started |
| Phase 2 — Database & Foundation | 4 tasks | ⬜ Not started |
| Phase 3 — Authentication | 6 tasks | ⬜ Not started |
| Phase 4 — Base Layout | 3 tasks | ⬜ Not started |
| Phase 5 — Recommendation Engine | 3 tasks | ⬜ Not started |
| Phase 6 — Patient Module | 9 tasks | ⬜ Not started |
| Phase 7 — Doctor Module | 4 tasks | ⬜ Not started |
| Phase 8 — Admin Module | 10 tasks | ⬜ Not started |
| Phase 9 — System Test | 10 checks | ⬜ Not started |
| **Total** | **54 tasks** | |

---

## Dependency Map

```
Phase 1 (Python)   ──────────────────────────────────────┐
                                                          │
Phase 2 (DB + Config)                                     │
    └── Phase 3 (Auth)                                    │
            └── Phase 4 (Layout)                          │
                    └── Phase 5 (Rec Engine) ◄────────────┘
                            └── Phase 6 (Patient)
                                    └── Phase 7 (Doctor)
                                            └── Phase 8 (Admin)
                                                    └── Phase 9 (Test)
```

**Phases 1 and 2 can run in parallel.** Everything else is sequential.

---

## Common Mistakes to Avoid

| Mistake | Correct approach |
|---|---|
| Using `mysqli_query()` directly with user input | Always use prepared statements with `bind_param()` |
| Echoing `$_POST` or `$_GET` values directly into HTML | Always wrap with `htmlspecialchars()` |
| Hardcoding the Python path as `"python"` inside PHP | Use `PYTHON_BIN` constant from `config/app.php` |
| Hardcoding the ML directory path | Use `ML_DIR` constant from `config/app.php` |
| Letting patients rate without a completed appointment | Check `status = "completed"` + `NOT EXISTS` review before showing form |
| Freeing a slot when appointment is rejected | Always `UPDATE doctor_availability SET slot_status = "available"` on reject/cancel |
| Deleting a review from the DB | Soft-delete only: `SET status = "removed"`, then recalculate `average_rating` |
| Skipping session regeneration on login | Always call `session_regenerate_id(true)` after successful login |
