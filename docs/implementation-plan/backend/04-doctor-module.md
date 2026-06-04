# Backend: Doctor Module — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all backend logic for the doctor role — dashboard, profile management, availability slots, and appointment request handling (accept/reject/complete).

**Architecture:** Each doctor page guards with `requireDoctor()` and reads `$_SESSION['doctor_id']`. The doctor can only see their own data. Appointment status changes update `doctor_availability.slot_status` accordingly.

**Prerequisites:** `01-database-and-auth.md` complete. At least one doctor approved in DB.

**Tech Stack:** PHP 8.x, MySQLi, Bootstrap 5

---

## File Map

| File | Purpose |
|---|---|
| `doctor/dashboard.php` | Doctor home — pending requests count, summary |
| `doctor/profile.php` | Update professional profile |
| `doctor/availability.php` | Add/remove available time slots |
| `doctor/appointments.php` | View all appointment requests; accept, reject, complete |

---

## Task 1: Doctor Dashboard

**Files:**
- Create: `doctor/dashboard.php`

- [ ] **Step 1: Write doctor/dashboard.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireDoctor();

$doctor_id = (int)$_SESSION['doctor_id'];
$user_id   = currentUserId();

$stmt = $conn->prepare('SELECT u.name, d.specialization_id, s.specialization_name, d.average_rating FROM users u JOIN doctors d ON d.user_id = u.user_id JOIN specializations s ON s.specialization_id = d.specialization_id WHERE u.user_id = ?');
$stmt->bind_param('i', $user_id);
$stmt->execute();
$stmt->bind_result($name, $spec_id, $spec_name, $avg_rating);
$stmt->fetch();
$stmt->close();

$pending  = $conn->query("SELECT COUNT(*) FROM appointments WHERE doctor_id = $doctor_id AND status = 'pending'")->fetch_row()[0];
$total    = $conn->query("SELECT COUNT(*) FROM appointments WHERE doctor_id = $doctor_id")->fetch_row()[0];
$slots    = $conn->query("SELECT COUNT(*) FROM doctor_availability WHERE doctor_id = $doctor_id AND slot_status = 'available'")->fetch_row()[0];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Doctor Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Dr. <?= htmlspecialchars($name) ?></h2>
    <p class="text-muted"><?= htmlspecialchars($spec_name) ?> | ⭐ <?= number_format($avg_rating, 1) ?></p>
    <div class="row g-3 mt-2">
        <div class="col-md-4">
            <div class="card text-center p-3 border-warning">
                <h4><?= $pending ?></h4><p>Pending Requests</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total ?></h4><p>Total Appointments</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $slots ?></h4><p>Available Slots</p>
            </div>
        </div>
    </div>
    <div class="mt-4">
        <a href="appointments.php" class="btn btn-warning me-2">View Appointment Requests</a>
        <a href="availability.php" class="btn btn-outline-secondary me-2">Manage Availability</a>
        <a href="profile.php" class="btn btn-outline-secondary">Edit Profile</a>
    </div>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Verify**

Login as approved doctor. Expected: dashboard with 3 stat cards and action buttons.

- [ ] **Step 3: Commit**

```bash
git add doctor/dashboard.php
git commit -m "feat(doctor): add doctor dashboard with appointment and slot counts"
```

---

## Task 2: Doctor Profile Management

**Files:**
- Create: `doctor/profile.php`

- [ ] **Step 1: Write doctor/profile.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireDoctor();

$doctor_id = (int)$_SESSION['doctor_id'];
$user_id   = currentUserId();
$error = '';
$success = '';

// Load specializations for dropdown
$specs = $conn->query('SELECT specialization_id, specialization_name FROM specializations ORDER BY specialization_name')->fetch_all(MYSQLI_ASSOC);

