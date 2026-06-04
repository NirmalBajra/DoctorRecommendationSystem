# Frontend: Admin Pages — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify all admin pages render correctly, seed required reference data, and confirm that every management action works end-to-end.

**Prerequisites:** `backend/05-admin-module.md` complete. `frontend/01-base-layout.md` complete. Admin account seeded by schema.sql.

**Tech Stack:** HTML5, Bootstrap 5.3, PHP

---

## Task 1: Seed Reference Data

Before testing the full system, seed the required reference data in the correct order (specializations must exist before doctors can register).

- [ ] **Step 1: Seed specializations** (if not done already)

Login as admin → `manage_specializations.php`. Add these one by one, or run this SQL in phpMyAdmin:

```sql
INSERT INTO specializations (specialization_name) VALUES
('General Physician'),('Dermatologist'),('Gastroenterologist'),
('Neurologist'),('Cardiologist'),('Pulmonologist'),('Endocrinologist'),
('Orthopedic Surgeon'),('Rheumatologist'),('Allergist'),
('ENT Specialist'),('Urologist'),('Vascular Surgeon'),
('Infectious Disease Specialist');
```

Verify: `manage_specializations.php` shows 14 specializations.

- [ ] **Step 2: Verify symptoms are seeded**

Go to `manage_symptoms.php`. Confirm ~132 symptoms are listed (seeded via `patient/symptoms.php` backend plan Task 3).
If not, re-run the seed SQL from `backend/02-patient-module.md Task 3 Step 2`.

- [ ] **Step 3: Seed diseases and mappings**

In phpMyAdmin → SQL:

```sql
INSERT INTO diseases (disease_name) VALUES
('Common Cold'),('Fungal infection'),('Allergy'),('GERD'),
('Chronic cholestasis'),('Drug Reaction'),('Peptic ulcer disease'),
('AIDS'),('Diabetes'),('Gastroenteritis'),('Bronchial Asthma'),
('Hypertension'),('Migraine'),('Cervical spondylosis'),
('Paralysis (brain hemorrhage)'),('Jaundice'),('Malaria'),
('Chicken pox'),('Dengue'),('Typhoid'),('hepatitis A'),
('Hepatitis B'),('Hepatitis C'),('Hepatitis D'),('Hepatitis E'),
('Alcoholic hepatitis'),('Tuberculosis'),('Pneumonia'),
('Dimorphic hemmorhoids(piles)'),('Heart attack'),('Varicose veins'),
('Hypothyroidism'),('Hyperthyroidism'),('Hypoglycemia'),
('Osteoarthritis'),('Arthritis'),
('(vertigo) Paroymsal  Positional Vertigo'),
('Acne'),('Urinary tract infection'),('Psoriasis'),('Impetigo');
```

Then add disease-specialization mappings in `manage_diseases.php` (or via SQL):

```sql
INSERT INTO disease_specialization_map (disease_id, specialization_id)
SELECT d.disease_id, s.specialization_id FROM diseases d, specializations s WHERE
(d.disease_name = 'Common Cold' AND s.specialization_name = 'General Physician') OR
(d.disease_name = 'Malaria' AND s.specialization_name = 'General Physician') OR
(d.disease_name = 'Chicken pox' AND s.specialization_name = 'General Physician') OR
(d.disease_name = 'Dengue' AND s.specialization_name = 'General Physician') OR
(d.disease_name = 'Typhoid' AND s.specialization_name = 'General Physician') OR
(d.disease_name = 'Fungal infection' AND s.specialization_name = 'Dermatologist') OR
(d.disease_name = 'Drug Reaction' AND s.specialization_name = 'Dermatologist') OR
(d.disease_name = 'Acne' AND s.specialization_name = 'Dermatologist') OR
(d.disease_name = 'Psoriasis' AND s.specialization_name = 'Dermatologist') OR
(d.disease_name = 'Impetigo' AND s.specialization_name = 'Dermatologist') OR
(d.disease_name = 'GERD' AND s.specialization_name = 'Gastroenterologist') OR
(d.disease_name = 'Chronic cholestasis' AND s.specialization_name = 'Gastroenterologist') OR
(d.disease_name = 'Peptic ulcer disease' AND s.specialization_name = 'Gastroenterologist') OR
(d.disease_name = 'Gastroenteritis' AND s.specialization_name = 'Gastroenterologist') OR
(d.disease_name = 'Jaundice' AND s.specialization_name = 'Gastroenterologist') OR
(d.disease_name = 'Migraine' AND s.specialization_name = 'Neurologist') OR
(d.disease_name = 'Paralysis (brain hemorrhage)' AND s.specialization_name = 'Neurologist') OR
(d.disease_name = 'Heart attack' AND s.specialization_name = 'Cardiologist') OR
(d.disease_name = 'Hypertension' AND s.specialization_name = 'Cardiologist') OR
(d.disease_name = 'Bronchial Asthma' AND s.specialization_name = 'Pulmonologist') OR
(d.disease_name = 'Tuberculosis' AND s.specialization_name = 'Pulmonologist') OR
(d.disease_name = 'Pneumonia' AND s.specialization_name = 'Pulmonologist') OR
(d.disease_name = 'Diabetes' AND s.specialization_name = 'Endocrinologist') OR
(d.disease_name = 'Hypothyroidism' AND s.specialization_name = 'Endocrinologist') OR
(d.disease_name = 'Hyperthyroidism' AND s.specialization_name = 'Endocrinologist') OR
(d.disease_name = 'Hypoglycemia' AND s.specialization_name = 'Endocrinologist') OR
(d.disease_name = 'Osteoarthritis' AND s.specialization_name = 'Orthopedic Surgeon') OR
(d.disease_name = 'Cervical spondylosis' AND s.specialization_name = 'Orthopedic Surgeon') OR
(d.disease_name = 'Arthritis' AND s.specialization_name = 'Rheumatologist') OR
(d.disease_name = 'Allergy' AND s.specialization_name = 'Allergist') OR
(d.disease_name = '(vertigo) Paroymsal  Positional Vertigo' AND s.specialization_name = 'ENT Specialist') OR
(d.disease_name = 'Urinary tract infection' AND s.specialization_name = 'Urologist') OR
(d.disease_name = 'Varicose veins' AND s.specialization_name = 'Vascular Surgeon') OR
(d.disease_name = 'AIDS' AND s.specialization_name = 'Infectious Disease Specialist');
```

