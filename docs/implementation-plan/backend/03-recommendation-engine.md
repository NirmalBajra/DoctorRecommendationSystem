# Backend: Recommendation Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire PHP to the Python ML model, look up the mapped specialization, rank matching doctors using the weighted utility function, display results, and persist the recommendation record.

**Architecture:** `patient/recommendations.php` receives symptom POST, calls Python via `shell_exec`, maps predicted disease → specialization in MySQL, fetches candidate doctors, computes weighted scores in PHP, renders ranked results, and saves a record to the `recommendations` table.

**Prerequisites:** `01-database-and-auth.md` and `02-patient-module.md` complete. Python `ml/predict.py` and `ml/model.pkl` exist (from `python/01-ml-pipeline.md`).

**Tech Stack:** PHP 8.x, MySQLi, Python via `shell_exec`

---

## File Map

| File | Purpose |
|---|---|
| `patient/recommendations.php` | Receives symptoms POST, calls ML, ranks doctors, renders results, saves record |
| `includes/ranking.php` | Pure-PHP weighted scoring function — imported by recommendations.php |
| `patient/search.php` | Manual doctor search + filter page (no ML, uses ranking for display order) |

---

## Task 1: PHP Ranking Function

**Files:**
- Create: `includes/ranking.php`

This file contains only the ranking logic — no HTML, no DB queries.

- [ ] **Step 1: Write includes/ranking.php**

```php
<?php

/**
 * Rank an array of doctor rows using the additive weighted utility function.
 *
 * Each $doctor row must contain:
 *   doctor_id, name, specialization_name, average_rating,
 *   experience_years, consultation_fee, city, area,
 *   has_availability (bool/int), predicted_spec_id, doctor_spec_id
 *
 * $patientCity and $patientArea are the patient's location strings.
 * $predictedSpecId is the specialization_id returned by the ML model.
 *
 * Returns the same array sorted descending by final_score.
 */
function rankDoctors(array $doctors, string $patientCity, string $patientArea, int $predictedSpecId): array
{
    if (empty($doctors)) {
        return [];
    }

    $fees = array_column($doctors, 'consultation_fee');
    $minFee = min($fees);
    $maxFee = max($fees);

    foreach ($doctors as &$doc) {
        // 1. Specialization match score
        if ((int)$doc['doctor_spec_id'] === $predictedSpecId) {
            $specScore = 100;
        } else {
            $specScore = 0;
        }

        // 2. Rating score  (0–5 scale → 0–100)
        $ratingScore = ((float)$doc['average_rating'] / 5.0) * 100;

        // 3. Experience score (capped at 20 years = 100)
        $expScore = min(((int)$doc['experience_years'] / 20.0) * 100, 100);

        // 4. Availability score
        $availScore = $doc['has_availability'] ? 100 : 60;

        // 5. Location score
        $docCity = strtolower(trim($doc['city']));
        $docArea = strtolower(trim($doc['area']));
        $pCity   = strtolower(trim($patientCity));
        $pArea   = strtolower(trim($patientArea));

        if ($docArea === $pArea && $docCity === $pCity) {
            $locationScore = 100;
        } elseif ($docCity === $pCity) {
            $locationScore = 70;
        } else {
            $locationScore = 30;
        }

        // 6. Fee score (lower fee = higher score)
        if ($maxFee === $minFee) {
            $feeScore = 100;
        } else {
            $feeScore = 100 - (((float)$doc['consultation_fee'] - $minFee) / ($maxFee - $minFee)) * 100;
        }

        $doc['final_score'] = round(
            ($specScore    * 0.35) +
            ($ratingScore  * 0.20) +
            ($expScore     * 0.15) +
            ($availScore   * 0.10) +
            ($locationScore * 0.10) +
            ($feeScore     * 0.10),
            2
        );

        // Store components for display
        $doc['score_breakdown'] = [
            'specialization' => round($specScore, 1),
            'rating'         => round($ratingScore, 1),
            'experience'     => round($expScore, 1),
            'availability'   => round($availScore, 1),
            'location'       => round($locationScore, 1),
            'fee'            => round($feeScore, 1),
        ];
    }
    unset($doc);

    usort($doctors, function (array $a, array $b): int {
        // Primary: final_score descending
        if ($b['final_score'] !== $a['final_score']) {
            return $b['final_score'] <=> $a['final_score'];
        }
        // Tie-break 1: rating
        if ($b['average_rating'] !== $a['average_rating']) {
            return $b['average_rating'] <=> $a['average_rating'];
        }
        // Tie-break 2: experience
        return $b['experience_years'] <=> $a['experience_years'];
    });

    return $doctors;
}
```

