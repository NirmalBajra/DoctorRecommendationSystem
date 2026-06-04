# Backend: Database Setup & Authentication — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the MySQL database schema, PHP database config, and complete authentication system for all three roles (Patient, Doctor, Admin) with secure sessions and role-based access control.

**Architecture:** Single `config/database.php` for the DB connection. `includes/auth_check.php` provides role-guard functions used at the top of every protected page. Passwords hashed with `password_hash(PASSWORD_BCRYPT)`. All queries use MySQLi prepared statements.

**Tech Stack:** PHP 8.x, MySQL 8.x, XAMPP (Apache + MySQL), MySQLi

---

## File Map

| File | Purpose |
|---|---|
| `database/schema.sql` | Full MySQL schema — run once to create all tables |
| `config/database.php` | DB connection singleton using MySQLi |
| `includes/auth_check.php` | `requirePatient()`, `requireDoctor()`, `requireAdmin()` guards |
| `includes/header.php` | Role-aware HTML nav included on every page |
| `includes/footer.php` | HTML footer included on every page |
| `auth/patient_register.php` | Patient registration form + handler |
| `auth/patient_login.php` | Patient login form + handler |
| `auth/doctor_register.php` | Doctor registration form + handler |
| `auth/doctor_login.php` | Doctor login form + handler |
| `auth/admin_login.php` | Admin login form + handler |
| `auth/logout.php` | Destroys session, redirects to home |
| `index.php` | Public home/landing page |

---

## Task 1: Create MySQL Database Schema

**Files:**
- Create: `database/schema.sql`

- [ ] **Step 1: Write the full schema**

```sql
CREATE DATABASE IF NOT EXISTS doctors_recommendation_system
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE doctors_recommendation_system;

CREATE TABLE users (
    user_id     INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    email       VARCHAR(150)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role        ENUM('patient','doctor','admin') NOT NULL,
    status      ENUM('active','inactive','pending','rejected') NOT NULL DEFAULT 'active',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE patients (
    patient_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    gender         VARCHAR(20),
    age            INT,
    contact_number VARCHAR(20),
    city           VARCHAR(100),
    area           VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE specializations (
    specialization_id   INT AUTO_INCREMENT PRIMARY KEY,
    specialization_name VARCHAR(100) NOT NULL,
    description         TEXT
);

CREATE TABLE doctors (
    doctor_id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id           INT NOT NULL,
    specialization_id INT,
    qualification     VARCHAR(150),
    experience_years  INT DEFAULT 0,
    consultation_fee  DECIMAL(10,2) DEFAULT 0.00,
    clinic_name       VARCHAR(150),
    license_number    VARCHAR(100),
    contact_number    VARCHAR(20),
    city              VARCHAR(100),
    area              VARCHAR(100),
    average_rating    DECIMAL(3,2) DEFAULT 0.00,
    approval_status   ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id)
);

CREATE TABLE symptoms (
    symptom_id   INT AUTO_INCREMENT PRIMARY KEY,
    symptom_name VARCHAR(100) NOT NULL,
    description  TEXT
);

CREATE TABLE diseases (
    disease_id   INT AUTO_INCREMENT PRIMARY KEY,
    disease_name VARCHAR(100) NOT NULL,
    description  TEXT
);

CREATE TABLE disease_specialization_map (
    map_id            INT AUTO_INCREMENT PRIMARY KEY,
    disease_id        INT NOT NULL,
    specialization_id INT NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE CASCADE
);

CREATE TABLE doctor_availability (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id       INT NOT NULL,
    available_day   ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    slot_status     ENUM('available','booked','inactive') NOT NULL DEFAULT 'available',
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

CREATE TABLE appointments (
    appointment_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT NOT NULL,
    doctor_id        INT NOT NULL,
    availability_id  INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status           ENUM('pending','approved','rejected','completed','cancelled') NOT NULL DEFAULT 'pending',
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id)      REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)       REFERENCES doctors(doctor_id),
    FOREIGN KEY (availability_id) REFERENCES doctor_availability(availability_id)
);

CREATE TABLE reviews (
    review_id      INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    patient_id     INT NOT NULL,
    doctor_id      INT NOT NULL,
    rating         TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text    TEXT,
    status         ENUM('active','removed') NOT NULL DEFAULT 'active',
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    FOREIGN KEY (patient_id)     REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)      REFERENCES doctors(doctor_id)
);

CREATE TABLE recommendations (
    recommendation_id        INT AUTO_INCREMENT PRIMARY KEY,
    patient_id               INT NOT NULL,
    symptoms_input           TEXT NOT NULL,
    predicted_disease        VARCHAR(100),
    predicted_specialization_id INT,
    recommended_doctors      JSON,
    confidence_score         DECIMAL(5,4),
    created_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id)                REFERENCES patients(patient_id),
    FOREIGN KEY (predicted_specialization_id) REFERENCES specializations(specialization_id)
);

-- Default admin account (password: admin123 — change immediately after setup)
INSERT INTO users (name, email, password_hash, role, status)
VALUES ('Admin', 'admin@drs.local',
        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'active');
```

