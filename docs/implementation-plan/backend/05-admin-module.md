# Backend: Admin Module — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all admin backend pages — dashboard, doctor approval, user management, content management (specializations, symptoms, diseases, mappings), appointment monitoring, and review moderation.

**Architecture:** Every admin page guards with `requireAdmin()`. Admin has read/write access to all records. All destructive actions (delete, reject) use POST with confirmation. No patient medical data is exposed beyond what's needed for management.

**Prerequisites:** `01-database-and-auth.md` complete. Admin account in DB (seeded by schema.sql).

**Tech Stack:** PHP 8.x, MySQLi, Bootstrap 5

---

## File Map

| File | Purpose |
|---|---|
| `admin/dashboard.php` | Summary stats for the whole system |
| `admin/approve_doctors.php` | List pending registrations; approve or reject |
| `admin/manage_doctors.php` | View all doctors; deactivate/remove |
| `admin/manage_patients.php` | View all patients; deactivate/remove |
| `admin/manage_specializations.php` | CRUD for specializations |
| `admin/manage_symptoms.php` | CRUD for symptoms (fed to ML dataset) |
| `admin/manage_diseases.php` | CRUD for diseases + disease-specialization mapping |
| `admin/manage_appointments.php` | View all appointments, filter by status |
| `admin/manage_reviews.php` | View all reviews; remove inappropriate ones |

---

## Task 1: Admin Dashboard

**Files:**
- Create: `admin/dashboard.php`

- [ ] **Step 1: Write admin/dashboard.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$total_patients    = $conn->query("SELECT COUNT(*) FROM patients")->fetch_row()[0];
$total_doctors     = $conn->query("SELECT COUNT(*) FROM doctors WHERE approval_status = 'approved'")->fetch_row()[0];
$pending_doctors   = $conn->query("SELECT COUNT(*) FROM doctors WHERE approval_status = 'pending'")->fetch_row()[0];
$total_appts       = $conn->query("SELECT COUNT(*) FROM appointments")->fetch_row()[0];
$pending_appts     = $conn->query("SELECT COUNT(*) FROM appointments WHERE status = 'pending'")->fetch_row()[0];
$total_reviews     = $conn->query("SELECT COUNT(*) FROM reviews WHERE status = 'active'")->fetch_row()[0];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Admin Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Admin Dashboard</h2>
    <div class="row g-3 mt-2">
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total_patients ?></h4><p>Registered Patients</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total_doctors ?></h4><p>Approved Doctors</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3 border-warning">
                <h4><?= $pending_doctors ?></h4><p>Pending Doctor Approvals</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total_appts ?></h4><p>Total Appointments</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3 border-warning">
                <h4><?= $pending_appts ?></h4><p>Pending Appointments</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center p-3">
                <h4><?= $total_reviews ?></h4><p>Active Reviews</p>
            </div>
        </div>
    </div>
    <div class="mt-4">
        <a href="approve_doctors.php" class="btn btn-warning me-2">Doctor Approvals</a>
        <a href="manage_doctors.php" class="btn btn-outline-secondary me-2">Manage Doctors</a>
        <a href="manage_patients.php" class="btn btn-outline-secondary me-2">Manage Patients</a>
        <a href="manage_appointments.php" class="btn btn-outline-secondary me-2">Appointments</a>
        <a href="manage_reviews.php" class="btn btn-outline-secondary me-2">Reviews</a>
        <a href="manage_specializations.php" class="btn btn-outline-dark me-2">Specializations</a>
        <a href="manage_symptoms.php" class="btn btn-outline-dark me-2">Symptoms</a>
        <a href="manage_diseases.php" class="btn btn-outline-dark">Diseases</a>
    </div>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Verify**

Login as admin. Expected: 6 stat cards and nav buttons.

- [ ] **Step 3: Commit**

```bash
git add admin/dashboard.php
git commit -m "feat(admin): add admin dashboard with system-wide stats"
```

