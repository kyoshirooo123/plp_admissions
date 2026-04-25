-- ============================================================
-- Migration: 2026-04-25 — Interview auto-scheduling + department
-- ============================================================
-- Adds:
--   * `departments` reference table (normalized college list)
--   * `course_departments` mapping table (course → department)
--   * `department_schedules` (predefined open windows per college)
--   * `users.department` column (+ index)
--   * `interview_slots.department` column (+ index)
--   * Backfills for both new columns based on existing data
--
-- Safe to re-run: uses CREATE TABLE IF NOT EXISTS and
-- ADD COLUMN IF NOT EXISTS (MariaDB 10.2+ / MySQL 8+).
-- ============================================================

-- ------------------------------------------------------------
-- departments — one row per college
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `departments` (
    `id`         INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`       VARCHAR(20)      NOT NULL COMMENT 'Short code, e.g. CCS, CON',
    `name`       VARCHAR(120)     NOT NULL COMMENT 'Official college name',
    `created_at` DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_dept_code` (`code`),
    UNIQUE KEY `uq_dept_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `departments` (`code`, `name`) VALUES
    ('CCS', 'College of Computer Studies'),
    ('CON', 'College of Nursing'),
    ('CBA', 'College of Business and Accountancy'),
    ('COE', 'College of Education'),
    ('CAS', 'College of Arts and Sciences'),
    ('CEN', 'College of Engineering')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ------------------------------------------------------------
-- course_departments — maps each PLP course to one department
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `course_departments` (
    `id`            INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `course_name`   VARCHAR(200)     NOT NULL,
    `department_id` INT(10) UNSIGNED NOT NULL,
    `created_at`    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cd_course` (`course_name`),
    KEY `idx_cd_department` (`department_id`),
    CONSTRAINT `fk_cd_department`
        FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `course_departments` (`course_name`, `department_id`)
SELECT c.course_name, d.id
FROM departments d
JOIN (
    SELECT 'BS Information Technology (BSIT)'                                  AS course_name, 'CCS' AS code UNION ALL
    SELECT 'BS Computer Science (BSCS)',                                             'CCS' UNION ALL
    SELECT 'BS Nursing (BSN)',                                                       'CON' UNION ALL
    SELECT 'BS Accountancy (BSA)',                                                   'CBA' UNION ALL
    SELECT 'BS Business Administration major in Marketing Management (BSBA)',       'CBA' UNION ALL
    SELECT 'BS Entrepreneurship (BSENT)',                                            'CBA' UNION ALL
    SELECT 'BS Hospitality Management (BSHM)',                                       'CBA' UNION ALL
    SELECT 'Bachelor of Elementary Education (BEED)',                                'COE' UNION ALL
    SELECT 'Bachelor of Secondary Education Major in English (BSED-ENG)',           'COE' UNION ALL
    SELECT 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)',          'COE' UNION ALL
    SELECT 'Bachelor of Secondary Education Major in Mathematics (BSED-MATH)',      'COE' UNION ALL
    SELECT 'AB Psychology (AB Psych)',                                               'CAS' UNION ALL
    SELECT 'BS Electronics Engineering (BSECE)',                                     'CEN'
) c ON c.code = d.code
ON DUPLICATE KEY UPDATE department_id = VALUES(department_id);

-- ------------------------------------------------------------
-- department_schedules — predefined open windows per college
-- Used by the auto-scheduler to generate/validate interview slots.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `department_schedules` (
    `id`                INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `department_id`     INT(10) UNSIGNED NOT NULL,
    `day_of_week`       TINYINT(1) UNSIGNED NOT NULL COMMENT '0=Sun..6=Sat',
    `start_time`        TIME             NOT NULL DEFAULT '09:00:00',
    `end_time`          TIME             NOT NULL DEFAULT '16:00:00',
    `slot_minutes`      SMALLINT(5) UNSIGNED NOT NULL DEFAULT 30,
    `capacity_per_slot` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_ds_dept_dow_start` (`department_id`, `day_of_week`, `start_time`),
    KEY `idx_ds_department` (`department_id`),
    CONSTRAINT `fk_ds_department`
        FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default schedule: every department opens Mon–Fri 09:00–16:00,
-- 30-min slots, 1 applicant per slot.  Admin can change later.
INSERT INTO `department_schedules`
    (`department_id`, `day_of_week`, `start_time`, `end_time`, `slot_minutes`, `capacity_per_slot`)
SELECT d.id, dow.day_of_week, '09:00:00', '16:00:00', 30, 1
FROM departments d
CROSS JOIN (
    SELECT 1 AS day_of_week UNION ALL
    SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
) dow
ON DUPLICATE KEY UPDATE start_time = VALUES(start_time);

-- ------------------------------------------------------------
-- users.department
-- ------------------------------------------------------------
ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `department` VARCHAR(120) NOT NULL DEFAULT '' AFTER `role`,
    ADD INDEX IF NOT EXISTS `idx_users_department` (`department`);

-- Backfill: each student's department is derived from their (most recent)
-- applicant row's course_applied → course_departments → departments.name.
UPDATE `users` u
JOIN (
    SELECT a.user_id, MAX(a.id) AS latest_applicant_id
    FROM applicants a
    GROUP BY a.user_id
) latest                     ON latest.user_id       = u.id
JOIN applicants          a   ON a.id                  = latest.latest_applicant_id
JOIN course_departments  cd  ON cd.course_name        = a.course_applied
JOIN departments         d   ON d.id                  = cd.department_id
SET u.department = d.name
WHERE u.role = 'student' AND (u.department = '' OR u.department IS NULL);

-- ------------------------------------------------------------
-- interview_slots.department
-- ------------------------------------------------------------
ALTER TABLE `interview_slots`
    ADD COLUMN IF NOT EXISTS `department` VARCHAR(120) NOT NULL DEFAULT '' AFTER `capacity`,
    ADD INDEX IF NOT EXISTS `idx_slots_department` (`department`);

-- Backfill existing slots using the creating staff's department (if any).
UPDATE `interview_slots` s
JOIN `users` u ON u.id = s.created_by
SET s.department = u.department
WHERE (s.department = '' OR s.department IS NULL)
  AND u.department <> '';