// Load current data
$stmt = $conn->prepare(
    'SELECT u.name, u.email, d.specialization_id, d.qualification, d.experience_years,
            d.consultation_fee, d.clinic_name, d.license_number, d.contact_number, d.city, d.area
     FROM users u JOIN doctors d ON d.user_id = u.user_id WHERE u.user_id = ?'
);
$stmt->bind_param('i', $user_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $new_name    = trim($_POST['name'] ?? '');
    $new_spec    = (int)($_POST['specialization_id'] ?? 0);
    $new_qual    = trim($_POST['qualification'] ?? '');
    $new_exp     = (int)($_POST['experience_years'] ?? 0);
    $new_fee     = (float)($_POST['consultation_fee'] ?? 0);
    $new_clinic  = trim($_POST['clinic_name'] ?? '');
    $new_license = trim($_POST['license_number'] ?? '');
    $new_contact = trim($_POST['contact_number'] ?? '');
    $new_city    = trim($_POST['city'] ?? '');
    $new_area    = trim($_POST['area'] ?? '');

    if (!$new_name || !$new_spec) {
        $error = 'Name and specialization are required.';
    } else {
        $s1 = $conn->prepare('UPDATE users SET name = ? WHERE user_id = ?');
        $s1->bind_param('si', $new_name, $user_id);
        $s1->execute();

        $s2 = $conn->prepare(
            'UPDATE doctors SET specialization_id = ?, qualification = ?, experience_years = ?,
             consultation_fee = ?, clinic_name = ?, license_number = ?, contact_number = ?, city = ?, area = ?
             WHERE doctor_id = ?'
        );
        $s2->bind_param('isidsssssi', $new_spec, $new_qual, $new_exp, $new_fee, $new_clinic, $new_license, $new_contact, $new_city, $new_area, $doctor_id);
        $s2->execute();

        $success = 'Profile updated.';
        $row = array_merge($row, [
            'name' => $new_name, 'specialization_id' => $new_spec,
            'qualification' => $new_qual, 'experience_years' => $new_exp,
            'consultation_fee' => $new_fee, 'clinic_name' => $new_clinic,
            'license_number' => $new_license, 'contact_number' => $new_contact,
            'city' => $new_city, 'area' => $new_area,
        ]);
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Doctor Profile</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4" style="max-width:560px">
    <h2>Edit Profile</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Full Name *</label>
            <input type="text" name="name" class="form-control" value="<?= htmlspecialchars($row['name']) ?>" required></div>
        <div class="mb-3"><label class="form-label">Email (read-only)</label>
            <input class="form-control" value="<?= htmlspecialchars($row['email']) ?>" disabled></div>
        <div class="mb-3"><label class="form-label">Specialization *</label>
            <select name="specialization_id" class="form-select" required>
                <?php foreach ($specs as $s): ?>
                <option value="<?= $s['specialization_id'] ?>" <?= (int)$row['specialization_id'] === (int)$s['specialization_id'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($s['specialization_name']) ?>
                </option>
                <?php endforeach; ?>
            </select></div>
        <div class="mb-3"><label class="form-label">Qualification</label>
            <input type="text" name="qualification" class="form-control" value="<?= htmlspecialchars($row['qualification']) ?>"></div>
        <div class="mb-3"><label class="form-label">Experience (years)</label>
            <input type="number" name="experience_years" class="form-control" min="0" value="<?= (int)$row['experience_years'] ?>"></div>
        <div class="mb-3"><label class="form-label">Consultation Fee (NPR)</label>
            <input type="number" name="consultation_fee" class="form-control" min="0" step="0.01" value="<?= (float)$row['consultation_fee'] ?>"></div>
        <div class="mb-3"><label class="form-label">Clinic/Hospital Name</label>
            <input type="text" name="clinic_name" class="form-control" value="<?= htmlspecialchars($row['clinic_name']) ?>"></div>
        <div class="mb-3"><label class="form-label">License Number</label>
            <input type="text" name="license_number" class="form-control" value="<?= htmlspecialchars($row['license_number']) ?>"></div>
        <div class="mb-3"><label class="form-label">Contact Number</label>
            <input type="text" name="contact_number" class="form-control" value="<?= htmlspecialchars($row['contact_number']) ?>"></div>
        <div class="mb-3"><label class="form-label">City</label>
            <input type="text" name="city" class="form-control" value="<?= htmlspecialchars($row['city']) ?>"></div>
        <div class="mb-3"><label class="form-label">Area</label>
            <input type="text" name="area" class="form-control" value="<?= htmlspecialchars($row['area']) ?>"></div>
        <button type="submit" class="btn btn-primary">Save Changes</button>
    </form>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test update**

Change fee and experience. Verify DB updated. Reload — values persist.

- [ ] **Step 3: Commit**

```bash
git add doctor/profile.php
git commit -m "feat(doctor): add doctor profile management page"
```

---

## Task 3: Availability Management

**Files:**
- Create: `doctor/availability.php`

- [ ] **Step 1: Write doctor/availability.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireDoctor();

$doctor_id = (int)$_SESSION['doctor_id'];
$error = '';
$success = '';

// Add slot
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_slot'])) {
    $day   = $_POST['available_day'] ?? '';
    $start = $_POST['start_time'] ?? '';
    $end   = $_POST['end_time'] ?? '';

    $valid_days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    if (!in_array($day, $valid_days, true) || !$start || !$end) {
        $error = 'Day, start time, and end time are required.';
    } elseif ($start >= $end) {
        $error = 'End time must be after start time.';
    } else {
        $ins = $conn->prepare('INSERT INTO doctor_availability (doctor_id, available_day, start_time, end_time) VALUES (?, ?, ?, ?)');
        $ins->bind_param('isss', $doctor_id, $day, $start, $end);
        $ins->execute();
        $success = 'Slot added.';
    }
}

// Remove slot (only if not booked)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['remove_id'])) {
    $slot_id = (int)$_POST['remove_id'];
    $del = $conn->prepare('DELETE FROM doctor_availability WHERE availability_id = ? AND doctor_id = ? AND slot_status = "available"');
    $del->bind_param('ii', $slot_id, $doctor_id);
    $del->execute();
    if ($del->affected_rows === 0) {
        $error = 'Cannot remove a booked slot.';
    } else {
        $success = 'Slot removed.';
    }
}

// Load existing slots
$slots_stmt = $conn->prepare(
    'SELECT availability_id, available_day, start_time, end_time, slot_status
     FROM doctor_availability WHERE doctor_id = ?
     ORDER BY FIELD(available_day,"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"), start_time'
);
$slots_stmt->bind_param('i', $doctor_id);
$slots_stmt->execute();
$slots = $slots_stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$slots_stmt->close();

$days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Manage Availability</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4" style="max-width:700px">
    <h2>Manage Availability</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>

    <h5>Add New Slot</h5>
    <form method="POST" class="row g-2 mb-4">
        <div class="col-md-4">
            <select name="available_day" class="form-select" required>
                <option value="">Select Day</option>
                <?php foreach ($days as $d): ?>
                <option value="<?= $d ?>"><?= $d ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-3">
            <input type="time" name="start_time" class="form-control" required>
        </div>
        <div class="col-md-3">
            <input type="time" name="end_time" class="form-control" required>
        </div>
        <div class="col-md-2">
            <button type="submit" name="add_slot" class="btn btn-primary w-100">Add</button>
        </div>
    </form>

    <h5>Current Slots</h5>
    <?php if (empty($slots)): ?>
        <p class="text-muted">No slots defined yet.</p>
    <?php else: ?>
    <table class="table table-bordered">
        <thead class="table-dark"><tr><th>Day</th><th>Start</th><th>End</th><th>Status</th><th>Action</th></tr></thead>
        <tbody>
        <?php foreach ($slots as $slot): ?>
            <tr>
                <td><?= htmlspecialchars($slot['available_day']) ?></td>
                <td><?= substr($slot['start_time'], 0, 5) ?></td>
                <td><?= substr($slot['end_time'], 0, 5) ?></td>
                <td>
                    <span class="badge bg-<?= $slot['slot_status'] === 'available' ? 'success' : ($slot['slot_status'] === 'booked' ? 'warning text-dark' : 'secondary') ?>">
                        <?= ucfirst($slot['slot_status']) ?>
                    </span>
                </td>
                <td>
                    <?php if ($slot['slot_status'] === 'available'): ?>
                    <form method="POST" style="display:inline" onsubmit="return confirm('Remove this slot?')">
                        <input type="hidden" name="remove_id" value="<?= $slot['availability_id'] ?>">
                        <button class="btn btn-sm btn-outline-danger">Remove</button>
                    </form>
                    <?php else: ?>
                        <span class="text-muted small">Cannot remove</span>
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

- [ ] **Step 2: Test add slot**

Add Monday 09:00–10:00. Check DB `doctor_availability` has new row with `slot_status = available`.

- [ ] **Step 3: Test remove slot**

Remove the slot. Check DB row deleted.

- [ ] **Step 4: Test cannot remove booked slot**

Book that slot as a patient. Then try to remove. Expected: "Cannot remove a booked slot."

- [ ] **Step 5: Commit**

```bash
git add doctor/availability.php
git commit -m "feat(doctor): add availability management with add/remove slot and booked protection"
```

---

## Task 4: Appointment Management

**Files:**
- Create: `doctor/appointments.php`

- [ ] **Step 1: Write doctor/appointments.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireDoctor();

$doctor_id = (int)$_SESSION['doctor_id'];
$error = '';
$success = '';

// Handle status change
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['appointment_id'])) {
    $appt_id = (int)$_POST['appointment_id'];
    $action  = $_POST['action'];

    $allowed = ['approved' => 'pending', 'rejected' => 'pending', 'completed' => 'approved'];

    if (array_key_exists($action, $allowed)) {
        $required_status = $allowed[$action];

        $upd = $conn->prepare(
            'UPDATE appointments SET status = ? WHERE appointment_id = ? AND doctor_id = ? AND status = ?'
        );
        $upd->bind_param('siis', $action, $appt_id, $doctor_id, $required_status);
        $upd->execute();

        if ($upd->affected_rows > 0) {
            // If rejected → free the slot
            if ($action === 'rejected') {
                $free = $conn->prepare(
                    'UPDATE doctor_availability da JOIN appointments a ON a.availability_id = da.availability_id
                     SET da.slot_status = "available" WHERE a.appointment_id = ?'
                );
                $free->bind_param('i', $appt_id);
                $free->execute();
            }
            $success = 'Appointment status updated.';
        } else {
            $error = 'Action not allowed for this appointment status.';
        }
    }
}