---

## Task 2: Doctor Approval

**Files:**
- Create: `admin/approve_doctors.php`

- [ ] **Step 1: Write admin/approve_doctors.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['doctor_id'])) {
    $doctor_id = (int)$_POST['doctor_id'];
    $action    = $_POST['action'];

    if ($action === 'approve') {
        $upd = $conn->prepare('UPDATE doctors SET approval_status = "approved" WHERE doctor_id = ?');
        // Also set user status to active
        $upd2 = $conn->prepare('UPDATE users SET status = "active" WHERE user_id = (SELECT user_id FROM doctors WHERE doctor_id = ?)');
        $upd->bind_param('i', $doctor_id);
        $upd->execute();
        $upd2->bind_param('i', $doctor_id);
        $upd2->execute();
        $success = 'Doctor approved.';
    } elseif ($action === 'reject') {
        $upd = $conn->prepare('UPDATE doctors SET approval_status = "rejected" WHERE doctor_id = ?');
        $upd->bind_param('i', $doctor_id);
        $upd->execute();
        $success = 'Doctor rejected.';
    }
}

// Load pending + all registrations
$stmt = $conn->prepare(
    'SELECT d.doctor_id, u.name, u.email, s.specialization_name,
            d.qualification, d.experience_years, d.consultation_fee,
            d.clinic_name, d.license_number, d.city, d.approval_status, u.created_at
     FROM doctors d
     JOIN users u ON u.user_id = d.user_id
     LEFT JOIN specializations s ON s.specialization_id = d.specialization_id
     ORDER BY FIELD(d.approval_status,"pending","approved","rejected"), u.created_at DESC'
);
$stmt->execute();
$doctors = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

$badge = ['pending' => 'warning', 'approved' => 'success', 'rejected' => 'danger'];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Doctor Approvals</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Doctor Approvals</h2>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <table class="table table-bordered table-hover table-sm">
        <thead class="table-dark">
            <tr><th>Name</th><th>Email</th><th>Specialization</th><th>Qualification</th><th>Experience</th><th>License</th><th>City</th><th>Status</th><th>Actions</th></tr>
        </thead>
        <tbody>
        <?php foreach ($doctors as $d): ?>
        <tr>
            <td><?= htmlspecialchars($d['name']) ?></td>
            <td><?= htmlspecialchars($d['email']) ?></td>
            <td><?= htmlspecialchars($d['specialization_name'] ?? '—') ?></td>
            <td><?= htmlspecialchars($d['qualification']) ?></td>
            <td><?= (int)$d['experience_years'] ?> yrs</td>
            <td><?= htmlspecialchars($d['license_number']) ?></td>
            <td><?= htmlspecialchars($d['city']) ?></td>
            <td><span class="badge bg-<?= $badge[$d['approval_status']] ?>"><?= ucfirst($d['approval_status']) ?></span></td>
            <td>
                <?php if ($d['approval_status'] === 'pending'): ?>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="doctor_id" value="<?= $d['doctor_id'] ?>">
                    <button name="action" value="approve" class="btn btn-sm btn-success">Approve</button>
                    <button name="action" value="reject" class="btn btn-sm btn-danger ms-1"
                            onclick="return confirm('Reject this doctor?')">Reject</button>
                </form>
                <?php elseif ($d['approval_status'] === 'approved'): ?>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="doctor_id" value="<?= $d['doctor_id'] ?>">
                    <button name="action" value="reject" class="btn btn-sm btn-outline-danger"
                            onclick="return confirm('Revoke approval?')">Revoke</button>
                </form>
                <?php else: ?>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="doctor_id" value="<?= $d['doctor_id'] ?>">
                    <button name="action" value="approve" class="btn btn-sm btn-outline-success">Re-approve</button>
                </form>
                <?php endif; ?>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test approval**

Register a doctor. Login as admin. Approve the doctor. Verify `approval_status = approved` in DB. Login as doctor — should now work.

