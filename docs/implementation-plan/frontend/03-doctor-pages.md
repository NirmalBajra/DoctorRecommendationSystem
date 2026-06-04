# Frontend: Doctor Pages — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify all doctor-facing pages render correctly and are accessible only to approved doctors. No new backend logic needed — this plan covers UI verification, the doctor login/register pages, and access control testing.

**Prerequisites:** `backend/04-doctor-module.md` complete. `frontend/01-base-layout.md` complete.

**Tech Stack:** HTML5, Bootstrap 5.3, PHP

---

## File Map

| File | Purpose |
|---|---|
| `auth/doctor_login.php` | Already written in backend plan — verify UI renders |
| `auth/doctor_register.php` | Already written — verify UI renders and approval flow |
| `doctor/dashboard.php` | Already written — verify stats display |
| `doctor/profile.php` | Already written — verify pre-filled form |
| `doctor/availability.php` | Already written — verify slot add/remove |
| `doctor/appointments.php` | Already written — verify approve/reject/complete flow |

---

## Task 1: Verify Doctor Registration and Login UI

- [ ] **Step 1: Test doctor registration page**

Visit `http://localhost/doctors-recommendation-system/auth/doctor_register.php`.
Expected:
- Specialization dropdown populated (requires at least one specialization in DB)
- All fields render
- Form submits, success message shown: "Registration submitted. Please wait for admin approval."

- [ ] **Step 2: Test registration with empty required fields**

Submit without name or email. Expected: browser validation prevents submission (required attributes).

- [ ] **Step 3: Test doctor login before approval**

Try logging in with just-registered credentials.
Expected: Error "Your registration is pending admin approval."

- [ ] **Step 4: Approve the doctor in admin panel**

Login as admin → `approve_doctors.php` → approve the doctor.

- [ ] **Step 5: Test doctor login after approval**

Login with the same doctor credentials.
Expected: Redirected to `doctor/dashboard.php`.

- [ ] **Step 6: Commit**

```bash
git commit -m "test(frontend): verify doctor registration approval flow and login"
```

---

## Task 2: Verify Doctor Dashboard and Profile

- [ ] **Step 1: Verify dashboard loads**

Login as approved doctor. Visit `doctor/dashboard.php`.
Expected: Doctor name, specialization, average rating, 3 stat cards (pending requests, total appointments, available slots).

- [ ] **Step 2: Test profile update**

Go to `doctor/profile.php`. Change consultation fee. Save.
Expected: Success message. Reload — updated fee shown in form.

- [ ] **Step 3: Verify specialization dropdown shows correct selection**

The currently-assigned specialization should be `selected` in the dropdown.

- [ ] **Step 4: Commit**

```bash
git commit -m "test(frontend): verify doctor dashboard and profile management"
```

---

## Task 3: Verify Availability Management

- [ ] **Step 1: Add a slot**

Go to `doctor/availability.php`. Add Monday 09:00–10:00. Submit.
Expected: Success message. New row appears in the slots table with `Available` badge.

- [ ] **Step 2: Add another slot with end time before start time**

Try adding 10:00–09:00. Expected: Error "End time must be after start time."

- [ ] **Step 3: Remove the slot**

Click Remove on the new slot. Expected: Row disappears from table.

- [ ] **Step 4: Verify booked slot cannot be removed**

Have a patient book the slot first. Then try to remove it.
Expected: Error "Cannot remove a booked slot."

- [ ] **Step 5: Commit**

```bash
git commit -m "test(frontend): verify availability management slot add/remove and booked protection"
```

---

## Task 4: Verify Appointment Request Workflow

- [ ] **Step 1: Have a patient book an appointment**

Login as patient → symptoms → recommendations → book appointment with this doctor.
Verify `appointments` table has a new row with `status = pending`.

- [ ] **Step 2: Verify appointment appears in doctor's list**

Login as doctor → `doctor/appointments.php`.
Expected: Appointment card shows patient name, date, time, symptoms, and "Approve / Reject" buttons.

- [ ] **Step 3: Approve the appointment**

Click Approve. Reload.
Expected: Status badge changes to "Approved". Only "Mark Completed" button shown.

- [ ] **Step 4: Complete the appointment**

Click "Mark Completed". Reload.
Expected: Status badge changes to "Completed". No action buttons shown.

- [ ] **Step 5: Verify patient can now leave a review**

Login as patient → `appointments.php`.
Expected: Completed appointment shows "Leave Review" link.

- [ ] **Step 6: Test rejected appointment slot release**

Book another appointment. Doctor rejects it.
Expected: `doctor_availability.slot_status` = `available` again (check phpMyAdmin).

- [ ] **Step 7: Commit**

```bash
git commit -m "test(frontend): verify full appointment approve/reject/complete workflow"
```

---

## Task 5: Doctor Access Control

- [ ] **Step 1: Access doctor pages without login**

Log out and visit `http://localhost/doctors-recommendation-system/doctor/dashboard.php`.
Expected: Redirected to `auth/doctor_login.php`.

- [ ] **Step 2: Access doctor pages as patient**

Login as patient and visit `doctor/dashboard.php`.
Expected: Redirected to `auth/doctor_login.php` (not to patient dashboard — the guard only checks role).

- [ ] **Step 3: Commit**

```bash
git commit -m "test(frontend): verify doctor role access control"
```
