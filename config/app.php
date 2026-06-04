<?php
/**
 * Application-level constants.
 * Plan: docs/implementation-plan/backend/01-database-and-auth.md — Task 2
 */

// Python executable — use 'python3' on Linux/Mac
define('PYTHON_BIN', 'python');

// Absolute path to the ml/ directory
define('ML_DIR', dirname(__DIR__) . DIRECTORY_SEPARATOR . 'ml');

// Application base URL (no trailing slash)
define('BASE_URL', 'http://localhost/doctors-recommendation-system');

// Application name
define('APP_NAME', 'Doctors Recommendation System');

// ML prediction confidence threshold (below this → fall back to General Physician)
define('ML_CONFIDENCE_THRESHOLD', 0.60);