- [ ] **Step 2: Verify function loads without errors**

```php
<?php
require_once 'includes/ranking.php';
$result = rankDoctors([], '', '', 0);
var_dump($result); // Should print array(0) {}
```

- [ ] **Step 3: Commit**

```bash
git add includes/ranking.php
git commit -m "feat(engine): add weighted utility ranking function with tie-breaking"
```

---

## Task 2: ML Integration and Recommendation Page

**Files:**
- Create: `patient/recommendations.php`

- [ ] **Step 1: Write patient/recommendations.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_once '../includes/ranking.php';
requirePatient();

$patient_id = (int)$_SESSION['patient_id'];
$user_id    = currentUserId();

// Only accept POST from symptoms.php
if ($_SERVER['REQUEST_METHOD'] !== 'POST' || empty($_POST['symptoms'])) {
    header('Location: symptoms.php');
    exit;
}

$selected_symptoms = array_map('trim', (array)$_POST['symptoms']);
$selected_symptoms = array_filter($selected_symptoms); // remove empties

if (empty($selected_symptoms)) {
    header('Location: symptoms.php');
    exit;
}

// ── Step 1: Call Python prediction ──────────────────────────────────────────
$symptoms_str = implode(',', $selected_symptoms);
$escaped      = escapeshellarg($symptoms_str);
$ml_root      = realpath(__DIR__ . '/../ml');
$output       = shell_exec("python \"{$ml_root}/predict.py\" {$escaped} 2>&1");
$prediction   = json_decode($output, true);

$predicted_disease = 'Unknown';
$recommended_spec  = 'General Physician';
$confidence        = 0.0;
$low_confidence    = true;

if ($prediction && empty($prediction['error'])) {
    $predicted_disease = $prediction['predicted_disease'];
    $recommended_spec  = $prediction['recommended_specialization'];
    $confidence        = (float)$prediction['confidence'];
    $low_confidence    = (bool)$prediction['low_confidence'];
}

// ── Step 2: Find matching specialization_id in DB ───────────────────────────
$spec_stmt = $conn->prepare('SELECT specialization_id FROM specializations WHERE specialization_name = ?');
$spec_stmt->bind_param('s', $recommended_spec);
$spec_stmt->execute();
$spec_stmt->bind_result($predicted_spec_id);
$spec_stmt->fetch();
$spec_stmt->close();

if (!$predicted_spec_id) {
    // Fallback: try General Physician
    $gen = $conn->prepare('SELECT specialization_id FROM specializations WHERE specialization_name = "General Physician"');
    $gen->execute();
    $gen->bind_result($predicted_spec_id);
    $gen->fetch();
    $gen->close();
}

// ── Step 3: Get patient location ─────────────────────────────────────────────
$loc = $conn->prepare('SELECT city, area FROM patients WHERE patient_id = ?');
$loc->bind_param('i', $patient_id);
$loc->execute();
$loc->bind_result($patient_city, $patient_area);
$loc->fetch();
$loc->close();

// ── Step 4: Fetch candidate doctors ──────────────────────────────────────────
$doc_stmt = $conn->prepare(
    'SELECT d.doctor_id, u.name, s.specialization_name, s.specialization_id AS doctor_spec_id,
            d.qualification, d.experience_years, d.consultation_fee,
            d.clinic_name, d.city, d.area, d.average_rating,
            (SELECT COUNT(*) FROM doctor_availability da
             WHERE da.doctor_id = d.doctor_id AND da.slot_status = "available") AS has_availability
     FROM doctors d
     JOIN users u ON u.user_id = d.user_id
     JOIN specializations s ON s.specialization_id = d.specialization_id
     WHERE d.approval_status = "approved"
     ORDER BY d.average_rating DESC'
);
$doc_stmt->execute();
$raw_doctors = $doc_stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$doc_stmt->close();

// ── Step 5: Rank doctors ──────────────────────────────────────────────────────
$ranked_doctors = rankDoctors($raw_doctors, (string)$patient_city, (string)$patient_area, (int)$predicted_spec_id);

// ── Step 6: Save recommendation record ───────────────────────────────────────
$doctors_json = json_encode(array_map(fn($d) => [
    'doctor_id' => $d['doctor_id'],
    'name'      => $d['name'],
    'score'     => $d['final_score'],
], array_slice($ranked_doctors, 0, 10)));