- [ ] **Step 3: Test rejection**

Reject the doctor. Login as doctor — expected: "registration has been rejected" error.

- [ ] **Step 4: Commit**

```bash
git add admin/approve_doctors.php
git commit -m "feat(admin): add doctor approval page with approve/reject/revoke actions"
```

---

## Task 3: Manage Patients and Doctors

**Files:**
- Create: `admin/manage_patients.php`
- Create: `admin/manage_doctors.php`

- [ ] **Step 1: Write admin/manage_patients.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['user_id'])) {
    $uid    = (int)$_POST['user_id'];
    $action = $_POST['action'];
    if ($action === 'deactivate') {
        $conn->prepare('UPDATE users SET status = "inactive" WHERE user_id = ? AND role = "patient"')->bind_param('i', $uid) && true;
        $stmt = $conn->prepare('UPDATE users SET status = "inactive" WHERE user_id = ? AND role = "patient"');
        $stmt->bind_param('i', $uid); $stmt->execute();
        $success = 'Patient deactivated.';
    } elseif ($action === 'activate') {
        $stmt = $conn->prepare('UPDATE users SET status = "active" WHERE user_id = ? AND role = "patient"');
        $stmt->bind_param('i', $uid); $stmt->execute();
        $success = 'Patient activated.';
    }
}

$patients = $conn->query(
    'SELECT u.user_id, u.name, u.email, u.status, p.gender, p.age, p.city, u.created_at
     FROM users u JOIN patients p ON p.user_id = u.user_id
     ORDER BY u.created_at DESC'
)->fetch_all(MYSQLI_ASSOC);
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Manage Patients</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Manage Patients</h2>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <table class="table table-bordered table-sm table-hover">
        <thead class="table-dark">
            <tr><th>Name</th><th>Email</th><th>Gender</th><th>Age</th><th>City</th><th>Status</th><th>Registered</th><th>Action</th></tr>
        </thead>
        <tbody>
        <?php foreach ($patients as $p): ?>
        <tr>
            <td><?= htmlspecialchars($p['name']) ?></td>
            <td><?= htmlspecialchars($p['email']) ?></td>
            <td><?= htmlspecialchars($p['gender']) ?></td>
            <td><?= $p['age'] ?></td>
            <td><?= htmlspecialchars($p['city']) ?></td>
            <td><span class="badge bg-<?= $p['status'] === 'active' ? 'success' : 'secondary' ?>"><?= ucfirst($p['status']) ?></span></td>
            <td><?= date('Y-m-d', strtotime($p['created_at'])) ?></td>
            <td>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="user_id" value="<?= $p['user_id'] ?>">
                    <?php if ($p['status'] === 'active'): ?>
                        <button name="action" value="deactivate" class="btn btn-sm btn-outline-warning" onclick="return confirm('Deactivate?')">Deactivate</button>
                    <?php else: ?>
                        <button name="action" value="activate" class="btn btn-sm btn-outline-success">Activate</button>
                    <?php endif; ?>
                </form>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Write admin/manage_doctors.php** (same pattern — shows approved/rejected doctors, allows deactivating/reactivating)

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['user_id'])) {
    $uid    = (int)$_POST['user_id'];
    $action = $_POST['action'];
    if ($action === 'deactivate') {
        $stmt = $conn->prepare('UPDATE users SET status = "inactive" WHERE user_id = ? AND role = "doctor"');
        $stmt->bind_param('i', $uid); $stmt->execute();
        $success = 'Doctor account deactivated.';
    } elseif ($action === 'activate') {
        $stmt = $conn->prepare('UPDATE users SET status = "active" WHERE user_id = ? AND role = "doctor"');
        $stmt->bind_param('i', $uid); $stmt->execute();
        $success = 'Doctor account activated.';
    }
}