- [ ] **Step 2: Run the schema in phpMyAdmin**

1. Open `http://localhost/phpmyadmin`
2. Click "SQL" tab
3. Paste the schema above and click "Go"

Expected: Database `doctors_recommendation_system` created with all 11 tables.

- [ ] **Step 3: Verify tables exist**

In phpMyAdmin → select the database → you should see: `users`, `patients`, `doctors`, `specializations`, `symptoms`, `diseases`, `disease_specialization_map`, `doctor_availability`, `appointments`, `reviews`, `recommendations`.

- [ ] **Step 4: Commit**

```bash
git add database/schema.sql
git commit -m "feat(db): create full MySQL schema for all 11 tables"
```

---

## Task 2: PHP Database Config

**Files:**
- Create: `config/database.php`

- [ ] **Step 1: Write database.php**

```php
<?php

define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'doctors_recommendation_system');

$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['error' => 'Database connection failed']));
}

$conn->set_charset('utf8mb4');
```

- [ ] **Step 2: Test connection**

Create a temporary `test_db.php` in the project root:

```php
<?php
require_once 'config/database.php';
echo $conn->query("SELECT 1")->fetch_row()[0] === 1 ? "DB OK" : "FAIL";
```

Visit `http://localhost/doctors-recommendation-system/test_db.php`.
Expected: `DB OK`

Delete `test_db.php` after verifying.

- [ ] **Step 3: Commit**

```bash
git add config/database.php
git commit -m "feat(backend): add MySQL connection config"
```

---

## Task 3: Auth Helpers and Session Guards

**Files:**
- Create: `includes/auth_check.php`

- [ ] **Step 1: Write auth_check.php**

```php
<?php

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function requirePatient(): void {
    if (empty($_SESSION['user_id']) || $_SESSION['role'] !== 'patient') {
        header('Location: /doctors-recommendation-system/auth/patient_login.php');
        exit;
    }
}

function requireDoctor(): void {
    if (empty($_SESSION['user_id']) || $_SESSION['role'] !== 'doctor') {
        header('Location: /doctors-recommendation-system/auth/doctor_login.php');
        exit;
    }
}

function requireAdmin(): void {
    if (empty($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') {
        header('Location: /doctors-recommendation-system/auth/admin_login.php');
        exit;
    }
}

function isLoggedIn(): bool {
    return !empty($_SESSION['user_id']);
}

function currentUserId(): int {
    return (int)($_SESSION['user_id'] ?? 0);
}

function currentRole(): string {
    return $_SESSION['role'] ?? '';
}
```

- [ ] **Step 2: Verify by visiting a protected page that uses requirePatient()**

Create `patient/dashboard.php` temporarily with just:
```php
<?php
require_once '../includes/auth_check.php';
requirePatient();
echo "Patient dashboard";
```

Visit `http://localhost/doctors-recommendation-system/patient/dashboard.php` without logging in.
Expected: Redirected to `auth/patient_login.php`.

- [ ] **Step 3: Commit**

```bash
git add includes/auth_check.php
git commit -m "feat(backend): add session guards for patient, doctor, admin roles"
```

---

## Task 4: Patient Registration

**Files:**
- Create: `auth/patient_register.php`

- [ ] **Step 1: Write patient_register.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';

