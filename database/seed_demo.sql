-- ============================================================
-- seed_demo.sql
-- Demo data for the PLP Admissions System.
-- Generates ~120 applicants distributed across all funnel
-- stages (pending → documents → submitted → exam → interview
-- → released → withdrawn), plus exam rooms, exam results,
-- interview sessions, queue entries, admission results,
-- course suggestions, reschedule logs, notifications, and
-- audit logs.
--
-- Run AFTER schema.sql and seed_users.sql.  Safe to re-run
-- (clears demo data first via the @plp_demo_marker).
--
-- All demo student logins use password: Student@123
-- ============================================================

SET time_zone = '+08:00';

-- Remove any prior demo seed (idempotent — safe to re-run).
DELETE FROM users WHERE email LIKE '%@student.plp.edu.ph';
DELETE FROM exam_slot_schedule WHERE room_label REGEXP '^Rm-[0-9]+$' AND school_year = '2026-2027';
DELETE FROM exams WHERE title = 'PLP Entrance Exam (Demo)';
DELETE FROM interview_slots WHERE location_notes = 'Bring your applicant ID.';

-- Ensure email-verification columns exist (matches what
-- core/automation.php :: ensure_email_verification_columns() does).
ALTER TABLE `users`
  ADD COLUMN IF NOT EXISTS `email_verified`              TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_active`,
  ADD COLUMN IF NOT EXISTS `email_verify_token`          VARCHAR(64) DEFAULT NULL AFTER `email_verified`,
  ADD COLUMN IF NOT EXISTS `email_verify_code`           VARCHAR(8) DEFAULT NULL AFTER `email_verify_token`,
  ADD COLUMN IF NOT EXISTS `email_verify_code_expires_at` DATETIME DEFAULT NULL AFTER `email_verify_code`,
  ADD COLUMN IF NOT EXISTS `email_verify_attempts`        TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `email_verify_code_expires_at`,
  ADD COLUMN IF NOT EXISTS `email_verify_last_sent_at`    DATETIME DEFAULT NULL AFTER `email_verify_attempts`;

-- 1. Student users (demo applicants).  email_verified = 1 so demo
-- accounts skip the email-verification gate in modules/auth/login.php.
INSERT INTO `users` (`name`, `first_name`, `middle_name`, `last_name`, `birthdate`, `sex`, `address`, `phone`, `email`, `password_hash`, `role`, `is_active`, `email_verified`, `created_at`) VALUES
  ('Maria T. Mendoza', 'Maria', 'Tan', 'Mendoza', '2007-09-16', 'F', '5290 P. Burgos St., Brgy. Maybunga, Pasig City', '+63964990148', 'maria.mendoza001@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 56 DAY + INTERVAL 36000 SECOND)),
  ('Janine T. Lacson', 'Janine', 'Tomas', 'Lacson', '2001-12-01', 'F', '7960 Sumulong Hwy., Brgy. Sumilang, Pasig City', '+63977894773', 'janine.lacson002@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 62 DAY + INTERVAL 32400 SECOND)),
  ('Bea S. Andrada', 'Bea', 'Soriano', 'Andrada', '2000-07-13', 'F', '4586 Rizal St., Brgy. Sumilang, Pasig City', '+63913343322', 'bea.andrada003@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 97 DAY + INTERVAL 32400 SECOND)),
  ('Faith E. Salazar', 'Faith', 'Esguerra', 'Salazar', '2002-04-06', 'F', '8877 P. Burgos St., Brgy. Manggahan, Pasig City', '+63984860227', 'faith.salazar004@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 33 DAY + INTERVAL 50400 SECOND)),
  ('Isabela A. Yap', 'Isabela', 'Aquino', 'Yap', '2001-12-21', 'F', '9639 Quezon Blvd., Brgy. Rosario, Pasig City', '+63998621757', 'isabela.yap005@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 51 DAY + INTERVAL 36000 SECOND)),
  ('Hope V. Pineda', 'Hope', 'Velasco', 'Pineda', '2001-03-30', 'F', '364 Quezon Blvd., Brgy. Buting, Pasig City', '+63964780786', 'hope.pineda006@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 74 DAY + INTERVAL 61200 SECOND)),
  ('Camille B. Aquino', 'Camille', 'Bautista', 'Aquino', '2001-06-25', 'F', '8340 Rizal St., Brgy. Sumilang, Pasig City', '+63945461167', 'camille.aquino007@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 78 DAY + INTERVAL 64800 SECOND)),
  ('Mark D. Rodriguez', 'Mark', 'Domingo', 'Rodriguez', '2009-04-13', 'M', '8696 Sumulong Hwy., Brgy. Caniogan, Pasig City', '+63965751970', 'mark.rodriguez008@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 70 DAY + INTERVAL 32400 SECOND)),
  ('Lance P. Velasco', 'Lance', 'Pineda', 'Velasco', '2008-05-13', 'M', '4582 Rizal St., Brgy. Manggahan, Pasig City', '+63949426414', 'lance.velasco009@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 106 DAY + INTERVAL 57600 SECOND)),
  ('Bea V. Ramos', 'Bea', 'Valdez', 'Ramos', '2007-11-13', 'F', '6132 Mabini Ave., Brgy. Maybunga, Pasig City', '+63910576106', 'bea.ramos010@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 57 DAY + INTERVAL 36000 SECOND)),
  ('Kris V. Del Rosario', 'Kris', 'Velasco', 'Del Rosario', '2001-01-30', 'F', '609 Roxas Ave., Brgy. Sumilang, Pasig City', '+63969286977', 'kris.delrosario011@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 110 DAY + INTERVAL 36000 SECOND)),
  ('Miguel U. Domingo', 'Miguel', 'Uy', 'Domingo', '2000-03-14', 'M', '9230 Sumulong Hwy., Brgy. Rosario, Pasig City', '+63997130306', 'miguel.domingo012@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 34 DAY + INTERVAL 46800 SECOND)),
  ('Earl E. Torres', 'Earl', 'Esguerra', 'Torres', '2005-10-20', 'M', '1891 Sumulong Hwy., Brgy. Maybunga, Pasig City', '+63991734645', 'earl.torres013@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 71 DAY + INTERVAL 64800 SECOND)),
  ('Mikaela A. Dela Cruz', 'Mikaela', 'Andrada', 'Dela Cruz', '2001-08-05', 'F', '8847 Kalayaan Ave., Brgy. Rosario, Pasig City', '+63939915497', 'mikaela.delacruz014@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND)),
  ('Kris O. Valdez', 'Kris', 'Ong', 'Valdez', '2009-02-15', 'F', '2802 Quezon Blvd., Brgy. Buting, Pasig City', '+63977043542', 'kris.valdez015@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 93 DAY + INTERVAL 39600 SECOND)),
  ('Imelda C. Dela Cruz', 'Imelda', 'Co', 'Dela Cruz', '2002-01-17', 'F', '759 Bonifacio St., Brgy. Buting, Pasig City', '+63925631749', 'imelda.delacruz016@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 53 DAY + INTERVAL 36000 SECOND)),
  ('Pedro P. Reyes', 'Pedro', 'Pineda', 'Reyes', '2009-03-28', 'M', '2058 Aguinaldo St., Brgy. Rosario, Pasig City', '+63991344566', 'pedro.reyes017@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 66 DAY + INTERVAL 61200 SECOND)),
  ('Cherry M. Ramos', 'Cherry', 'Marquez', 'Ramos', '2007-03-09', 'F', '2606 Quezon Blvd., Brgy. Santolan, Pasig City', '+63989104543', 'cherry.ramos018@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 114 DAY + INTERVAL 57600 SECOND)),
  ('Mark S. Co', 'Mark', 'Soriano', 'Co', '2006-06-04', 'M', '9776 Sumulong Hwy., Brgy. Manggahan, Pasig City', '+63972210215', 'mark.co019@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 30 DAY + INTERVAL 61200 SECOND)),
  ('Isabel L. Torres', 'Isabel', 'Lim', 'Torres', '2003-07-20', 'F', '425 Roxas Ave., Brgy. Maybunga, Pasig City', '+63945230984', 'isabel.torres020@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 78 DAY + INTERVAL 32400 SECOND)),
  ('Joshua D. Magsaysay', 'Joshua', 'Domingo', 'Magsaysay', '2005-09-09', 'M', '680 Bonifacio St., Brgy. Pinagbuhatan, Pasig City', '+63932192077', 'joshua.magsaysay021@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND)),
  ('Lourdes S. Chua', 'Lourdes', 'Santos', 'Chua', '2005-11-03', 'F', '7375 Rizal St., Brgy. Pinagbuhatan, Pasig City', '+63933558592', 'lourdes.chua022@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 67 DAY + INTERVAL 64800 SECOND)),
  ('Lourdes T. Santos', 'Lourdes', 'Tan', 'Santos', '2003-08-16', 'F', '5936 M.L. Quezon St., Brgy. Bambang, Pasig City', '+63988784832', 'lourdes.santos023@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND)),
  ('Andres D. Soriano', 'Andres', 'Del Rosario', 'Soriano', '2005-02-19', 'M', '4539 Quezon Blvd., Brgy. Manggahan, Pasig City', '+63946554968', 'andres.soriano024@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 65 DAY + INTERVAL 64800 SECOND)),
  ('Ronnel V. Garcia', 'Ronnel', 'Villanueva', 'Garcia', '2009-02-03', 'M', '4958 M.L. Quezon St., Brgy. Sumilang, Pasig City', '+63991794735', 'ronnel.garcia025@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ('Jericho G. Torres', 'Jericho', 'Gonzales', 'Torres', '2004-04-02', 'M', '3958 P. Burgos St., Brgy. Santolan, Pasig City', '+63957576645', 'jericho.torres026@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 85 DAY + INTERVAL 54000 SECOND)),
  ('Charmaine L. Tomas', 'Charmaine', 'Lim', 'Tomas', '2006-04-08', 'F', '3352 Mabini Ave., Brgy. Buting, Pasig City', '+63999754637', 'charmaine.tomas027@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 107 DAY + INTERVAL 43200 SECOND)),
  ('Lourdes A. Lacson', 'Lourdes', 'Aguilar', 'Lacson', '2009-11-15', 'F', '1604 Bonifacio St., Brgy. Maybunga, Pasig City', '+63922227731', 'lourdes.lacson028@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 47 DAY + INTERVAL 39600 SECOND)),
  ('Justin N. Ong', 'Justin', 'Navarro', 'Ong', '2003-05-22', 'M', '4108 Aguinaldo St., Brgy. Bambang, Pasig City', '+63962735299', 'justin.ong029@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 46 DAY + INTERVAL 57600 SECOND)),
  ('Mark M. Esguerra', 'Mark', 'Marquez', 'Esguerra', '2005-12-29', 'M', '1436 Aguinaldo St., Brgy. Manggahan, Pasig City', '+63995548179', 'mark.esguerra030@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 50 DAY + INTERVAL 39600 SECOND)),
  ('Ella S. Manalo', 'Ella', 'Soriano', 'Manalo', '2004-04-19', 'F', '9970 P. Burgos St., Brgy. San Joaquin, Pasig City', '+63995234250', 'ella.manalo031@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 54 DAY + INTERVAL 36000 SECOND)),
  ('Vincent L. Chua', 'Vincent', 'Lim', 'Chua', '2005-11-14', 'M', '5287 P. Burgos St., Brgy. Rosario, Pasig City', '+63976087280', 'vincent.chua032@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 40 DAY + INTERVAL 46800 SECOND)),
  ('Jose H. Lacson', 'Jose', 'Hernandez', 'Lacson', '2003-11-26', 'M', '3064 Quezon Blvd., Brgy. Santolan, Pasig City', '+63991178776', 'jose.lacson033@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND)),
  ('Angel M. Salazar', 'Angel', 'Mendoza', 'Salazar', '2002-10-21', 'F', '5261 Quezon Blvd., Brgy. Rosario, Pasig City', '+63942397352', 'angel.salazar034@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 32 DAY + INTERVAL 36000 SECOND)),
  ('Eduardo C. Lim', 'Eduardo', 'Chua', 'Lim', '2002-04-21', 'M', '5472 Aguinaldo St., Brgy. Bambang, Pasig City', '+63977106435', 'eduardo.lim035@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 90 DAY + INTERVAL 61200 SECOND)),
  ('Camille T. Ramos', 'Camille', 'Tan', 'Ramos', '2007-02-23', 'F', '6808 Kalayaan Ave., Brgy. San Joaquin, Pasig City', '+63949490724', 'camille.ramos036@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 117 DAY + INTERVAL 50400 SECOND)),
  ('Maria P. Gonzales', 'Maria', 'Pineda', 'Gonzales', '2001-11-05', 'F', '3224 Rizal St., Brgy. San Joaquin, Pasig City', '+63964318876', 'maria.gonzales037@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 68 DAY + INTERVAL 46800 SECOND)),
  ('Rico P. Co', 'Rico', 'Pineda', 'Co', '2001-07-05', 'M', '1091 P. Burgos St., Brgy. Bambang, Pasig City', '+63996107830', 'rico.co038@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 103 DAY + INTERVAL 36000 SECOND)),
  ('Lance T. Uy', 'Lance', 'Torres', 'Uy', '2004-07-27', 'M', '8520 Aguinaldo St., Brgy. San Joaquin, Pasig City', '+63958476434', 'lance.uy039@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 73 DAY + INTERVAL 50400 SECOND)),
  ('Earl R. Sy', 'Earl', 'Rodriguez', 'Sy', '2008-08-16', 'M', '4808 Aguinaldo St., Brgy. Rosario, Pasig City', '+63968085938', 'earl.sy040@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 85 DAY + INTERVAL 61200 SECOND)),
  ('Felix S. Magsaysay', 'Felix', 'Soriano', 'Magsaysay', '2005-11-27', 'M', '5431 P. Burgos St., Brgy. Bambang, Pasig City', '+63998729343', 'felix.magsaysay041@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 87 DAY + INTERVAL 64800 SECOND)),
  ('Christian A. Co', 'Christian', 'Aguilar', 'Co', '2001-02-05', 'M', '2490 Sumulong Hwy., Brgy. Manggahan, Pasig City', '+63988533697', 'christian.co042@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 105 DAY + INTERVAL 54000 SECOND)),
  ('Krizia D. Bautista', 'Krizia', 'Domingo', 'Bautista', '2002-05-17', 'F', '6647 Mabini Ave., Brgy. Maybunga, Pasig City', '+63952690760', 'krizia.bautista043@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 38 DAY + INTERVAL 43200 SECOND)),
  ('Cherry D. Manalo', 'Cherry', 'Dela Cruz', 'Manalo', '2007-12-05', 'F', '9699 M.L. Quezon St., Brgy. Buting, Pasig City', '+63911269657', 'cherry.manalo044@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 111 DAY + INTERVAL 64800 SECOND)),
  ('Juan S. Ramos', 'Juan', 'Soriano', 'Ramos', '2000-03-06', 'M', '8219 Aguinaldo St., Brgy. Pinagbuhatan, Pasig City', '+63992742093', 'juan.ramos045@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 102 DAY + INTERVAL 46800 SECOND)),
  ('Yna M. Tan', 'Yna', 'Marquez', 'Tan', '2009-06-08', 'F', '6657 Rizal St., Brgy. Santolan, Pasig City', '+63938691779', 'yna.tan046@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 75 DAY + INTERVAL 64800 SECOND)),
  ('Mercedes T. Salazar', 'Mercedes', 'Tan', 'Salazar', '2003-09-21', 'F', '2771 Sumulong Hwy., Brgy. Bambang, Pasig City', '+63913120708', 'mercedes.salazar047@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 108 DAY + INTERVAL 61200 SECOND)),
  ('Justin M. Dela Cruz', 'Justin', 'Manalo', 'Dela Cruz', '2002-07-31', 'M', '5429 P. Burgos St., Brgy. Bambang, Pasig City', '+63995698396', 'justin.delacruz048@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 42 DAY + INTERVAL 50400 SECOND)),
  ('Aileen O. Esguerra', 'Aileen', 'Ong', 'Esguerra', '2008-06-15', 'F', '9238 P. Burgos St., Brgy. Pinagbuhatan, Pasig City', '+63913281836', 'aileen.esguerra049@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 32 DAY + INTERVAL 32400 SECOND)),
  ('Lance N. Rodriguez', 'Lance', 'Navarro', 'Rodriguez', '2004-10-26', 'M', '9816 M.L. Quezon St., Brgy. Rosario, Pasig City', '+63970261458', 'lance.rodriguez050@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 69 DAY + INTERVAL 36000 SECOND)),
  ('Dominic V. Velasco', 'Dominic', 'Villanueva', 'Velasco', '2006-01-18', 'M', '9816 Mabini Ave., Brgy. Maybunga, Pasig City', '+63928342661', 'dominic.velasco051@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 70 DAY + INTERVAL 57600 SECOND)),
  ('Andrea T. Velasco', 'Andrea', 'Tan', 'Velasco', '2008-08-19', 'F', '1245 P. Burgos St., Brgy. Rosario, Pasig City', '+63971780868', 'andrea.velasco052@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 76 DAY + INTERVAL 32400 SECOND)),
  ('Juan R. Del Rosario', 'Juan', 'Reyes', 'Del Rosario', '2001-11-15', 'M', '1791 Kalayaan Ave., Brgy. Maybunga, Pasig City', '+63944011394', 'juan.delrosario053@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 48 DAY + INTERVAL 36000 SECOND)),
  ('Kevin D. Villanueva', 'Kevin', 'Del Rosario', 'Villanueva', '2000-03-22', 'M', '1536 M.L. Quezon St., Brgy. Santolan, Pasig City', '+63965847734', 'kevin.villanueva054@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 101 DAY + INTERVAL 64800 SECOND)),
  ('Jericho C. Valdez', 'Jericho', 'Chua', 'Valdez', '2004-11-13', 'M', '5624 Bonifacio St., Brgy. Buting, Pasig City', '+63922675748', 'jericho.valdez055@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 30 DAY + INTERVAL 39600 SECOND)),
  ('Liza C. Garcia', 'Liza', 'Cruz', 'Garcia', '2000-03-02', 'F', '1970 Roxas Ave., Brgy. Sumilang, Pasig City', '+63951461985', 'liza.garcia056@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 90 DAY + INTERVAL 50400 SECOND)),
  ('Imelda S. Sy', 'Imelda', 'Santos', 'Sy', '2003-02-15', 'F', '3486 Quezon Blvd., Brgy. Caniogan, Pasig City', '+63929642712', 'imelda.sy057@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 72 DAY + INTERVAL 61200 SECOND)),
  ('Nicole O. Reyes', 'Nicole', 'Ong', 'Reyes', '2003-07-30', 'F', '3568 Kalayaan Ave., Brgy. San Joaquin, Pasig City', '+63939133733', 'nicole.reyes058@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 90 DAY + INTERVAL 61200 SECOND)),
  ('Imelda G. Lim', 'Imelda', 'Garcia', 'Lim', '2004-10-09', 'F', '5018 Mabini Ave., Brgy. Buting, Pasig City', '+63954758507', 'imelda.lim059@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 66 DAY + INTERVAL 64800 SECOND)),
  ('Ana D. Del Rosario', 'Ana', 'Dela Cruz', 'Del Rosario', '2000-02-13', 'F', '3816 Mabini Ave., Brgy. San Joaquin, Pasig City', '+63927378201', 'ana.delrosario060@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 85 DAY + INTERVAL 43200 SECOND)),
  ('Mae G. Co', 'Mae', 'Gonzales', 'Co', '2008-04-11', 'F', '6948 Rizal St., Brgy. San Joaquin, Pasig City', '+63926069123', 'mae.co061@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 89 DAY + INTERVAL 64800 SECOND)),
  ('John V. Sy', 'John', 'Valdez', 'Sy', '2004-12-05', 'M', '1811 Rizal St., Brgy. Santolan, Pasig City', '+63992927448', 'john.sy062@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 45 DAY + INTERVAL 50400 SECOND)),
  ('Patricia S. Villanueva', 'Patricia', 'Soriano', 'Villanueva', '2002-11-15', 'F', '4766 M.L. Quezon St., Brgy. Sumilang, Pasig City', '+63991514066', 'patricia.villanueva063@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 89 DAY + INTERVAL 50400 SECOND)),
  ('Justin T. Lacson', 'Justin', 'Torres', 'Lacson', '2002-07-20', 'M', '3860 Roxas Ave., Brgy. Rosario, Pasig City', '+63995966533', 'justin.lacson064@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 111 DAY + INTERVAL 57600 SECOND)),
  ('Lyka T. Chua', 'Lyka', 'Tan', 'Chua', '2004-07-23', 'F', '1270 Roxas Ave., Brgy. Santolan, Pasig City', '+63974483133', 'lyka.chua065@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 69 DAY + INTERVAL 32400 SECOND)),
  ('Isabela V. Tan', 'Isabela', 'Villanueva', 'Tan', '2009-07-28', 'F', '1795 P. Burgos St., Brgy. Caniogan, Pasig City', '+63953266082', 'isabela.tan066@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 63 DAY + INTERVAL 57600 SECOND)),
  ('Miguel D. Gonzales', 'Miguel', 'Domingo', 'Gonzales', '2007-07-09', 'M', '3715 Aguinaldo St., Brgy. Pinagbuhatan, Pasig City', '+63982724467', 'miguel.gonzales067@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 103 DAY + INTERVAL 46800 SECOND)),
  ('Patrick M. Magsaysay', 'Patrick', 'Magsaysay', 'Magsaysay', '2008-12-11', 'M', '9988 P. Burgos St., Brgy. San Joaquin, Pasig City', '+63995452525', 'patrick.magsaysay068@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 60 DAY + INTERVAL 39600 SECOND)),
  ('Miguel E. Navarro', 'Miguel', 'Esguerra', 'Navarro', '2009-07-23', 'M', '564 Sumulong Hwy., Brgy. Santolan, Pasig City', '+63924137827', 'miguel.navarro069@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 79 DAY + INTERVAL 39600 SECOND)),
  ('Andrea P. Tomas', 'Andrea', 'Pineda', 'Tomas', '2009-10-18', 'F', '3037 Kalayaan Ave., Brgy. Buting, Pasig City', '+63973033395', 'andrea.tomas070@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 97 DAY + INTERVAL 50400 SECOND)),
  ('Adrian T. Cruz', 'Adrian', 'Torres', 'Cruz', '2006-12-03', 'M', '9901 Mabini Ave., Brgy. Sumilang, Pasig City', '+63958459159', 'adrian.cruz071@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 68 DAY + INTERVAL 43200 SECOND)),
  ('Faith R. Aquino', 'Faith', 'Reyes', 'Aquino', '2008-01-05', 'F', '7614 Rizal St., Brgy. Santolan, Pasig City', '+63957867507', 'faith.aquino072@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 117 DAY + INTERVAL 36000 SECOND)),
  ('Vincent P. Rodriguez', 'Vincent', 'Pineda', 'Rodriguez', '2000-07-11', 'M', '6798 M.L. Quezon St., Brgy. Maybunga, Pasig City', '+63978048419', 'vincent.rodriguez073@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 91 DAY + INTERVAL 39600 SECOND)),
  ('Renz M. Torres', 'Renz', 'Magsaysay', 'Torres', '2007-06-18', 'M', '3016 Aguinaldo St., Brgy. Rosario, Pasig City', '+63925496530', 'renz.torres074@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 107 DAY + INTERVAL 57600 SECOND)),
  ('Grace A. Ramos', 'Grace', 'Aguilar', 'Ramos', '2007-06-03', 'F', '2296 Roxas Ave., Brgy. Buting, Pasig City', '+63931986453', 'grace.ramos075@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 103 DAY + INTERVAL 46800 SECOND)),
  ('Faith E. Rodriguez', 'Faith', 'Esguerra', 'Rodriguez', '2009-01-18', 'F', '3135 Kalayaan Ave., Brgy. Bambang, Pasig City', '+63981882754', 'faith.rodriguez076@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 92 DAY + INTERVAL 36000 SECOND)),
  ('Pedro B. Santos', 'Pedro', 'Bautista', 'Santos', '2007-07-14', 'M', '2118 Aguinaldo St., Brgy. San Joaquin, Pasig City', '+63998356231', 'pedro.santos077@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 107 DAY + INTERVAL 46800 SECOND)),
  ('Lance M. Lacson', 'Lance', 'Magsaysay', 'Lacson', '2007-12-18', 'M', '8690 P. Burgos St., Brgy. Pinagbuhatan, Pasig City', '+63922842992', 'lance.lacson078@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 71 DAY + INTERVAL 54000 SECOND)),
  ('Mae H. Cruz', 'Mae', 'Hernandez', 'Cruz', '2001-02-09', 'F', '650 Aguinaldo St., Brgy. San Joaquin, Pasig City', '+63941882960', 'mae.cruz079@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 72 DAY + INTERVAL 36000 SECOND)),
  ('Liza H. Villanueva', 'Liza', 'Hernandez', 'Villanueva', '2000-06-12', 'F', '30 M.L. Quezon St., Brgy. Bambang, Pasig City', '+63918378731', 'liza.villanueva080@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 66 DAY + INTERVAL 46800 SECOND)),
  ('Ramon H. Chua', 'Ramon', 'Hernandez', 'Chua', '2007-10-21', 'M', '6963 Kalayaan Ave., Brgy. Caniogan, Pasig City', '+63934804286', 'ramon.chua081@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 60 DAY + INTERVAL 32400 SECOND)),
  ('Angelica R. Sy', 'Angelica', 'Rodriguez', 'Sy', '2008-02-10', 'F', '2071 Rizal St., Brgy. Caniogan, Pasig City', '+63985293587', 'angelica.sy082@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 69 DAY + INTERVAL 57600 SECOND)),
  ('Maria A. Yap', 'Maria', 'Aquino', 'Yap', '2000-01-18', 'F', '8521 M.L. Quezon St., Brgy. Maybunga, Pasig City', '+63957062490', 'maria.yap083@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 47 DAY + INTERVAL 64800 SECOND)),
  ('Isabel S. Esguerra', 'Isabel', 'Santos', 'Esguerra', '2008-12-15', 'F', '7228 Bonifacio St., Brgy. Buting, Pasig City', '+63987814459', 'isabel.esguerra084@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 95 DAY + INTERVAL 32400 SECOND)),
  ('Aaron G. Del Rosario', 'Aaron', 'Garcia', 'Del Rosario', '2009-07-03', 'M', '4208 Roxas Ave., Brgy. Pinagbuhatan, Pasig City', '+63986969906', 'aaron.delrosario085@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 78 DAY + INTERVAL 39600 SECOND)),
  ('John C. Yap', 'John', 'Castillo', 'Yap', '2006-09-09', 'M', '3055 Aguinaldo St., Brgy. Pinagbuhatan, Pasig City', '+63920727724', 'john.yap086@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 94 DAY + INTERVAL 54000 SECOND)),
  ('Aileen B. Soriano', 'Aileen', 'Bautista', 'Soriano', '2000-05-18', 'F', '3341 Aguinaldo St., Brgy. Santolan, Pasig City', '+63965733257', 'aileen.soriano087@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 77 DAY + INTERVAL 54000 SECOND)),
  ('Miguel V. Domingo', 'Miguel', 'Velasco', 'Domingo', '2007-08-08', 'M', '9536 Rizal St., Brgy. San Joaquin, Pasig City', '+63960656424', 'miguel.domingo088@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 81 DAY + INTERVAL 64800 SECOND)),
  ('Patricia V. Reyes', 'Patricia', 'Villanueva', 'Reyes', '2001-11-07', 'F', '294 Roxas Ave., Brgy. Pinagbuhatan, Pasig City', '+63974497828', 'patricia.reyes089@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 77 DAY + INTERVAL 43200 SECOND)),
  ('Rowena M. Del Rosario', 'Rowena', 'Magsaysay', 'Del Rosario', '2006-09-26', 'F', '8347 Quezon Blvd., Brgy. Manggahan, Pasig City', '+63987367777', 'rowena.delrosario090@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 64 DAY + INTERVAL 43200 SECOND)),
  ('Liwayway T. Pineda', 'Liwayway', 'Torres', 'Pineda', '2009-12-04', 'F', '1882 M.L. Quezon St., Brgy. Sumilang, Pasig City', '+63946912384', 'liwayway.pineda091@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 40 DAY + INTERVAL 57600 SECOND)),
  ('Gabriel T. Marquez', 'Gabriel', 'Tomas', 'Marquez', '2002-04-21', 'M', '7031 P. Burgos St., Brgy. Bambang, Pasig City', '+63928559414', 'gabriel.marquez092@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 76 DAY + INTERVAL 54000 SECOND)),
  ('Rowena A. Reyes', 'Rowena', 'Aguilar', 'Reyes', '2004-03-17', 'F', '5669 Quezon Blvd., Brgy. San Joaquin, Pasig City', '+63912790720', 'rowena.reyes093@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 115 DAY + INTERVAL 46800 SECOND)),
  ('Justin S. Santos', 'Justin', 'Sy', 'Santos', '2007-07-03', 'M', '4232 Sumulong Hwy., Brgy. Caniogan, Pasig City', '+63922424131', 'justin.santos094@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND)),
  ('Eduardo D. Ramos', 'Eduardo', 'Del Rosario', 'Ramos', '2008-02-29', 'M', '3785 Roxas Ave., Brgy. Sumilang, Pasig City', '+63975552200', 'eduardo.ramos095@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 44 DAY + INTERVAL 43200 SECOND)),
  ('Isabela P. Pineda', 'Isabela', 'Pangilinan', 'Pineda', '2003-10-07', 'F', '7078 Roxas Ave., Brgy. Pinagbuhatan, Pasig City', '+63954936327', 'isabela.pineda096@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 82 DAY + INTERVAL 46800 SECOND)),
  ('Carlos V. Tan', 'Carlos', 'Valdez', 'Tan', '2009-02-10', 'M', '8272 Mabini Ave., Brgy. San Joaquin, Pasig City', '+63938800873', 'carlos.tan097@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 60 DAY + INTERVAL 61200 SECOND)),
  ('Marco N. Del Rosario', 'Marco', 'Navarro', 'Del Rosario', '2007-09-02', 'M', '8705 Aguinaldo St., Brgy. Caniogan, Pasig City', '+63911077117', 'marco.delrosario098@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 102 DAY + INTERVAL 46800 SECOND)),
  ('Sherwin C. Velasco', 'Sherwin', 'Cruz', 'Velasco', '2009-03-20', 'M', '1451 Mabini Ave., Brgy. Caniogan, Pasig City', '+63947558357', 'sherwin.velasco099@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 43 DAY + INTERVAL 39600 SECOND)),
  ('Ronnel N. Cruz', 'Ronnel', 'Navarro', 'Cruz', '2004-01-16', 'M', '7868 Kalayaan Ave., Brgy. Maybunga, Pasig City', '+63995786856', 'ronnel.cruz100@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 61 DAY + INTERVAL 57600 SECOND)),
  ('Angelo L. Reyes', 'Angelo', 'Lacson', 'Reyes', '2003-08-28', 'M', '3141 Quezon Blvd., Brgy. Manggahan, Pasig City', '+63995184960', 'angelo.reyes101@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 115 DAY + INTERVAL 39600 SECOND)),
  ('Adrian M. Santos', 'Adrian', 'Manalo', 'Santos', '2003-07-30', 'M', '5332 P. Burgos St., Brgy. Maybunga, Pasig City', '+63922021522', 'adrian.santos102@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 77 DAY + INTERVAL 50400 SECOND)),
  ('Bea G. Domingo', 'Bea', 'Garcia', 'Domingo', '2005-05-25', 'F', '2498 M.L. Quezon St., Brgy. Maybunga, Pasig City', '+63937189543', 'bea.domingo103@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 65 DAY + INTERVAL 61200 SECOND)),
  ('Rafael D. Domingo', 'Rafael', 'Domingo', 'Domingo', '2008-08-28', 'M', '2538 Bonifacio St., Brgy. Maybunga, Pasig City', '+63927433299', 'rafael.domingo104@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 99 DAY + INTERVAL 36000 SECOND)),
  ('Christian C. Esguerra', 'Christian', 'Co', 'Esguerra', '2006-04-09', 'M', '2013 Mabini Ave., Brgy. Rosario, Pasig City', '+63949549796', 'christian.esguerra105@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 43 DAY + INTERVAL 39600 SECOND)),
  ('Earl A. Lim', 'Earl', 'Aguilar', 'Lim', '2008-07-28', 'M', '388 Aguinaldo St., Brgy. Manggahan, Pasig City', '+63910965847', 'earl.lim106@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 48 DAY + INTERVAL 32400 SECOND)),
  ('Liza P. Aquino', 'Liza', 'Pangilinan', 'Aquino', '2008-11-02', 'F', '2130 P. Burgos St., Brgy. Sumilang, Pasig City', '+63985347446', 'liza.aquino107@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 41 DAY + INTERVAL 57600 SECOND)),
  ('Divina D. Tan', 'Divina', 'Domingo', 'Tan', '2009-04-10', 'F', '106 Rizal St., Brgy. Pinagbuhatan, Pasig City', '+63918988105', 'divina.tan108@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 92 DAY + INTERVAL 50400 SECOND)),
  ('Charmaine B. Villanueva', 'Charmaine', 'Bautista', 'Villanueva', '2008-12-21', 'F', '6055 Bonifacio St., Brgy. Caniogan, Pasig City', '+63954439903', 'charmaine.villanueva109@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 67 DAY + INTERVAL 32400 SECOND)),
  ('Rafael Y. Dela Cruz', 'Rafael', 'Yap', 'Dela Cruz', '2004-08-04', 'M', '4960 P. Burgos St., Brgy. Rosario, Pasig City', '+63930044700', 'rafael.delacruz110@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 100 DAY + INTERVAL 61200 SECOND)),
  ('Pia Y. Lim', 'Pia', 'Yap', 'Lim', '2007-12-28', 'F', '8319 Kalayaan Ave., Brgy. Bambang, Pasig City', '+63944064297', 'pia.lim111@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 89 DAY + INTERVAL 61200 SECOND)),
  ('Patricia R. Aquino', 'Patricia', 'Rodriguez', 'Aquino', '2003-12-26', 'F', '7545 Bonifacio St., Brgy. Sumilang, Pasig City', '+63976630742', 'patricia.aquino112@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 109 DAY + INTERVAL 39600 SECOND)),
  ('John S. Velasco', 'John', 'Salazar', 'Velasco', '2008-03-06', 'M', '2950 Kalayaan Ave., Brgy. Pinagbuhatan, Pasig City', '+63914083632', 'john.velasco113@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 71 DAY + INTERVAL 32400 SECOND)),
  ('Lorenzo H. Ong', 'Lorenzo', 'Hernandez', 'Ong', '2009-01-16', 'M', '1891 Sumulong Hwy., Brgy. Caniogan, Pasig City', '+63936951066', 'lorenzo.ong114@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 57 DAY + INTERVAL 61200 SECOND)),
  ('Andres T. Hernandez', 'Andres', 'Tomas', 'Hernandez', '2002-03-03', 'M', '4376 Rizal St., Brgy. Maybunga, Pasig City', '+63956309040', 'andres.hernandez115@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 52 DAY + INTERVAL 39600 SECOND)),
  ('Maria C. Aquino', 'Maria', 'Chua', 'Aquino', '2006-03-06', 'F', '3910 Aguinaldo St., Brgy. Santolan, Pasig City', '+63985373060', 'maria.aquino116@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 120 DAY + INTERVAL 43200 SECOND)),
  ('Camille D. Cruz', 'Camille', 'Domingo', 'Cruz', '2009-08-29', 'F', '4676 Rizal St., Brgy. Manggahan, Pasig City', '+63991900355', 'camille.cruz117@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 80 DAY + INTERVAL 61200 SECOND)),
  ('Grace Y. Valdez', 'Grace', 'Yap', 'Valdez', '2005-12-22', 'F', '5738 Aguinaldo St., Brgy. Maybunga, Pasig City', '+63915330917', 'grace.valdez118@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 34 DAY + INTERVAL 64800 SECOND)),
  ('Kim R. Aguilar', 'Kim', 'Ramos', 'Aguilar', '2009-07-04', 'F', '4067 Aguinaldo St., Brgy. Bambang, Pasig City', '+63938235240', 'kim.aguilar119@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 98 DAY + INTERVAL 54000 SECOND)),
  ('Krizia V. Domingo', 'Krizia', 'Valdez', 'Domingo', '2003-05-13', 'F', '7310 Sumulong Hwy., Brgy. Caniogan, Pasig City', '+63934680762', 'krizia.domingo120@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 81 DAY + INTERVAL 50400 SECOND)),
  ('Jericho S. Garcia', 'Jericho', 'Santos', 'Garcia', '2001-02-13', 'M', '4377 M.L. Quezon St., Brgy. Maybunga, Pasig City', '+63921633643', 'jericho.garcia121@student.plp.edu.ph', '$2y$10$YA3cyxlq8B8rWC/RMV0U5uoZY1yaQMDsbC0L8cfJENJXjMFcpckSK', 'student', 1, 1, (CURDATE() + INTERVAL 85 DAY + INTERVAL 50400 SECOND));

-- 2. Applicants (one per demo user, linked via email lookup)
INSERT INTO `applicants` (`user_id`, `applicant_type`, `course_applied`, `shs_strand`, `overall_status`, `school_year`, `created_at`, `withdrawn_at`, `withdrawn_reason`, `documents_approved_at`) VALUES
  ((SELECT id FROM users WHERE email = 'maria.mendoza001@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'pending', '2026-2027', (CURDATE() + INTERVAL 56 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'janine.lacson002@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 'GAS', 'pending', '2026-2027', (CURDATE() + INTERVAL 62 DAY + INTERVAL 32400 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'bea.andrada003@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 'HUMSS', 'pending', '2026-2027', (CURDATE() + INTERVAL 97 DAY + INTERVAL 32400 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'faith.salazar004@student.plp.edu.ph'), 'transferee', 'BS Computer Science (BSCS)', NULL, 'pending', '2026-2027', (CURDATE() + INTERVAL 33 DAY + INTERVAL 50400 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'isabela.yap005@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'GAS', 'pending', '2026-2027', (CURDATE() + INTERVAL 51 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'hope.pineda006@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'GAS', 'pending', '2026-2027', (CURDATE() + INTERVAL 74 DAY + INTERVAL 61200 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'camille.aquino007@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'pending', '2026-2027', (CURDATE() + INTERVAL 78 DAY + INTERVAL 64800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'mark.rodriguez008@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'HUMSS', 'pending', '2026-2027', (CURDATE() + INTERVAL 70 DAY + INTERVAL 32400 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'lance.velasco009@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Mathematics (BSED-MATH)', 'HUMSS', 'pending', '2026-2027', (CURDATE() + INTERVAL 106 DAY + INTERVAL 57600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'bea.ramos010@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'pending', '2026-2027', (CURDATE() + INTERVAL 57 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'kris.delrosario011@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'HUMSS', 'documents', '2026-2027', (CURDATE() + INTERVAL 110 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'miguel.domingo012@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'GAS', 'documents', '2026-2027', (CURDATE() + INTERVAL 34 DAY + INTERVAL 46800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'earl.torres013@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'TVL-HE', 'documents', '2026-2027', (CURDATE() + INTERVAL 71 DAY + INTERVAL 64800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'mikaela.delacruz014@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'TVL-ICT', 'documents', '2026-2027', (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'kris.valdez015@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'documents', '2026-2027', (CURDATE() + INTERVAL 93 DAY + INTERVAL 39600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'imelda.delacruz016@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'documents', '2026-2027', (CURDATE() + INTERVAL 53 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'pedro.reyes017@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'documents', '2026-2027', (CURDATE() + INTERVAL 66 DAY + INTERVAL 61200 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'cherry.ramos018@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'documents', '2026-2027', (CURDATE() + INTERVAL 114 DAY + INTERVAL 57600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'mark.co019@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'HUMSS', 'documents', '2026-2027', (CURDATE() + INTERVAL 30 DAY + INTERVAL 61200 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'isabel.torres020@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Mathematics (BSED-MATH)', 'STEM', 'documents', '2026-2027', (CURDATE() + INTERVAL 78 DAY + INTERVAL 32400 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'joshua.magsaysay021@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'TVL-HE', 'documents', '2026-2027', (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'lourdes.chua022@student.plp.edu.ph'), 'transferee', 'BS Accountancy (BSA)', NULL, 'documents', '2026-2027', (CURDATE() + INTERVAL 67 DAY + INTERVAL 64800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'lourdes.santos023@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'HUMSS', 'documents', '2026-2027', (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'andres.soriano024@student.plp.edu.ph'), 'foreign', 'BS Information Technology (BSIT)', NULL, 'documents', '2026-2027', (CURDATE() + INTERVAL 65 DAY + INTERVAL 64800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'ronnel.garcia025@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'documents', '2026-2027', (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'jericho.torres026@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 85 DAY + INTERVAL 54000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'charmaine.tomas027@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 107 DAY + INTERVAL 43200 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'lourdes.lacson028@student.plp.edu.ph'), 'freshman', 'AB Psychology (AB Psych)', 'HUMSS', 'submitted', '2026-2027', (CURDATE() + INTERVAL 47 DAY + INTERVAL 39600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'justin.ong029@student.plp.edu.ph'), 'foreign', 'BS Electronics Engineering (BSECE)', NULL, 'submitted', '2026-2027', (CURDATE() + INTERVAL 46 DAY + INTERVAL 57600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'mark.esguerra030@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 50 DAY + INTERVAL 39600 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'ella.manalo031@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Mathematics (BSED-MATH)', 'HUMSS', 'submitted', '2026-2027', (CURDATE() + INTERVAL 54 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'vincent.chua032@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 40 DAY + INTERVAL 46800 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'jose.lacson033@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'angel.salazar034@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 32 DAY + INTERVAL 36000 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'eduardo.lim035@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'submitted', '2026-2027', (CURDATE() + INTERVAL 90 DAY + INTERVAL 61200 SECOND), NULL, NULL, NULL),
  ((SELECT id FROM users WHERE email = 'camille.ramos036@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 'HUMSS', 'exam', '2026-2027', (CURDATE() + INTERVAL 117 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 111 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'maria.gonzales037@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'HUMSS', 'exam', '2026-2027', (CURDATE() + INTERVAL 68 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 63 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'rico.co038@student.plp.edu.ph'), 'transferee', 'AB Psychology (AB Psych)', NULL, 'exam', '2026-2027', (CURDATE() + INTERVAL 103 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 101 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'lance.uy039@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 'HUMSS', 'exam', '2026-2027', (CURDATE() + INTERVAL 73 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 68 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'earl.sy040@student.plp.edu.ph'), 'transferee', 'Bachelor of Secondary Education Major in English (BSED-ENG)', NULL, 'exam', '2026-2027', (CURDATE() + INTERVAL 85 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 78 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'felix.magsaysay041@student.plp.edu.ph'), 'transferee', 'AB Psychology (AB Psych)', NULL, 'exam', '2026-2027', (CURDATE() + INTERVAL 87 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 83 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'christian.co042@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'exam', '2026-2027', (CURDATE() + INTERVAL 105 DAY + INTERVAL 54000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 102 DAY + INTERVAL 54000 SECOND)),
  ((SELECT id FROM users WHERE email = 'krizia.bautista043@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'exam', '2026-2027', (CURDATE() + INTERVAL 38 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 31 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'cherry.manalo044@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 111 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 109 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'juan.ramos045@student.plp.edu.ph'), 'transferee', 'AB Psychology (AB Psych)', NULL, 'exam', '2026-2027', (CURDATE() + INTERVAL 102 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'yna.tan046@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 75 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 71 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'mercedes.salazar047@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'exam', '2026-2027', (CURDATE() + INTERVAL 108 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 105 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'justin.delacruz048@student.plp.edu.ph'), 'transferee', 'BS Nursing (BSN)', NULL, 'exam', '2026-2027', (CURDATE() + INTERVAL 42 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 35 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'aileen.esguerra049@student.plp.edu.ph'), 'transferee', 'BS Nursing (BSN)', NULL, 'exam', '2026-2027', (CURDATE() + INTERVAL 32 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 30 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'lance.rodriguez050@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'exam', '2026-2027', (CURDATE() + INTERVAL 69 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 66 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'dominic.velasco051@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 70 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 67 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'andrea.velasco052@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 76 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 72 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'juan.delrosario053@student.plp.edu.ph'), 'freshman', 'BS Entrepreneurship (BSENT)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 48 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 42 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'kevin.villanueva054@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 101 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 94 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'jericho.valdez055@student.plp.edu.ph'), 'freshman', 'BS Entrepreneurship (BSENT)', 'ABM', 'exam', '2026-2027', (CURDATE() + INTERVAL 30 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 23 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'liza.garcia056@student.plp.edu.ph'), 'transferee', 'BS Computer Science (BSCS)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 90 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 85 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'imelda.sy057@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 72 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 65 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'nicole.reyes058@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 90 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 86 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'imelda.lim059@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 66 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 63 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'ana.delrosario060@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'HUMSS', 'interview', '2026-2027', (CURDATE() + INTERVAL 85 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 80 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'mae.co061@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 'HUMSS', 'interview', '2026-2027', (CURDATE() + INTERVAL 89 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 82 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'john.sy062@student.plp.edu.ph'), 'transferee', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 45 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 42 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'patricia.villanueva063@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 89 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 82 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'justin.lacson064@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 111 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 105 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'lyka.chua065@student.plp.edu.ph'), 'freshman', 'BS Entrepreneurship (BSENT)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 69 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 66 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'isabela.tan066@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 63 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 60 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'miguel.gonzales067@student.plp.edu.ph'), 'transferee', 'BS Information Technology (BSIT)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 103 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 100 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'patrick.magsaysay068@student.plp.edu.ph'), 'transferee', 'Bachelor of Elementary Education (BEED)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 60 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 54 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'miguel.navarro069@student.plp.edu.ph'), 'transferee', 'BS Electronics Engineering (BSECE)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 79 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 73 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'andrea.tomas070@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 97 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 93 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'adrian.cruz071@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 68 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 66 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'faith.aquino072@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 117 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 113 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'vincent.rodriguez073@student.plp.edu.ph'), 'transferee', 'AB Psychology (AB Psych)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 91 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 86 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'renz.torres074@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'TVL-ICT', 'interview', '2026-2027', (CURDATE() + INTERVAL 107 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 102 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'grace.ramos075@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 103 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 96 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'faith.rodriguez076@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'interview', '2026-2027', (CURDATE() + INTERVAL 92 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 86 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'pedro.santos077@student.plp.edu.ph'), 'transferee', 'BS Business Administration major in Marketing Management (BSBA)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 107 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 101 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'lance.lacson078@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 71 DAY + INTERVAL 54000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 54000 SECOND)),
  ((SELECT id FROM users WHERE email = 'mae.cruz079@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'interview', '2026-2027', (CURDATE() + INTERVAL 72 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 70 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'liza.villanueva080@student.plp.edu.ph'), 'transferee', 'BS Electronics Engineering (BSECE)', NULL, 'interview', '2026-2027', (CURDATE() + INTERVAL 66 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 62 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'ramon.chua081@student.plp.edu.ph'), 'transferee', 'AB Psychology (AB Psych)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 60 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 54 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'angelica.sy082@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 69 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 62 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'maria.yap083@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'HUMSS', 'released', '2026-2027', (CURDATE() + INTERVAL 47 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 41 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'isabel.esguerra084@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 95 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 91 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'aaron.delrosario085@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 78 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 74 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'john.yap086@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'TVL-ICT', 'released', '2026-2027', (CURDATE() + INTERVAL 94 DAY + INTERVAL 54000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 89 DAY + INTERVAL 54000 SECOND)),
  ((SELECT id FROM users WHERE email = 'aileen.soriano087@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 77 DAY + INTERVAL 54000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 71 DAY + INTERVAL 54000 SECOND)),
  ((SELECT id FROM users WHERE email = 'miguel.domingo088@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 81 DAY + INTERVAL 64800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 79 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'patricia.reyes089@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 'HUMSS', 'released', '2026-2027', (CURDATE() + INTERVAL 77 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 74 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'rowena.delrosario090@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 64 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'liwayway.pineda091@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 40 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'gabriel.marquez092@student.plp.edu.ph'), 'transferee', 'BS Business Administration major in Marketing Management (BSBA)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 76 DAY + INTERVAL 54000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 74 DAY + INTERVAL 54000 SECOND)),
  ((SELECT id FROM users WHERE email = 'rowena.reyes093@student.plp.edu.ph'), 'freshman', 'BS Information Technology (BSIT)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 115 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 109 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'justin.santos094@student.plp.edu.ph'), 'freshman', 'AB Psychology (AB Psych)', 'HUMSS', 'released', '2026-2027', (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 57 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'eduardo.ramos095@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 44 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 42 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'isabela.pineda096@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 82 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 75 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'carlos.tan097@student.plp.edu.ph'), 'freshman', 'BS Nursing (BSN)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 60 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 57 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'marco.delrosario098@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 102 DAY + INTERVAL 46800 SECOND), NULL, NULL, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT id FROM users WHERE email = 'sherwin.velasco099@student.plp.edu.ph'), 'foreign', 'BS Electronics Engineering (BSECE)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 43 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 41 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'ronnel.cruz100@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 61 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 56 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'angelo.reyes101@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 115 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 108 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'adrian.santos102@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Mathematics (BSED-MATH)', 'HUMSS', 'released', '2026-2027', (CURDATE() + INTERVAL 77 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 71 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'bea.domingo103@student.plp.edu.ph'), 'transferee', 'BS Information Technology (BSIT)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 65 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 61 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'rafael.domingo104@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 99 DAY + INTERVAL 36000 SECOND), NULL, NULL, (CURDATE() + INTERVAL 95 DAY + INTERVAL 36000 SECOND)),
  ((SELECT id FROM users WHERE email = 'christian.esguerra105@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'GAS', 'released', '2026-2027', (CURDATE() + INTERVAL 43 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 36 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'earl.lim106@student.plp.edu.ph'), 'freshman', 'BS Hospitality Management (BSHM)', 'TVL-HE', 'released', '2026-2027', (CURDATE() + INTERVAL 48 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 41 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'liza.aquino107@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in Mathematics (BSED-MATH)', 'GAS', 'released', '2026-2027', (CURDATE() + INTERVAL 41 DAY + INTERVAL 57600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 37 DAY + INTERVAL 57600 SECOND)),
  ((SELECT id FROM users WHERE email = 'divina.tan108@student.plp.edu.ph'), 'freshman', 'BS Electronics Engineering (BSECE)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 92 DAY + INTERVAL 50400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 90 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'charmaine.villanueva109@student.plp.edu.ph'), 'transferee', 'BS Accountancy (BSA)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 67 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 60 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'rafael.delacruz110@student.plp.edu.ph'), 'foreign', 'BS Electronics Engineering (BSECE)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 100 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 96 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'pia.lim111@student.plp.edu.ph'), 'freshman', 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'GAS', 'released', '2026-2027', (CURDATE() + INTERVAL 89 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 83 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'patricia.aquino112@student.plp.edu.ph'), 'freshman', 'AB Psychology (AB Psych)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 109 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 103 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'john.velasco113@student.plp.edu.ph'), 'foreign', 'BS Information Technology (BSIT)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 71 DAY + INTERVAL 32400 SECOND), NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 32400 SECOND)),
  ((SELECT id FROM users WHERE email = 'lorenzo.ong114@student.plp.edu.ph'), 'foreign', 'Bachelor of Secondary Education Major in English (BSED-ENG)', NULL, 'released', '2026-2027', (CURDATE() + INTERVAL 57 DAY + INTERVAL 61200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 51 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'andres.hernandez115@student.plp.edu.ph'), 'freshman', 'BS Entrepreneurship (BSENT)', 'ABM', 'released', '2026-2027', (CURDATE() + INTERVAL 52 DAY + INTERVAL 39600 SECOND), NULL, NULL, (CURDATE() + INTERVAL 46 DAY + INTERVAL 39600 SECOND)),
  ((SELECT id FROM users WHERE email = 'maria.aquino116@student.plp.edu.ph'), 'freshman', 'BS Computer Science (BSCS)', 'STEM', 'released', '2026-2027', (CURDATE() + INTERVAL 120 DAY + INTERVAL 43200 SECOND), NULL, NULL, (CURDATE() + INTERVAL 116 DAY + INTERVAL 43200 SECOND)),
  ((SELECT id FROM users WHERE email = 'camille.cruz117@student.plp.edu.ph'), 'transferee', 'BS Entrepreneurship (BSENT)', NULL, 'withdrawn', '2026-2027', (CURDATE() + INTERVAL 80 DAY + INTERVAL 61200 SECOND), (CURDATE() + INTERVAL 73 DAY + INTERVAL 61200 SECOND), 'Personal reasons.', (CURDATE() + INTERVAL 73 DAY + INTERVAL 61200 SECOND)),
  ((SELECT id FROM users WHERE email = 'grace.valdez118@student.plp.edu.ph'), 'freshman', 'BS Business Administration major in Marketing Management (BSBA)', 'ABM', 'withdrawn', '2026-2027', (CURDATE() + INTERVAL 34 DAY + INTERVAL 64800 SECOND), (CURDATE() + INTERVAL 10 DAY + INTERVAL 64800 SECOND), 'Personal reasons.', (CURDATE() + INTERVAL 32 DAY + INTERVAL 64800 SECOND)),
  ((SELECT id FROM users WHERE email = 'kim.aguilar119@student.plp.edu.ph'), 'freshman', 'BS Accountancy (BSA)', 'ABM', 'withdrawn', '2026-2027', (CURDATE() + INTERVAL 98 DAY + INTERVAL 54000 SECOND), (CURDATE() + INTERVAL 87 DAY + INTERVAL 54000 SECOND), 'Will defer to next school year.', (CURDATE() + INTERVAL 91 DAY + INTERVAL 54000 SECOND)),
  ((SELECT id FROM users WHERE email = 'krizia.domingo120@student.plp.edu.ph'), 'freshman', 'BS Entrepreneurship (BSENT)', 'ABM', 'withdrawn', '2026-2027', (CURDATE() + INTERVAL 81 DAY + INTERVAL 50400 SECOND), (CURDATE() + INTERVAL 74 DAY + INTERVAL 50400 SECOND), 'Personal reasons.', (CURDATE() + INTERVAL 78 DAY + INTERVAL 50400 SECOND)),
  ((SELECT id FROM users WHERE email = 'jericho.garcia121@student.plp.edu.ph'), 'freshman', 'Bachelor of Elementary Education (BEED)', 'HUMSS', 'withdrawn', '2026-2027', (CURDATE() + INTERVAL 85 DAY + INTERVAL 50400 SECOND), (CURDATE() + INTERVAL 68 DAY + INTERVAL 50400 SECOND), 'Decided to enroll at another university.', (CURDATE() + INTERVAL 81 DAY + INTERVAL 50400 SECOND));

-- Map applicant index → id via a temp table keyed on email
DROP TEMPORARY TABLE IF EXISTS _demo_app_ids;
CREATE TEMPORARY TABLE _demo_app_ids (
    idx INT UNSIGNED PRIMARY KEY,
    email VARCHAR(180) NOT NULL,
    applicant_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL
) ENGINE=Memory;
INSERT INTO _demo_app_ids (idx, email, applicant_id, user_id)
SELECT t.idx, t.email, a.id, u.id
FROM (
      SELECT 0 AS idx, 'maria.mendoza001@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 1 AS idx, 'janine.lacson002@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 2 AS idx, 'bea.andrada003@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 3 AS idx, 'faith.salazar004@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 4 AS idx, 'isabela.yap005@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 5 AS idx, 'hope.pineda006@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 6 AS idx, 'camille.aquino007@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 7 AS idx, 'mark.rodriguez008@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 8 AS idx, 'lance.velasco009@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 9 AS idx, 'bea.ramos010@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 10 AS idx, 'kris.delrosario011@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 11 AS idx, 'miguel.domingo012@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 12 AS idx, 'earl.torres013@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 13 AS idx, 'mikaela.delacruz014@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 14 AS idx, 'kris.valdez015@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 15 AS idx, 'imelda.delacruz016@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 16 AS idx, 'pedro.reyes017@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 17 AS idx, 'cherry.ramos018@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 18 AS idx, 'mark.co019@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 19 AS idx, 'isabel.torres020@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 20 AS idx, 'joshua.magsaysay021@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 21 AS idx, 'lourdes.chua022@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 22 AS idx, 'lourdes.santos023@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 23 AS idx, 'andres.soriano024@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 24 AS idx, 'ronnel.garcia025@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 25 AS idx, 'jericho.torres026@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 26 AS idx, 'charmaine.tomas027@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 27 AS idx, 'lourdes.lacson028@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 28 AS idx, 'justin.ong029@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 29 AS idx, 'mark.esguerra030@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 30 AS idx, 'ella.manalo031@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 31 AS idx, 'vincent.chua032@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 32 AS idx, 'jose.lacson033@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 33 AS idx, 'angel.salazar034@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 34 AS idx, 'eduardo.lim035@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 35 AS idx, 'camille.ramos036@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 36 AS idx, 'maria.gonzales037@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 37 AS idx, 'rico.co038@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 38 AS idx, 'lance.uy039@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 39 AS idx, 'earl.sy040@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 40 AS idx, 'felix.magsaysay041@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 41 AS idx, 'christian.co042@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 42 AS idx, 'krizia.bautista043@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 43 AS idx, 'cherry.manalo044@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 44 AS idx, 'juan.ramos045@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 45 AS idx, 'yna.tan046@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 46 AS idx, 'mercedes.salazar047@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 47 AS idx, 'justin.delacruz048@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 48 AS idx, 'aileen.esguerra049@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 49 AS idx, 'lance.rodriguez050@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 50 AS idx, 'dominic.velasco051@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 51 AS idx, 'andrea.velasco052@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 52 AS idx, 'juan.delrosario053@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 53 AS idx, 'kevin.villanueva054@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 54 AS idx, 'jericho.valdez055@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 55 AS idx, 'liza.garcia056@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 56 AS idx, 'imelda.sy057@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 57 AS idx, 'nicole.reyes058@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 58 AS idx, 'imelda.lim059@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 59 AS idx, 'ana.delrosario060@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 60 AS idx, 'mae.co061@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 61 AS idx, 'john.sy062@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 62 AS idx, 'patricia.villanueva063@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 63 AS idx, 'justin.lacson064@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 64 AS idx, 'lyka.chua065@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 65 AS idx, 'isabela.tan066@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 66 AS idx, 'miguel.gonzales067@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 67 AS idx, 'patrick.magsaysay068@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 68 AS idx, 'miguel.navarro069@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 69 AS idx, 'andrea.tomas070@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 70 AS idx, 'adrian.cruz071@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 71 AS idx, 'faith.aquino072@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 72 AS idx, 'vincent.rodriguez073@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 73 AS idx, 'renz.torres074@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 74 AS idx, 'grace.ramos075@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 75 AS idx, 'faith.rodriguez076@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 76 AS idx, 'pedro.santos077@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 77 AS idx, 'lance.lacson078@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 78 AS idx, 'mae.cruz079@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 79 AS idx, 'liza.villanueva080@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 80 AS idx, 'ramon.chua081@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 81 AS idx, 'angelica.sy082@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 82 AS idx, 'maria.yap083@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 83 AS idx, 'isabel.esguerra084@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 84 AS idx, 'aaron.delrosario085@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 85 AS idx, 'john.yap086@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 86 AS idx, 'aileen.soriano087@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 87 AS idx, 'miguel.domingo088@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 88 AS idx, 'patricia.reyes089@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 89 AS idx, 'rowena.delrosario090@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 90 AS idx, 'liwayway.pineda091@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 91 AS idx, 'gabriel.marquez092@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 92 AS idx, 'rowena.reyes093@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 93 AS idx, 'justin.santos094@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 94 AS idx, 'eduardo.ramos095@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 95 AS idx, 'isabela.pineda096@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 96 AS idx, 'carlos.tan097@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 97 AS idx, 'marco.delrosario098@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 98 AS idx, 'sherwin.velasco099@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 99 AS idx, 'ronnel.cruz100@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 100 AS idx, 'angelo.reyes101@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 101 AS idx, 'adrian.santos102@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 102 AS idx, 'bea.domingo103@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 103 AS idx, 'rafael.domingo104@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 104 AS idx, 'christian.esguerra105@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 105 AS idx, 'earl.lim106@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 106 AS idx, 'liza.aquino107@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 107 AS idx, 'divina.tan108@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 108 AS idx, 'charmaine.villanueva109@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 109 AS idx, 'rafael.delacruz110@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 110 AS idx, 'pia.lim111@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 111 AS idx, 'patricia.aquino112@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 112 AS idx, 'john.velasco113@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 113 AS idx, 'lorenzo.ong114@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 114 AS idx, 'andres.hernandez115@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 115 AS idx, 'maria.aquino116@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 116 AS idx, 'camille.cruz117@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 117 AS idx, 'grace.valdez118@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 118 AS idx, 'kim.aguilar119@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 119 AS idx, 'krizia.domingo120@student.plp.edu.ph' AS email
      UNION ALL
      SELECT 120 AS idx, 'jericho.garcia121@student.plp.edu.ph' AS email
) t
JOIN users u ON u.email = t.email
JOIN applicants a ON a.user_id = u.id;

-- 3. Documents — varying status per stage
INSERT INTO `documents` (`applicant_id`, `doc_type`, `file_path`, `status`, `staff_remarks`, `reviewed_by`, `updated_at`) VALUES
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'applicant_id', 'public/uploads/documents/1_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 51 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 53 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 50 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 47 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 52 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 55 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 0), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 55 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'applicant_id', 'public/uploads/documents/2_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 53 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 59 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 57 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 57 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 60 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 54 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 53 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 1), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 52 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'applicant_id', 'public/uploads/documents/3_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 95 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 88 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 87 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 96 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 90 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 87 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 96 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 2), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 92 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'applicant_id', 'public/uploads/documents/4_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 24 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 23 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 29 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 32 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 26 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 28 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'tor', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 31 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 3), 'good_moral', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 32 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'applicant_id', 'public/uploads/documents/5_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 49 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 41 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 47 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 45 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 45 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 47 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 45 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 4), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 47 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'applicant_id', 'public/uploads/documents/6_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 70 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 70 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 66 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 70 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 71 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 70 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 66 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 5), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'applicant_id', 'public/uploads/documents/7_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 77 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 74 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 73 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 76 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 73 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 77 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 71 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 6), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 70 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'applicant_id', 'public/uploads/documents/8_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 65 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 60 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 69 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 66 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 61 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 7), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 61 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'applicant_id', 'public/uploads/documents/9_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 103 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 98 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 103 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 98 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 100 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 102 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 104 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 8), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 104 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'applicant_id', 'public/uploads/documents/10_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 52 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 47 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 51 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 51 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'proof_of_income', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 50 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 50 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'form_138', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 54 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 9), 'form_137', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 47 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'applicant_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 100 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'psa_birth_cert', 'public/uploads/documents/11_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'passport_photos', 'public/uploads/documents/11_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'parent_id', 'public/uploads/documents/11_parent_id_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 105 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'proof_of_income', 'public/uploads/documents/11_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'guardianship_affidavit', 'public/uploads/documents/11_guardianship_affidavit_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'form_138', 'public/uploads/documents/11_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'form_137', 'public/uploads/documents/11_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 105 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'applicant_id', 'public/uploads/documents/12_applicant_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'psa_birth_cert', 'public/uploads/documents/12_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 26 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'passport_photos', 'public/uploads/documents/12_passport_photos_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 30 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'parent_id', 'public/uploads/documents/12_parent_id_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'proof_of_income', 'public/uploads/documents/12_proof_of_income_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'guardianship_affidavit', 'public/uploads/documents/12_guardianship_affidavit_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 24 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'form_138', 'public/uploads/documents/12_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 26 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'form_137', 'public/uploads/documents/12_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 29 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'applicant_id', 'public/uploads/documents/13_applicant_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'psa_birth_cert', 'public/uploads/documents/13_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 65 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'parent_id', 'public/uploads/documents/13_parent_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 68 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'proof_of_income', 'public/uploads/documents/13_proof_of_income_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'guardianship_affidavit', 'public/uploads/documents/13_guardianship_affidavit_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'form_138', 'public/uploads/documents/13_form_138_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 12), 'form_137', 'public/uploads/documents/13_form_137_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 67 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'applicant_id', 'public/uploads/documents/14_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'psa_birth_cert', 'public/uploads/documents/14_psa_birth_cert_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 41 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'passport_photos', 'public/uploads/documents/14_passport_photos_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 40 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'parent_id', 'public/uploads/documents/14_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'proof_of_income', 'public/uploads/documents/14_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'guardianship_affidavit', 'public/uploads/documents/14_guardianship_affidavit_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 47 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'form_138', 'public/uploads/documents/14_form_138_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 13), 'form_137', 'public/uploads/documents/14_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'applicant_id', 'public/uploads/documents/15_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 83 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'psa_birth_cert', 'public/uploads/documents/15_psa_birth_cert_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 92 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'passport_photos', 'public/uploads/documents/15_passport_photos_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'parent_id', 'public/uploads/documents/15_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 89 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'proof_of_income', 'public/uploads/documents/15_proof_of_income_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'guardianship_affidavit', 'public/uploads/documents/15_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'form_138', 'public/uploads/documents/15_form_138_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 14), 'form_137', 'public/uploads/documents/15_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'applicant_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 49 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'psa_birth_cert', 'public/uploads/documents/16_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 45 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'passport_photos', 'public/uploads/documents/16_passport_photos_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'parent_id', 'public/uploads/documents/16_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 52 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'proof_of_income', 'public/uploads/documents/16_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 52 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'guardianship_affidavit', 'public/uploads/documents/16_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'form_138', 'public/uploads/documents/16_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 15), 'form_137', 'public/uploads/documents/16_form_137_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 45 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'applicant_id', 'public/uploads/documents/17_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 56 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'psa_birth_cert', 'public/uploads/documents/17_psa_birth_cert_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 58 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'passport_photos', 'public/uploads/documents/17_passport_photos_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'parent_id', 'public/uploads/documents/17_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'proof_of_income', 'public/uploads/documents/17_proof_of_income_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 58 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'guardianship_affidavit', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 64 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'form_138', 'public/uploads/documents/17_form_138_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 62 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 16), 'form_137', 'public/uploads/documents/17_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'applicant_id', 'public/uploads/documents/18_applicant_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 109 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'psa_birth_cert', 'public/uploads/documents/18_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 113 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'passport_photos', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 107 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'parent_id', 'public/uploads/documents/18_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 111 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'proof_of_income', 'public/uploads/documents/18_proof_of_income_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 113 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'guardianship_affidavit', 'public/uploads/documents/18_guardianship_affidavit_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 107 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'form_138', 'public/uploads/documents/18_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'form_137', 'public/uploads/documents/18_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'applicant_id', 'public/uploads/documents/19_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 20 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'psa_birth_cert', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 26 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'passport_photos', 'public/uploads/documents/19_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 28 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'parent_id', 'public/uploads/documents/19_parent_id_demo.png', 'rejected', 'Image is blurred; please re-upload a clear copy.', 2, (CURDATE() + INTERVAL 22 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'proof_of_income', 'public/uploads/documents/19_proof_of_income_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 27 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'guardianship_affidavit', 'public/uploads/documents/19_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 22 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'form_138', 'public/uploads/documents/19_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 18), 'form_137', 'public/uploads/documents/19_form_137_demo.png', 'rejected', 'Wrong document — please upload the correct file.', 2, (CURDATE() + INTERVAL 19 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'applicant_id', 'public/uploads/documents/20_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'psa_birth_cert', 'public/uploads/documents/20_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'passport_photos', 'public/uploads/documents/20_passport_photos_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'parent_id', 'public/uploads/documents/20_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'proof_of_income', 'public/uploads/documents/20_proof_of_income_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 72 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'guardianship_affidavit', 'public/uploads/documents/20_guardianship_affidavit_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'form_138', 'public/uploads/documents/20_form_138_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 19), 'form_137', 'public/uploads/documents/20_form_137_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'applicant_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 27 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'psa_birth_cert', 'public/uploads/documents/21_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'passport_photos', 'public/uploads/documents/21_passport_photos_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 25 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'parent_id', 'public/uploads/documents/21_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'proof_of_income', 'public/uploads/documents/21_proof_of_income_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 30 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'guardianship_affidavit', 'public/uploads/documents/21_guardianship_affidavit_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 27 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'form_138', 'public/uploads/documents/21_form_138_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 24 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'form_137', 'public/uploads/documents/21_form_137_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 30 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'applicant_id', 'public/uploads/documents/22_applicant_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'psa_birth_cert', 'public/uploads/documents/22_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'passport_photos', 'public/uploads/documents/22_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'parent_id', 'public/uploads/documents/22_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'proof_of_income', 'public/uploads/documents/22_proof_of_income_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'guardianship_affidavit', 'public/uploads/documents/22_guardianship_affidavit_demo.png', 'rejected', 'Wrong document — please upload the correct file.', 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'tor', 'public/uploads/documents/22_tor_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 21), 'good_moral', 'public/uploads/documents/22_good_moral_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'applicant_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 39 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'psa_birth_cert', 'public/uploads/documents/23_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 45 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'passport_photos', 'public/uploads/documents/23_passport_photos_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'parent_id', 'public/uploads/documents/23_parent_id_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 43 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'proof_of_income', 'public/uploads/documents/23_proof_of_income_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 43 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'guardianship_affidavit', 'public/uploads/documents/23_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'form_138', 'public/uploads/documents/23_form_138_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 22), 'form_137', 'public/uploads/documents/23_form_137_demo.png', 'rejected', 'Document is not signed; resubmit a notarized copy.', 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'applicant_id', 'public/uploads/documents/24_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'psa_birth_cert', 'public/uploads/documents/24_psa_birth_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'passport_photos', 'public/uploads/documents/24_passport_photos_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 60 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'parent_id', NULL, 'pending', NULL, NULL, (CURDATE() + INTERVAL 58 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'proof_of_income', 'public/uploads/documents/24_proof_of_income_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 56 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'guardianship_affidavit', 'public/uploads/documents/24_guardianship_affidavit_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 63 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'tor', 'public/uploads/documents/24_tor_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'good_moral', 'public/uploads/documents/24_good_moral_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'passport', 'public/uploads/documents/24_passport_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'visa_permit', 'public/uploads/documents/24_visa_permit_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 58 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 23), 'alien_cert', 'public/uploads/documents/24_alien_cert_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'applicant_id', 'public/uploads/documents/25_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'psa_birth_cert', 'public/uploads/documents/25_psa_birth_cert_demo.png', 'rejected', 'Wrong document — please upload the correct file.', 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'passport_photos', 'public/uploads/documents/25_passport_photos_demo.png', 'under_review', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'parent_id', 'public/uploads/documents/25_parent_id_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 92 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'proof_of_income', 'public/uploads/documents/25_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 90 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'guardianship_affidavit', 'public/uploads/documents/25_guardianship_affidavit_demo.png', 'rejected', 'Wrong document — please upload the correct file.', 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'form_138', 'public/uploads/documents/25_form_138_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 95 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'form_137', 'public/uploads/documents/25_form_137_demo.png', 'uploaded', NULL, NULL, (CURDATE() + INTERVAL 95 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'applicant_id', 'public/uploads/documents/26_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'psa_birth_cert', 'public/uploads/documents/26_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'passport_photos', 'public/uploads/documents/26_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'parent_id', 'public/uploads/documents/26_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'proof_of_income', 'public/uploads/documents/26_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'guardianship_affidavit', 'public/uploads/documents/26_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'form_138', 'public/uploads/documents/26_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 25), 'form_137', 'public/uploads/documents/26_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'applicant_id', 'public/uploads/documents/27_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'psa_birth_cert', 'public/uploads/documents/27_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'passport_photos', 'public/uploads/documents/27_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'parent_id', 'public/uploads/documents/27_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'proof_of_income', 'public/uploads/documents/27_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'guardianship_affidavit', 'public/uploads/documents/27_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'form_138', 'public/uploads/documents/27_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 26), 'form_137', 'public/uploads/documents/27_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 104 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'applicant_id', 'public/uploads/documents/28_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'psa_birth_cert', 'public/uploads/documents/28_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'passport_photos', 'public/uploads/documents/28_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'parent_id', 'public/uploads/documents/28_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'proof_of_income', 'public/uploads/documents/28_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'guardianship_affidavit', 'public/uploads/documents/28_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'form_138', 'public/uploads/documents/28_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 27), 'form_137', 'public/uploads/documents/28_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'applicant_id', 'public/uploads/documents/29_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'psa_birth_cert', 'public/uploads/documents/29_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'passport_photos', 'public/uploads/documents/29_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'parent_id', 'public/uploads/documents/29_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'proof_of_income', 'public/uploads/documents/29_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'guardianship_affidavit', 'public/uploads/documents/29_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'tor', 'public/uploads/documents/29_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'good_moral', 'public/uploads/documents/29_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'passport', 'public/uploads/documents/29_passport_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'visa_permit', 'public/uploads/documents/29_visa_permit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 28), 'alien_cert', 'public/uploads/documents/29_alien_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'applicant_id', 'public/uploads/documents/30_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'psa_birth_cert', 'public/uploads/documents/30_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'passport_photos', 'public/uploads/documents/30_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'parent_id', 'public/uploads/documents/30_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'proof_of_income', 'public/uploads/documents/30_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'guardianship_affidavit', 'public/uploads/documents/30_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'form_138', 'public/uploads/documents/30_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 29), 'form_137', 'public/uploads/documents/30_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'applicant_id', 'public/uploads/documents/31_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'psa_birth_cert', 'public/uploads/documents/31_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'passport_photos', 'public/uploads/documents/31_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'parent_id', 'public/uploads/documents/31_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'proof_of_income', 'public/uploads/documents/31_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'guardianship_affidavit', 'public/uploads/documents/31_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'form_138', 'public/uploads/documents/31_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 30), 'form_137', 'public/uploads/documents/31_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'applicant_id', 'public/uploads/documents/32_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'psa_birth_cert', 'public/uploads/documents/32_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'passport_photos', 'public/uploads/documents/32_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'parent_id', 'public/uploads/documents/32_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 30 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'proof_of_income', 'public/uploads/documents/32_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'guardianship_affidavit', 'public/uploads/documents/32_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'form_138', 'public/uploads/documents/32_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 31), 'form_137', 'public/uploads/documents/32_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'applicant_id', 'public/uploads/documents/33_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'psa_birth_cert', 'public/uploads/documents/33_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'passport_photos', 'public/uploads/documents/33_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'parent_id', 'public/uploads/documents/33_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'proof_of_income', 'public/uploads/documents/33_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'guardianship_affidavit', 'public/uploads/documents/33_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'form_138', 'public/uploads/documents/33_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 32), 'form_137', 'public/uploads/documents/33_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'applicant_id', 'public/uploads/documents/34_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 26 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'psa_birth_cert', 'public/uploads/documents/34_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'passport_photos', 'public/uploads/documents/34_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 27 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'parent_id', 'public/uploads/documents/34_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'proof_of_income', 'public/uploads/documents/34_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'guardianship_affidavit', 'public/uploads/documents/34_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 30 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'form_138', 'public/uploads/documents/34_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 26 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 33), 'form_137', 'public/uploads/documents/34_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 22 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'applicant_id', 'public/uploads/documents/35_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'psa_birth_cert', 'public/uploads/documents/35_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'passport_photos', 'public/uploads/documents/35_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'parent_id', 'public/uploads/documents/35_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'proof_of_income', 'public/uploads/documents/35_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'guardianship_affidavit', 'public/uploads/documents/35_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'form_138', 'public/uploads/documents/35_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 34), 'form_137', 'public/uploads/documents/35_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'applicant_id', 'public/uploads/documents/36_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 108 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'psa_birth_cert', 'public/uploads/documents/36_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 111 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'passport_photos', 'public/uploads/documents/36_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 112 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'parent_id', 'public/uploads/documents/36_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'proof_of_income', 'public/uploads/documents/36_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'guardianship_affidavit', 'public/uploads/documents/36_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 108 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'form_138', 'public/uploads/documents/36_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 114 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 'form_137', 'public/uploads/documents/36_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'applicant_id', 'public/uploads/documents/37_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'psa_birth_cert', 'public/uploads/documents/37_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'passport_photos', 'public/uploads/documents/37_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'parent_id', 'public/uploads/documents/37_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'proof_of_income', 'public/uploads/documents/37_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'guardianship_affidavit', 'public/uploads/documents/37_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'form_138', 'public/uploads/documents/37_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 'form_137', 'public/uploads/documents/37_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'applicant_id', 'public/uploads/documents/38_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'psa_birth_cert', 'public/uploads/documents/38_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'passport_photos', 'public/uploads/documents/38_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'parent_id', 'public/uploads/documents/38_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'proof_of_income', 'public/uploads/documents/38_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'guardianship_affidavit', 'public/uploads/documents/38_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'tor', 'public/uploads/documents/38_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 'good_moral', 'public/uploads/documents/38_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'applicant_id', 'public/uploads/documents/39_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'psa_birth_cert', 'public/uploads/documents/39_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'passport_photos', 'public/uploads/documents/39_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'parent_id', 'public/uploads/documents/39_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'proof_of_income', 'public/uploads/documents/39_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'guardianship_affidavit', 'public/uploads/documents/39_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'form_138', 'public/uploads/documents/39_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 'form_137', 'public/uploads/documents/39_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'applicant_id', 'public/uploads/documents/40_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'psa_birth_cert', 'public/uploads/documents/40_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'passport_photos', 'public/uploads/documents/40_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'parent_id', 'public/uploads/documents/40_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'proof_of_income', 'public/uploads/documents/40_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'guardianship_affidavit', 'public/uploads/documents/40_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'tor', 'public/uploads/documents/40_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 'good_moral', 'public/uploads/documents/40_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'applicant_id', 'public/uploads/documents/41_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'psa_birth_cert', 'public/uploads/documents/41_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'passport_photos', 'public/uploads/documents/41_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'parent_id', 'public/uploads/documents/41_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'proof_of_income', 'public/uploads/documents/41_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'guardianship_affidavit', 'public/uploads/documents/41_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'tor', 'public/uploads/documents/41_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), 'good_moral', 'public/uploads/documents/41_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'applicant_id', 'public/uploads/documents/42_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'psa_birth_cert', 'public/uploads/documents/42_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'passport_photos', 'public/uploads/documents/42_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'parent_id', 'public/uploads/documents/42_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'proof_of_income', 'public/uploads/documents/42_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'guardianship_affidavit', 'public/uploads/documents/42_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'form_138', 'public/uploads/documents/42_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 'form_137', 'public/uploads/documents/42_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'applicant_id', 'public/uploads/documents/43_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'psa_birth_cert', 'public/uploads/documents/43_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'passport_photos', 'public/uploads/documents/43_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'parent_id', 'public/uploads/documents/43_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'proof_of_income', 'public/uploads/documents/43_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'guardianship_affidavit', 'public/uploads/documents/43_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'form_138', 'public/uploads/documents/43_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 29 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 'form_137', 'public/uploads/documents/43_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 34 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'applicant_id', 'public/uploads/documents/44_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'psa_birth_cert', 'public/uploads/documents/44_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'passport_photos', 'public/uploads/documents/44_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'parent_id', 'public/uploads/documents/44_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'proof_of_income', 'public/uploads/documents/44_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 108 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'guardianship_affidavit', 'public/uploads/documents/44_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'form_138', 'public/uploads/documents/44_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 'form_137', 'public/uploads/documents/44_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'applicant_id', 'public/uploads/documents/45_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'psa_birth_cert', 'public/uploads/documents/45_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'passport_photos', 'public/uploads/documents/45_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'parent_id', 'public/uploads/documents/45_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'proof_of_income', 'public/uploads/documents/45_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'guardianship_affidavit', 'public/uploads/documents/45_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'tor', 'public/uploads/documents/45_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), 'good_moral', 'public/uploads/documents/45_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'applicant_id', 'public/uploads/documents/46_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'psa_birth_cert', 'public/uploads/documents/46_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'passport_photos', 'public/uploads/documents/46_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'parent_id', 'public/uploads/documents/46_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'proof_of_income', 'public/uploads/documents/46_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'guardianship_affidavit', 'public/uploads/documents/46_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'form_138', 'public/uploads/documents/46_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 'form_137', 'public/uploads/documents/46_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'applicant_id', 'public/uploads/documents/47_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'psa_birth_cert', 'public/uploads/documents/47_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 104 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'passport_photos', 'public/uploads/documents/47_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'parent_id', 'public/uploads/documents/47_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 104 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'proof_of_income', 'public/uploads/documents/47_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'guardianship_affidavit', 'public/uploads/documents/47_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'form_138', 'public/uploads/documents/47_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 'form_137', 'public/uploads/documents/47_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'applicant_id', 'public/uploads/documents/48_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'psa_birth_cert', 'public/uploads/documents/48_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'passport_photos', 'public/uploads/documents/48_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'parent_id', 'public/uploads/documents/48_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'proof_of_income', 'public/uploads/documents/48_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'guardianship_affidavit', 'public/uploads/documents/48_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'tor', 'public/uploads/documents/48_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 'good_moral', 'public/uploads/documents/48_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'applicant_id', 'public/uploads/documents/49_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'psa_birth_cert', 'public/uploads/documents/49_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 30 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'passport_photos', 'public/uploads/documents/49_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 28 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'parent_id', 'public/uploads/documents/49_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'proof_of_income', 'public/uploads/documents/49_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 29 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'guardianship_affidavit', 'public/uploads/documents/49_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 31 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'tor', 'public/uploads/documents/49_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 31 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 'good_moral', 'public/uploads/documents/49_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'applicant_id', 'public/uploads/documents/50_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'psa_birth_cert', 'public/uploads/documents/50_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'passport_photos', 'public/uploads/documents/50_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'parent_id', 'public/uploads/documents/50_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'proof_of_income', 'public/uploads/documents/50_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'guardianship_affidavit', 'public/uploads/documents/50_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'form_138', 'public/uploads/documents/50_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 'form_137', 'public/uploads/documents/50_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'applicant_id', 'public/uploads/documents/51_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'psa_birth_cert', 'public/uploads/documents/51_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'passport_photos', 'public/uploads/documents/51_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'parent_id', 'public/uploads/documents/51_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'proof_of_income', 'public/uploads/documents/51_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'guardianship_affidavit', 'public/uploads/documents/51_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'form_138', 'public/uploads/documents/51_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 'form_137', 'public/uploads/documents/51_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'applicant_id', 'public/uploads/documents/52_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'psa_birth_cert', 'public/uploads/documents/52_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'passport_photos', 'public/uploads/documents/52_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'parent_id', 'public/uploads/documents/52_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'proof_of_income', 'public/uploads/documents/52_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'guardianship_affidavit', 'public/uploads/documents/52_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'form_138', 'public/uploads/documents/52_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 'form_137', 'public/uploads/documents/52_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'applicant_id', 'public/uploads/documents/53_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'psa_birth_cert', 'public/uploads/documents/53_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'passport_photos', 'public/uploads/documents/53_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 47 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'parent_id', 'public/uploads/documents/53_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'proof_of_income', 'public/uploads/documents/53_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'guardianship_affidavit', 'public/uploads/documents/53_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'form_138', 'public/uploads/documents/53_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 'form_137', 'public/uploads/documents/53_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'applicant_id', 'public/uploads/documents/54_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'psa_birth_cert', 'public/uploads/documents/54_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'passport_photos', 'public/uploads/documents/54_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'parent_id', 'public/uploads/documents/54_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'proof_of_income', 'public/uploads/documents/54_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'guardianship_affidavit', 'public/uploads/documents/54_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'form_138', 'public/uploads/documents/54_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), 'form_137', 'public/uploads/documents/54_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'applicant_id', 'public/uploads/documents/55_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'psa_birth_cert', 'public/uploads/documents/55_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 28 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'passport_photos', 'public/uploads/documents/55_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 29 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'parent_id', 'public/uploads/documents/55_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'proof_of_income', 'public/uploads/documents/55_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'guardianship_affidavit', 'public/uploads/documents/55_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 20 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'form_138', 'public/uploads/documents/55_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 20 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 'form_137', 'public/uploads/documents/55_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 21 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'applicant_id', 'public/uploads/documents/56_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 89 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'psa_birth_cert', 'public/uploads/documents/56_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 89 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'passport_photos', 'public/uploads/documents/56_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'parent_id', 'public/uploads/documents/56_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'proof_of_income', 'public/uploads/documents/56_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'guardianship_affidavit', 'public/uploads/documents/56_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'tor', 'public/uploads/documents/56_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 'good_moral', 'public/uploads/documents/56_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'applicant_id', 'public/uploads/documents/57_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'psa_birth_cert', 'public/uploads/documents/57_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'passport_photos', 'public/uploads/documents/57_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'parent_id', 'public/uploads/documents/57_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'proof_of_income', 'public/uploads/documents/57_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'guardianship_affidavit', 'public/uploads/documents/57_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'form_138', 'public/uploads/documents/57_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 'form_137', 'public/uploads/documents/57_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'applicant_id', 'public/uploads/documents/58_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'psa_birth_cert', 'public/uploads/documents/58_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'passport_photos', 'public/uploads/documents/58_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'parent_id', 'public/uploads/documents/58_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'proof_of_income', 'public/uploads/documents/58_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'guardianship_affidavit', 'public/uploads/documents/58_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'form_138', 'public/uploads/documents/58_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 'form_137', 'public/uploads/documents/58_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'applicant_id', 'public/uploads/documents/59_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'psa_birth_cert', 'public/uploads/documents/59_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'passport_photos', 'public/uploads/documents/59_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'parent_id', 'public/uploads/documents/59_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'proof_of_income', 'public/uploads/documents/59_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'guardianship_affidavit', 'public/uploads/documents/59_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'form_138', 'public/uploads/documents/59_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 'form_137', 'public/uploads/documents/59_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'applicant_id', 'public/uploads/documents/60_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'psa_birth_cert', 'public/uploads/documents/60_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'passport_photos', 'public/uploads/documents/60_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'parent_id', 'public/uploads/documents/60_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'proof_of_income', 'public/uploads/documents/60_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'guardianship_affidavit', 'public/uploads/documents/60_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'form_138', 'public/uploads/documents/60_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 'form_137', 'public/uploads/documents/60_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'applicant_id', 'public/uploads/documents/61_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'psa_birth_cert', 'public/uploads/documents/61_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'passport_photos', 'public/uploads/documents/61_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'parent_id', 'public/uploads/documents/61_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'proof_of_income', 'public/uploads/documents/61_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'guardianship_affidavit', 'public/uploads/documents/61_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'form_138', 'public/uploads/documents/61_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 'form_137', 'public/uploads/documents/61_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'applicant_id', 'public/uploads/documents/62_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'psa_birth_cert', 'public/uploads/documents/62_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'passport_photos', 'public/uploads/documents/62_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'parent_id', 'public/uploads/documents/62_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'proof_of_income', 'public/uploads/documents/62_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'guardianship_affidavit', 'public/uploads/documents/62_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'tor', 'public/uploads/documents/62_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 'good_moral', 'public/uploads/documents/62_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'applicant_id', 'public/uploads/documents/63_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'psa_birth_cert', 'public/uploads/documents/63_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'passport_photos', 'public/uploads/documents/63_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'parent_id', 'public/uploads/documents/63_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'proof_of_income', 'public/uploads/documents/63_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'guardianship_affidavit', 'public/uploads/documents/63_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'form_138', 'public/uploads/documents/63_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 'form_137', 'public/uploads/documents/63_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'applicant_id', 'public/uploads/documents/64_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'psa_birth_cert', 'public/uploads/documents/64_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'passport_photos', 'public/uploads/documents/64_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 104 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'parent_id', 'public/uploads/documents/64_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'proof_of_income', 'public/uploads/documents/64_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 105 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'guardianship_affidavit', 'public/uploads/documents/64_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 102 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'form_138', 'public/uploads/documents/64_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 'form_137', 'public/uploads/documents/64_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'applicant_id', 'public/uploads/documents/65_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'psa_birth_cert', 'public/uploads/documents/65_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'passport_photos', 'public/uploads/documents/65_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'parent_id', 'public/uploads/documents/65_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'proof_of_income', 'public/uploads/documents/65_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'guardianship_affidavit', 'public/uploads/documents/65_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'form_138', 'public/uploads/documents/65_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 'form_137', 'public/uploads/documents/65_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 66 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'applicant_id', 'public/uploads/documents/66_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'psa_birth_cert', 'public/uploads/documents/66_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'passport_photos', 'public/uploads/documents/66_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'parent_id', 'public/uploads/documents/66_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'proof_of_income', 'public/uploads/documents/66_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 53 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'guardianship_affidavit', 'public/uploads/documents/66_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'form_138', 'public/uploads/documents/66_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 'form_137', 'public/uploads/documents/66_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'applicant_id', 'public/uploads/documents/67_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'psa_birth_cert', 'public/uploads/documents/67_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'passport_photos', 'public/uploads/documents/67_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'parent_id', 'public/uploads/documents/67_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'proof_of_income', 'public/uploads/documents/67_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'guardianship_affidavit', 'public/uploads/documents/67_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'tor', 'public/uploads/documents/67_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 'good_moral', 'public/uploads/documents/67_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'applicant_id', 'public/uploads/documents/68_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'psa_birth_cert', 'public/uploads/documents/68_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'passport_photos', 'public/uploads/documents/68_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'parent_id', 'public/uploads/documents/68_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'proof_of_income', 'public/uploads/documents/68_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'guardianship_affidavit', 'public/uploads/documents/68_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'tor', 'public/uploads/documents/68_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 'good_moral', 'public/uploads/documents/68_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 53 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'applicant_id', 'public/uploads/documents/69_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'psa_birth_cert', 'public/uploads/documents/69_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'passport_photos', 'public/uploads/documents/69_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'parent_id', 'public/uploads/documents/69_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'proof_of_income', 'public/uploads/documents/69_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'guardianship_affidavit', 'public/uploads/documents/69_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'tor', 'public/uploads/documents/69_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 'good_moral', 'public/uploads/documents/69_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'applicant_id', 'public/uploads/documents/70_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'psa_birth_cert', 'public/uploads/documents/70_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'passport_photos', 'public/uploads/documents/70_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'parent_id', 'public/uploads/documents/70_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'proof_of_income', 'public/uploads/documents/70_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'guardianship_affidavit', 'public/uploads/documents/70_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'form_138', 'public/uploads/documents/70_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 89 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 'form_137', 'public/uploads/documents/70_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'applicant_id', 'public/uploads/documents/71_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'psa_birth_cert', 'public/uploads/documents/71_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'passport_photos', 'public/uploads/documents/71_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'parent_id', 'public/uploads/documents/71_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'proof_of_income', 'public/uploads/documents/71_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'guardianship_affidavit', 'public/uploads/documents/71_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'form_138', 'public/uploads/documents/71_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 66 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 'form_137', 'public/uploads/documents/71_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'applicant_id', 'public/uploads/documents/72_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 112 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'psa_birth_cert', 'public/uploads/documents/72_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'passport_photos', 'public/uploads/documents/72_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 114 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'parent_id', 'public/uploads/documents/72_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 114 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'proof_of_income', 'public/uploads/documents/72_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 113 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'guardianship_affidavit', 'public/uploads/documents/72_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'form_138', 'public/uploads/documents/72_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 'form_137', 'public/uploads/documents/72_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 116 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'applicant_id', 'public/uploads/documents/73_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'psa_birth_cert', 'public/uploads/documents/73_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'passport_photos', 'public/uploads/documents/73_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'parent_id', 'public/uploads/documents/73_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'proof_of_income', 'public/uploads/documents/73_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'guardianship_affidavit', 'public/uploads/documents/73_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 90 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'tor', 'public/uploads/documents/73_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 'good_moral', 'public/uploads/documents/73_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'applicant_id', 'public/uploads/documents/74_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 96 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'psa_birth_cert', 'public/uploads/documents/74_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'passport_photos', 'public/uploads/documents/74_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 105 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'parent_id', 'public/uploads/documents/74_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'proof_of_income', 'public/uploads/documents/74_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 105 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'guardianship_affidavit', 'public/uploads/documents/74_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'form_138', 'public/uploads/documents/74_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 'form_137', 'public/uploads/documents/74_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'applicant_id', 'public/uploads/documents/75_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'psa_birth_cert', 'public/uploads/documents/75_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'passport_photos', 'public/uploads/documents/75_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'parent_id', 'public/uploads/documents/75_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'proof_of_income', 'public/uploads/documents/75_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'guardianship_affidavit', 'public/uploads/documents/75_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'form_138', 'public/uploads/documents/75_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 'form_137', 'public/uploads/documents/75_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'applicant_id', 'public/uploads/documents/76_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'psa_birth_cert', 'public/uploads/documents/76_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'passport_photos', 'public/uploads/documents/76_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'parent_id', 'public/uploads/documents/76_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'proof_of_income', 'public/uploads/documents/76_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'guardianship_affidavit', 'public/uploads/documents/76_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'form_138', 'public/uploads/documents/76_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 'form_137', 'public/uploads/documents/76_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'applicant_id', 'public/uploads/documents/77_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'psa_birth_cert', 'public/uploads/documents/77_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'passport_photos', 'public/uploads/documents/77_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'parent_id', 'public/uploads/documents/77_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 104 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'proof_of_income', 'public/uploads/documents/77_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 102 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'guardianship_affidavit', 'public/uploads/documents/77_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'tor', 'public/uploads/documents/77_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 'good_moral', 'public/uploads/documents/77_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 102 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'applicant_id', 'public/uploads/documents/78_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'psa_birth_cert', 'public/uploads/documents/78_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'passport_photos', 'public/uploads/documents/78_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'parent_id', 'public/uploads/documents/78_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'proof_of_income', 'public/uploads/documents/78_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'guardianship_affidavit', 'public/uploads/documents/78_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'form_138', 'public/uploads/documents/78_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 'form_137', 'public/uploads/documents/78_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'applicant_id', 'public/uploads/documents/79_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'psa_birth_cert', 'public/uploads/documents/79_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'passport_photos', 'public/uploads/documents/79_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'parent_id', 'public/uploads/documents/79_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'proof_of_income', 'public/uploads/documents/79_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'guardianship_affidavit', 'public/uploads/documents/79_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'form_138', 'public/uploads/documents/79_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 'form_137', 'public/uploads/documents/79_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'applicant_id', 'public/uploads/documents/80_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'psa_birth_cert', 'public/uploads/documents/80_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'passport_photos', 'public/uploads/documents/80_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'parent_id', 'public/uploads/documents/80_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'proof_of_income', 'public/uploads/documents/80_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'guardianship_affidavit', 'public/uploads/documents/80_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'tor', 'public/uploads/documents/80_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 'good_moral', 'public/uploads/documents/80_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'applicant_id', 'public/uploads/documents/81_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'psa_birth_cert', 'public/uploads/documents/81_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'passport_photos', 'public/uploads/documents/81_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'parent_id', 'public/uploads/documents/81_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 52 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'proof_of_income', 'public/uploads/documents/81_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'guardianship_affidavit', 'public/uploads/documents/81_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'tor', 'public/uploads/documents/81_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 52 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'good_moral', 'public/uploads/documents/81_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'applicant_id', 'public/uploads/documents/82_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 66 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'psa_birth_cert', 'public/uploads/documents/82_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'passport_photos', 'public/uploads/documents/82_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'parent_id', 'public/uploads/documents/82_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'proof_of_income', 'public/uploads/documents/82_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'guardianship_affidavit', 'public/uploads/documents/82_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'form_138', 'public/uploads/documents/82_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 61 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'form_137', 'public/uploads/documents/82_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'applicant_id', 'public/uploads/documents/83_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'psa_birth_cert', 'public/uploads/documents/83_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'passport_photos', 'public/uploads/documents/83_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'parent_id', 'public/uploads/documents/83_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'proof_of_income', 'public/uploads/documents/83_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 45 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'guardianship_affidavit', 'public/uploads/documents/83_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'form_138', 'public/uploads/documents/83_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 43 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'form_137', 'public/uploads/documents/83_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 45 DAY + INTERVAL 7200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'applicant_id', 'public/uploads/documents/84_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'psa_birth_cert', 'public/uploads/documents/84_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 90 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'passport_photos', 'public/uploads/documents/84_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'parent_id', 'public/uploads/documents/84_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'proof_of_income', 'public/uploads/documents/84_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'guardianship_affidavit', 'public/uploads/documents/84_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'form_138', 'public/uploads/documents/84_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'form_137', 'public/uploads/documents/84_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'applicant_id', 'public/uploads/documents/85_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'psa_birth_cert', 'public/uploads/documents/85_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'passport_photos', 'public/uploads/documents/85_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'parent_id', 'public/uploads/documents/85_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'proof_of_income', 'public/uploads/documents/85_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'guardianship_affidavit', 'public/uploads/documents/85_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'form_138', 'public/uploads/documents/85_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'form_137', 'public/uploads/documents/85_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'applicant_id', 'public/uploads/documents/86_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'psa_birth_cert', 'public/uploads/documents/86_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'passport_photos', 'public/uploads/documents/86_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'parent_id', 'public/uploads/documents/86_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'proof_of_income', 'public/uploads/documents/86_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'guardianship_affidavit', 'public/uploads/documents/86_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'form_138', 'public/uploads/documents/86_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 85 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'form_137', 'public/uploads/documents/86_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'applicant_id', 'public/uploads/documents/87_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'psa_birth_cert', 'public/uploads/documents/87_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'passport_photos', 'public/uploads/documents/87_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'parent_id', 'public/uploads/documents/87_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'proof_of_income', 'public/uploads/documents/87_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'guardianship_affidavit', 'public/uploads/documents/87_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'form_138', 'public/uploads/documents/87_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'form_137', 'public/uploads/documents/87_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'applicant_id', 'public/uploads/documents/88_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'psa_birth_cert', 'public/uploads/documents/88_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'passport_photos', 'public/uploads/documents/88_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'parent_id', 'public/uploads/documents/88_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'proof_of_income', 'public/uploads/documents/88_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'guardianship_affidavit', 'public/uploads/documents/88_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'form_138', 'public/uploads/documents/88_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'form_137', 'public/uploads/documents/88_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'applicant_id', 'public/uploads/documents/89_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'psa_birth_cert', 'public/uploads/documents/89_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'passport_photos', 'public/uploads/documents/89_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'parent_id', 'public/uploads/documents/89_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'proof_of_income', 'public/uploads/documents/89_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'guardianship_affidavit', 'public/uploads/documents/89_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'form_138', 'public/uploads/documents/89_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'form_137', 'public/uploads/documents/89_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'applicant_id', 'public/uploads/documents/90_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'psa_birth_cert', 'public/uploads/documents/90_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'passport_photos', 'public/uploads/documents/90_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'parent_id', 'public/uploads/documents/90_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'proof_of_income', 'public/uploads/documents/90_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'guardianship_affidavit', 'public/uploads/documents/90_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'form_138', 'public/uploads/documents/90_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'form_137', 'public/uploads/documents/90_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'applicant_id', 'public/uploads/documents/91_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'psa_birth_cert', 'public/uploads/documents/91_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'passport_photos', 'public/uploads/documents/91_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 31 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'parent_id', 'public/uploads/documents/91_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 31 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'proof_of_income', 'public/uploads/documents/91_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'guardianship_affidavit', 'public/uploads/documents/91_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'form_138', 'public/uploads/documents/91_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'form_137', 'public/uploads/documents/91_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'applicant_id', 'public/uploads/documents/92_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'psa_birth_cert', 'public/uploads/documents/92_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'passport_photos', 'public/uploads/documents/92_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'parent_id', 'public/uploads/documents/92_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'proof_of_income', 'public/uploads/documents/92_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'guardianship_affidavit', 'public/uploads/documents/92_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'tor', 'public/uploads/documents/92_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 67 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'good_moral', 'public/uploads/documents/92_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'applicant_id', 'public/uploads/documents/93_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 114 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'psa_birth_cert', 'public/uploads/documents/93_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 108 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'passport_photos', 'public/uploads/documents/93_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'parent_id', 'public/uploads/documents/93_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 105 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'proof_of_income', 'public/uploads/documents/93_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 107 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'guardianship_affidavit', 'public/uploads/documents/93_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 113 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'form_138', 'public/uploads/documents/93_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 108 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'form_137', 'public/uploads/documents/93_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'applicant_id', 'public/uploads/documents/94_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'psa_birth_cert', 'public/uploads/documents/94_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'passport_photos', 'public/uploads/documents/94_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'parent_id', 'public/uploads/documents/94_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'proof_of_income', 'public/uploads/documents/94_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'guardianship_affidavit', 'public/uploads/documents/94_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'form_138', 'public/uploads/documents/94_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'form_137', 'public/uploads/documents/94_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'applicant_id', 'public/uploads/documents/95_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'psa_birth_cert', 'public/uploads/documents/95_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'passport_photos', 'public/uploads/documents/95_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'parent_id', 'public/uploads/documents/95_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 43 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'proof_of_income', 'public/uploads/documents/95_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 38 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'guardianship_affidavit', 'public/uploads/documents/95_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'form_138', 'public/uploads/documents/95_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'form_137', 'public/uploads/documents/95_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 43 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'applicant_id', 'public/uploads/documents/96_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'psa_birth_cert', 'public/uploads/documents/96_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 72 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'passport_photos', 'public/uploads/documents/96_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'parent_id', 'public/uploads/documents/96_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'proof_of_income', 'public/uploads/documents/96_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'guardianship_affidavit', 'public/uploads/documents/96_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'form_138', 'public/uploads/documents/96_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 81 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'form_137', 'public/uploads/documents/96_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'applicant_id', 'public/uploads/documents/97_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'psa_birth_cert', 'public/uploads/documents/97_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'passport_photos', 'public/uploads/documents/97_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'parent_id', 'public/uploads/documents/97_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 52 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'proof_of_income', 'public/uploads/documents/97_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'guardianship_affidavit', 'public/uploads/documents/97_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 53 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'form_138', 'public/uploads/documents/97_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'form_137', 'public/uploads/documents/97_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'applicant_id', 'public/uploads/documents/98_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'psa_birth_cert', 'public/uploads/documents/98_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'passport_photos', 'public/uploads/documents/98_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 96 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'parent_id', 'public/uploads/documents/98_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'proof_of_income', 'public/uploads/documents/98_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 101 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'guardianship_affidavit', 'public/uploads/documents/98_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'form_138', 'public/uploads/documents/98_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'form_137', 'public/uploads/documents/98_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'applicant_id', 'public/uploads/documents/99_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'psa_birth_cert', 'public/uploads/documents/99_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'passport_photos', 'public/uploads/documents/99_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'parent_id', 'public/uploads/documents/99_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'proof_of_income', 'public/uploads/documents/99_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 34 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'guardianship_affidavit', 'public/uploads/documents/99_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 34 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'tor', 'public/uploads/documents/99_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'good_moral', 'public/uploads/documents/99_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'passport', 'public/uploads/documents/99_passport_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'visa_permit', 'public/uploads/documents/99_visa_permit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'alien_cert', 'public/uploads/documents/99_alien_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'applicant_id', 'public/uploads/documents/100_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'psa_birth_cert', 'public/uploads/documents/100_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'passport_photos', 'public/uploads/documents/100_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'parent_id', 'public/uploads/documents/100_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'proof_of_income', 'public/uploads/documents/100_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 53 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'guardianship_affidavit', 'public/uploads/documents/100_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'form_138', 'public/uploads/documents/100_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 53 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'form_137', 'public/uploads/documents/100_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'applicant_id', 'public/uploads/documents/101_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'psa_birth_cert', 'public/uploads/documents/101_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 114 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'passport_photos', 'public/uploads/documents/101_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'parent_id', 'public/uploads/documents/101_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'proof_of_income', 'public/uploads/documents/101_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 109 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'guardianship_affidavit', 'public/uploads/documents/101_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'form_138', 'public/uploads/documents/101_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 112 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'form_137', 'public/uploads/documents/101_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 108 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'applicant_id', 'public/uploads/documents/102_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 69 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'psa_birth_cert', 'public/uploads/documents/102_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 71 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'passport_photos', 'public/uploads/documents/102_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'parent_id', 'public/uploads/documents/102_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'proof_of_income', 'public/uploads/documents/102_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'guardianship_affidavit', 'public/uploads/documents/102_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'form_138', 'public/uploads/documents/102_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'form_137', 'public/uploads/documents/102_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 73 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'applicant_id', 'public/uploads/documents/103_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'psa_birth_cert', 'public/uploads/documents/103_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'passport_photos', 'public/uploads/documents/103_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'parent_id', 'public/uploads/documents/103_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'proof_of_income', 'public/uploads/documents/103_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'guardianship_affidavit', 'public/uploads/documents/103_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 58 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'tor', 'public/uploads/documents/103_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'good_moral', 'public/uploads/documents/103_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'applicant_id', 'public/uploads/documents/104_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'psa_birth_cert', 'public/uploads/documents/104_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'passport_photos', 'public/uploads/documents/104_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 89 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'parent_id', 'public/uploads/documents/104_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'proof_of_income', 'public/uploads/documents/104_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'guardianship_affidavit', 'public/uploads/documents/104_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'form_138', 'public/uploads/documents/104_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 93 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'form_137', 'public/uploads/documents/104_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'applicant_id', 'public/uploads/documents/105_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'psa_birth_cert', 'public/uploads/documents/105_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'passport_photos', 'public/uploads/documents/105_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 39 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'parent_id', 'public/uploads/documents/105_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 34 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'proof_of_income', 'public/uploads/documents/105_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'guardianship_affidavit', 'public/uploads/documents/105_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'form_138', 'public/uploads/documents/105_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 34 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'form_137', 'public/uploads/documents/105_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'applicant_id', 'public/uploads/documents/106_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'psa_birth_cert', 'public/uploads/documents/106_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 43 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'passport_photos', 'public/uploads/documents/106_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'parent_id', 'public/uploads/documents/106_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 42 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'proof_of_income', 'public/uploads/documents/106_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 40 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'guardianship_affidavit', 'public/uploads/documents/106_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 47 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'form_138', 'public/uploads/documents/106_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 43 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'form_137', 'public/uploads/documents/106_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 41 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'applicant_id', 'public/uploads/documents/107_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'psa_birth_cert', 'public/uploads/documents/107_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'passport_photos', 'public/uploads/documents/107_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 34 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'parent_id', 'public/uploads/documents/107_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 36 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'proof_of_income', 'public/uploads/documents/107_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'guardianship_affidavit', 'public/uploads/documents/107_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 37 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'form_138', 'public/uploads/documents/107_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 32 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'form_137', 'public/uploads/documents/107_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 35 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'applicant_id', 'public/uploads/documents/108_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'psa_birth_cert', 'public/uploads/documents/108_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'passport_photos', 'public/uploads/documents/108_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'parent_id', 'public/uploads/documents/108_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 82 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'proof_of_income', 'public/uploads/documents/108_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'guardianship_affidavit', 'public/uploads/documents/108_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'form_138', 'public/uploads/documents/108_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'form_137', 'public/uploads/documents/108_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'applicant_id', 'public/uploads/documents/109_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 60 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'psa_birth_cert', 'public/uploads/documents/109_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'passport_photos', 'public/uploads/documents/109_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'parent_id', 'public/uploads/documents/109_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 63 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'proof_of_income', 'public/uploads/documents/109_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'guardianship_affidavit', 'public/uploads/documents/109_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'tor', 'public/uploads/documents/109_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 59 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'good_moral', 'public/uploads/documents/109_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 57 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'applicant_id', 'public/uploads/documents/110_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 90 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'psa_birth_cert', 'public/uploads/documents/110_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'passport_photos', 'public/uploads/documents/110_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'parent_id', 'public/uploads/documents/110_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 96 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'proof_of_income', 'public/uploads/documents/110_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 90 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'guardianship_affidavit', 'public/uploads/documents/110_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 94 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'tor', 'public/uploads/documents/110_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'good_moral', 'public/uploads/documents/110_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 90 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'passport', 'public/uploads/documents/110_passport_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 91 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'visa_permit', 'public/uploads/documents/110_visa_permit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'alien_cert', 'public/uploads/documents/110_alien_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 98 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'applicant_id', 'public/uploads/documents/111_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'psa_birth_cert', 'public/uploads/documents/111_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'passport_photos', 'public/uploads/documents/111_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'parent_id', 'public/uploads/documents/111_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'proof_of_income', 'public/uploads/documents/111_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 84 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'guardianship_affidavit', 'public/uploads/documents/111_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 86 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'form_138', 'public/uploads/documents/111_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'form_137', 'public/uploads/documents/111_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 87 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'applicant_id', 'public/uploads/documents/112_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'psa_birth_cert', 'public/uploads/documents/112_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 100 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'passport_photos', 'public/uploads/documents/112_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 99 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'parent_id', 'public/uploads/documents/112_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'proof_of_income', 'public/uploads/documents/112_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'guardianship_affidavit', 'public/uploads/documents/112_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 106 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'form_138', 'public/uploads/documents/112_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 103 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'form_137', 'public/uploads/documents/112_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 105 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'applicant_id', 'public/uploads/documents/113_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'psa_birth_cert', 'public/uploads/documents/113_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'passport_photos', 'public/uploads/documents/113_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'parent_id', 'public/uploads/documents/113_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 68 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'proof_of_income', 'public/uploads/documents/113_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 66 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'guardianship_affidavit', 'public/uploads/documents/113_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'tor', 'public/uploads/documents/113_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'good_moral', 'public/uploads/documents/113_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 64 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'passport', 'public/uploads/documents/113_passport_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 65 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'visa_permit', 'public/uploads/documents/113_visa_permit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 66 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'alien_cert', 'public/uploads/documents/113_alien_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 62 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'applicant_id', 'public/uploads/documents/114_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 52 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'psa_birth_cert', 'public/uploads/documents/114_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'passport_photos', 'public/uploads/documents/114_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'parent_id', 'public/uploads/documents/114_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'proof_of_income', 'public/uploads/documents/114_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 56 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'guardianship_affidavit', 'public/uploads/documents/114_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'tor', 'public/uploads/documents/114_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 55 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'good_moral', 'public/uploads/documents/114_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'passport', 'public/uploads/documents/114_passport_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 48 DAY + INTERVAL 3600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'visa_permit', 'public/uploads/documents/114_visa_permit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'alien_cert', 'public/uploads/documents/114_alien_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 54 DAY)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'applicant_id', 'public/uploads/documents/115_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'psa_birth_cert', 'public/uploads/documents/115_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'passport_photos', 'public/uploads/documents/115_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'parent_id', 'public/uploads/documents/115_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 49 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'proof_of_income', 'public/uploads/documents/115_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 51 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'guardianship_affidavit', 'public/uploads/documents/115_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 46 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'form_138', 'public/uploads/documents/115_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 50 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'form_137', 'public/uploads/documents/115_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 44 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'applicant_id', 'public/uploads/documents/116_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 112 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'psa_birth_cert', 'public/uploads/documents/116_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 118 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'passport_photos', 'public/uploads/documents/116_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 117 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'parent_id', 'public/uploads/documents/116_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 115 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'proof_of_income', 'public/uploads/documents/116_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 111 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'guardianship_affidavit', 'public/uploads/documents/116_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 117 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'form_138', 'public/uploads/documents/116_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 118 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'form_137', 'public/uploads/documents/116_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 110 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'applicant_id', 'public/uploads/documents/117_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'psa_birth_cert', 'public/uploads/documents/117_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 78 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'passport_photos', 'public/uploads/documents/117_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'parent_id', 'public/uploads/documents/117_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'proof_of_income', 'public/uploads/documents/117_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'guardianship_affidavit', 'public/uploads/documents/117_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'tor', 'public/uploads/documents/117_tor_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 70 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 116), 'good_moral', 'public/uploads/documents/117_good_moral_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'applicant_id', 'public/uploads/documents/118_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 29 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'psa_birth_cert', 'public/uploads/documents/118_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 26 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'passport_photos', 'public/uploads/documents/118_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'parent_id', 'public/uploads/documents/118_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 27 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'proof_of_income', 'public/uploads/documents/118_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 29 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'guardianship_affidavit', 'public/uploads/documents/118_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 33 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'form_138', 'public/uploads/documents/118_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 117), 'form_137', 'public/uploads/documents/118_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 26 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'applicant_id', 'public/uploads/documents/119_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'psa_birth_cert', 'public/uploads/documents/119_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'passport_photos', 'public/uploads/documents/119_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'parent_id', 'public/uploads/documents/119_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 88 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'proof_of_income', 'public/uploads/documents/119_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 97 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'guardianship_affidavit', 'public/uploads/documents/119_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 95 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'form_138', 'public/uploads/documents/119_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 92 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 118), 'form_137', 'public/uploads/documents/119_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 96 DAY + INTERVAL 82800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'applicant_id', 'public/uploads/documents/120_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'psa_birth_cert', 'public/uploads/documents/120_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 79 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'passport_photos', 'public/uploads/documents/120_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'parent_id', 'public/uploads/documents/120_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 74 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'proof_of_income', 'public/uploads/documents/120_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 72000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'guardianship_affidavit', 'public/uploads/documents/120_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'form_138', 'public/uploads/documents/120_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 119), 'form_137', 'public/uploads/documents/120_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'applicant_id', 'public/uploads/documents/121_applicant_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 83 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'psa_birth_cert', 'public/uploads/documents/121_psa_birth_cert_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'passport_photos', 'public/uploads/documents/121_passport_photos_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'parent_id', 'public/uploads/documents/121_parent_id_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'proof_of_income', 'public/uploads/documents/121_proof_of_income_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 75 DAY + INTERVAL 75600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'guardianship_affidavit', 'public/uploads/documents/121_guardianship_affidavit_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 76 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'form_138', 'public/uploads/documents/121_form_138_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 80 DAY + INTERVAL 79200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 120), 'form_137', 'public/uploads/documents/121_form_137_demo.png', 'approved', NULL, 2, (CURDATE() + INTERVAL 77 DAY + INTERVAL 57600 SECOND));

-- 4. Demo exam (single row referenced by exam_results)
INSERT INTO `exams` (`id`, `title`, `description`, `passing_score`, `is_active`) VALUES (1, 'PLP Entrance Exam (Demo)', 'Auto-generated demo exam for the seed_demo data set.', 50, 1)
ON DUPLICATE KEY UPDATE title = VALUES(title);

-- 5. Exam rooms
INSERT INTO `exam_slot_schedule` (`exam_id`, `exam_date`, `slot_time`, `end_time`, `room_label`, `department`, `capacity`, `filled`, `school_year`, `created_by`, `created_at`) VALUES
  (1, (CURDATE() - INTERVAL 15 DAY), '08:00:00', '09:30:00', 'Rm-01', 'College of Computer Studies', 35, 6, '2026-2027', 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 15 DAY), '08:00:00', '09:30:00', 'Rm-02', 'College of Nursing', 35, 3, '2026-2027', 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 15 DAY), '08:00:00', '09:30:00', 'Rm-03', 'College of Business and Accountancy', 35, 8, '2026-2027', 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 15 DAY), '08:00:00', '09:30:00', 'Rm-04', 'College of Education', 35, 6, '2026-2027', 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 15 DAY), '08:00:00', '09:30:00', 'Rm-05', 'College of Arts and Sciences', 35, 2, '2026-2027', 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 15 DAY), '08:00:00', '09:30:00', 'Rm-06', 'College of Engineering', 35, 3, '2026-2027', 2, (CURDATE() + INTERVAL 25 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 14 DAY), '08:00:00', '09:30:00', 'Rm-07', 'College of Computer Studies', 35, 5, '2026-2027', 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 14 DAY), '08:00:00', '09:30:00', 'Rm-08', 'College of Nursing', 35, 3, '2026-2027', 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 14 DAY), '08:00:00', '09:30:00', 'Rm-09', 'College of Business and Accountancy', 35, 8, '2026-2027', 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 14 DAY), '08:00:00', '09:30:00', 'Rm-10', 'College of Education', 35, 5, '2026-2027', 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 14 DAY), '08:00:00', '09:30:00', 'Rm-11', 'College of Arts and Sciences', 35, 2, '2026-2027', 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 14 DAY), '08:00:00', '09:30:00', 'Rm-12', 'College of Engineering', 35, 3, '2026-2027', 2, (CURDATE() + INTERVAL 24 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 13 DAY), '08:00:00', '09:30:00', 'Rm-13', 'College of Computer Studies', 35, 5, '2026-2027', 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 13 DAY), '08:00:00', '09:30:00', 'Rm-14', 'College of Nursing', 35, 2, '2026-2027', 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 13 DAY), '08:00:00', '09:30:00', 'Rm-15', 'College of Business and Accountancy', 35, 8, '2026-2027', 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 13 DAY), '08:00:00', '09:30:00', 'Rm-16', 'College of Education', 35, 5, '2026-2027', 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 13 DAY), '08:00:00', '09:30:00', 'Rm-17', 'College of Arts and Sciences', 35, 1, '2026-2027', 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() - INTERVAL 13 DAY), '08:00:00', '09:30:00', 'Rm-18', 'College of Engineering', 35, 3, '2026-2027', 2, (CURDATE() + INTERVAL 23 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 2 DAY), '09:00:00', '10:30:00', 'Rm-19', 'College of Computer Studies', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 8 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 2 DAY), '09:00:00', '10:30:00', 'Rm-20', 'College of Nursing', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 8 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 2 DAY), '09:00:00', '10:30:00', 'Rm-21', 'College of Business and Accountancy', 35, 1, '2026-2027', 2, (CURDATE() + INTERVAL 8 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 2 DAY), '09:00:00', '10:30:00', 'Rm-22', 'College of Education', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 8 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 2 DAY), '09:00:00', '10:30:00', 'Rm-23', 'College of Arts and Sciences', 35, 1, '2026-2027', 2, (CURDATE() + INTERVAL 8 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 2 DAY), '09:00:00', '10:30:00', 'Rm-24', 'College of Engineering', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 8 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 3 DAY), '09:00:00', '10:30:00', 'Rm-25', 'College of Computer Studies', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 3 DAY), '09:00:00', '10:30:00', 'Rm-26', 'College of Nursing', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 3 DAY), '09:00:00', '10:30:00', 'Rm-27', 'College of Business and Accountancy', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 3 DAY), '09:00:00', '10:30:00', 'Rm-28', 'College of Education', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 3 DAY), '09:00:00', '10:30:00', 'Rm-29', 'College of Arts and Sciences', 35, 1, '2026-2027', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (1, (CURDATE() + INTERVAL 3 DAY), '09:00:00', '10:30:00', 'Rm-30', 'College of Engineering', 35, 0, '2026-2027', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND));

DROP TEMPORARY TABLE IF EXISTS _demo_exam_rooms;
CREATE TEMPORARY TABLE _demo_exam_rooms (
    local_id INT UNSIGNED PRIMARY KEY,
    room_label VARCHAR(80) NOT NULL,
    db_id INT UNSIGNED NOT NULL
) ENGINE=Memory;
INSERT INTO _demo_exam_rooms (local_id, room_label, db_id)
SELECT t.local_id, t.room_label, ess.id FROM (
      SELECT 1 AS local_id, 'Rm-01' AS room_label
      UNION ALL
      SELECT 2 AS local_id, 'Rm-02' AS room_label
      UNION ALL
      SELECT 3 AS local_id, 'Rm-03' AS room_label
      UNION ALL
      SELECT 4 AS local_id, 'Rm-04' AS room_label
      UNION ALL
      SELECT 5 AS local_id, 'Rm-05' AS room_label
      UNION ALL
      SELECT 6 AS local_id, 'Rm-06' AS room_label
      UNION ALL
      SELECT 7 AS local_id, 'Rm-07' AS room_label
      UNION ALL
      SELECT 8 AS local_id, 'Rm-08' AS room_label
      UNION ALL
      SELECT 9 AS local_id, 'Rm-09' AS room_label
      UNION ALL
      SELECT 10 AS local_id, 'Rm-10' AS room_label
      UNION ALL
      SELECT 11 AS local_id, 'Rm-11' AS room_label
      UNION ALL
      SELECT 12 AS local_id, 'Rm-12' AS room_label
      UNION ALL
      SELECT 13 AS local_id, 'Rm-13' AS room_label
      UNION ALL
      SELECT 14 AS local_id, 'Rm-14' AS room_label
      UNION ALL
      SELECT 15 AS local_id, 'Rm-15' AS room_label
      UNION ALL
      SELECT 16 AS local_id, 'Rm-16' AS room_label
      UNION ALL
      SELECT 17 AS local_id, 'Rm-17' AS room_label
      UNION ALL
      SELECT 18 AS local_id, 'Rm-18' AS room_label
      UNION ALL
      SELECT 19 AS local_id, 'Rm-19' AS room_label
      UNION ALL
      SELECT 20 AS local_id, 'Rm-20' AS room_label
      UNION ALL
      SELECT 21 AS local_id, 'Rm-21' AS room_label
      UNION ALL
      SELECT 22 AS local_id, 'Rm-22' AS room_label
      UNION ALL
      SELECT 23 AS local_id, 'Rm-23' AS room_label
      UNION ALL
      SELECT 24 AS local_id, 'Rm-24' AS room_label
      UNION ALL
      SELECT 25 AS local_id, 'Rm-25' AS room_label
      UNION ALL
      SELECT 26 AS local_id, 'Rm-26' AS room_label
      UNION ALL
      SELECT 27 AS local_id, 'Rm-27' AS room_label
      UNION ALL
      SELECT 28 AS local_id, 'Rm-28' AS room_label
      UNION ALL
      SELECT 29 AS local_id, 'Rm-29' AS room_label
      UNION ALL
      SELECT 30 AS local_id, 'Rm-30' AS room_label
) t
JOIN exam_slot_schedule ess ON ess.room_label = t.room_label
  AND ess.school_year = '2026-2027';

-- 6. Applicant ↔ exam slot assignments
INSERT INTO `applicant_exam_slots` (`applicant_id`, `slot_id`, `assigned_at`) VALUES
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 4), (CURDATE() + INTERVAL 111 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 10), (CURDATE() + INTERVAL 63 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 5), (CURDATE() + INTERVAL 101 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 16), (CURDATE() + INTERVAL 68 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 4), (CURDATE() + INTERVAL 78 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 40), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 23), (CURDATE() + INTERVAL 83 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 1), (CURDATE() + INTERVAL 102 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 2), (CURDATE() + INTERVAL 31 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 109 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 44), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 29), (CURDATE() + INTERVAL 97 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 71 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 7), (CURDATE() + INTERVAL 105 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 8), (CURDATE() + INTERVAL 35 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 14), (CURDATE() + INTERVAL 30 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 13), (CURDATE() + INTERVAL 66 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 67 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 72 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 42 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 53), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 21), (CURDATE() + INTERVAL 94 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 23 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 1), (CURDATE() + INTERVAL 85 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 65 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 86 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 2), (CURDATE() + INTERVAL 63 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 10), (CURDATE() + INTERVAL 80 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 16), (CURDATE() + INTERVAL 82 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 4), (CURDATE() + INTERVAL 42 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 6), (CURDATE() + INTERVAL 82 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 8), (CURDATE() + INTERVAL 105 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 66 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 60 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 7), (CURDATE() + INTERVAL 100 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 10), (CURDATE() + INTERVAL 54 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 12), (CURDATE() + INTERVAL 73 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 93 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 13), (CURDATE() + INTERVAL 66 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 18), (CURDATE() + INTERVAL 113 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 11), (CURDATE() + INTERVAL 86 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 1), (CURDATE() + INTERVAL 102 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 7), (CURDATE() + INTERVAL 96 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 13), (CURDATE() + INTERVAL 86 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 101 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 64 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 70 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 6), (CURDATE() + INTERVAL 62 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 17), (CURDATE() + INTERVAL 54 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 16), (CURDATE() + INTERVAL 62 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 4), (CURDATE() + INTERVAL 41 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 12), (CURDATE() + INTERVAL 91 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 18), (CURDATE() + INTERVAL 74 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 1), (CURDATE() + INTERVAL 89 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 71 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 7), (CURDATE() + INTERVAL 79 DAY + INTERVAL 68400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 10), (CURDATE() + INTERVAL 74 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 60 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 14), (CURDATE() + INTERVAL 33 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 74 DAY + INTERVAL 57600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 13), (CURDATE() + INTERVAL 109 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 5), (CURDATE() + INTERVAL 57 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 42 DAY + INTERVAL 46800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 2), (CURDATE() + INTERVAL 75 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 8), (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 97 DAY + INTERVAL 50400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 6), (CURDATE() + INTERVAL 41 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 56 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 1), (CURDATE() + INTERVAL 108 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 16), (CURDATE() + INTERVAL 71 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 7), (CURDATE() + INTERVAL 61 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 95 DAY + INTERVAL 39600 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 4), (CURDATE() + INTERVAL 36 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 3), (CURDATE() + INTERVAL 41 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 10), (CURDATE() + INTERVAL 37 DAY + INTERVAL 61200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 12), (CURDATE() + INTERVAL 90 DAY + INTERVAL 54000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 9), (CURDATE() + INTERVAL 60 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 18), (CURDATE() + INTERVAL 96 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 16), (CURDATE() + INTERVAL 83 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 11), (CURDATE() + INTERVAL 103 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 13), (CURDATE() + INTERVAL 64 DAY + INTERVAL 36000 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 4), (CURDATE() + INTERVAL 51 DAY + INTERVAL 64800 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 15), (CURDATE() + INTERVAL 46 DAY + INTERVAL 43200 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), (SELECT db_id FROM _demo_exam_rooms WHERE local_id = 1), (CURDATE() + INTERVAL 116 DAY + INTERVAL 46800 SECOND));

-- 7. Exam results (for applicants whose exam date has passed)
INSERT INTO `exam_results` (`applicant_id`, `exam_id`, `score`, `total_items`, `rank_score`, `passed`, `answers`, `submitted_at`) VALUES
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 35), 1, 36, 100, 4, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 36), 1, 91, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 37), 1, 65, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 38), 1, 38, 100, 4, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 39), 1, 46, 100, 5, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 41), 1, 74, 100, 8, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 42), 1, 95, 100, 10, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 43), 1, 80, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 45), 1, 77, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 46), 1, 75, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 47), 1, 92, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 48), 1, 54, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 49), 1, 84, 100, 9, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 50), 1, 0, 100, 0, 0, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 51), 1, 64, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 52), 1, 90, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 54), 1, 58, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 1, 67, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 1, 82, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 1, 73, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 1, 88, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 1, 72, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 1, 55, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 1, 70, 100, 8, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 1, 76, 100, 8, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 1, 85, 100, 9, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 1, 58, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 1, 61, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 1, 77, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 1, 67, 100, 7, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 1, 95, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 1, 70, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 1, 87, 100, 9, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 1, 88, 100, 9, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 1, 59, 100, 6, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 1, 55, 100, 6, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 1, 57, 100, 6, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 1, 93, 100, 10, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 1, 76, 100, 8, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 1, 80, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 1, 69, 100, 7, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 1, 72, 100, 8, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 1, 76, 100, 8, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 1, 67, 100, 7, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 1, 61, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 1, 60, 100, 7, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 1, 60, 100, 7, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 1, 82, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 1, 56, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 1, 95, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 1, 60, 100, 7, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 1, 79, 100, 8, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 1, 87, 100, 9, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 1, 93, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 1, 59, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 1, 83, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 1, 65, 100, 7, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 1, 63, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 1, 94, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 1, 85, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 1, 79, 100, 8, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 1, 59, 100, 6, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 1, 60, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 1, 70, 100, 8, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 1, 79, 100, 8, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 1, 55, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 1, 63, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 1, 87, 100, 9, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 1, 89, 100, 9, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 1, 82, 100, 9, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 1, 95, 100, 10, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 1, 94, 100, 10, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 1, 55, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 1, 55, 100, 6, 1, NULL, (CURDATE() + INTERVAL 14 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 1, 71, 100, 8, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 1, 61, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 1, 58, 100, 6, 1, NULL, (CURDATE() + INTERVAL 13 DAY + INTERVAL 33300 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 1, 62, 100, 7, 1, NULL, (CURDATE() + INTERVAL 15 DAY + INTERVAL 33300 SECOND));

-- 8. Interview sessions
INSERT INTO `interview_slots` (`slot_date`, `slot_time`, `end_time`, `capacity`, `department`, `status`, `created_by`, `assigned_to`, `location_label`, `location_notes`, `created_at`) VALUES
  ((CURDATE() - INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Computer Studies', 'open', 2, 9, 'Room 201', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Computer Studies', 'open', 2, 9, 'Room 202', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Nursing', 'open', 2, 10, 'Room 202', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Nursing', 'open', 2, 10, 'Room 305', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Business and Accountancy', 'open', 2, 11, 'Room 305', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Business and Accountancy', 'open', 2, 11, 'Room 410', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Education', 'open', 2, 12, 'Room 410', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Education', 'open', 2, 12, 'Faculty Lounge', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Arts and Sciences', 'open', 2, 13, 'Faculty Lounge', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Arts and Sciences', 'open', 2, 13, 'Library AVR', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Engineering', 'open', 2, 14, 'Library AVR', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() - INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Engineering', 'open', 2, 14, 'Room 201', 'Bring your applicant ID.', (CURDATE() + INTERVAL 13 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '09:00:00', '11:00:00', 12, 'College of Computer Studies', 'open', 2, 9, 'Room 201', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '13:00:00', '15:00:00', 12, 'College of Computer Studies', 'open', 2, 9, 'Room 202', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '09:00:00', '11:00:00', 12, 'College of Nursing', 'open', 2, 10, 'Room 202', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '13:00:00', '15:00:00', 12, 'College of Nursing', 'open', 2, 10, 'Room 305', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '09:00:00', '11:00:00', 12, 'College of Business and Accountancy', 'open', 2, 11, 'Room 305', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '13:00:00', '15:00:00', 12, 'College of Business and Accountancy', 'open', 2, 11, 'Room 410', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '09:00:00', '11:00:00', 12, 'College of Education', 'open', 2, 12, 'Room 410', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '13:00:00', '15:00:00', 12, 'College of Education', 'open', 2, 12, 'Faculty Lounge', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '09:00:00', '11:00:00', 12, 'College of Arts and Sciences', 'open', 2, 13, 'Faculty Lounge', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '13:00:00', '15:00:00', 12, 'College of Arts and Sciences', 'open', 2, 13, 'Library AVR', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '09:00:00', '11:00:00', 12, 'College of Engineering', 'open', 2, 14, 'Library AVR', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  (CURDATE(), '13:00:00', '15:00:00', 12, 'College of Engineering', 'open', 2, 14, 'Room 201', 'Bring your applicant ID.', (CURDATE() + INTERVAL 10 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Computer Studies', 'open', 2, 9, 'Room 201', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Computer Studies', 'open', 2, 9, 'Room 202', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Nursing', 'open', 2, 10, 'Room 202', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Nursing', 'open', 2, 10, 'Room 305', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Business and Accountancy', 'open', 2, 11, 'Room 305', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Business and Accountancy', 'open', 2, 11, 'Room 410', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Education', 'open', 2, 12, 'Room 410', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Education', 'open', 2, 12, 'Faculty Lounge', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Arts and Sciences', 'open', 2, 13, 'Faculty Lounge', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Arts and Sciences', 'open', 2, 13, 'Library AVR', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '09:00:00', '11:00:00', 12, 'College of Engineering', 'open', 2, 14, 'Library AVR', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((CURDATE() + INTERVAL 3 DAY), '13:00:00', '15:00:00', 12, 'College of Engineering', 'open', 2, 14, 'Room 201', 'Bring your applicant ID.', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND));

DROP TEMPORARY TABLE IF EXISTS _demo_iv_slots;
CREATE TEMPORARY TABLE _demo_iv_slots (
    local_id INT UNSIGNED PRIMARY KEY,
    slot_date DATE NOT NULL,
    slot_time TIME NOT NULL,
    department VARCHAR(120) NOT NULL,
    db_id INT UNSIGNED NOT NULL
) ENGINE=Memory;
INSERT INTO _demo_iv_slots (local_id, slot_date, slot_time, department, db_id)
SELECT t.local_id, t.slot_date, t.slot_time, t.department, isl.id FROM (
      SELECT 1 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Computer Studies' AS department
      UNION ALL
      SELECT 2 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Computer Studies' AS department
      UNION ALL
      SELECT 3 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Nursing' AS department
      UNION ALL
      SELECT 4 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Nursing' AS department
      UNION ALL
      SELECT 5 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Business and Accountancy' AS department
      UNION ALL
      SELECT 6 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Business and Accountancy' AS department
      UNION ALL
      SELECT 7 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Education' AS department
      UNION ALL
      SELECT 8 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Education' AS department
      UNION ALL
      SELECT 9 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Arts and Sciences' AS department
      UNION ALL
      SELECT 10 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Arts and Sciences' AS department
      UNION ALL
      SELECT 11 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Engineering' AS department
      UNION ALL
      SELECT 12 AS local_id, (CURDATE() - INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Engineering' AS department
      UNION ALL
      SELECT 13 AS local_id, CURDATE() AS slot_date, '09:00:00' AS slot_time, 'College of Computer Studies' AS department
      UNION ALL
      SELECT 14 AS local_id, CURDATE() AS slot_date, '13:00:00' AS slot_time, 'College of Computer Studies' AS department
      UNION ALL
      SELECT 15 AS local_id, CURDATE() AS slot_date, '09:00:00' AS slot_time, 'College of Nursing' AS department
      UNION ALL
      SELECT 16 AS local_id, CURDATE() AS slot_date, '13:00:00' AS slot_time, 'College of Nursing' AS department
      UNION ALL
      SELECT 17 AS local_id, CURDATE() AS slot_date, '09:00:00' AS slot_time, 'College of Business and Accountancy' AS department
      UNION ALL
      SELECT 18 AS local_id, CURDATE() AS slot_date, '13:00:00' AS slot_time, 'College of Business and Accountancy' AS department
      UNION ALL
      SELECT 19 AS local_id, CURDATE() AS slot_date, '09:00:00' AS slot_time, 'College of Education' AS department
      UNION ALL
      SELECT 20 AS local_id, CURDATE() AS slot_date, '13:00:00' AS slot_time, 'College of Education' AS department
      UNION ALL
      SELECT 21 AS local_id, CURDATE() AS slot_date, '09:00:00' AS slot_time, 'College of Arts and Sciences' AS department
      UNION ALL
      SELECT 22 AS local_id, CURDATE() AS slot_date, '13:00:00' AS slot_time, 'College of Arts and Sciences' AS department
      UNION ALL
      SELECT 23 AS local_id, CURDATE() AS slot_date, '09:00:00' AS slot_time, 'College of Engineering' AS department
      UNION ALL
      SELECT 24 AS local_id, CURDATE() AS slot_date, '13:00:00' AS slot_time, 'College of Engineering' AS department
      UNION ALL
      SELECT 25 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Computer Studies' AS department
      UNION ALL
      SELECT 26 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Computer Studies' AS department
      UNION ALL
      SELECT 27 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Nursing' AS department
      UNION ALL
      SELECT 28 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Nursing' AS department
      UNION ALL
      SELECT 29 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Business and Accountancy' AS department
      UNION ALL
      SELECT 30 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Business and Accountancy' AS department
      UNION ALL
      SELECT 31 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Education' AS department
      UNION ALL
      SELECT 32 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Education' AS department
      UNION ALL
      SELECT 33 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Arts and Sciences' AS department
      UNION ALL
      SELECT 34 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Arts and Sciences' AS department
      UNION ALL
      SELECT 35 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '09:00:00' AS slot_time, 'College of Engineering' AS department
      UNION ALL
      SELECT 36 AS local_id, (CURDATE() + INTERVAL 3 DAY) AS slot_date, '13:00:00' AS slot_time, 'College of Engineering' AS department
) t
JOIN interview_slots isl
  ON isl.slot_date = t.slot_date
 AND isl.slot_time = t.slot_time
 AND isl.department = t.department;

-- 9. Interview queue entries
INSERT INTO `interview_queue` (`slot_id`, `applicant_id`, `queue_number`, `status`, `checked_in_at`, `interview_notes`, `attendance_status`, `evaluation_result`, `interview_status`, `evaluated_by`, `evaluated_at`) VALUES
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 1), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 55), 1, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32940 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 5), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), 1, 'no_show', NULL, NULL, 'absent', NULL, 'absent', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 29), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 57), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 27), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 58), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 7), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 59), 1, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32880 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 31), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 60), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 32), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 61), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 35), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 62), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 28), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 63), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 6), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 64), 1, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 47520 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 30), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 65), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 2), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 66), 1, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 47040 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 8), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 67), 1, 'completed', NULL, 'Average; could improve on technical reasoning.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 36), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 68), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 17), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 69), 1, 'checked_in', (CURDATE() + INTERVAL 33240 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 25), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 70), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 11), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 71), 1, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32700 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 9), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 72), 1, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 33120 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 26), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 73), 1, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 25), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 74), 2, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 26), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 75), 2, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 18), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 76), 1, 'completed', NULL, 'Excellent; well-prepared and articulate.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 5), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 77), 2, 'checked_in', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32520 SECOND), NULL, 'present', NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 29), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 78), 2, 'scheduled', NULL, NULL, NULL, NULL, 'pending', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 12), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), 1, 'no_show', NULL, NULL, 'absent', NULL, 'absent', NULL, NULL),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 10), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 1, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 13, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 19), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 1, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 20), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 1, 'completed', NULL, 'Strong candidate. Recommend acceptance.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 23), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 1, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 14, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 24), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 1, 'completed', NULL, 'Strong candidate. Recommend acceptance.', 'present', 'pass', 'completed', 14, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 13), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 1, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 9, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 6), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 2, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 14), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 1, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'fail', 'completed', 9, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 7), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 2, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 17), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 2, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 3), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 1, 'completed', NULL, 'Did not meet program expectations.', 'present', 'fail', 'completed', 10, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 18), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 2, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'fail', 'completed', 11, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 1), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 2, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'pass', 'completed', 9, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 21), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 1, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 13, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 5), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 3, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 4), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 1, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'pass', 'completed', 10, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 15), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 1, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'pass', 'completed', 10, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 6), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 3, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 11), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 2, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'fail', 'completed', 14, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 17), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 3, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'fail', 'completed', 11, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 2), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 2, 'completed', NULL, 'Strong candidate. Recommend acceptance.', 'present', 'pass', 'completed', 9, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 8), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 2, 'completed', NULL, 'Strong candidate. Recommend acceptance.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 13), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 2, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'fail', 'completed', 9, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 18), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 3, 'completed', NULL, 'Strong candidate. Recommend acceptance.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 19), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 2, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 5), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 4, 'completed', NULL, 'Strong candidate. Recommend acceptance.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 20), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 2, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 12), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 2, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 14, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 6), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 4, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 23), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 2, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'fail', 'completed', 14, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 7), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 3, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'fail', 'completed', 12, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 22), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 1, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 13, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 14), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 2, 'completed', NULL, 'Did not meet program expectations.', 'present', 'pass', 'completed', 9, (CURDATE() + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 8), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 3, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'pass', 'completed', 12, (CURDATE() + INTERVAL 3 DAY + INTERVAL 54000 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 17), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 4, 'completed', NULL, 'Solid potential; admit pending capacity.', 'present', 'pass', 'completed', 11, (CURDATE() + INTERVAL 39600 SECOND)),
  ((SELECT db_id FROM _demo_iv_slots WHERE local_id = 1), (SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 3, 'completed', NULL, 'Borderline; consider waitlist.', 'present', 'fail', 'completed', 9, (CURDATE() + INTERVAL 3 DAY + INTERVAL 39600 SECOND));

-- 10. Admission results (released applicants)
INSERT INTO `admission_results` (`applicant_id`, `result`, `enrollment_intent`, `intent_deadline`, `intent_submitted_at`, `promoted_from_waitlist`, `remarks`, `released_by`, `released_at`) VALUES
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 80), 'accepted', NULL, CURDATE(), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 81), 'accepted', 'confirmed', (CURDATE() + INTERVAL 5 DAY), (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 82), 'waitlisted', NULL, (CURDATE() + INTERVAL 4 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 83), 'accepted', NULL, (CURDATE() + INTERVAL 3 DAY), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 84), 'waitlisted', NULL, (CURDATE() + INTERVAL 6 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 85), 'rejected', NULL, (CURDATE() + INTERVAL 4 DAY), NULL, 0, 'Did not meet the cut-off for the applied program.', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 86), 'accepted', 'declined', (CURDATE() + INTERVAL 7 DAY), (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 87), 'accepted', NULL, (CURDATE() + INTERVAL 4 DAY), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 88), 'rejected', NULL, (CURDATE() + INTERVAL 1 DAY), NULL, 0, 'Did not meet the cut-off for the applied program.', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 89), 'rejected', NULL, CURDATE(), NULL, 0, 'Did not meet the cut-off for the applied program.', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'waitlisted', NULL, (CURDATE() + INTERVAL 1 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 91), 'accepted', 'confirmed', (CURDATE() + INTERVAL 2 DAY), (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 92), 'accepted', NULL, (CURDATE() + INTERVAL 7 DAY), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 93), 'waitlisted', NULL, (CURDATE() + INTERVAL 1 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 94), 'accepted', 'confirmed', (CURDATE() + INTERVAL 1 DAY), (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 95), 'accepted', 'declined', (CURDATE() + INTERVAL 5 DAY), (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 96), 'accepted', 'confirmed', (CURDATE() + INTERVAL 2 DAY), (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 97), 'waitlisted', NULL, (CURDATE() + INTERVAL 4 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 98), 'accepted', NULL, CURDATE(), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'accepted', 'declined', CURDATE(), (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 100), 'waitlisted', NULL, (CURDATE() + INTERVAL 5 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 101), 'accepted', NULL, (CURDATE() + INTERVAL 3 DAY), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 102), 'rejected', NULL, (CURDATE() + INTERVAL 1 DAY), NULL, 0, 'Did not meet the cut-off for the applied program.', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 103), 'accepted', NULL, (CURDATE() + INTERVAL 7 DAY), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 104), 'accepted', 'confirmed', (CURDATE() + INTERVAL 4 DAY), (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 105), 'accepted', 'confirmed', (CURDATE() + INTERVAL 4 DAY), (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 106), 'accepted', NULL, (CURDATE() + INTERVAL 3 DAY), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 107), 'accepted', 'declined', (CURDATE() + INTERVAL 3 DAY), (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 108), 'accepted', NULL, CURDATE(), NULL, 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 109), 'rejected', NULL, (CURDATE() + INTERVAL 4 DAY), NULL, 0, 'Did not meet the cut-off for the applied program.', 2, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'accepted', 'declined', (CURDATE() + INTERVAL 5 DAY), (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 111), 'accepted', 'confirmed', (CURDATE() + INTERVAL 3 DAY), (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 112), 'waitlisted', NULL, (CURDATE() + INTERVAL 1 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 113), 'waitlisted', NULL, (CURDATE() + INTERVAL 1 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 114), 'accepted', 'confirmed', (CURDATE() + INTERVAL 1 DAY), (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND), 0, 'Congratulations — welcome to PLP!', 2, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 115), 'waitlisted', NULL, (CURDATE() + INTERVAL 7 DAY), NULL, 0, 'Capacity reached; waitlisted pending declines.', 2, (CURDATE() + INTERVAL 32400 SECOND));

-- 11. Course suggestions (staff recommended alternatives)
INSERT INTO `course_suggestions` (`applicant_id`, `original_course`, `suggested_course`, `suggested_by`, `note`, `status`) VALUES
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 10), 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'BS Entrepreneurship (BSENT)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 11), 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'BS Hospitality Management (BSHM)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 17), 'BS Business Administration major in Marketing Management (BSBA)', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 20), 'BS Hospitality Management (BSHM)', 'BS Nursing (BSN)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 24), 'BS Information Technology (BSIT)', 'BS Nursing (BSN)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 90), 'BS Nursing (BSN)', 'Bachelor of Secondary Education Major in Filipino (BSED-FIL)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 99), 'BS Business Administration major in Marketing Management (BSBA)', 'BS Computer Science (BSCS)', 2, 'Based on the interview, this alternative is a better fit.', 'pending'),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 110), 'Bachelor of Secondary Education Major in English (BSED-ENG)', 'BS Nursing (BSN)', 2, 'Based on the interview, this alternative is a better fit.', 'pending');

-- 12. Reschedule logs (no-shows rebooked)
INSERT INTO `reschedule_logs` (`applicant_id`, `from_slot_id`, `to_slot_id`, `from_slot_date`, `from_slot_time`, `reason`, `rescheduled_by`) VALUES
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 56), (SELECT db_id FROM _demo_iv_slots WHERE local_id = 5) , (SELECT db_id FROM _demo_iv_slots WHERE local_id = 29), (CURDATE() - INTERVAL 3 DAY), '09:00:00', 'absent', 2),
  ((SELECT applicant_id FROM _demo_app_ids WHERE idx = 79), (SELECT db_id FROM _demo_iv_slots WHERE local_id = 12) , (SELECT db_id FROM _demo_iv_slots WHERE local_id = 35), (CURDATE() - INTERVAL 3 DAY), '13:00:00', 'absent', 2);

-- 13. Notifications
INSERT INTO `notifications` (`user_id`, `type`, `title`, `message`, `is_read`, `created_at`) VALUES
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 10), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 110 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 11), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 34 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 12), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 13), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 48 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 14), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 93 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 15), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 53 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 16), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 66 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 17), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 114 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 18), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 30 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 19), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 78 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 20), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 33 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 21), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 67 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 22), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 48 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 23), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 65 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 24), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 97 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 25), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 85 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 25), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 82 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 26), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 107 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 26), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 104 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 27), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 47 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 27), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 44 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 28), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 46 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 28), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 43 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 29), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 50 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 29), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 47 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 30), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 54 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 30), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 51 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 31), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 40 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 31), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 37 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 32), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 32), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 33), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 32 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 33), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 29 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 34), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 90 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 34), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 87 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 35), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 117 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 35), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 111 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 36), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 68 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 36), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 63 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 37), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 103 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 37), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 101 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 38), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 73 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 38), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 68 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 39), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 85 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 39), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 78 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 40), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 87 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 40), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 83 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 41), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 105 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 41), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 102 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 42), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 38 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 42), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 31 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 43), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 111 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 43), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 109 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 44), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 102 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 44), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 45), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 75 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 45), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 46), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 108 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 46), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 105 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 47), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 42 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 47), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 35 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 48), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 32 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 48), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 30 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 49), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 69 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 49), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 66 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 50), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 70 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 50), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 67 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 51), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 76 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 51), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 72 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 52), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 48 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 52), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 42 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 53), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 101 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 53), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 94 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 54), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 30 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 54), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 23 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 55), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 90 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 55), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 85 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 55), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 70 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 56), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 72 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 56), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 65 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 56), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 52 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 57), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 90 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 57), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 86 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 57), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 70 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 58), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 66 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 58), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 63 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 58), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 46 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 59), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 85 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 59), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 80 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 59), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 65 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 60), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 89 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 60), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 82 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 60), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 69 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 61), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 45 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 61), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 42 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 61), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 25 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 62), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 89 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 62), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 82 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 62), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 69 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 63), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 111 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 63), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 105 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 63), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 91 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 64), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 69 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 64), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 66 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 64), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 49 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 65), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 63 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 65), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 65), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 43 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 66), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 103 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 66), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 100 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 66), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 83 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 67), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 67), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 54 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 67), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 40 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 68), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 79 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 68), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 73 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 68), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 59 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 69), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 97 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 69), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 93 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 69), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 77 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 70), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 68 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 70), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 66 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 70), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 48 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 71), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 117 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 71), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 113 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 71), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 97 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 72), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 91 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 72), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 86 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 72), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 73), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 107 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 73), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 102 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 73), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 87 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 74), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 103 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 74), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 96 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 74), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 83 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 75), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 92 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 75), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 86 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 75), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 72 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 76), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 107 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 76), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 101 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 76), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 87 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 77), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 77), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 64 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 77), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 51 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 78), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 72 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 78), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 70 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 78), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 52 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 79), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 66 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 79), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 62 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 79), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 46 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 80), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 80), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 54 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 80), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 40 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 80), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-11.', 0, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 81), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 69 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 81), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 62 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 81), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 49 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 81), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-16.', 0, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 82), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 47 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 82), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 41 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 82), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 27 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 82), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 83), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 95 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 83), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 91 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 83), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 75 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 83), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-14.', 0, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 84), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 78 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 84), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 74 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 84), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 58 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 84), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-17.', 0, (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 85), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 94 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 85), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 89 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 85), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 74 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 85), 'danger', 'Admission result: rejected', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 86), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 77 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 86), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 86), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 86), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-18.', 0, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 87), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 81 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 87), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 79 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 87), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 61 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 87), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 88), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 77 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 88), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 74 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 88), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 88), 'danger', 'Admission result: rejected', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 89), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 64 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 89), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 89), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 44 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 89), 'danger', 'Admission result: rejected', 'Your application result is now available. Please review and respond before 2026-09-11.', 0, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 90), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 40 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 90), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 90), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 20 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 90), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 91), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 76 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 91), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 74 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 91), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 56 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 91), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-13.', 0, (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 92), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 115 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 92), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 109 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 92), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 95 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 92), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-18.', 0, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 93), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 93), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 93), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 40 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 93), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 94), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 44 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 94), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 42 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 94), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 24 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 94), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 95), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 82 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 95), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 75 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 95), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 62 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 95), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-16.', 0, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 96), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 96), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 96), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 40 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 96), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-13.', 0, (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 97), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 102 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 97), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 97), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 82 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 97), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 98), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 43 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 98), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 41 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 98), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 23 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 98), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-11.', 0, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 99), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 61 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 99), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 56 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 99), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 41 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 99), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-11.', 0, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 100), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 115 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 100), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 108 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 100), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 95 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 100), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-16.', 0, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 101), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 77 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 101), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 101), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 101), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-14.', 0, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 102), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 65 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 102), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 61 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 102), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 45 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 102), 'danger', 'Admission result: rejected', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 103), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 99 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 103), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 95 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 103), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 79 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 103), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-18.', 0, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 104), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 43 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 104), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 36 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 104), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 23 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 104), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 105), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 48 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 105), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 41 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 105), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 28 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 105), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 106), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 41 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 106), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 37 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 106), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 21 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 106), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-14.', 0, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 107), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 92 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 107), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 90 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 107), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 72 DAY + INTERVAL 50400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 107), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-14.', 0, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 108), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 67 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 108), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 60 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 108), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 47 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 108), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-11.', 0, (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 109), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 100 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 109), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 96 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 109), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 80 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 109), 'danger', 'Admission result: rejected', 'Your application result is now available. Please review and respond before 2026-09-15.', 0, (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 110), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 89 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 110), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 83 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 110), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 69 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 110), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-16.', 0, (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 111), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 109 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 111), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 103 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 111), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 89 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 111), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-14.', 0, (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 112), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 71 DAY + INTERVAL 36000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 112), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 64 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 112), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 51 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 112), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 113), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 57 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 113), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 51 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 113), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 37 DAY + INTERVAL 61200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 113), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 114), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 52 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 114), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 46 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 114), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 32 DAY + INTERVAL 39600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 114), 'success', 'Admission result: accepted', 'Your application result is now available. Please review and respond before 2026-09-12.', 0, (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 115), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 120 DAY + INTERVAL 46800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 115), 'success', 'Documents approved', 'All required documents have been approved. You are cleared for the entrance exam.', 0, (CURDATE() + INTERVAL 116 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 115), 'info', 'Interview schedule', 'You have been scheduled for an interview. Please check your dashboard for the date and time.', 0, (CURDATE() + INTERVAL 100 DAY + INTERVAL 43200 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 115), 'warning', 'Admission result: waitlisted', 'Your application result is now available. Please review and respond before 2026-09-18.', 0, (CURDATE() + INTERVAL 32400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 116), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 80 DAY + INTERVAL 64800 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 117), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 34 DAY + INTERVAL 68400 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 118), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 98 DAY + INTERVAL 57600 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 119), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 81 DAY + INTERVAL 54000 SECOND)),
  ((SELECT user_id FROM _demo_app_ids WHERE idx = 120), 'info', 'Welcome to PLP Admissions', 'Your application has been received. Please complete your documents.', 0, (CURDATE() + INTERVAL 85 DAY + INTERVAL 54000 SECOND));

-- 14. Audit logs
INSERT INTO `audit_logs` (`user_id`, `user_name`, `user_role`, `action`, `description`, `created_at`) VALUES
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #1 (Maria Mendoza)', (CURDATE() + INTERVAL 56 DAY + INTERVAL 36000 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #2 (Janine Lacson)', (CURDATE() + INTERVAL 62 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #3 (Bea Andrada)', (CURDATE() + INTERVAL 97 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #4 (Faith Salazar)', (CURDATE() + INTERVAL 33 DAY + INTERVAL 50400 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #5 (Isabela Yap)', (CURDATE() + INTERVAL 51 DAY + INTERVAL 36000 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #6 (Hope Pineda)', (CURDATE() + INTERVAL 74 DAY + INTERVAL 61200 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #7 (Camille Aquino)', (CURDATE() + INTERVAL 78 DAY + INTERVAL 64800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #8 (Mark Rodriguez)', (CURDATE() + INTERVAL 70 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #9 (Lance Velasco)', (CURDATE() + INTERVAL 106 DAY + INTERVAL 57600 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #10 (Bea Ramos)', (CURDATE() + INTERVAL 57 DAY + INTERVAL 36000 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #11 (Kris Del Rosario)', (CURDATE() + INTERVAL 110 DAY + INTERVAL 36000 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #12 (Miguel Domingo)', (CURDATE() + INTERVAL 34 DAY + INTERVAL 46800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #13 (Earl Torres)', (CURDATE() + INTERVAL 71 DAY + INTERVAL 64800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #14 (Mikaela Dela Cruz)', (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #15 (Kris Valdez)', (CURDATE() + INTERVAL 93 DAY + INTERVAL 39600 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #16 (Imelda Dela Cruz)', (CURDATE() + INTERVAL 53 DAY + INTERVAL 36000 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #17 (Pedro Reyes)', (CURDATE() + INTERVAL 66 DAY + INTERVAL 61200 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #18 (Cherry Ramos)', (CURDATE() + INTERVAL 114 DAY + INTERVAL 57600 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #19 (Mark Co)', (CURDATE() + INTERVAL 30 DAY + INTERVAL 61200 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #20 (Isabel Torres)', (CURDATE() + INTERVAL 78 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #21 (Joshua Magsaysay)', (CURDATE() + INTERVAL 33 DAY + INTERVAL 57600 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #22 (Lourdes Chua)', (CURDATE() + INTERVAL 67 DAY + INTERVAL 64800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #23 (Lourdes Santos)', (CURDATE() + INTERVAL 48 DAY + INTERVAL 46800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #24 (Andres Soriano)', (CURDATE() + INTERVAL 65 DAY + INTERVAL 64800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #25 (Ronnel Garcia)', (CURDATE() + INTERVAL 97 DAY + INTERVAL 46800 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #26 (Jericho Torres)', (CURDATE() + INTERVAL 85 DAY + INTERVAL 54000 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #27 (Charmaine Tomas)', (CURDATE() + INTERVAL 107 DAY + INTERVAL 43200 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #28 (Lourdes Lacson)', (CURDATE() + INTERVAL 47 DAY + INTERVAL 39600 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #29 (Justin Ong)', (CURDATE() + INTERVAL 46 DAY + INTERVAL 57600 SECOND)),
  (2, 'SSO Office', 'sso', 'applicant.create', 'Created applicant #30 (Mark Esguerra)', (CURDATE() + INTERVAL 50 DAY + INTERVAL 39600 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #81', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #82', (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #83', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #84', (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #85', (CURDATE() + INTERVAL 1 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.rejected', 'Released rejected for applicant #86', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #87', (CURDATE() + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #88', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.rejected', 'Released rejected for applicant #89', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.rejected', 'Released rejected for applicant #90', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #91', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #92', (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #93', (CURDATE() + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #94', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #95', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #96', (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #97', (CURDATE() + INTERVAL 5 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #98', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #99', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #100', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #101', (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #102', (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.rejected', 'Released rejected for applicant #103', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #104', (CURDATE() + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #105', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #106', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #107', (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #108', (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #109', (CURDATE() + INTERVAL 7 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.rejected', 'Released rejected for applicant #110', (CURDATE() + INTERVAL 3 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #111', (CURDATE() + INTERVAL 2 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #112', (CURDATE() + INTERVAL 4 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #113', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #114', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.accepted', 'Released accepted for applicant #115', (CURDATE() + INTERVAL 6 DAY + INTERVAL 32400 SECOND)),
  (2, 'SSO Office', 'sso', 'result.waitlisted', 'Released waitlisted for applicant #116', (CURDATE() + INTERVAL 32400 SECOND));

-- Done.  Total demo applicants seeded: 121