$doctors = $conn->query(
    'SELECT u.user_id, u.name, u.email, u.status, s.specialization_name,
            d.experience_years, d.city, d.approval_status, u.created_at
     FROM users u
     JOIN doctors d ON d.user_id = u.user_id
     LEFT JOIN specializations s ON s.specialization_id = d.specialization_id
     WHERE d.approval_status = "approved"
     ORDER BY u.created_at DESC'
)->fetch_all(MYSQLI_ASSOC);
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Manage Doctors</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Manage Doctors</h2>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <p><a href="approve_doctors.php">→ Doctor Approval Page</a></p>
    <table class="table table-bordered table-sm table-hover">
        <thead class="table-dark">
            <tr><th>Name</th><th>Email</th><th>Specialization</th><th>Experience</th><th>City</th><th>Account Status</th><th>Action</th></tr>
        </thead>
        <tbody>
        <?php foreach ($doctors as $d): ?>
        <tr>
            <td><?= htmlspecialchars($d['name']) ?></td>
            <td><?= htmlspecialchars($d['email']) ?></td>
            <td><?= htmlspecialchars($d['specialization_name'] ?? '—') ?></td>
            <td><?= (int)$d['experience_years'] ?> yrs</td>
            <td><?= htmlspecialchars($d['city']) ?></td>
            <td><span class="badge bg-<?= $d['status'] === 'active' ? 'success' : 'secondary' ?>"><?= ucfirst($d['status']) ?></span></td>
            <td>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="user_id" value="<?= $d['user_id'] ?>">
                    <?php if ($d['status'] === 'active'): ?>
                        <button name="action" value="deactivate" class="btn btn-sm btn-outline-warning" onclick="return confirm('Deactivate?')">Deactivate</button>
                    <?php else: ?>
                        <button name="action" value="activate" class="btn btn-sm btn-outline-success">Activate</button>
                    <?php endif; ?>
                </form>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 3: Test both pages**

Deactivate a patient. Try to login as that patient — expected: "Your account is inactive."

- [ ] **Step 4: Commit**

```bash
git add admin/manage_patients.php admin/manage_doctors.php
git commit -m "feat(admin): add patient and doctor management with activate/deactivate actions"
```

---

## Task 4: Manage Specializations, Symptoms, Diseases

**Files:**
- Create: `admin/manage_specializations.php`
- Create: `admin/manage_symptoms.php`
- Create: `admin/manage_diseases.php`

These three pages follow the same CRUD pattern. Below is the full implementation for `manage_specializations.php` — apply the same pattern to symptoms and diseases.

- [ ] **Step 1: Write admin/manage_specializations.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$error = '';
$success = '';

// Add
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add'])) {
    $name = trim($_POST['specialization_name'] ?? '');
    $desc = trim($_POST['description'] ?? '');
    if (!$name) {
        $error = 'Specialization name is required.';
    } else {
        $ins = $conn->prepare('INSERT INTO specializations (specialization_name, description) VALUES (?, ?)');
        $ins->bind_param('ss', $name, $desc);
        $ins->execute();
        $success = 'Specialization added.';
    }
}

// Update
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update'])) {
    $id   = (int)$_POST['specialization_id'];
    $name = trim($_POST['specialization_name'] ?? '');
    $desc = trim($_POST['description'] ?? '');
    if (!$name) {
        $error = 'Name is required.';
    } else {
        $upd = $conn->prepare('UPDATE specializations SET specialization_name = ?, description = ? WHERE specialization_id = ?');
        $upd->bind_param('ssi', $name, $desc, $id);
        $upd->execute();
        $success = 'Specialization updated.';
    }
}

// Delete
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete'])) {
    $id = (int)$_POST['specialization_id'];
    $del = $conn->prepare('DELETE FROM specializations WHERE specialization_id = ?');
    $del->bind_param('i', $id);
    $del->execute();
    $success = $del->affected_rows > 0 ? 'Specialization deleted.' : 'Cannot delete — it may be in use.';
}

