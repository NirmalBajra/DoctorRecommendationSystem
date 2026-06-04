-- Doctors Recommendation System — Full Database Schema
-- Plan: docs/implementation-plan/backend/01-database-and-auth.md — Task 1
-- Run this once in phpMyAdmin or MySQL CLI to create all tables.

CREATE DATABASE IF NOT EXISTS doctors_recommendation_system
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE doctors_recommendation_system;

CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(150)  NOT NULL UNIQUE,
    password_hash VARCHAR(255)  NOT NULL,
    role          ENUM('patient','doctor','admin') NOT NULL,
    status        ENUM('active','inactive','pending','rejected') NOT NULL DEFAULT 'active',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
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
    experience_years  INT          DEFAULT 0,
    consultation_fee  DECIMAL(10,2) DEFAULT 0.00,
    clinic_name       VARCHAR(150),
    license_number    VARCHAR(100),
    contact_number    VARCHAR(20),
    city              VARCHAR(100),
    area              VARCHAR(100),
    average_rating    DECIMAL(3,2)  DEFAULT 0.00,
    approval_status   ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    FOREIGN KEY (user_id)           REFERENCES users(user_id) ON DELETE CASCADE,
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
    FOREIGN KEY (disease_id)        REFERENCES diseases(disease_id) ON DELETE CASCADE,
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
    recommendation_id           INT AUTO_INCREMENT PRIMARY KEY,
    patient_id                  INT NOT NULL,
    symptoms_input              TEXT NOT NULL,
    predicted_disease           VARCHAR(100),
    predicted_specialization_id INT,
    recommended_doctors         JSON,
    confidence_score            DECIMAL(5,4),
    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id)                  REFERENCES patients(patient_id),
    FOREIGN KEY (predicted_specialization_id) REFERENCES specializations(specialization_id)
);

-- ── Default admin account ────────────────────────────────────────────────────
-- Password: password  ← CHANGE THIS IMMEDIATELY AFTER SETUP
INSERT INTO users (name, email, password_hash, role, status)
VALUES (
    'Admin',
    'admin@drs.local',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'admin',
    'active'
);
