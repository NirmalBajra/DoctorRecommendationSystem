# Frontend: Patient Pages — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete all patient-facing UI — the symptom input page with a searchable checklist, the recommendation results cards with score breakdown, and the appointment history with status badges.

**Architecture:** Patient pages live in `patient/`. Each page includes `header.php` and `footer.php`. Backend logic is embedded in each PHP file (no separate API layer). Bootstrap 5 provides the component library.

**Prerequisites:** `backend/02-patient-module.md` and `backend/03-recommendation-engine.md` complete. `frontend/01-base-layout.md` complete.

**Tech Stack:** HTML5, Bootstrap 5.3, vanilla JavaScript (symptom search filter), PHP

**Note:** The PHP backend for each page was written in `backend/02-patient-module.md` and `backend/03-recommendation-engine.md`. This plan covers UI enhancements and any missing visual pages.

---

## File Map

| File | Purpose |
|---|---|
| `patient/symptoms.php` | Symptom selection with live search filter (UI enhancement) |
| `patient/recommendations.php` | Ranked doctor cards with confidence badge and score display |
| `patient/search.php` | Manual search with filter sidebar |
| `patient/appointments.php` | Appointment list with status badges and action buttons |
| `patient/recommendation_history.php` | Accordion history with symptom + prediction details |

All these files have backend logic already written. This plan adds the UI polish tasks below.

---

## Task 1: Symptom Page — Live Search Filter

**Files:**
- Modify: `patient/symptoms.php` (add JavaScript search filter to the existing checklist)

- [ ] **Step 1: Add search input and JS filter above the symptom checkboxes**

Add this HTML block just before the `<div class="row row-cols-2 ...">` in `patient/symptoms.php`:

```html
<div class="mb-3" style="max-width:360px">
    <input type="text" id="symptomSearch" class="form-control"
           placeholder="Search symptoms..." autocomplete="off">
</div>
```

- [ ] **Step 2: Add the JavaScript filter at the bottom of the page (before `</body>`)**

```html
<script>
document.getElementById('symptomSearch').addEventListener('input', function () {
    const term = this.value.toLowerCase().trim();
    document.querySelectorAll('.symptom-item').forEach(function (item) {
        const label = item.querySelector('label').textContent.toLowerCase();
        item.style.display = label.includes(term) ? '' : 'none';
    });
});
</script>
```

- [ ] **Step 3: Add class `symptom-item` to each checklist column div**

Change:
```html
<div class="col">
```
To:
```html
<div class="col symptom-item">
```

- [ ] **Step 4: Test the filter**

Visit `patient/symptoms.php`. Type "fever" in the search box.
Expected: Only symptom checkboxes containing "fever" are visible. Others are hidden.
Clear the search — all symptoms reappear.

- [ ] **Step 5: Commit**

```bash
git add patient/symptoms.php
git commit -m "feat(frontend): add live symptom search filter to symptom selection page"
```

---

## Task 2: Recommendations Page — Score Breakdown Display

**Files:**
- Modify: `patient/recommendations.php` (add visual score breakdown to each doctor card)

The backend already computes `$doc['score_breakdown']`. Add the visual bar inside each doctor card.

- [ ] **Step 1: Add score breakdown section inside each doctor card**

After the "Book Appointment" button in the recommendations card loop, add:

```html
<div class="mt-3">
    <small class="text-muted d-block mb-1">Score Breakdown</small>
    <?php
    $labels = [
        'specialization' => 'Specialization',
        'rating'         => 'Rating',
        'experience'     => 'Experience',
        'availability'   => 'Availability',
        'location'       => 'Location',
        'fee'            => 'Fee',
    ];
    foreach ($doc['score_breakdown'] as $key => $val): ?>
    <div class="d-flex align-items-center mb-1">
        <small style="width:90px;font-size:0.75rem" class="text-muted"><?= $labels[$key] ?></small>
        <div class="score-bar flex-grow-1 me-2">
            <div class="score-fill" style="width:<?= $val ?>%"></div>
        </div>
        <small style="width:35px;text-align:right;font-size:0.75rem"><?= $val ?></small>
    </div>
    <?php endforeach; ?>
</div>
```

- [ ] **Step 2: Test**

Submit symptoms, view results. Each doctor card now shows a 6-bar breakdown.
Expected: Specialization match bar at 100% for matching specialization, others reflecting computed values.

- [ ] **Step 3: Commit**

```bash
git add patient/recommendations.php
git commit -m "feat(frontend): add score breakdown bars to doctor recommendation cards"
```

---

## Task 3: Verify All Patient Pages Load Without Errors

- [ ] **Step 1: Check each page as a logged-in patient**

| Page | URL | Expected |
|---|---|---|
| Dashboard | `/patient/dashboard.php` | Stats, action buttons |
| Symptoms | `/patient/symptoms.php` | Checklist with search, submit button |
| Recommendations | POST from symptoms | Ranked doctor cards with scores |
| Search | `/patient/search.php` | Filter form, doctor list |
| Book Appointment | `/patient/book_appointment.php?doctor_id=1` | Doctor info, slot selector, date picker |
| Appointments | `/patient/appointments.php` | Table with status badges |
| Recommendation History | `/patient/recommendation_history.php` | Accordion with history entries |
| Review | `/patient/review.php?appointment_id=X` | Rating form (only if appointment completed) |
| Profile | `/patient/profile.php` | Pre-filled form |

- [ ] **Step 2: Test access control**

Log out and try visiting `/patient/dashboard.php` directly.
Expected: Redirected to `auth/patient_login.php`.

- [ ] **Step 3: Commit**

```bash
git commit -m "test(frontend): verify all patient pages load and access control works"
```
