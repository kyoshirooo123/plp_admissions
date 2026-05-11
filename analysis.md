# PLP Admissions System — Full Flow & Reference

> Verified against the code on `baseline` (post-zip-merge, post-demo-seed-fix). When something in the code disagrees with this document, the **code is the source of truth** — please open a PR to update this file.

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Roles & Access](#2-roles--access)
3. [The Admissions Pipeline (end to end)](#3-the-admissions-pipeline-end-to-end)
4. [Automations Cheat-Sheet](#4-automations-cheat-sheet)
5. [Department Scoping (who sees whom)](#5-department-scoping-who-sees-whom)
6. [Edge Cases & Business Rules](#6-edge-cases--business-rules)
7. [Frequently Asked Questions](#7-frequently-asked-questions)
8. [Known Gaps & Risks](#8-known-gaps--risks)
9. [Codebase Map](#9-codebase-map)

---

## 1. System Overview

PLP Admissions is a vanilla-PHP web app for **Pamantasan ng Lungsod ng Pasig** that runs the entire student admissions cycle — registration → email verification → document review → entrance exam → interview → admission decision → enrollment intent.

**Stack:** PHP 8 (no framework), MySQL/MariaDB (utf8mb4), vanilla CSS/JS, PHPMailer (SMTP), hCaptcha (anti-bot), Chart.js for dashboards, Puter AI as a browser-side fallback for document validation.

**Architecture:** One entry point (`public/index.php`) routes every request through a hand-rolled `Router`. Each feature lives in `modules/<area>/` and renders into a shared layout via `ob_start()` / `ob_get_clean()`. Cross-cutting logic (auth, automation, the interview scheduler) lives in `core/`.

---

## 2. Roles & Access

The seed_users.sql script provisions five role tiers. `Auth::homeUrl()` in `core/Auth.php` decides where each role lands after login.

| Role           | Default landing page    | What they do |
|----------------|-------------------------|--------------|
| **Admin**      | `/admin/dashboard`      | System-wide oversight: users, school year window, courses & caps, branding, settings, audit log, all reports |
| **SSO**        | `/admin/dashboard`      | Office of Student Services. Reviews documents, runs the global doc queue, bulk-releases results, exports |
| **Dean**       | `/admin/dashboard`      | Per-college oversight: sees all applicants in their college, can edit course caps for their college, can release results for their applicants |
| **Staff** (Professor) | `/staff/dashboard` | Per-college interviewer. Creates interview sessions, runs their own live queue, evaluates assigned applicants |
| **Student**    | `/student/documents`    | Applicant. Uploads documents, takes the exam, sees their interview slot, confirms enrollment |

The seeded passwords (from `database/seed_users.sql`) are `Admin@123`, `SSO@123`, `Dean@123`, `Staff@123`. **Change them before going to production.**

---

## 3. The Admissions Pipeline (end to end)

Every applicant moves through a single column on the `applicants` table: `overall_status`. The values, in order, are:

```
pending → documents → submitted → exam → interview → released
                                                       ↘ withdrawn (terminal)
```

Below is what triggers each transition.

### Phase 0 — Admin / Staff configuration (before admissions open)

These steps happen once per cycle. None of them touch student data.

1. **Admin opens the admissions window** (`/admin/school-year`)
   - Sets the open date, close date, and optional document submission deadline.
   - The current school year is auto-derived (e.g. opening in 2026 → `2026-2027`).
   - Outside this window, `/register` is blocked with a friendly message.
2. **Admin / Dean configures courses, strand maps, and caps** (`/admin/courses`)
   - Courses live in `course_departments` and `course_passing_scores`.
   - Each course has a `pass_from` rank (1–10) and an optional cap (`course_caps.max_slots`).
   - Caps are enforced at registration time **and** when releasing results.
3. **Admin provisions Staff / Dean / SSO accounts** (`/admin/users`)
   - Every staff/dean account must have a `department` matching the college it serves (e.g. `College of Computer Studies`). This is what scopes the interview queue.
4. **SSO builds the entrance exam** (`/staff/exam`)
   - Title, scheduled date, access password, sections, questions (multiple choice, checkbox, dropdown, short answer, paragraph, linear scale).
   - Only one exam can be active at a time (`is_active = 1`).
5. **SSO creates exam rooms** (`/staff/exam/slots`)
   - Date + start/end time + room label + department + capacity. Supports batch create.
6. **Staff creates interview sessions** (`/staff/interviews/setup`)
   - Per-college list. **+ Add Session** asks for date, start/end time, capacity, interviewer (auto-filled with the logged-in Staff/Dean), location label, location notes. There is no separate Desk concept anymore — desk and session were merged into `interview_slots`.

### Phase 1 — Registration

`POST /register` (`modules/auth/register.php`):

1. Admissions-window check. Blocked if closed.
2. hCaptcha verification.
3. Field validation: name, birthdate, sex, street address + Pasig barangay (hardcoded list of 30), phone, email, password (≥ 8 chars), applicant type (`freshman | transferee | foreign`), course, SHS strand (freshmen only).
4. **Course-cap pre-check** — if `accepted_count ≥ max_slots` for the chosen course in the current school year, registration is blocked.
5. **Strand compatibility check** — freshmen's SHS strand must be in the course's `strands` allowlist.
6. **Duplicate detection** — same `first_name + last_name + birthdate` is rejected.
7. On success, inside a transaction:
   - Insert into `users` with `role = 'student'`, `department = course_to_department(course)`, password bcrypt-hashed (cost 12).
   - Insert into `applicants` with `overall_status = 'pending'`.
   - Pre-create the required `documents` rows in `status = 'pending'`.
8. Outside the transaction:
   - Generate a verification credential pair (a magic-link token + a 6-digit code).
   - Send the verification email via PHPMailer + Gmail SMTP.
   - **The user is NOT auto-logged in.** They're redirected to `/verify-pending`.

### Phase 2 — Email verification

`/verify-pending` (`modules/auth/verify_pending.php`):

- Shows a 6-digit code form and a "Resend code" button with a cooldown timer (default 60 seconds).
- Code verification: success → auto-login + redirect to `/student/documents`. Failure increments `email_verify_attempts`.
- The magic link in the email (`/verify-email?token=…`) does the same thing — clicking it logs the user in.
- `modules/auth/login.php` will send unverified students back to `/verify-pending` rather than refusing them.

The verification columns (`email_verified`, `email_verify_token`, `email_verify_code`, `email_verify_code_expires_at`, `email_verify_attempts`, `email_verify_last_sent_at`) are auto-created by `ensure_email_verification_columns()` in `core/automation.php`.

> **Demo bypass:** `database/seed_demo.sql` inserts every demo student with `email_verified = 1`, so they skip the verification gate during presentations.

### Phase 3 — Document submission

`modules/documents/student_upload.php`:

1. **Document list depends on applicant type** (from `config/app.php`):
   - **Core (all)**: government ID, PSA birth certificate, passport photos, parent ID, proof of income, guardianship affidavit.
   - **Freshman**: form 138 (or form 137).
   - **Transferee**: TOR + good moral.
   - **Foreign**: TOR + good moral + passport + visa/study permit + alien certificate.
2. **Upload constraints**: PDF / JPG / PNG / WEBP, ≤ 5 MB per file.
3. **Auto-validation pipeline** (`auto_validate_document()` in `core/automation.php`):
   - Step 1: MIME-type + size check.
   - Step 2: Image integrity (decode with GD, check minimum dimensions).
   - Step 3: PDF header + basic text extraction.
   - Step 4: Minimum file-size heuristic (rejects blank scans).
   - Confidence ≥ 70 → passed, ≥ 40 → uncertain, < 40 → failed.
   - Results logged to `document_validations`. A separate Puter-AI (Claude in the browser) check is invoked client-side via `modules/api/auto_validate` and feeds back through `save_ai_validation()`.
4. **Status transitions**:
   - Upload moves a single document from `pending` → `uploaded`.
   - Once **all** required documents are `uploaded` (or already `approved`) the student can click **Submit**, which sets `applicants.overall_status = 'submitted'`.
   - Student can withdraw their submission (back to `documents`) up until the first staff approval.
   - Once `overall_status` is past `documents` (i.e. exam / interview / released), changing applicant type is locked.
5. **Document deadline enforcement** — if the admin set a doc deadline and it has passed, applicants who haven't submitted see a "Document Submission Closed" page. POST is blocked server-side. Applicants who already submitted continue normally.

### Phase 4 — Staff document review

`modules/documents/staff_review.php` — the document-review queue, used by SSO (and admin/dean as oversight).

- Default tab: applicants with `overall_status IN ('documents', 'submitted')`.
- Per-document actions: **Approve**, **Reject** (with reason), **Request Resubmission** (softer; comes with instructions).
- Bulk actions: approve / reject / request-resubmit all selected rows.
- **The moment every required document is `approved`**, `staff_action.php` runs:
  ```sql
  UPDATE applicants
     SET overall_status = 'exam',
         documents_approved_at = COALESCE(documents_approved_at, NOW())
   WHERE id = ?
     AND overall_status NOT IN ('exam','interview','released')
  ```
  Then it calls `notify_stage_transition()` (in-app + email) **and** `auto_assign_exam_slot()`.
- **Undo approval** is allowed only while the applicant hasn't taken the exam yet. It rolls `overall_status` back from `exam` to `submitted`.

### Phase 5 — Entrance exam

Once `overall_status = 'exam'`, `auto_assign_exam_slot()` (`core/automation.php`) picks the earliest-available, lowest-fill exam room in the applicant's department and inserts a row into `applicant_exam_slots`. SSO can also assign manually from `/staff/exam/slots`.

`modules/exam/take.php` (the student-facing exam page) renders in three states:

1. **No slot yet** → "Awaiting Slot Assignment" notice.
2. **Slot is in the future** → countdown card with date, time, room.
3. **Slot is today** → access-password gate, then the exam itself.

Anti-cheating measures during the exam:
- Text selection disabled.
- Timer counts from scheduled start to end time.
- Autosave: every 60s the partial answers are POSTed to `/api/exam-autosave` and stored in `exam_drafts`. On reload, drafts are restored.

On submit:

```text
raw_score   = sum of correct points across auto-gradable items
percentage  = raw_score / total * 100
rank        = ceil(percentage / 10)            # clamped 1..10
passed      = rank >= course_passing_scores.pass_from   # default 4
```

Then a row goes into `exam_results`. **Tier labels** (purely cosmetic on result pages):

| Rank | Tier   | Verdict   |
|-----:|:-------|:----------|
| 7–10 | High   | Passed    |
| 4–6  | Average | Passed    |
| 1–3  | Low    | Rejected  |

- **Passed**: `overall_status` flips to `interview`, and `assign_interview_slot()` is called immediately (see Phase 6).
- **Failed**: status stays at `exam`. `suggest_alt_courses()` proposes courses with a lower `pass_from` the score would have qualified for; SSO can then push a suggestion via `staff_suggest.php`.

### Phase 6 — Interview

`core/interview_scheduler.php :: assign_interview_slot()`:

1. Resolves the applicant's department from `users.department` first, falling back to `course_to_department(course_applied)` and opportunistically backfilling `users.department`.
2. Inside a `FOR UPDATE` transaction:
   - Lock all open future slots in that department.
   - Pick the one with the **lowest booked count → earliest date → earliest time** (fair distribution).
   - Refuse if the applicant already has an active queue row (no double-booking).
3. Insert into `interview_queue`:
   - `status = 'checked_in'` (yes, immediately — there is no longer an "I'm Here" button).
   - `queue_number` = sequential per-slot.
   - `checked_in_at = NOW()`.
4. Audit log + in-app + email notification.

If no slot exists yet (e.g. Staff hasn't created any sessions for that college), the applicant stays at `overall_status = 'interview'` with no queue row. The next time a Staff member creates a session for that department in `/staff/interviews/setup`, `bulk_assign_pending_applicants($dept)` sweeps every waiting applicant into the new slot.

**On interview day** (`modules/interview/staff_queue.php`):

- The Live Queue page is scoped:
  - **Staff (Professor)** → only rows where `COALESCE(s.assigned_to, s.created_by) = self`.
  - **Dean** → all rows where `s.department = staff.department`.
  - **Admin / SSO** → can pick a college or see everything via `?college=__all__`.
- Actions:
  - **Call Next** flips the next `checked_in` row to `in_progress`.
  - **Evaluate Pass / Fail** records `evaluation_result` on the queue row and `interview_completed_at` on the applicant.
  - **Mark No-show** sets `attendance_status = 'absent'`. Auto-reschedule (`auto_reschedule_noshows`) can route them to the next available slot.

The applicant page (`/student/interview`) is read-only — it shows their date, time, location, interviewer, and a live queue position ("you are #3 in line") computed against `checked_in` rows ahead of them. Students can submit a reschedule request from the same page (POSTs to `/api/reschedule-request`).

### Phase 7 — Admission decision (results)

`modules/results/staff_manage.php` is the results console. It buckets applicants:

| Bucket          | Predicate |
|-----------------|-----------|
| **Ready: Accept**  | `exam_passed = 1 AND interview = pass` |
| **Ready: Reject**  | `exam_passed = 0 OR interview = fail` |
| **Awaiting**       | Interview not yet evaluated |
| **Released**       | Already has an `admission_results` row |
| **Withdrawn**      | `applicants.overall_status = 'withdrawn'` |

> **Note on waitlist:** the `admission_results.result` column still allows `waitlisted` for backward compatibility, and the seed data includes legacy waitlisted rows, but the **current staff UI only emits accepted or rejected**. The auto-promote-waitlist function in `core/automation.php` is a documented no-op stub.

**Three ways to release:**

1. **Single row** — Accept or Reject buttons on `/staff/results`. Calls `staff_action.php`, which inserts a row into `admission_results`, flips `overall_status = 'released'`, audits, and notifies.
2. **Bulk** — checkbox selection + Accept Selected / Reject Selected. Calls `staff_bulk.php`. Skips withdrawn applicants and applicants with an existing result.
3. **Auto-release** — `POST /staff/results/auto-release`. Calls `auto_release_results()`, which walks every `overall_status IN ('exam','interview','released')` row without a result and emits `accepted` (exam passed AND interview passed) or `rejected` (exam failed OR interview failed). Skips applicants whose interview hasn't been evaluated yet. Only runs when `school_settings.auto_release_results = '1'`.

### Phase 8 — Enrollment intent

`modules/results/enrollment_intent.php` handles `POST /student/result`:

- Accepted students see **"I Confirm My Enrollment"** and **"Decline Slot"** on `/student/result`.
- Confirming sets `admission_results.enrollment_intent = 'confirmed'` and stamps `intent_submitted_at`.
- Declining sets `enrollment_intent = 'declined'` **and** flips `overall_status = 'withdrawn'`.
- Withdrawing also accepts a free-text reason saved to `applicants.withdrawn_reason`.

The legacy "promote next from waitlist" hook fires here but is currently a no-op.

There is also an **auto-expire** sweep (`auto_expire_accepted_pending` in `automation.php`): accepted students who don't act within `enrollment_intent_deadline_days` (default 7) get auto-withdrawn with a "Slot expired" notification.

---

## 4. Automations Cheat-Sheet

Every automation toggle lives in `school_settings` and is toggleable from `/admin/settings`.

| Setting key                   | Default | What it does |
|------------------------------|---------|--------------|
| `auto_validate_documents`     | `1`     | Run the OCR-style pipeline on every upload + (client-side) Puter AI fallback |
| `auto_assign_exam_slots`      | `1`     | Drop applicant into the next exam room when all docs are approved |
| `auto_reschedule_noshows`     | `1`     | Move interview no-shows to the next available slot for their department |
| `auto_release_results`        | `0`     | Allow the auto-release sweep to flip Ready: Accept / Ready: Reject into released |
| `auto_promote_waitlist`       | `1`     | **Deprecated** — the function is a no-op stub since waitlist was retired |

Triggers that always fire (not toggleable):

- All-docs-approved → `overall_status = 'exam'` + `auto_assign_exam_slot()` + notification.
- Exam pass → `overall_status = 'interview'` + `assign_interview_slot()` + notification.
- Staff creates a new interview session → `bulk_assign_pending_applicants()` sweeps unscheduled applicants in that department into the new slot.
- `interview_queue` evaluation → if Pass, applicant lands in **Ready: Accept**; if Fail, **Ready: Reject**. Nothing is auto-released unless the toggle is on.
- Notifications (in-app + email via PHPMailer) on every status transition.
- Audit log row on every state-changing action.

---

## 5. Department Scoping (who sees whom)

This is the area that caused the demo seed regression — worth calling out explicitly.

| Page                        | Scope rule |
|-----------------------------|-----------|
| `/student/documents`        | Always shows the logged-in student's own applicant. No cross-applicant access. |
| `/staff/applicants` (doc review) | **Unscoped by college** — this is the SSO global doc-review queue. SSO, Dean, Admin all see all colleges here. (Doc review is centralized; only interview / results are per-college.) |
| `/staff/applicants/{id}`    | Permitted for SSO/Admin always. Dean is granted only if `users.department = applicant.department`. |
| `/staff/interviews/setup`   | Staff & Dean see their own college's sessions. Admin/SSO can pick a college. |
| `/staff/interviews/queue`   | Staff → only their own assigned/created sessions. Dean → all sessions in their college. Admin/SSO → college picker, with `?college=__all__` escape. |
| `/staff/results`            | Staff is blocked. Dean → only applicants in their college. SSO/Admin → all. |
| `/admin/users`, `/admin/school-year`, `/admin/settings` | Admin only. |
| `/admin/courses`            | Admin → all courses. Dean → can edit `max_slots` on courses in their college. |
| `/admin/audit-log`          | Admin + Staff/Dean (read-only). |

---

## 6. Edge Cases & Business Rules

### 6.1 Course is full at registration
Cap check runs against `course_caps.max_slots` vs current `accepted` count. Registration is blocked with a clear error and the course gets a red "Full" badge in the UI.

### 6.2 Student fails the exam
Stays at `overall_status = 'exam'`. `suggest_alt_courses()` lists courses with a lower `pass_from` that the score would have qualified for. SSO can suggest one via `/staff/results/suggest/{id}`. The student sees the suggestion on `/student/result` and can accept (which changes their `course_applied`) or decline.

### 6.3 Document rejection / resubmission
Rejecting a document does NOT roll back the applicant if they were already past `documents`. Requesting Resubmission is a softer alternative — it puts the document back to `uploaded` with staff instructions in `staff_remarks`. Either way the student sees the reason and can re-upload.

### 6.4 Interview no-show
Staff hits **Mark No-show** on the queue row → `attendance_status = 'absent'`. If `auto_reschedule_noshows = 1`, the next sweep books them into the next available slot for their department. Staff can also reschedule manually.

### 6.5 Student reschedule request
`/student/interview` shows a "Need to reschedule?" details panel. POSTs to `/api/reschedule-request` with a free-text reason. Logged to `reschedule_requests`; staff can approve via the queue page.

### 6.6 Admissions window closed
`/register` shows a "Closed" page. Existing applicants are unaffected and can still log in to continue their journey.

### 6.7 Document deadline passed
Students who haven't yet submitted see "Document Submission Closed". POST to upload/submit is blocked server-side. Submitted students proceed normally.

### 6.8 Withdrawal
Allowed at any stage before `withdrawn`. Sets `overall_status = 'withdrawn'`, `withdrawn_at = NOW()`, optional reason. The student loses their interview slot and admission result row.

### 6.9 Acceptance expired (no enrollment intent)
After `enrollment_intent_deadline_days` (default 7), accepted applicants who didn't confirm or decline are auto-withdrawn by `auto_expire_accepted_pending()` with a "Slot expired" notification.

### 6.10 Staff undoes a document approval
Allowed only if the applicant hasn't taken the exam yet. Rolls `documents.status` from `approved` to `uploaded` and `applicants.overall_status` from `exam` to `submitted`.

### 6.11 Custom courses
Admin can add courses beyond the 13 built-in PLP programs via `/admin/courses`. Each custom course gets its own strand allowlist, `pass_from`, and `max_slots`. They appear in registration immediately.

### 6.12 Session timeouts
Student sessions expire after 30 minutes of inactivity; staff sessions after 2 hours. A warning appears 5 minutes before expiry. `POST /auth/keepalive` extends the session.

---

## 7. Frequently Asked Questions

### "Can a CCS professor interview a CON student?"
No (by default). Live-queue scoping for Staff is `COALESCE(s.assigned_to, s.created_by) = me` — and a Staff member can only create sessions in their own department, so they will never end up assigned to a CON session. An Admin/SSO can override by explicitly assigning across colleges, but that's a deliberate action, not the default.

### "What if someone uploads a fake document?"
Auto-validation catches blank pages, corrupted files, wrong formats, and PDFs without text. It does **not** verify authenticity — that still needs human eyes. The Puter AI fallback runs client-side and gives a confidence score, but it's an aid, not a guarantee.

### "What prevents impersonation at the exam?"
Login + per-slot access password + name shown on the exam interface. There's no facial verification or proctoring software. In-room proctors should still check physical IDs.

### "What happens if the server dies mid-exam?"
Answers autosave to `exam_drafts` every 60 s. On reload after recovery, drafts are restored.

### "Can staff manipulate results?"
Every state change writes to `audit_logs` (actor user, IP, action, entity, timestamp). The admin audit log at `/admin/audit-log` shows the full trail. Logs are stored in the same DB as the data, so an admin with raw DB access could tamper — for high-stakes deployments, export the log to an external store.

### "How many applicants can it handle?"
Realistically, single-institution scale (a few thousand applicants per cycle). MySQL pagination is everywhere, queries are indexed, exam slots have configurable capacity. The exam submit path is the hot spot — under simultaneous heavy submission load you'd want a queue.

### "Can we run two school years simultaneously?"
No. `current_school_year` is a single global setting; only one exam can be `is_active = 1`.

### "What data can we export?"
CSV from `/admin/dashboard` (applicants with filters) and `/admin/results`. No PDF letters yet.

### "Can parents log in?"
No — there's no guardian portal. Only the student account.

---

## 8. Known Gaps & Risks

| # | Gap | Severity | Status |
|---|-----|----------|--------|
| 1 | Audit logs are not append-only at the DB level — an admin with SQL access can edit them | Medium | Open |
| 2 | No 2FA for staff / admin | Medium | Open |
| 3 | No PDF report generation (admission letters, exam summaries) | Low | Open |
| 4 | Exam UI is laptop-oriented; mobile layout is rough | Low | Open |
| 5 | No backup/restore docs — `schema.sql` is destructive | Medium | Open |
| 6 | No accessibility (ARIA / screen-reader) pass | Low | Open |
| 7 | Rejected students can't reapply in a future cycle without admin intervention | Low | Open |
| 8 | No support for concurrent school years | Low | By design |
| 9 | Waitlist tier is half-retired — schema still allows it but the UI doesn't emit it | Low | Tech debt |

Already addressed in earlier work (kept here for historical context):

- Email verification (verification email + code form).
- Duplicate applicant detection on registration.
- Exam autosave (`exam_drafts`).
- Student-initiated reschedule requests.
- Applicant type change before submission.
- Login rate limiting (15-minute lockout after 5 failed attempts).
- CSP / X-Frame-Options / X-Content-Type-Options security headers.
- Email notifications via PHPMailer + Gmail SMTP.
- Enrollment-intent flow (confirm / decline).
- Secrets in `.env`, not in source.

---

## 9. Codebase Map

### Core infrastructure

| File | Purpose |
|------|---------|
| `config/app.php` | Constants: paths, role names, document slugs per type, course list, strand maps, tier thresholds, role permissions |
| `config/db.php` | PDO MySQL connection, SSL support for cloud DBs |
| `core/bootstrap.php` | Loads config, session, auth, router, helpers, automation in order |
| `core/Auth.php` | Login / logout / role guards / `homeUrl()` |
| `core/Session.php` | Session lifecycle + flash messages |
| `core/Router.php` | Path routing including `/staff/applicants/{id}` style params |
| `core/helpers.php` | URL / CSRF helpers, admissions window, `score_to_rank`, `exam_passed`, `course_to_department`, `suggest_alt_courses`, etc. |
| `core/automation.php` | All the auto-* logic: notifications, document validation pipeline, exam slot assignment, results auto-release, no-show auto-reschedule, expire-accepted-pending |
| `core/interview_scheduler.php` | The interview-side algorithms: `assign_interview_slot`, `bulk_assign_pending_applicants`, `record_interview_evaluation`, `reschedule_absent_applicant` |

### Authentication

| Path | File |
|------|------|
| `/login` | `modules/auth/login.php` |
| `/register` | `modules/auth/register.php` |
| `/verify-email` | `modules/auth/verify_email.php` (magic-link path) |
| `/verify-pending` | `modules/auth/verify_pending.php` (6-digit code path) |
| `/forgot-password`, `/reset-password` | `modules/auth/forgot_password.php`, `modules/auth/reset_password.php` |
| `/auth/keepalive` | `modules/auth/keepalive.php` |
| `/logout` | `modules/auth/logout.php` |

### Student-facing

| Path | File |
|------|------|
| `/student/documents` | `modules/documents/student_upload.php` |
| `/student/exam` | `modules/exam/take.php` |
| `/student/interview` | `modules/interview/student_view.php` |
| `/student/result` (GET) | `modules/results/student_view.php` |
| `/student/result` (POST) | `modules/results/enrollment_intent.php` |
| `/student/settings` | `modules/settings/student.php` |

### Staff / Dean / SSO

| Path | File |
|------|------|
| `/staff/dashboard` | `modules/auth/staff/dashboard.php` |
| `/staff/applicants` (queue + per-applicant) | `modules/documents/staff_review.php` |
| `POST /staff/documents/{id}` | `modules/documents/staff_action.php` |
| `/staff/exam` (build the exam) | `modules/exam/staff_manage.php` |
| `/staff/exam/slots` | `modules/exam/staff_slots.php` |
| `/staff/exam/export-rooms` | `modules/exam/staff_export_rooms.php` |
| `/staff/interviews/setup` | `modules/interview/staff_setup.php` |
| `/staff/interviews/queue` | `modules/interview/staff_queue.php` |
| `POST /staff/interviews/call-next` | `modules/interview/staff_call_next.php` |
| `POST /staff/interviews/{id}` | `modules/interview/staff_action.php` |
| `/staff/interviews/absent` | `modules/interview/staff_absent.php` |
| `/staff/results` | `modules/results/staff_manage.php` |
| `POST /staff/results/bulk` | `modules/results/staff_bulk.php` |
| `POST /staff/results/auto-release` | `modules/results/staff_auto_release.php` |
| `POST /staff/results/suggest/{id}` | `modules/results/staff_suggest.php` |
| `POST /staff/results/{id}` | `modules/results/staff_action.php` |
| `/staff/settings` | `modules/settings/staff.php` |
| `/staff/audit-log` | `modules/audit/log.php` |

### Admin

| Path | File |
|------|------|
| `/admin/dashboard` | `modules/auth/admin/dashboard.php` |
| `/admin/users` | `modules/settings/admin_users.php` |
| `/admin/school-year` | `modules/settings/admin_school_year.php` |
| `/admin/courses` | `modules/settings/admin_courses.php` |
| `/admin/settings` | `modules/settings/admin.php` |
| `/admin/results` | `modules/results/admin_export.php` |
| `/admin/audit-log` | `modules/audit/log.php` |

### AJAX / API

| Path | File |
|------|------|
| `/api/notifications` | `modules/api/notifications.php` |
| `/api/auto-validate` | `modules/api/auto_validate.php` |
| `/api/exam-autosave` | `modules/api/exam_autosave.php` |
| `/api/reschedule-request` | `modules/api/reschedule_request.php` |
| `/api/applicant-panel` | `modules/api/applicant_panel.php` |

### Database

| File | Purpose |
|------|---------|
| `database/schema.sql` | Single-file destructive schema. Creates every table + seeds school settings, departments, courses, passing scores, the seed admin. Idempotent: drops everything first. |
| `database/seed_users.sql` | Inserts admin (id 2), SSO (3), 6 Deans (ids 4–9), 6 Staff (ids 10–15). Departments are pre-set. |
| `database/seed_demo.sql` | 121 demo applicants spread across the funnel + 36 interview sessions + 78 exam results + 299 notifications. Idempotent. All dates are relative to `CURDATE()` so today's queue is always populated. Every demo student is pre-verified. |

---

*Last verified against `baseline` after PR #4 (demo-seed fixes) merged.*