if (isLoggedIn()) {
    header('Location: ../patient/dashboard.php');
    exit;
}

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name     = trim($_POST['name'] ?? '');
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $gender   = $_POST['gender'] ?? '';
    $age      = (int)($_POST['age'] ?? 0);
    $contact  = trim($_POST['contact_number'] ?? '');
    $city     = trim($_POST['city'] ?? '');
    $area     = trim($_POST['area'] ?? '');

    if (!$name || !$email || !$password || !$gender || $age <= 0) {
        $error = 'All required fields must be filled.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = 'Invalid email address.';
    } elseif (strlen($password) < 6) {
        $error = 'Password must be at least 6 characters.';
    } else {
        // Check duplicate email
        $stmt = $conn->prepare('SELECT user_id FROM users WHERE email = ?');
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            $error = 'Email address is already registered.';
        } else {
            $hash = password_hash($password, PASSWORD_BCRYPT);

            $conn->begin_transaction();
            try {
                $stmt2 = $conn->prepare(
                    'INSERT INTO users (name, email, password_hash, role, status) VALUES (?, ?, ?, "patient", "active")'
                );
                $stmt2->bind_param('sss', $name, $email, $hash);
                $stmt2->execute();
                $user_id = $conn->insert_id;

                $stmt3 = $conn->prepare(
                    'INSERT INTO patients (user_id, gender, age, contact_number, city, area) VALUES (?, ?, ?, ?, ?, ?)'
                );
                $stmt3->bind_param('isssss', $user_id, $gender, $age, $contact, $city, $area);
                $stmt3->execute();

                $conn->commit();
                $success = 'Registration successful. You can now log in.';
            } catch (Exception $e) {
                $conn->rollback();
                $error = 'Registration failed. Please try again.';
            }
        }
        $stmt->close();
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Patient Registration</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-5" style="max-width:520px">
    <h2 class="mb-4">Patient Registration</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Full Name *</label>
            <input type="text" name="name" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Email *</label>
            <input type="email" name="email" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Password *</label>
            <input type="password" name="password" class="form-control" required minlength="6"></div>
        <div class="mb-3"><label class="form-label">Gender *</label>
            <select name="gender" class="form-select" required>
                <option value="">Select</option>
                <option>Male</option><option>Female</option><option>Other</option>
            </select></div>
        <div class="mb-3"><label class="form-label">Age *</label>
            <input type="number" name="age" class="form-control" min="1" max="120" required></div>
        <div class="mb-3"><label class="form-label">Contact Number</label>
            <input type="text" name="contact_number" class="form-control"></div>
        <div class="mb-3"><label class="form-label">City</label>
            <input type="text" name="city" class="form-control"></div>
        <div class="mb-3"><label class="form-label">Area</label>
            <input type="text" name="area" class="form-control"></div>
        <button type="submit" class="btn btn-primary w-100">Register</button>
    </form>
    <p class="mt-3 text-center">Already registered? <a href="patient_login.php">Login</a></p>
</div>
</body>
</html>
```

- [ ] **Step 2: Test registration**

Visit `http://localhost/doctors-recommendation-system/auth/patient_register.php`.
Fill the form and submit. Check phpMyAdmin → `users` and `patients` tables for a new row.

- [ ] **Step 3: Test duplicate email**

Submit the same email again. Expected: error "Email address is already registered."

- [ ] **Step 4: Commit**

```bash
git add auth/patient_register.php
git commit -m "feat(auth): add patient registration with email duplicate check and bcrypt hashing"
```

---

## Task 5: Patient Login

**Files:**
- Create: `auth/patient_login.php`

- [ ] **Step 1: Write patient_login.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';

