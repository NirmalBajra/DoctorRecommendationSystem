# Backend: Patient Module — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all backend logic for the patient role — profile management, symptom submission, recommendation display, appointment booking, history views, and review submission.

**Architecture:** Each patient page guards with `requirePatient()` at the top, reads `$_SESSION['patient_id']`, and queries the DB using MySQLi prepared statements. All user output is escaped with `htmlspecialchars()`.

**Prerequisites:** `01-database-and-auth.md` completed. Database schema exists. Patient can log in.

**Tech Stack:** PHP 8.x, MySQLi, Bootstrap 5

---

## File Map

| File | Purpose |
|---|---|
| `patient/dashboard.php` | Patient home — summary stats and quick links |
| `patient/profile.php` | View and update patient profile |
| `patient/symptoms.php` | Symptom selection form (POST → recommendation engine) |
| `patient/search.php` | Manual doctor search with filters |
| `patient/book_appointment.php` | Select slot and confirm booking |
| `patient/appointments.php` | List all appointments with statuses |
| `patient/recommendation_history.php` | List all previous recommendation sessions |
| `patient/review.php` | Submit rating + review for completed appointment |

---

## Task 1: Patient Dashboard

**Files:**
- Create: `patient/dashboard.php`

- [ ] **Step 1: Write patient/dashboard.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$patient_id = (int)$_SESSION['patient_id'];
$user_id    = currentUserId();

// Fetch patient name
$stmt = $conn->prepare('SELECT u.name, p.city FROM users u JOIN patients p ON p.user_id = u.user_id WHERE u.user_id = ?');
$stmt->bind_param('i', $user_id);
$stmt->execute();
$stmt->bind_result($name, $city);
$stmt->fetch();
$stmt->close();

// Counts
$total_appointments = $conn->query("SELECT COUNT(*) FROM appointments WHERE patient_id = $patient_id")->fetch_row()[0];
$pending_appointments = $conn->query("SELECT COUNT(*) FROM appointments WHERE patient_id = $patient_id AND status = 'pending'")->fetch_row()[0];
$total_recommendations = $conn->query("SELECT COUNT(*) FROM recommendations WHERE patient_id = $patient_id")->fetch_row()[0];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Patient Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Welcome, <?= htmlspecialchars($name) ?></h2>
    <p class="text-muted"><?= htmlspecialchars($city ?: 'Location not set') ?></p>
    <div class="row g-3 mt-2">
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total_appointments ?></h4><p>Total Appointments</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $pending_appointments ?></h4><p>Pending Appointments</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total_recommendations ?></h4><p>Recommendations</p>
            </div>
        </div>
    </div>
    <div class="mt-4">
        <a href="symptoms.php" class="btn btn-primary me-2">Get Doctor Recommendation</a>
        <a href="search.php" class="btn btn-outline-secondary me-2">Search Doctors</a>
        <a href="appointments.php" class="btn btn-outline-secondary">My Appointments</a>
    </div>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Verify**

Login as a patient and visit `http://localhost/doctors-recommendation-system/patient/dashboard.php`.
Expected: Welcome message, 3 stat cards, action buttons.

- [ ] **Step 3: Commit**

```bash
git add patient/dashboard.php
git commit -m "feat(patient): add patient dashboard with summary stats"
```

---

## Task 2: Patient Profile Management

**Files:**
- Create: `patient/profile.php`

- [ ] **Step 1: Write patient/profile.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$user_id    = currentUserId();
$patient_id = (int)$_SESSION['patient_id'];
$error = '';
$success = '';