$save = $conn->prepare(
    'INSERT INTO recommendations (patient_id, symptoms_input, predicted_disease, predicted_specialization_id, recommended_doctors, confidence_score)
     VALUES (?, ?, ?, ?, ?, ?)'
);
$save->bind_param('issisd', $patient_id, $symptoms_str, $predicted_disease, $predicted_spec_id, $doctors_json, $confidence);
$save->execute();
$save->close();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Recommendation Results</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Recommendation Results</h2>

    <?php if ($low_confidence): ?>
    <div class="alert alert-warning">
        <strong>Low confidence prediction</strong> — the symptom combination was ambiguous.
        Showing General Physician doctors. Please consult a doctor for an accurate diagnosis.
    </div>
    <?php endif; ?>

    <div class="card mb-4 p-3">
        <strong>Symptoms entered:</strong> <?= htmlspecialchars(implode(', ', $selected_symptoms)) ?><br>
        <strong>Predicted disease:</strong> <?= htmlspecialchars($predicted_disease) ?><br>
        <strong>Recommended specialization:</strong> <?= htmlspecialchars($recommended_spec) ?><br>
        <strong>Confidence:</strong> <?= number_format($confidence * 100, 1) ?>%
    </div>

    <?php if (empty($ranked_doctors)): ?>
        <div class="alert alert-info">No doctors available for this specialization. Try searching manually.</div>
    <?php else: ?>
    <div class="row g-3">
    <?php foreach ($ranked_doctors as $i => $doc): ?>
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <h5 class="card-title"><?= htmlspecialchars($doc['name']) ?></h5>
                        <span class="badge bg-<?= $i === 0 ? 'warning text-dark' : 'secondary' ?>">
                            Score: <?= $doc['final_score'] ?>
                        </span>
                    </div>
                    <p class="card-text mb-1"><?= htmlspecialchars($doc['specialization_name']) ?></p>
                    <p class="card-text mb-1">
                        ⭐ <?= number_format($doc['average_rating'], 1) ?> |
                        <?= (int)$doc['experience_years'] ?> yrs exp |
                        NPR <?= number_format($doc['consultation_fee'], 0) ?>
                    </p>
                    <p class="card-text mb-1 text-muted small">
                        <?= htmlspecialchars($doc['clinic_name']) ?>,
                        <?= htmlspecialchars($doc['area']) ?>, <?= htmlspecialchars($doc['city']) ?>
                    </p>
                    <p class="card-text mb-2">
                        <?php if ($doc['has_availability']): ?>
                            <span class="badge bg-success">Available</span>
                        <?php else: ?>
                            <span class="badge bg-secondary">Limited availability</span>
                        <?php endif; ?>
                    </p>
                    <a href="book_appointment.php?doctor_id=<?= $doc['doctor_id'] ?>" class="btn btn-sm btn-primary">Book Appointment</a>
                </div>
            </div>
        </div>
    <?php endforeach; ?>
    </div>
    <?php endif; ?>

    <div class="mt-3">
        <a href="symptoms.php" class="btn btn-outline-secondary">Try Different Symptoms</a>
        <a href="search.php" class="btn btn-outline-secondary ms-2">Search Manually</a>
    </div>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test end-to-end**

1. Ensure Python ML model is trained and `ml/predict.py` works from command line.
2. Login as patient → go to symptoms page → select some symptoms → submit.
3. Expected: Recommendation page loads with predicted disease, confidence, and ranked doctor cards.
4. Check phpMyAdmin → `recommendations` table has a new row.

- [ ] **Step 3: Test with no doctors in DB**

Expected: "No doctors available" message. No crash.

- [ ] **Step 4: Test with Python not available**

Rename `ml/model.pkl` temporarily. Expected: `$prediction` is null, system falls back to General Physician specialization and still renders (with 0% confidence).

- [ ] **Step 5: Commit**

```bash
git add patient/recommendations.php includes/ranking.php
git commit -m "feat(engine): add recommendation page — ML prediction, ranking, result display, history save"
```

---

## Task 3: Manual Doctor Search

**Files:**
- Create: `patient/search.php`

- [ ] **Step 1: Write patient/search.php**