if (isLoggedIn() && currentRole() === 'patient') {
    header('Location: ../patient/dashboard.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if (!$email || !$password) {
        $error = 'Email and password are required.';
    } else {
        $stmt = $conn->prepare(
            'SELECT u.user_id, u.password_hash, u.status, p.patient_id
             FROM users u
             JOIN patients p ON p.user_id = u.user_id
             WHERE u.email = ? AND u.role = "patient"'
        );
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $stmt->bind_result($user_id, $hash, $status, $patient_id);
        $stmt->fetch();
        $stmt->close();

        if (!$user_id) {
            $error = 'Invalid email or password.';
        } elseif ($status !== 'active') {
            $error = 'Your account is inactive. Contact admin.';
        } elseif (!password_verify($password, $hash)) {
            $error = 'Invalid email or password.';
        } else {
            session_regenerate_id(true);
            $_SESSION['user_id']    = $user_id;
            $_SESSION['patient_id'] = $patient_id;
            $_SESSION['role']       = 'patient';
            header('Location: ../patient/dashboard.php');
            exit;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Patient Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-5" style="max-width:420px">
    <h2 class="mb-4">Patient Login</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Email</label>
            <input type="email" name="email" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Password</label>
            <input type="password" name="password" class="form-control" required></div>
        <button type="submit" class="btn btn-primary w-100">Login</button>
    </form>
    <p class="mt-3 text-center">New patient? <a href="patient_register.php">Register</a></p>
</div>
</body>
</html>
```

- [ ] **Step 2: Test login with valid credentials**

Expected: Redirected to `patient/dashboard.php`.

- [ ] **Step 3: Test login with wrong password**

Expected: Error "Invalid email or password."

- [ ] **Step 4: Commit**

```bash
git add auth/patient_login.php
git commit -m "feat(auth): add patient login with session creation and regeneration"
```

---

## Task 6: Doctor Registration and Login

**Files:**
- Create: `auth/doctor_register.php`
- Create: `auth/doctor_login.php`

- [ ] **Step 1: Write doctor_register.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';

$error = '';
$success = '';

// Load specializations for dropdown
$specializations = [];
$res = $conn->query('SELECT specialization_id, specialization_name FROM specializations ORDER BY specialization_name');
while ($row = $res->fetch_assoc()) {
    $specializations[] = $row;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name      = trim($_POST['name'] ?? '');
    $email     = trim($_POST['email'] ?? '');
    $password  = $_POST['password'] ?? '';
    $spec_id   = (int)($_POST['specialization_id'] ?? 0);
    $qual      = trim($_POST['qualification'] ?? '');
    $exp       = (int)($_POST['experience_years'] ?? 0);
    $fee       = (float)($_POST['consultation_fee'] ?? 0);
    $clinic    = trim($_POST['clinic_name'] ?? '');
    $license   = trim($_POST['license_number'] ?? '');
    $contact   = trim($_POST['contact_number'] ?? '');
    $city      = trim($_POST['city'] ?? '');
    $area      = trim($_POST['area'] ?? '');

    if (!$name || !$email || !$password || !$spec_id) {
        $error = 'Name, email, password, and specialization are required.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = 'Invalid email address.';
    } else {
        $chk = $conn->prepare('SELECT user_id FROM users WHERE email = ?');
        $chk->bind_param('s', $email);
        $chk->execute();
        $chk->store_result();

        if ($chk->num_rows > 0) {
            $error = 'Email already registered.';
        } else {
            $hash = password_hash($password, PASSWORD_BCRYPT);
            $conn->begin_transaction();
            try {
                $s1 = $conn->prepare('INSERT INTO users (name, email, password_hash, role, status) VALUES (?, ?, ?, "doctor", "pending")');
                $s1->bind_param('sss', $name, $email, $hash);
                $s1->execute();
                $uid = $conn->insert_id;

                $s2 = $conn->prepare('INSERT INTO doctors (user_id, specialization_id, qualification, experience_years, consultation_fee, clinic_name, license_number, contact_number, city, area) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
                $s2->bind_param('iisidssss', $uid, $spec_id, $qual, $exp, $fee, $clinic, $license, $contact, $city, $area);
                // Note: 'i' for spec_id, 'i' for uid, 's' qual, 'i' exp, 'd' fee, 's' clinic, 's' license, 's' contact, 's' city, 's' area
                $s2->execute();
                $conn->commit();
                $success = 'Registration submitted. Please wait for admin approval.';
            } catch (Exception $e) {
                $conn->rollback();
                $error = 'Registration failed. Please try again.';
            }
        }
        $chk->close();
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Doctor Registration</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-5" style="max-width:560px">
    <h2 class="mb-4">Doctor Registration</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Full Name *</label><input type="text" name="name" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Email *</label><input type="email" name="email" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Password *</label><input type="password" name="password" class="form-control" required minlength="6"></div>
        <div class="mb-3"><label class="form-label">Specialization *</label>
            <select name="specialization_id" class="form-select" required>
                <option value="">Select Specialization</option>
                <?php foreach ($specializations as $s): ?>
                <option value="<?= $s['specialization_id'] ?>"><?= htmlspecialchars($s['specialization_name']) ?></option>
                <?php endforeach; ?>
            </select></div>
        <div class="mb-3"><label class="form-label">Qualification</label><input type="text" name="qualification" class="form-control"></div>
        <div class="mb-3"><label class="form-label">Experience (years)</label><input type="number" name="experience_years" class="form-control" min="0"></div>
        <div class="mb-3"><label class="form-label">Consultation Fee (NPR)</label><input type="number" name="consultation_fee" class="form-control" min="0" step="0.01"></div>
        <div class="mb-3"><label class="form-label">Clinic/Hospital Name</label><input type="text" name="clinic_name" class="form-control"></div>
        <div class="mb-3"><label class="form-label">License/Registration Number</label><input type="text" name="license_number" class="form-control"></div>
        <div class="mb-3"><label class="form-label">Contact Number</label><input type="text" name="contact_number" class="form-control"></div>
        <div class="mb-3"><label class="form-label">City</label><input type="text" name="city" class="form-control"></div>
        <div class="mb-3"><label class="form-label">Area</label><input type="text" name="area" class="form-control"></div>
        <button type="submit" class="btn btn-primary w-100">Submit Registration</button>
    </form>
    <p class="mt-3 text-center">Already approved? <a href="doctor_login.php">Login</a></p>
</div>
</body>
</html>
```

- [ ] **Step 2: Write doctor_login.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if (!$email || !$password) {
        $error = 'Email and password are required.';
    } else {
        $stmt = $conn->prepare(
            'SELECT u.user_id, u.password_hash, u.status, d.doctor_id, d.approval_status
             FROM users u
             JOIN doctors d ON d.user_id = u.user_id
             WHERE u.email = ? AND u.role = "doctor"'
        );
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $stmt->bind_result($user_id, $hash, $status, $doctor_id, $approval);
        $stmt->fetch();
        $stmt->close();

        if (!$user_id || !password_verify($password, $hash)) {
            $error = 'Invalid email or password.';
        } elseif ($approval === 'pending') {
            $error = 'Your registration is pending admin approval.';
        } elseif ($approval === 'rejected') {
            $error = 'Your registration has been rejected. Contact admin.';
        } elseif ($status !== 'active') {
            $error = 'Your account is inactive. Contact admin.';
        } else {
            session_regenerate_id(true);
            $_SESSION['user_id']   = $user_id;
            $_SESSION['doctor_id'] = $doctor_id;
            $_SESSION['role']      = 'doctor';
            header('Location: ../doctor/dashboard.php');
            exit;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Doctor Login</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-5" style="max-width:420px">
    <h2 class="mb-4">Doctor Login</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Email</label><input type="email" name="email" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Password</label><input type="password" name="password" class="form-control" required></div>
        <button type="submit" class="btn btn-success w-100">Login</button>
    </form>
    <p class="mt-3 text-center">New doctor? <a href="doctor_register.php">Register</a></p>
</div>
</body>
</html>
```

- [ ] **Step 3: Test doctor registration with a pending status**

Register a doctor, check phpMyAdmin → `users` table: `status = pending`, `doctors` table: `approval_status = pending`.
Try logging in: Expected error "pending admin approval."

- [ ] **Step 4: Commit**

```bash
git add auth/doctor_register.php auth/doctor_login.php
git commit -m "feat(auth): add doctor registration (pending approval) and login with status checks"
```

---

## Task 7: Admin Login and Logout

**Files:**
- Create: `auth/admin_login.php`
- Create: `auth/logout.php`

- [ ] **Step 1: Write admin_login.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if (!$email || !$password) {
        $error = 'Email and password are required.';
    } else {
        $stmt = $conn->prepare('SELECT user_id, password_hash, status FROM users WHERE email = ? AND role = "admin"');
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $stmt->bind_result($user_id, $hash, $status);
        $stmt->fetch();
        $stmt->close();

        if (!$user_id || !password_verify($password, $hash)) {
            $error = 'Invalid credentials.';
        } elseif ($status !== 'active') {
            $error = 'Admin account is inactive.';
        } else {
            session_regenerate_id(true);
            $_SESSION['user_id'] = $user_id;
            $_SESSION['role']    = 'admin';
            header('Location: ../admin/dashboard.php');
            exit;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Admin Login</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-5" style="max-width:420px">
    <h2 class="mb-4">Admin Login</h2>
    <?php if ($error): ?><div class="alert alert-danger"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <form method="POST">
        <div class="mb-3"><label class="form-label">Email</label><input type="email" name="email" class="form-control" required></div>
        <div class="mb-3"><label class="form-label">Password</label><input type="password" name="password" class="form-control" required></div>
        <button type="submit" class="btn btn-danger w-100">Admin Login</button>
    </form>
</div>
</body>
</html>
```

- [ ] **Step 2: Write logout.php**

```php
<?php
require_once '../includes/auth_check.php';
session_unset();
session_destroy();
header('Location: /doctors-recommendation-system/index.php');
exit;
```

- [ ] **Step 3: Test admin login**

Default admin: `admin@drs.local` / `password` (the hash in schema.sql is for `password`).

> Change this password after first login. In phpMyAdmin run:
> ```sql
> UPDATE users SET password_hash = '$2y$10$<your_hash>' WHERE role = 'admin';
> ```

- [ ] **Step 4: Test logout**

After logging in as any role, visit `auth/logout.php`. Expected: session destroyed, redirected to home.

- [ ] **Step 5: Commit**

```bash
git add auth/admin_login.php auth/logout.php
git commit -m "feat(auth): add admin login and logout"
```