// Load current profile
$stmt = $conn->prepare(
    'SELECT u.name, u.email, p.gender, p.age, p.contact_number, p.city, p.area
     FROM users u JOIN patients p ON p.user_id = u.user_id WHERE u.user_id = ?'
);
$stmt->bind_param('i', $user_id);
$stmt->execute();
$stmt->bind_result($name, $email, $gender, $age, $contact, $city, $area);
$stmt->fetch();
$stmt->close();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $new_name    = trim($_POST['name'] ?? '');
    $new_gender  = $_POST['gender'] ?? $gender;
    $new_age     = (int)($_POST['age'] ?? $age);
    $new_contact = trim($_POST['contact_number'] ?? '');
    $new_city    = trim($_POST['city'] ?? '');
    $new_area    = trim($_POST['area'] ?? '');

    if (!$new_name || $new_age <= 0) {
        $error = 'Name and age are required.';
    } else {
        $s1 = $conn->prepare('UPDATE users SET name = ? WHERE user_id = ?');
        $s1->bind_param('si', $new_name, $user_id);
        $s1->execute();

        $s2 = $conn->prepare('UPDATE patients SET gender = ?, age = ?, contact_number = ?, city = ?, area = ? WHERE patient_id = ?');
        $s2->bind_param('sisssi', $new_gender, $new_age, $new_contact, $new_city, $new_area, $patient_id);
        $s2->execute();

        $success = 'Profile updated successfully.';
        // Refresh displayed values
        $name = $new_name; $gender = $new_gender; $age = $new_age;
        $contact = $new_contact; $city = $new_city; $area = $new_area;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>My Profile</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4" style="max-width:520px">
    <h2>My Profile</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Full Name *</label>
            <input type="text" name="name" class="form-control" value="<?= htmlspecialchars($name) ?>" required></div>
        <div class="mb-3"><label class="form-label">Email (read-only)</label>
            <input type="email" class="form-control" value="<?= htmlspecialchars($email) ?>" disabled></div>
        <div class="mb-3"><label class="form-label">Gender</label>
            <select name="gender" class="form-select">
                <option <?= $gender === 'Male' ? 'selected' : '' ?>>Male</option>
                <option <?= $gender === 'Female' ? 'selected' : '' ?>>Female</option>
                <option <?= $gender === 'Other' ? 'selected' : '' ?>>Other</option>
            </select></div>
        <div class="mb-3"><label class="form-label">Age *</label>
            <input type="number" name="age" class="form-control" value="<?= (int)$age ?>" min="1" max="120" required></div>
        <div class="mb-3"><label class="form-label">Contact Number</label>
            <input type="text" name="contact_number" class="form-control" value="<?= htmlspecialchars($contact) ?>"></div>
        <div class="mb-3"><label class="form-label">City</label>
            <input type="text" name="city" class="form-control" value="<?= htmlspecialchars($city) ?>"></div>
        <div class="mb-3"><label class="form-label">Area</label>
            <input type="text" name="area" class="form-control" value="<?= htmlspecialchars($area) ?>"></div>
        <button type="submit" class="btn btn-primary">Save Changes</button>
    </form>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test profile update**

Change name, submit. Verify updated name appears. Check DB in phpMyAdmin.

- [ ] **Step 3: Commit**

```bash
git add patient/profile.php
git commit -m "feat(patient): add patient profile management page"
```

---

## Task 3: Symptom Input Page (Backend Handler)

**Files:**
- Create: `patient/symptoms.php`

- [ ] **Step 1: Write patient/symptoms.php**

This page shows a symptom checklist and POSTs to `patient/recommendations.php`.

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

// Load all symptoms from DB
$symptoms = [];
$res = $conn->query('SELECT symptom_id, symptom_name FROM symptoms ORDER BY symptom_name');
while ($row = $res->fetch_assoc()) {
    $symptoms[] = $row;
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Enter Symptoms</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Enter Your Symptoms</h2>
    <p class="text-muted">Select all symptoms you are currently experiencing.</p>
    <form method="POST" action="recommendations.php">
        <div class="row row-cols-2 row-cols-md-3 g-2 mb-4">
            <?php foreach ($symptoms as $s): ?>
            <div class="col">
                <div class="form-check">
                    <input class="form-check-input" type="checkbox"
                           name="symptoms[]"
                           value="<?= htmlspecialchars($s['symptom_name']) ?>"
                           id="s<?= $s['symptom_id'] ?>">
                    <label class="form-check-label" for="s<?= $s['symptom_id'] ?>">
                        <?= htmlspecialchars($s['symptom_name']) ?>
                    </label>
                </div>
            </div>
            <?php endforeach; ?>
        </div>
        <?php if (empty($symptoms)): ?>
            <div class="alert alert-warning">No symptoms available. Ask admin to add symptoms.</div>
        <?php else: ?>
            <button type="submit" class="btn btn-primary">Get Recommendations</button>
        <?php endif; ?>
    </form>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Add seed symptoms to DB**

In phpMyAdmin → SQL:

```sql
INSERT INTO symptoms (symptom_name) VALUES
('itching'),('skin_rash'),('nodal_skin_eruptions'),('continuous_sneezing'),('shivering'),
('chills'),('joint_pain'),('stomach_pain'),('acidity'),('ulcers_on_tongue'),
('muscle_wasting'),('vomiting'),('burning_micturition'),('fatigue'),('weight_gain'),
('anxiety'),('cold_hands_and_feets'),('mood_swings'),('weight_loss'),('restlessness'),
('lethargy'),('patches_in_throat'),('irregular_sugar_level'),('cough'),('high_fever'),
('sunken_eyes'),('breathlessness'),('sweating'),('dehydration'),('indigestion'),
('headache'),('yellowish_skin'),('dark_urine'),('nausea'),('loss_of_appetite'),
('pain_behind_the_eyes'),('back_pain'),('constipation'),('abdominal_pain'),('diarrhoea'),
('mild_fever'),('yellow_urine'),('yellowing_of_eyes'),('acute_liver_failure'),
('fluid_overload'),('swelling_of_stomach'),('swelled_lymph_nodes'),('malaise'),
('blurred_and_distorted_vision'),('phlegm'),('throat_irritation'),('redness_of_eyes'),
('sinus_pressure'),('runny_nose'),('congestion'),('chest_pain'),('weakness_in_limbs'),
('fast_heart_rate'),('pain_during_bowel_motions'),('pain_in_anal_region'),
('bloody_stool'),('irritation_in_anus'),('neck_pain'),('dizziness'),('cramps'),
('bruising'),('obesity'),('swollen_legs'),('swollen_blood_vessels'),
('puffy_face_and_eyes'),('enlarged_thyroid'),('brittle_nails'),('swollen_extremeties'),
('excessive_hunger'),('extra_marital_contacts'),('drying_and_tingling_lips'),
('slurred_speech'),('knee_pain'),('hip_joint_pain'),('muscle_weakness'),('stiff_neck'),
('swelling_joints'),('movement_stiffness'),('spinning_movements'),('loss_of_balance'),
('unsteadiness'),('weakness_of_one_body_side'),('loss_of_smell'),('bladder_discomfort'),
('foul_smell_of_urine'),('continuous_feel_of_urine'),('passage_of_gases'),
('internal_itching'),('toxic_look_(typhos)'),('depression'),('irritability'),
('muscle_pain'),('altered_sensorium'),('red_spots_over_body'),('belly_pain'),
('abnormal_menstruation'),('watering_from_eyes'),('increased_appetite'),
('polyuria'),('family_history'),('mucoid_sputum'),('rusty_sputum'),
('lack_of_concentration'),('visual_disturbances'),('receiving_blood_transfusion'),
('receiving_unsterile_injections'),('coma'),('stomach_bleeding'),
('distention_of_abdomen'),('history_of_alcohol_consumption'),('blood_in_sputum'),
('prominent_veins_on_calf'),('palpitations'),('painful_walking'),
('pus_filled_pimples'),('blackheads'),('scurring'),('skin_peeling'),
('silver_like_dusting'),('small_dents_in_nails'),('inflammatory_nails'),
('blister'),('red_sore_around_nose'),('yellow_crust_ooze');
```

Expected: ~132 symptoms inserted.

- [ ] **Step 3: Reload symptoms page, verify checkboxes appear**

- [ ] **Step 4: Commit**

```bash
git add patient/symptoms.php
git commit -m "feat(patient): add symptom selection page with DB-driven checklist"
```

---

## Task 4: Appointment Booking

**Files:**
- Create: `patient/book_appointment.php`

- [ ] **Step 1: Write patient/book_appointment.php**

This page receives `?doctor_id=X` from the recommendations page and shows available slots.

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$patient_id = (int)$_SESSION['patient_id'];
$doctor_id  = (int)($_GET['doctor_id'] ?? 0);

if (!$doctor_id) {
    header('Location: recommendations.php');
    exit;
}

$error = '';
$success = '';

// Load doctor info
$stmt = $conn->prepare(
    'SELECT u.name, d.specialization_id, d.consultation_fee, d.city, d.area, d.clinic_name,
            s.specialization_name
     FROM doctors d
     JOIN users u ON u.user_id = d.user_id
     JOIN specializations s ON s.specialization_id = d.specialization_id
     WHERE d.doctor_id = ? AND d.approval_status = "approved"'
);
$stmt->bind_param('i', $doctor_id);
$stmt->execute();
$stmt->bind_result($doc_name, $spec_id, $fee, $doc_city, $doc_area, $clinic, $spec_name);
$stmt->fetch();
$stmt->close();

if (!$doc_name) {
    header('Location: recommendations.php');
    exit;
}

// Load available slots
$slots = [];
$s2 = $conn->prepare(
    'SELECT availability_id, available_day, start_time, end_time
     FROM doctor_availability
     WHERE doctor_id = ? AND slot_status = "available"
     ORDER BY FIELD(available_day,"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"), start_time'
);
$s2->bind_param('i', $doctor_id);
$s2->execute();
$res = $s2->get_result();
while ($row = $res->fetch_assoc()) {
    $slots[] = $row;
}
$s2->close();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $availability_id = (int)($_POST['availability_id'] ?? 0);
    $appt_date       = trim($_POST['appointment_date'] ?? '');

    if (!$availability_id || !$appt_date) {
        $error = 'Please select a time slot and date.';
    } else {
        // Check slot is still available
        $chk = $conn->prepare('SELECT slot_status FROM doctor_availability WHERE availability_id = ? AND doctor_id = ?');
        $chk->bind_param('ii', $availability_id, $doctor_id);
        $chk->execute();
        $chk->bind_result($slot_status);
        $chk->fetch();
        $chk->close();

        if ($slot_status !== 'available') {
            $error = 'Selected slot is no longer available.';
        } else {
            // Check duplicate booking for same patient + doctor + date
            $dup = $conn->prepare(
                'SELECT appointment_id FROM appointments WHERE patient_id = ? AND doctor_id = ? AND appointment_date = ? AND status NOT IN ("rejected","cancelled")'
            );
            $dup->bind_param('iis', $patient_id, $doctor_id, $appt_date);
            $dup->execute();
            $dup->store_result();

            if ($dup->num_rows > 0) {
                $error = 'You already have an appointment with this doctor on that date.';
            } else {
                // Get time from slot
                $ts = $conn->prepare('SELECT start_time FROM doctor_availability WHERE availability_id = ?');
                $ts->bind_param('i', $availability_id);
                $ts->execute();
                $ts->bind_result($appt_time);
                $ts->fetch();
                $ts->close();

                $conn->begin_transaction();
                try {
                    $ins = $conn->prepare(
                        'INSERT INTO appointments (patient_id, doctor_id, availability_id, appointment_date, appointment_time, status)
                         VALUES (?, ?, ?, ?, ?, "pending")'
                    );
                    $ins->bind_param('iiiss', $patient_id, $doctor_id, $availability_id, $appt_date, $appt_time);
                    $ins->execute();

                    // Mark slot as booked
                    $upd = $conn->prepare('UPDATE doctor_availability SET slot_status = "booked" WHERE availability_id = ?');
                    $upd->bind_param('i', $availability_id);
                    $upd->execute();

                    $conn->commit();
                    $success = 'Appointment booked successfully. Waiting for doctor approval.';
                } catch (Exception $e) {
                    $conn->rollback();
                    $error = 'Booking failed. Please try again.';
                }
            }
            $dup->close();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Book Appointment</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4" style="max-width:600px">
    <h2>Book Appointment</h2>
    <div class="card p-3 mb-3">
        <strong><?= htmlspecialchars($doc_name) ?></strong><br>
        <?= htmlspecialchars($spec_name) ?> | <?= htmlspecialchars($clinic) ?><br>
        <?= htmlspecialchars($doc_city) ?>, <?= htmlspecialchars($doc_area) ?> | Fee: NPR <?= number_format($fee, 2) ?>
    </div>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?> <a href="appointments.php">View appointments</a></div><?php endif; ?>
    <?php if (!$success): ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Select Available Slot *</label>
            <select name="availability_id" class="form-select" required>
                <option value="">-- Select Slot --</option>
                <?php foreach ($slots as $slot): ?>
                <option value="<?= $slot['availability_id'] ?>">
                    <?= htmlspecialchars($slot['available_day']) ?> — <?= substr($slot['start_time'], 0, 5) ?> to <?= substr($slot['end_time'], 0, 5) ?>
                </option>
                <?php endforeach; ?>
            </select></div>
        <div class="mb-3"><label class="form-label">Appointment Date *</label>
            <input type="date" name="appointment_date" class="form-control" min="<?= date('Y-m-d') ?>" required></div>
        <button type="submit" class="btn btn-primary">Confirm Booking</button>
    </form>
    <?php endif; ?>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test booking flow**

First add availability for a doctor (in doctor module). Then book as patient.
Check DB: `appointments` table has a new row with `status = pending`. `doctor_availability` slot status = `booked`.

- [ ] **Step 3: Test duplicate prevention**

Try booking same doctor and date again. Expected: error "You already have an appointment..."

- [ ] **Step 4: Commit**

```bash
git add patient/book_appointment.php
git commit -m "feat(patient): add appointment booking with slot availability and duplicate prevention"
```

---

## Task 5: Appointment History

**Files:**
- Create: `patient/appointments.php`

- [ ] **Step 1: Write patient/appointments.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$patient_id = (int)$_SESSION['patient_id'];

// Cancel appointment handler
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cancel_id'])) {
    $appt_id = (int)$_POST['cancel_id'];
    $upd = $conn->prepare(
        'UPDATE appointments SET status = "cancelled" WHERE appointment_id = ? AND patient_id = ? AND status = "pending"'
    );
    $upd->bind_param('ii', $appt_id, $patient_id);
    $upd->execute();

    if ($upd->affected_rows > 0) {
        // Free up the slot
        $slot = $conn->prepare(
            'UPDATE doctor_availability da
             JOIN appointments a ON a.availability_id = da.availability_id
             SET da.slot_status = "available"
             WHERE a.appointment_id = ?'
        );
        $slot->bind_param('i', $appt_id);
        $slot->execute();
    }
}

// Fetch appointments
$stmt = $conn->prepare(
    'SELECT a.appointment_id, u.name AS doctor_name, s.specialization_name,
            a.appointment_date, a.appointment_time, a.status,
            (SELECT COUNT(*) FROM reviews r WHERE r.appointment_id = a.appointment_id) AS has_review
     FROM appointments a
     JOIN doctors d ON d.doctor_id = a.doctor_id
     JOIN users u ON u.user_id = d.user_id
     JOIN specializations s ON s.specialization_id = d.specialization_id
     WHERE a.patient_id = ?
     ORDER BY a.appointment_date DESC'
);
$stmt->bind_param('i', $patient_id);
$stmt->execute();
$appointments = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

$status_badges = [
    'pending'   => 'warning',
    'approved'  => 'success',
    'rejected'  => 'danger',
    'completed' => 'primary',
    'cancelled' => 'secondary',
];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>My Appointments</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>My Appointments</h2>
    <?php if (empty($appointments)): ?>
        <div class="alert alert-info">No appointments yet. <a href="symptoms.php">Get a recommendation</a> to book one.</div>
    <?php else: ?>
    <table class="table table-bordered table-hover">
        <thead class="table-dark">
            <tr><th>Doctor</th><th>Specialization</th><th>Date</th><th>Time</th><th>Status</th><th>Action</th></tr>
        </thead>
        <tbody>
        <?php foreach ($appointments as $a): ?>
            <tr>
                <td><?= htmlspecialchars($a['doctor_name']) ?></td>
                <td><?= htmlspecialchars($a['specialization_name']) ?></td>
                <td><?= htmlspecialchars($a['appointment_date']) ?></td>
                <td><?= substr($a['appointment_time'], 0, 5) ?></td>
                <td><span class="badge bg-<?= $status_badges[$a['status']] ?>"><?= ucfirst($a['status']) ?></span></td>
                <td>
                    <?php if ($a['status'] === 'pending'): ?>
                        <form method="POST" style="display:inline" onsubmit="return confirm('Cancel this appointment?')">
                            <input type="hidden" name="cancel_id" value="<?= $a['appointment_id'] ?>">
                            <button class="btn btn-sm btn-outline-danger">Cancel</button>
                        </form>
                    <?php elseif ($a['status'] === 'completed' && !$a['has_review']): ?>
                        <a href="review.php?appointment_id=<?= $a['appointment_id'] ?>" class="btn btn-sm btn-outline-primary">Leave Review</a>
                    <?php elseif ($a['status'] === 'completed' && $a['has_review']): ?>
                        <span class="text-muted small">Reviewed</span>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php endif; ?>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test**

Book an appointment, visit this page. Verify appointment shows with `Pending` badge.
Test cancellation — status changes to `Cancelled`, slot freed in `doctor_availability`.

- [ ] **Step 3: Commit**

```bash
git add patient/appointments.php
git commit -m "feat(patient): add appointment history with cancel action and review link"
```

---

## Task 6: Rating and Review Submission

**Files:**
- Create: `patient/review.php`

- [ ] **Step 1: Write patient/review.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$patient_id    = (int)$_SESSION['patient_id'];
$appointment_id = (int)($_GET['appointment_id'] ?? 0);

if (!$appointment_id) {
    header('Location: appointments.php');
    exit;
}

// Verify appointment belongs to this patient, is completed, and not yet reviewed
$stmt = $conn->prepare(
    'SELECT a.doctor_id, u.name AS doctor_name, a.appointment_date
     FROM appointments a
     JOIN doctors d ON d.doctor_id = a.doctor_id
     JOIN users u ON u.user_id = d.user_id
     WHERE a.appointment_id = ? AND a.patient_id = ? AND a.status = "completed"
       AND NOT EXISTS (SELECT 1 FROM reviews r WHERE r.appointment_id = a.appointment_id)'
);
$stmt->bind_param('ii', $appointment_id, $patient_id);
$stmt->execute();
$stmt->bind_result($doctor_id, $doctor_name, $appt_date);
$fetched = $stmt->fetch();
$stmt->close();

if (!$fetched) {
    header('Location: appointments.php');
    exit;
}

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rating      = (int)($_POST['rating'] ?? 0);
    $review_text = trim($_POST['review_text'] ?? '');

    if ($rating < 1 || $rating > 5) {
        $error = 'Please select a rating between 1 and 5.';
    } else {
        $ins = $conn->prepare(
            'INSERT INTO reviews (appointment_id, patient_id, doctor_id, rating, review_text) VALUES (?, ?, ?, ?, ?)'
        );
        $ins->bind_param('iiiis', $appointment_id, $patient_id, $doctor_id, $rating, $review_text);
        $ins->execute();

        // Recalculate doctor average rating from active reviews
        $upd = $conn->prepare(
            'UPDATE doctors SET average_rating = (
                SELECT COALESCE(AVG(r.rating), 0)
                FROM reviews r
                WHERE r.doctor_id = ? AND r.status = "active"
             ) WHERE doctor_id = ?'
        );
        $upd->bind_param('ii', $doctor_id, $doctor_id);
        $upd->execute();

        $success = 'Review submitted. Thank you!';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Leave Review</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4" style="max-width:520px">
    <h2>Leave a Review</h2>
    <p>Appointment with <strong><?= htmlspecialchars($doctor_name) ?></strong> on <?= htmlspecialchars($appt_date) ?></p>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?> <a href="appointments.php">Back to appointments</a></div>
    <?php else: ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Rating *</label>
            <select name="rating" class="form-select" required>
                <option value="">-- Select --</option>
                <?php for ($i = 5; $i >= 1; $i--): ?>
                <option value="<?= $i ?>"><?= $i ?> Star<?= $i > 1 ? 's' : '' ?></option>
                <?php endfor; ?>
            </select></div>
        <div class="mb-3"><label class="form-label">Written Review (optional)</label>
            <textarea name="review_text" class="form-control" rows="4" maxlength="1000"></textarea></div>
        <button type="submit" class="btn btn-primary">Submit Review</button>
    </form>
    <?php endif; ?>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test review submission**

Mark an appointment as `completed` in phpMyAdmin. Click "Leave Review" from appointments page. Submit a rating. Verify `reviews` table has a new row and `doctors.average_rating` is updated.

- [ ] **Step 3: Test duplicate prevention**

Try visiting the review URL again after submitting. Expected: redirected back to appointments (NOT EXISTS check fails).

- [ ] **Step 4: Commit**

```bash
git add patient/review.php
git commit -m "feat(patient): add rating and review submission with average rating recalculation"
```

---

## Task 7: Recommendation History

**Files:**
- Create: `patient/recommendation_history.php`

- [ ] **Step 1: Write patient/recommendation_history.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$patient_id = (int)$_SESSION['patient_id'];

$stmt = $conn->prepare(
    'SELECT r.recommendation_id, r.symptoms_input, r.predicted_disease,
            s.specialization_name, r.confidence_score, r.created_at
     FROM recommendations r
     LEFT JOIN specializations s ON s.specialization_id = r.predicted_specialization_id
     WHERE r.patient_id = ?
     ORDER BY r.created_at DESC'
);
$stmt->bind_param('i', $patient_id);
$stmt->execute();
$records = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Recommendation History</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Recommendation History</h2>
    <?php if (empty($records)): ?>
        <div class="alert alert-info">No recommendations yet.</div>
    <?php else: ?>
    <div class="accordion" id="historyAccordion">
    <?php foreach ($records as $i => $r): ?>
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button <?= $i > 0 ? 'collapsed' : '' ?>" type="button"
                        data-bs-toggle="collapse" data-bs-target="#rec<?= $r['recommendation_id'] ?>">
                    <?= htmlspecialchars($r['created_at']) ?> —
                    <?= htmlspecialchars($r['predicted_disease'] ?? 'Unknown') ?>
                    (<?= number_format($r['confidence_score'] * 100, 1) ?>% confidence)
                </button>
            </h2>
            <div id="rec<?= $r['recommendation_id'] ?>" class="accordion-collapse collapse <?= $i === 0 ? 'show' : '' ?>">
                <div class="accordion-body">
                    <p><strong>Symptoms entered:</strong> <?= htmlspecialchars($r['symptoms_input']) ?></p>
                    <p><strong>Predicted disease:</strong> <?= htmlspecialchars($r['predicted_disease'] ?? 'N/A') ?></p>
                    <p><strong>Recommended specialization:</strong> <?= htmlspecialchars($r['specialization_name'] ?? 'General Physician') ?></p>
                </div>
            </div>
        </div>
    <?php endforeach; ?>
    </div>
    <?php endif; ?>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test**

After using the symptom recommendation feature, visit this page. Verify history entries show.

- [ ] **Step 3: Commit**

```bash
git add patient/recommendation_history.php
git commit -m "feat(patient): add recommendation history page with accordion view"
```
