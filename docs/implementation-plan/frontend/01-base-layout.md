# Frontend: Base Layout & Public Pages — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the shared HTML structure (header, footer, CSS), and the public-facing home page. Every page in the system includes these files so consistency is maintained in one place.

**Architecture:** `includes/header.php` renders the `<head>`, Bootstrap nav, and role-aware menu. `includes/footer.php` closes the HTML. `assets/css/style.css` adds custom overrides. `index.php` is the public landing page.

**Prerequisites:** XAMPP running. Project folder at `C:\xampp\htdocs\doctors-recommendation-system\`.

**Tech Stack:** HTML5, Bootstrap 5.3 (CDN), CSS3, PHP

---

## File Map

| File | Purpose |
|---|---|
| `assets/css/style.css` | Custom CSS overrides on top of Bootstrap |
| `includes/header.php` | HTML head, Bootstrap navbar, role-aware nav links |
| `includes/footer.php` | Closing HTML, Bootstrap JS bundle |
| `index.php` | Public home/landing page |

---

## Task 1: Custom CSS

**Files:**
- Create: `assets/css/style.css`

- [ ] **Step 1: Write assets/css/style.css**

```css
/* Doctor Recommendation System — custom styles */

body {
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.navbar-brand {
    font-weight: 700;
    font-size: 1.3rem;
    color: #ffffff !important;
}

.hero-section {
    background: linear-gradient(135deg, #0d6efd 0%, #0a58ca 100%);
    color: #ffffff;
    padding: 80px 0 60px;
}

.hero-section h1 {
    font-size: 2.5rem;
    font-weight: 700;
}

.feature-card {
    border: none;
    border-radius: 12px;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
    transition: transform 0.2s ease;
}

.feature-card:hover {
    transform: translateY(-4px);
}

.feature-icon {
    font-size: 2.5rem;
    margin-bottom: 12px;
}

.card {
    border-radius: 10px;
    box-shadow: 0 1px 6px rgba(0, 0, 0, 0.07);
}

.badge {
    font-size: 0.78rem;
}

footer {
    background-color: #343a40;
    color: #adb5bd;
    padding: 20px 0;
    margin-top: 60px;
    font-size: 0.875rem;
}

footer a {
    color: #adb5bd;
    text-decoration: none;
}

footer a:hover {
    color: #ffffff;
}

.score-bar {
    height: 8px;
    border-radius: 4px;
    background: #dee2e6;
}

.score-fill {
    height: 8px;
    border-radius: 4px;
    background: linear-gradient(90deg, #0d6efd, #0a58ca);
}

/* Symptom checklist grid */
.symptom-check-label {
    font-size: 0.875rem;
    cursor: pointer;
}

@media (max-width: 576px) {
    .hero-section h1 {
        font-size: 1.8rem;
    }
}
```

- [ ] **Step 2: Verify file is in the right location**

Visit `http://localhost/doctors-recommendation-system/assets/css/style.css`.
Expected: CSS text is returned (no 404).

- [ ] **Step 3: Commit**

```bash
git add assets/css/style.css
git commit -m "feat(frontend): add custom CSS with hero, card, and symptom grid styles"
```

---

## Task 2: Header and Footer Includes

**Files:**
- Create: `includes/header.php`
- Create: `includes/footer.php`

- [ ] **Step 1: Write includes/header.php**

```php
<?php
// auth_check.php must already be included by the parent page before including header.php
$role = currentRole();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= isset($pageTitle) ? htmlspecialchars($pageTitle) . ' — DRS' : 'Doctors Recommendation System' ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="/doctors-recommendation-system/assets/css/style.css" rel="stylesheet">
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark bg-primary">
    <div class="container">
        <a class="navbar-brand" href="/doctors-recommendation-system/index.php">🏥 DRS</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMenu">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navMenu">
            <ul class="navbar-nav ms-auto">

                <?php if ($role === 'patient'): ?>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/patient/dashboard.php">Dashboard</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/patient/symptoms.php">Get Recommendation</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/patient/search.php">Search Doctors</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/patient/appointments.php">My Appointments</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/patient/recommendation_history.php">History</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/patient/profile.php">Profile</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/auth/logout.php">Logout</a></li>

                <?php elseif ($role === 'doctor'): ?>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/doctor/dashboard.php">Dashboard</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/doctor/appointments.php">Appointments</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/doctor/availability.php">Availability</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/doctor/profile.php">Profile</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/auth/logout.php">Logout</a></li>

                <?php elseif ($role === 'admin'): ?>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/admin/dashboard.php">Dashboard</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/admin/approve_doctors.php">Approvals</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/admin/manage_doctors.php">Doctors</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/admin/manage_patients.php">Patients</a></li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">Content</a>
                        <ul class="dropdown-menu">
                            <li><a class="dropdown-item" href="/doctors-recommendation-system/admin/manage_specializations.php">Specializations</a></li>
                            <li><a class="dropdown-item" href="/doctors-recommendation-system/admin/manage_symptoms.php">Symptoms</a></li>
                            <li><a class="dropdown-item" href="/doctors-recommendation-system/admin/manage_diseases.php">Diseases</a></li>
                        </ul>
                    </li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/admin/manage_appointments.php">Appointments</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/admin/manage_reviews.php">Reviews</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/auth/logout.php">Logout</a></li>

                <?php else: ?>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/auth/patient_login.php">Patient Login</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/auth/doctor_login.php">Doctor Login</a></li>
                    <li class="nav-item"><a class="nav-link" href="/doctors-recommendation-system/auth/patient_register.php">Register</a></li>
                <?php endif; ?>

            </ul>
        </div>
    </div>
</nav>
```

- [ ] **Step 2: Write includes/footer.php**

```php
<footer>
    <div class="container text-center">
        <p class="mb-1">Doctors Recommendation System &copy; <?= date('Y') ?></p>
        <p class="mb-0">BCA Final Year Project | XAMPP Local Environment</p>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

- [ ] **Step 3: Test header on patient dashboard**

Login as patient and visit dashboard. Expected: blue Bootstrap navbar with patient-specific links.

- [ ] **Step 4: Test nav as guest**

Visit `index.php` without logging in. Expected: navbar shows Patient Login, Doctor Login, Register links.

- [ ] **Step 5: Commit**

```bash
git add includes/header.php includes/footer.php
git commit -m "feat(frontend): add role-aware navbar header and footer includes"
```

---

## Task 3: Home / Landing Page

**Files:**
- Create: `index.php`

- [ ] **Step 1: Write index.php**

```php
<?php
require_once 'config/database.php';
require_once 'includes/auth_check.php';

// Redirect logged-in users to their dashboard
if (isLoggedIn()) {
    $dash = [
        'patient' => 'patient/dashboard.php',
        'doctor'  => 'doctor/dashboard.php',
        'admin'   => 'admin/dashboard.php',
    ];
    header('Location: ' . ($dash[currentRole()] ?? 'auth/patient_login.php'));
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Doctors Recommendation System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="assets/css/style.css" rel="stylesheet">
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark bg-primary">
    <div class="container">
        <a class="navbar-brand" href="index.php">🏥 DRS</a>
        <div class="collapse navbar-collapse">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="auth/patient_login.php">Patient Login</a></li>
                <li class="nav-item"><a class="nav-link" href="auth/doctor_login.php">Doctor Login</a></li>
                <li class="nav-item"><a class="nav-link btn btn-light text-primary ms-2 px-3" href="auth/patient_register.php">Register</a></li>
            </ul>
        </div>
    </div>
</nav>

<!-- Hero -->
<section class="hero-section text-center">
    <div class="container">
        <h1>Find the Right Doctor</h1>
        <p class="lead mt-3 mb-4">Enter your symptoms and let our AI-powered system recommend the best specialist for you.</p>
        <a href="auth/patient_register.php" class="btn btn-light btn-lg me-3">Get Started</a>
        <a href="auth/patient_login.php" class="btn btn-outline-light btn-lg">Login</a>
    </div>
</section>

<!-- How it works -->
<section class="py-5">
    <div class="container">
        <h2 class="text-center mb-4">How It Works</h2>
        <div class="row g-4">
            <div class="col-md-4">
                <div class="card feature-card text-center p-4">
                    <div class="feature-icon">🩺</div>
                    <h5>1. Enter Symptoms</h5>
                    <p class="text-muted">Select your current symptoms from our comprehensive symptom list.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card feature-card text-center p-4">
                    <div class="feature-icon">🤖</div>
                    <h5>2. AI Predicts</h5>
                    <p class="text-muted">Our machine learning model analyzes your symptoms and predicts the probable disease and required specialist.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card feature-card text-center p-4">
                    <div class="feature-icon">📅</div>
                    <h5>3. Book Appointment</h5>
                    <p class="text-muted">Choose from ranked doctor recommendations and book an appointment instantly.</p>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Features -->
<section class="py-4 bg-light">
    <div class="container">
        <h2 class="text-center mb-4">System Features</h2>
        <div class="row g-3">
            <div class="col-md-6">
                <ul class="list-group">
                    <li class="list-group-item">✅ Symptom-based doctor recommendation</li>
                    <li class="list-group-item">✅ Random Forest ML disease prediction</li>
                    <li class="list-group-item">✅ Weighted doctor ranking algorithm</li>
                </ul>
            </div>
            <div class="col-md-6">
                <ul class="list-group">
                    <li class="list-group-item">✅ Appointment booking and management</li>
                    <li class="list-group-item">✅ Patient ratings and reviews</li>
                    <li class="list-group-item">✅ Admin approval and monitoring</li>
                </ul>
            </div>
        </div>
    </div>
</section>

<!-- CTA for doctors -->
<section class="py-5 text-center">
    <div class="container">
        <h3>Are you a doctor?</h3>
        <p class="text-muted mb-3">Register your profile and start receiving patient appointments.</p>
        <a href="auth/doctor_register.php" class="btn btn-success btn-lg">Register as a Doctor</a>
    </div>
</section>

<?php include 'includes/footer.php'; ?>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

- [ ] **Step 2: Test home page**

Visit `http://localhost/doctors-recommendation-system/`.
Expected: Hero section, "How It Works" cards, feature list, doctor registration CTA.

- [ ] **Step 3: Test redirect for logged-in users**

Login as patient then visit `index.php`. Expected: redirected to `patient/dashboard.php`.

- [ ] **Step 4: Commit**

```bash
git add index.php
git commit -m "feat(frontend): add public home page with hero, how-it-works, and feature overview"
```