$items = $conn->query('SELECT * FROM specializations ORDER BY specialization_name')->fetch_all(MYSQLI_ASSOC);
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Manage Specializations</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Manage Specializations</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>

    <h5>Add New</h5>
    <form method="POST" class="row g-2 mb-4">
        <div class="col-md-4"><input type="text" name="specialization_name" class="form-control" placeholder="Specialization Name *" required></div>
        <div class="col-md-5"><input type="text" name="description" class="form-control" placeholder="Description (optional)"></div>
        <div class="col-md-2"><button name="add" type="submit" class="btn btn-primary w-100">Add</button></div>
    </form>

    <table class="table table-bordered table-sm">
        <thead class="table-dark"><tr><th>ID</th><th>Name</th><th>Description</th><th>Actions</th></tr></thead>
        <tbody>
        <?php foreach ($items as $item): ?>
        <tr>
            <td><?= $item['specialization_id'] ?></td>
            <td>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="specialization_id" value="<?= $item['specialization_id'] ?>">
                    <input type="text" name="specialization_name" class="form-control form-control-sm" value="<?= htmlspecialchars($item['specialization_name']) ?>" required>
                </form>
            </td>
            <td>
                <form method="POST" id="upd<?= $item['specialization_id'] ?>">
                    <input type="hidden" name="specialization_id" value="<?= $item['specialization_id'] ?>">
                    <input type="text" name="description" class="form-control form-control-sm" value="<?= htmlspecialchars($item['description'] ?? '') ?>">
                    <input type="hidden" name="specialization_name" value="<?= htmlspecialchars($item['specialization_name']) ?>">
                </form>
            </td>
            <td>
                <form method="POST" style="display:inline">
                    <input type="hidden" name="specialization_id" value="<?= $item['specialization_id'] ?>">
                    <input type="hidden" name="specialization_name" value="<?= htmlspecialchars($item['specialization_name']) ?>">
                    <button name="update" type="submit" class="btn btn-sm btn-success">Save</button>
                    <button name="delete" type="submit" class="btn btn-sm btn-danger ms-1" onclick="return confirm('Delete?')">Delete</button>
                </form>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Write admin/manage_symptoms.php** — same pattern, replace `specializations` table references with `symptoms`, and `specialization_name`/`specialization_id` with `symptom_name`/`symptom_id`.

- [ ] **Step 3: Write admin/manage_diseases.php** — same pattern for `diseases` table. Also add a disease-specialization mapping section at the bottom of this page:

```php
// After the diseases table, add mapping management:
// Load diseases and specializations for the mapping form
$all_diseases = $conn->query('SELECT disease_id, disease_name FROM diseases ORDER BY disease_name')->fetch_all(MYSQLI_ASSOC);
$all_specs    = $conn->query('SELECT specialization_id, specialization_name FROM specializations ORDER BY specialization_name')->fetch_all(MYSQLI_ASSOC);
$mappings     = $conn->query(
    'SELECT m.map_id, d.disease_name, s.specialization_name
     FROM disease_specialization_map m
     JOIN diseases d ON d.disease_id = m.disease_id
     JOIN specializations s ON s.specialization_id = m.specialization_id
     ORDER BY d.disease_name'
)->fetch_all(MYSQLI_ASSOC);

// Add mapping
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_mapping'])) {
    $did = (int)$_POST['disease_id'];
    $sid = (int)$_POST['specialization_id'];
    if ($did && $sid) {
        $ins = $conn->prepare('INSERT IGNORE INTO disease_specialization_map (disease_id, specialization_id) VALUES (?, ?)');
        $ins->bind_param('ii', $did, $sid);
        $ins->execute();
    }
}
// Delete mapping
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_mapping'])) {
    $mid = (int)$_POST['map_id'];
    $del = $conn->prepare('DELETE FROM disease_specialization_map WHERE map_id = ?');
    $del->bind_param('i', $mid);
    $del->execute();
}
```