// Fetch appointments with patient recommendation details
$stmt = $conn->prepare(
    'SELECT a.appointment_id, u.name AS patient_name, a.appointment_date, a.appointment_time, a.status,
            r.symptoms_input, r.predicted_disease, sp.specialization_name
     FROM appointments a
     JOIN patients p ON p.patient_id = a.patient_id
     JOIN users u ON u.user_id = p.user_id
     LEFT JOIN recommendations r ON r.patient_id = a.patient_id
         AND r.created_at = (SELECT MAX(r2.created_at) FROM recommendations r2 WHERE r2.patient_id = a.patient_id)
     LEFT JOIN specializations sp ON sp.specialization_id = r.predicted_specialization_id
     WHERE a.doctor_id = ?
     ORDER BY FIELD(a.status,"pending","approved","completed","rejected","cancelled"), a.appointment_date ASC'
);
$stmt->bind_param('i', $doctor_id);
$stmt->execute();
$appointments = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

$badge = ['pending' => 'warning', 'approved' => 'success', 'rejected' => 'danger', 'completed' => 'primary', 'cancelled' => 'secondary'];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Appointment Requests</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Appointment Requests</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <?php if (empty($appointments)): ?>
        <div class="alert alert-info">No appointment requests yet.</div>
    <?php else: ?>
    <?php foreach ($appointments as $a): ?>
    <div class="card mb-3">
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <h6 class="mb-1"><strong><?= htmlspecialchars($a['patient_name']) ?></strong></h6>
                    <p class="mb-1"><?= htmlspecialchars($a['appointment_date']) ?> at <?= substr($a['appointment_time'], 0, 5) ?></p>
                    <?php if ($a['symptoms_input']): ?>
                    <p class="mb-1 text-muted small">
                        <em>Symptoms:</em> <?= htmlspecialchars($a['symptoms_input']) ?><br>
                        <em>Predicted disease:</em> <?= htmlspecialchars($a['predicted_disease'] ?? 'N/A') ?>
                    </p>
                    <?php endif; ?>
                </div>
                <span class="badge bg-<?= $badge[$a['status']] ?>"><?= ucfirst($a['status']) ?></span>
            </div>
            <div class="mt-2">
                <?php if ($a['status'] === 'pending'): ?>
                    <form method="POST" style="display:inline">
                        <input type="hidden" name="appointment_id" value="<?= $a['appointment_id'] ?>">
                        <button name="action" value="approved" class="btn btn-sm btn-success me-1">Approve</button>
                        <button name="action" value="rejected" class="btn btn-sm btn-danger"
                                onclick="return confirm('Reject this appointment?')">Reject</button>
                    </form>
                <?php elseif ($a['status'] === 'approved'): ?>
                    <form method="POST" style="display:inline">
                        <input type="hidden" name="appointment_id" value="<?= $a['appointment_id'] ?>">
                        <button name="action" value="completed" class="btn btn-sm btn-primary">Mark Completed</button>
                    </form>
                <?php endif; ?>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
    <?php endif; ?>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test approve flow**

Have a patient book an appointment. Login as doctor. Approve it. Verify DB: `status = approved`.

- [ ] **Step 3: Test reject flow**

Reject a pending appointment. Verify: `status = rejected`, `doctor_availability.slot_status = available` (slot freed).

- [ ] **Step 4: Test complete flow**

Mark an approved appointment as completed. Verify `status = completed`. Patient should now be able to leave a review.

- [ ] **Step 5: Commit**

```bash
git add doctor/appointments.php
git commit -m "feat(doctor): add appointment management with approve, reject, complete actions and patient recommendation details"
```