- [ ] **Step 4: Commit seed data**

```bash
git add database/schema.sql
git commit -m "feat(db): add seed data SQL for diseases and disease-specialization mappings"
```

---

## Task 2: Admin Dashboard Verification

- [ ] **Step 1: Login as admin**

Default credentials: `admin@drs.local` / `password`

Expected: Redirected to `admin/dashboard.php` with 6 stat cards.

- [ ] **Step 2: Verify all nav links work**

Click each nav item: Approvals, Doctors, Patients, Appointments, Reviews, Specializations, Symptoms, Diseases.
Expected: Each page loads without PHP errors.

- [ ] **Step 3: Commit**

```bash
git commit -m "test(frontend): verify admin dashboard and all admin nav links load"
```

---

## Task 3: Verify Doctor Approval Workflow

- [ ] **Step 1: Register a new doctor from the public form**

Visit `auth/doctor_register.php`, fill all fields, submit.

- [ ] **Step 2: Admin approves the doctor**

Login as admin → `approve_doctors.php`.
Expected: New doctor listed with "Pending" badge and Approve/Reject buttons.
Click Approve.

- [ ] **Step 3: Doctor can now login**

Login as the newly approved doctor. Expected: Doctor dashboard loads.

- [ ] **Step 4: Test revoke approval**

In `approve_doctors.php`, click Revoke on the approved doctor.
Expected: `approval_status` changes back. Doctor login attempt shows "rejected" message.

- [ ] **Step 5: Commit**

```bash
git commit -m "test(frontend): verify full doctor approval and revocation workflow"
```

---

## Task 4: Verify Content Management

- [ ] **Step 1: Add a specialization**

Admin → `manage_specializations.php` → Add "Sports Medicine".
Expected: New row appears in the table.

- [ ] **Step 2: Update the specialization**

Edit "Sports Medicine" → rename to "Sports Medicine Specialist". Click Save.
Expected: Name updated in table.

- [ ] **Step 3: Delete the specialization**

Delete "Sports Medicine Specialist".
Expected: Row removed. If a doctor has this specialization assigned, deletion will fail due to foreign key constraint — this is correct behavior.

- [ ] **Step 4: Add a symptom**

Admin → `manage_symptoms.php` → Add "test_symptom".
Expected: New row in table.
Delete it afterward.

- [ ] **Step 5: Commit**

```bash
git commit -m "test(frontend): verify admin CRUD for specializations and symptoms"
```

---

## Task 5: Verify Review Moderation

- [ ] **Step 1: Submit a review as patient**

Complete the full booking → approval → completion → review flow as a patient.

- [ ] **Step 2: Admin removes the review**

Admin → `manage_reviews.php` → Active tab → click Remove on the review.
Expected: Review disappears from Active tab. Appears in Removed tab.
Doctor's `average_rating` in DB is recalculated.

- [ ] **Step 3: Verify review no longer shows on doctor card**

In `patient/recommendations.php` or `patient/search.php`, the doctor's displayed rating should reflect the recalculated value.

- [ ] **Step 4: Commit**

```bash
git commit -m "test(frontend): verify admin review removal and rating recalculation"
```

---

## Task 6: Final System-Wide Smoke Test

Run through the complete happy path from a fresh state:

- [ ] Register a new patient
- [ ] Register a new doctor (with a valid specialization)
- [ ] Admin approves the doctor
- [ ] Doctor sets availability (add 3 slots)
- [ ] Patient logs in, enters symptoms, receives recommendations
- [ ] Patient books appointment with the recommended doctor
- [ ] Doctor approves the appointment
- [ ] Doctor marks appointment as completed
- [ ] Patient leaves a 5-star review
- [ ] Admin views the appointment in the monitoring page
- [ ] Admin views the review in the review moderation page

Expected: All 10 steps complete without PHP errors or blank pages.

- [ ] **Commit**

```bash
git commit -m "test(system): complete end-to-end smoke test — all modules verified"
```