Then render a mapping form and table below the diseases table.

- [ ] **Step 4: Seed specializations**

In phpMyAdmin → SQL:

```sql
INSERT INTO specializations (specialization_name) VALUES
('General Physician'),('Dermatologist'),('Gastroenterologist'),
('Neurologist'),('Cardiologist'),('Pulmonologist'),('Endocrinologist'),
('Orthopedic Surgeon'),('Rheumatologist'),('Allergist'),
('ENT Specialist'),('Urologist'),('Vascular Surgeon'),
('Infectious Disease Specialist');
```

- [ ] **Step 5: Test CRUD for specializations**

Add, edit, delete a specialization. Verify in phpMyAdmin.

- [ ] **Step 6: Commit**

```bash
git add admin/manage_specializations.php admin/manage_symptoms.php admin/manage_diseases.php
git commit -m "feat(admin): add CRUD pages for specializations, symptoms, diseases, and disease-specialization mappings"
```

---

## Task 5: Monitor Appointments

**Files:**
- Create: `admin/manage_appointments.php`

- [ ] **Step 1: Write admin/manage_appointments.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$filter_status = $_GET['status'] ?? '';
$where = '';
$params = [];
$types  = '';

if ($filter_status) {
    $where  = 'WHERE a.status = ?';
    $params[] = $filter_status;
    $types    = 's';
}

$sql = "SELECT a.appointment_id, up.name AS patient_name, ud.name AS doctor_name,
               s.specialization_name, a.appointment_date, a.appointment_time, a.status, a.created_at
        FROM appointments a
        JOIN patients p ON p.patient_id = a.patient_id
        JOIN users up ON up.user_id = p.user_id
        JOIN doctors d ON d.doctor_id = a.doctor_id
        JOIN users ud ON ud.user_id = d.user_id
        JOIN specializations s ON s.specialization_id = d.specialization_id
        $where
        ORDER BY a.created_at DESC";

$stmt = $conn->prepare($sql);
if ($types) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$appointments = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

$statuses = ['pending','approved','rejected','completed','cancelled'];
$badge    = ['pending' => 'warning', 'approved' => 'success', 'rejected' => 'danger', 'completed' => 'primary', 'cancelled' => 'secondary'];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Manage Appointments</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Appointments Monitor</h2>
    <form method="GET" class="d-flex gap-2 mb-3">
        <select name="status" class="form-select" style="max-width:200px">
            <option value="">All Statuses</option>
            <?php foreach ($statuses as $s): ?>
            <option value="<?= $s ?>" <?= $filter_status === $s ? 'selected' : '' ?>><?= ucfirst($s) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit" class="btn btn-primary">Filter</button>
        <a href="manage_appointments.php" class="btn btn-outline-secondary">Reset</a>
    </form>
    <p class="text-muted"><?= count($appointments) ?> records</p>
    <table class="table table-bordered table-sm table-hover">
        <thead class="table-dark">
            <tr><th>Patient</th><th>Doctor</th><th>Specialization</th><th>Date</th><th>Time</th><th>Status</th><th>Booked At</th></tr>
        </thead>
        <tbody>
        <?php foreach ($appointments as $a): ?>
        <tr>
            <td><?= htmlspecialchars($a['patient_name']) ?></td>
            <td><?= htmlspecialchars($a['doctor_name']) ?></td>
            <td><?= htmlspecialchars($a['specialization_name']) ?></td>
            <td><?= htmlspecialchars($a['appointment_date']) ?></td>
            <td><?= substr($a['appointment_time'], 0, 5) ?></td>
            <td><span class="badge bg-<?= $badge[$a['status']] ?>"><?= ucfirst($a['status']) ?></span></td>
            <td><?= date('Y-m-d', strtotime($a['created_at'])) ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test filtering by status**

