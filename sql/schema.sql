-- Creating database 
CREATE DATABASE patient_analytics_db;

-- Setting patient_analytics_db to be used
USE patient_analytics_db;

-- Drop child tables first (those containing Foreign Keys)
DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS visit_secondary_diagnoses;
DROP TABLE IF EXISTS outcomes;
DROP TABLE IF EXISTS diagnoses;
DROP TABLE IF EXISTS medicines;

-- Drop parent/reference tables last
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS charlson_comorbidity_index;

-- Create the Parent Tables (No Foreign Keys)

CREATE TABLE charlson_comorbidity_index (
    condition_name VARCHAR(100) PRIMARY KEY,
    cci_weight INT
);

-- 2. Creating Patients table
CREATE TABLE patients (
    patient_id VARCHAR(50) PRIMARY KEY,
    age INT,
    sex VARCHAR(1),
    bmi DECIMAL(10 , 2 ),
    systolic_bp INT,
    diastolic_bp INT,
    heart_rate INT,
    temperature_f DECIMAL(10 , 2 ),
    smoking_status VARCHAR(50),
    alcohol_use VARCHAR(50),
    exercise_level VARCHAR(50),
    insurance_type VARCHAR(100),
    charlson_index INT,
    dx_hypertension INT,
    dx_type2_diabetes INT,
    dx_hyperlipidemia INT,
    dx_obesity INT,
    dx_coronary_artery_disease INT,
    dx_heart_failure INT,
    dx_atrial_fibrillation INT,
    dx_chronic_kidney_disease INT,
    dx_copd INT,
    dx_asthma INT,
    dx_depression INT,
    dx_anxiety INT,
    dx_hypothyroidism INT,
    dx_osteoarthritis INT,
    dx_type1_diabetes INT,
    age_group VARCHAR(30),
    gender VARCHAR(10)
);

-- Create the Child Tables (With Foreign Keys)

CREATE TABLE medicines (
    med_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id VARCHAR(50),
    medication VARCHAR(100),
    dose DECIMAL(10 , 2 ),
    unit VARCHAR(20),
    frequency VARCHAR(50),
    indication VARCHAR(50),
    start_date DATE,
    duration_days INT,
    is_generic INT,
    adherence_pct DECIMAL(10 , 2 ),
    FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
);

-- 4. Creating lab results table
CREATE TABLE lab_results (
    lab_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id VARCHAR(50),
    test_date DATE,
    test_name VARCHAR(100),
    `value` DECIMAL(10 , 2 ),
    unit VARCHAR(50),
    reference_low DECIMAL(10 , 2 ),
    reference_high DECIMAL(10 , 2 ),
    flag VARCHAR(50),
    is_abnormal INT,
    delta_from_normal DECIMAL(10 , 2 ),
    FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
);

-- 5. The Primary Diagnoses Table
CREATE TABLE diagnoses (
    visit_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50),
    visit_date DATE,
    visit_type VARCHAR(50),
    primary_diagnosis VARCHAR(100),
    primary_icd10 VARCHAR(20),
    provider_specialty VARCHAR(150),
    FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
);

-- 6. Creating vist secondary diagnoses table
CREATE TABLE visit_secondary_diagnoses (
    second_diag_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id VARCHAR(50),
    patient_id VARCHAR(50),
    diagnosis_name VARCHAR(100),
    icd10_code VARCHAR(20),
    FOREIGN KEY (visit_id)
        REFERENCES diagnoses (visit_id),
    FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
);

-- 7. Creating outcomes table
CREATE TABLE outcomes (
    outcome_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id VARCHAR(50),
    admission_date DATE,
    discharge_date DATE,
    length_of_stay_days INT,
    icu_admission INT,
    icu_days INT,
    in_hospital_death INT,
    discharge_disposition VARCHAR(25),
    readmitted_30d INT,
    days_to_readmission INT,
    primary_drg INT,
    total_charges_usd DECIMAL(10 , 2 ),
    FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
);





