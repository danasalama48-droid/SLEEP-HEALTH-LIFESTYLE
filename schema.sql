-- ============================================================
-- Sleep Health and Lifestyle Dataset — Database Schema
-- Target: PostgreSQL (minor tweaks needed for MySQL/SQLite,
-- noted inline where relevant)
-- ============================================================

-- Drop tables if re-running this script during development
DROP TABLE IF EXISTS sleep_records;
DROP TABLE IF EXISTS occupations;
DROP TABLE IF EXISTS bmi_categories;
DROP TABLE IF EXISTS sleep_disorders;

-- ------------------------------------------------------------
-- Lookup tables (normalize repeated string values)
-- ------------------------------------------------------------

CREATE TABLE occupations (
    occupation_id   SERIAL PRIMARY KEY,      -- SQLite: INTEGER PRIMARY KEY AUTOINCREMENT
    occupation_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE bmi_categories (
    bmi_category_id SERIAL PRIMARY KEY,
    category_name    VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE sleep_disorders (
    disorder_id   SERIAL PRIMARY KEY,
    disorder_name VARCHAR(20) NOT NULL UNIQUE  -- 'None', 'Insomnia', 'Sleep Apnea'
);

-- ------------------------------------------------------------
-- Main fact table: one row per person
-- ------------------------------------------------------------

CREATE TABLE sleep_records (
    person_id                 INTEGER PRIMARY KEY,
    gender                    VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female')),
    age                       SMALLINT NOT NULL CHECK (age > 0),
    occupation_id             INTEGER REFERENCES occupations(occupation_id),
    sleep_duration_hours      NUMERIC(3,1) NOT NULL CHECK (sleep_duration_hours BETWEEN 0 AND 24),
    quality_of_sleep          SMALLINT NOT NULL CHECK (quality_of_sleep BETWEEN 1 AND 10),
    physical_activity_level   SMALLINT NOT NULL CHECK (physical_activity_level >= 0),
    stress_level              SMALLINT NOT NULL CHECK (stress_level BETWEEN 1 AND 10),
    bmi_category_id           INTEGER REFERENCES bmi_categories(bmi_category_id),
    blood_pressure_systolic   SMALLINT,
    blood_pressure_diastolic  SMALLINT,
    heart_rate                SMALLINT NOT NULL CHECK (heart_rate > 0),
    daily_steps               INTEGER NOT NULL CHECK (daily_steps >= 0),
    sleep_disorder_id         INTEGER REFERENCES sleep_disorders(disorder_id)
);

-- Helpful indexes for the kinds of grouped queries used in the analysis
CREATE INDEX idx_sleep_records_occupation ON sleep_records(occupation_id);
CREATE INDEX idx_sleep_records_bmi ON sleep_records(bmi_category_id);
CREATE INDEX idx_sleep_records_disorder ON sleep_records(sleep_disorder_id);
CREATE INDEX idx_sleep_records_gender ON sleep_records(gender);

-- ------------------------------------------------------------
-- Seed lookup tables
-- ------------------------------------------------------------

INSERT INTO occupations (occupation_name) VALUES
    ('Software Engineer'), ('Doctor'), ('Sales Representative'), ('Teacher'),
    ('Nurse'), ('Engineer'), ('Accountant'), ('Scientist'), ('Lawyer'),
    ('Salesperson'), ('Manager');

INSERT INTO bmi_categories (category_name) VALUES
    ('Normal'), ('Normal Weight'), ('Overweight'), ('Obese');

INSERT INTO sleep_disorders (disorder_name) VALUES
    ('None'), ('Insomnia'), ('Sleep Apnea');

-- ------------------------------------------------------------
-- Loading the CSV data
-- ------------------------------------------------------------
-- Option A: load raw CSV into a staging table, then transform into
-- sleep_records with the lookup IDs resolved. This avoids manually
-- retyping 374 rows of INSERT statements.

CREATE TABLE staging_sleep_raw (
    person_id                INTEGER,
    gender                   VARCHAR(10),
    age                      SMALLINT,
    occupation               VARCHAR(50),
    sleep_duration            NUMERIC(3,1),
    quality_of_sleep          SMALLINT,
    physical_activity_level   SMALLINT,
    stress_level              SMALLINT,
    bmi_category              VARCHAR(20),
    blood_pressure            VARCHAR(10),   -- e.g. '126/83', split below
    heart_rate                SMALLINT,
    daily_steps               INTEGER,
    sleep_disorder            VARCHAR(20)
);

-- PostgreSQL: run from psql, adjust path to your CSV
-- \copy staging_sleep_raw FROM 'Sleep_health_and_lifestyle_dataset.csv' WITH (FORMAT csv, HEADER true);

-- MySQL equivalent:
-- LOAD DATA LOCAL INFILE 'Sleep_health_and_lifestyle_dataset.csv'
-- INTO TABLE staging_sleep_raw
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- Transform staging data into the normalized sleep_records table
INSERT INTO sleep_records (
    person_id, gender, age, occupation_id, sleep_duration_hours,
    quality_of_sleep, physical_activity_level, stress_level,
    bmi_category_id, blood_pressure_systolic, blood_pressure_diastolic,
    heart_rate, daily_steps, sleep_disorder_id
)
SELECT
    s.person_id,
    s.gender,
    s.age,
    o.occupation_id,
    s.sleep_duration,
    s.quality_of_sleep,
    s.physical_activity_level,
    s.stress_level,
    b.bmi_category_id,
    SPLIT_PART(s.blood_pressure, '/', 1)::SMALLINT,
    SPLIT_PART(s.blood_pressure, '/', 2)::SMALLINT,
    s.heart_rate,
    s.daily_steps,
    d.disorder_id
FROM staging_sleep_raw s
LEFT JOIN occupations o       ON o.occupation_name = s.occupation
LEFT JOIN bmi_categories b    ON b.category_name = s.bmi_category
LEFT JOIN sleep_disorders d   ON d.disorder_name = COALESCE(s.sleep_disorder, 'None');

-- Staging table can be dropped once the load is verified
-- DROP TABLE staging_sleep_raw;

-- ------------------------------------------------------------
-- Example queries matching the visual story's findings
-- ------------------------------------------------------------

-- Sleep quality by stress level (Section 01)
-- SELECT stress_level, ROUND(AVG(quality_of_sleep), 2) AS avg_quality
-- FROM sleep_records
-- GROUP BY stress_level
-- ORDER BY stress_level;

-- Average sleep duration & stress by occupation (Section 02)
-- SELECT o.occupation_name,
--        COUNT(*) AS n,
--        ROUND(AVG(r.sleep_duration_hours), 2) AS avg_sleep,
--        ROUND(AVG(r.stress_level), 2) AS avg_stress
-- FROM sleep_records r
-- JOIN occupations o ON o.occupation_id = r.occupation_id
-- GROUP BY o.occupation_name
-- HAVING COUNT(*) >= 20
-- ORDER BY avg_sleep;

-- Sleep disorder distribution by BMI category (Section 03)
-- SELECT b.category_name, d.disorder_name, COUNT(*) AS n
-- FROM sleep_records r
-- JOIN bmi_categories b ON b.bmi_category_id = r.bmi_category_id
-- JOIN sleep_disorders d ON d.disorder_id = r.sleep_disorder_id
-- GROUP BY b.category_name, d.disorder_name
-- ORDER BY b.category_name, d.disorder_name;