```php
<?php
require_once '../config/database.php';
require_once '../includes/auth_check.php';
requirePatient();

$patient_id = (int)$_SESSION['patient_id'];

// Load filter options
$specs = $conn->query('SELECT specialization_id, specialization_name FROM specializations ORDER BY specialization_name')->fetch_all(MYSQLI_ASSOC);

// Build query based on filters
$filter_spec  = (int)($_GET['specialization_id'] ?? 0);
$filter_city  = trim($_GET['city'] ?? '');
$filter_min_r = (float)($_GET['min_rating'] ?? 0);
$filter_max_f = (float)($_GET['max_fee'] ?? 0);

$where = ['d.approval_status = "approved"'];
$params = [];
$types  = '';

if ($filter_spec) {
    $where[] = 'd.specialization_id = ?';
    $params[] = $filter_spec;
    $types .= 'i';
}
if ($filter_city) {
    $where[] = 'd.city LIKE ?';
    $params[] = '%' . $filter_city . '%';
    $types .= 's';
}
if ($filter_min_r > 0) {
    $where[] = 'd.average_rating >= ?';
    $params[] = $filter_min_r;
    $types .= 'd';
}
if ($filter_max_f > 0) {
    $where[] = 'd.consultation_fee <= ?';
    $params[] = $filter_max_f;
    $types .= 'd';
}

$sql = 'SELECT d.doctor_id, u.name, s.specialization_name, d.qualification,
               d.experience_years, d.consultation_fee, d.clinic_name,
               d.city, d.area, d.average_rating,
               (SELECT COUNT(*) FROM doctor_availability da WHERE da.doctor_id = d.doctor_id AND da.slot_status = "available") AS has_availability
        FROM doctors d
        JOIN users u ON u.user_id = d.user_id
        JOIN specializations s ON s.specialization_id = d.specialization_id
        WHERE ' . implode(' AND ', $where) . '
        ORDER BY d.average_rating DESC, d.experience_years DESC';

$stmt = $conn->prepare($sql);
if ($types && $params) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$doctors = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Search Doctors</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<?php include '../includes/header.php'; ?>
<div class="container py-4">
    <h2>Search Doctors</h2>
    <form method="GET" class="row g-2 mb-4">
        <div class="col-md-3">
            <select name="specialization_id" class="form-select">
                <option value="">All Specializations</option>
                <?php foreach ($specs as $s): ?>
                <option value="<?= $s['specialization_id'] ?>" <?= $filter_spec === (int)$s['specialization_id'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($s['specialization_name']) ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-2">
            <input type="text" name="city" class="form-control" placeholder="City" value="<?= htmlspecialchars($filter_city) ?>">
        </div>
        <div class="col-md-2">
            <input type="number" name="min_rating" class="form-control" placeholder="Min Rating (0-5)" min="0" max="5" step="0.1" value="<?= $filter_min_r ?: '' ?>">
        </div>
        <div class="col-md-2">
            <input type="number" name="max_fee" class="form-control" placeholder="Max Fee (NPR)" min="0" value="<?= $filter_max_f ?: '' ?>">
        </div>
        <div class="col-md-2">
            <button type="submit" class="btn btn-primary w-100">Search</button>
        </div>
        <div class="col-md-1">
            <a href="search.php" class="btn btn-outline-secondary w-100">Reset</a>
        </div>
    </form>

    <p class="text-muted"><?= count($doctors) ?> doctor(s) found</p>

    <?php foreach ($doctors as $doc): ?>
    <div class="card mb-3">
        <div class="card-body">
            <div class="d-flex justify-content-between">
                <h5><?= htmlspecialchars($doc['name']) ?></h5>
                <span>⭐ <?= number_format($doc['average_rating'], 1) ?></span>
            </div>
            <p class="mb-1"><?= htmlspecialchars($doc['specialization_name']) ?> | <?= htmlspecialchars($doc['qualification']) ?></p>
            <p class="mb-1"><?= (int)$doc['experience_years'] ?> years exp | NPR <?= number_format($doc['consultation_fee'], 0) ?></p>
            <p class="mb-1 text-muted"><?= htmlspecialchars($doc['clinic_name']) ?>, <?= htmlspecialchars($doc['area']) ?>, <?= htmlspecialchars($doc['city']) ?></p>
            <?php if ($doc['has_availability']): ?>
                <span class="badge bg-success mb-2">Slots Available</span>
            <?php else: ?>
                <span class="badge bg-secondary mb-2">No Available Slots</span>
            <?php endif; ?>
            <br>
            <a href="book_appointment.php?doctor_id=<?= $doc['doctor_id'] ?>" class="btn btn-sm btn-primary">Book Appointment</a>
        </div>
    </div>
    <?php endforeach; ?>
</div>
<?php include '../includes/footer.php'; ?>
</body>
</html>
```

- [ ] **Step 2: Test filters**

Search by specialization, by city, by max fee. Verify results filter correctly.

- [ ] **Step 3: Commit**

```bash
git add patient/search.php
git commit -m "feat(patient): add manual doctor search with specialization, city, rating, fee filters"
```