Filter "pending", "completed". Verify correct rows shown.

- [ ] **Step 3: Commit**

```bash
git add admin/manage_appointments.php
git commit -m "feat(admin): add appointment monitoring page with status filter"
```

---

## Task 6: Review Moderation

**Files:**
- Create: `admin/manage_reviews.php`

- [ ] **Step 1: Write admin/manage_reviews.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requireAdmin();

$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['remove_id'])) {
    $review_id = (int)$_POST['remove_id'];

    // Soft-delete: mark as removed
    $upd = $conn->prepare('UPDATE reviews SET status = "removed" WHERE review_id = ?');
    $upd->bind_param('i', $review_id);
    $upd->execute();

    // Recalculate the affected doctor's average rating
    $get_doc = $conn->prepare('SELECT doctor_id FROM reviews WHERE review_id = ?');
    $get_doc->bind_param('i', $review_id);
    $get_doc->execute();
    $get_doc->bind_result($affected_doctor_id);
    $get_doc->fetch();
    $get_doc->close();

    if ($affected_doctor_id) {
        $recalc = $conn->prepare(
            'UPDATE doctors SET average_rating = (SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE doctor_id = ? AND status = "active") WHERE doctor_id = ?'
        );
        $recalc->bind_param('ii', $affected_doctor_id, $affected_doctor_id);
        $recalc->execute();
    }

    $success = 'Review removed and doctor rating recalculated.';
}

$filter = $_GET['status'] ?? 'active';
$stmt = $conn->prepare(
    'SELECT r.review_id, up.name AS patient_name, ud.name AS doctor_name,
            r.rating, r.review_text, r.status, r.created_at
     FROM reviews r
     JOIN patients p ON p.patient_id = r.patient_id
     JOIN users up ON up.user_id = p.user_id
     JOIN doctors d ON d.doctor_id = r.doctor_id
     JOIN users ud ON ud.user_id = d.user_id
     WHERE r.status = ?
     ORDER BY r.created_at DESC'
);
$stmt->bind_param('s', $filter);
$stmt->execute();
$reviews = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Manage Reviews</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Review Moderation</h2>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <div class="mb-3">
        <a href="?status=active" class="btn btn-sm <?= $filter === 'active' ? 'btn-primary' : 'btn-outline-primary' ?>">Active</a>
        <a href="?status=removed" class="btn btn-sm <?= $filter === 'removed' ? 'btn-danger' : 'btn-outline-danger' ?> ms-1">Removed</a>
    </div>
    <p class="text-muted"><?= count($reviews) ?> review(s)</p>
    <?php foreach ($reviews as $r): ?>
    <div class="card mb-2">
        <div class="card-body">
            <div class="d-flex justify-content-between">
                <div>
                    <strong><?= htmlspecialchars($r['patient_name']) ?></strong> → Dr. <?= htmlspecialchars($r['doctor_name']) ?><br>
                    Rating: <?= $r['rating'] ?>/5 | <?= date('Y-m-d', strtotime($r['created_at'])) ?><br>
                    <?php if ($r['review_text']): ?>
                    <em>"<?= htmlspecialchars($r['review_text']) ?>"</em>
                    <?php endif; ?>
                </div>
                <?php if ($r['status'] === 'active'): ?>
                <form method="POST">
                    <input type="hidden" name="remove_id" value="<?= $r['review_id'] ?>">
                    <button class="btn btn-sm btn-danger" onclick="return confirm('Remove this review?')">Remove</button>
                </form>
                <?php else: ?>
                <span class="badge bg-secondary align-self-start">Removed</span>
                <?php endif; ?>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test review removal**

Submit a review as patient. Login as admin, remove it. Verify `status = removed` in DB and doctor's `average_rating` recalculated.

- [ ] **Step 3: Commit**

```bash
git add admin/manage_reviews.php
git commit -m "feat(admin): add review moderation with soft-delete and automatic rating recalculation"
```
