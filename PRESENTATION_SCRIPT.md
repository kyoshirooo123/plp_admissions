# PLP Admissions — Presentation Script

Direct, no-fluff script for each role. Read each line as the demo
clicks through. **DO:** lines are what to do on screen.

Every claim in this script is grounded in the code. Inline file
references point at the exact module that backs the behavior so the
demo and the system stay in sync. Routes are registered in
`public/index.php`. Role gates come from `Auth::requireRole(...)` at
the top of each module.

---

## 1. INTRODUCTION — ADMIN

Presenter: (Admin demo) — show **Users** page

This is the PLP Admissions system. It runs the whole pipeline from
registration to released decisions in one place.

There are **6 roles**: Student, Proctor, Professor (`staff`), SSO,
Dean, Admin. Each role only sees the pages it can actually act on —
the sidebars in `views/partials/nav_*.php` are filtered per role, so
nobody sees a link that 403s when clicked.

**DO:** open `/admin/users`. (Backed by `modules/settings/admin_users.php`.)

To create an account: pick the role, then fill in Name, Email,
Password (min 8 chars), and Department. The code enforces:

- **Dean** accounts MUST be tied to a department.
- **Proctor** accounts MUST be tied to a department.
- SSO, Admin, and Professor (`staff`) are school-wide; department
  is optional for them.

(See the validation block in `modules/settings/admin_users.php` —
`'Dean accounts must be assigned to a department.'`)

**DO:** create a sample staff account → show it appear in the list.

That account is now ready to log in.

Admin's sidebar (`views/partials/nav_admin.php`):

- **Dashboard** — pipeline stats.
- **School Year** (`/admin/school-year`) — set the admissions
  window (Open date, Close date, Document Deadline). The school
  year string is auto-derived from the open date.
- **Courses & Strands** (`/admin/courses`) — add/edit/delete custom
  courses, map SHS strands, set Pass / Average / High tier
  thresholds, and set per-course enrollment caps for the active
  school year.
- **Documents** (`/staff/applicants`) — review submitted docs.
- **Exam** (`/staff/exam`) — build the entrance exam.
- **Interviews** — landing or queue depending on role.
- **Reschedules** (`/staff/interviews/absent`) — handle no-shows
  and student reschedule requests.
- **Results** (`/staff/results`) — release decisions.
- **Users** (`/admin/users`) — Admin-only.
- **Audit Log** (`/admin/audit-log`) — Admin-only
  (`Auth::requireRole(ROLE_ADMIN)` in `modules/audit/log.php`).

Settings (`/admin/settings`, `modules/settings/admin.php`) is
Admin-only and covers School Branding (name, logo, accent color)
plus the Admin's own password change. CSV export of every result is
at `/admin/results` (`modules/results/admin_export.php`).

---

## 2. BUILD EXAM / SET EXAM SLOT / SET INTERVIEW SLOT — SSO (Huenda)

Presenter: log in as SSO

SSO is the operations role. They set up everything the student
walks through — the exam, the rooms, and the interview sessions.
SSO does NOT conduct interviews and does NOT release results
(that's later).

### Build Exam

**DO:** open `/staff/exam`. (Backed by `modules/exam/staff_manage.php`,
gated to SSO + Admin.)

Click **Create Exam**. The title is auto-derived server-side as
`PLP Admissions Test ({current_school_year})` — I don't type it.
I just fill in the Description and tick the two shuffle toggles:

- Shuffle Questions
- Shuffle Choices

Both flags live on the `exams` row (`shuffle_questions`,
`shuffle_choices` in `database/schema.sql`), so no two students get
the same order.

**DO:** add questions. The builder supports 6 question types,
each color-coded by type (see `$SECTION_COLORS` in
`staff_manage.php`):

| Type             | Auto-graded? |
|------------------|--------------|
| Multiple Choice  | Yes          |
| Checkboxes       | Yes          |
| Dropdown         | Yes          |
| Short Answer     | Yes (exact-match if a correct answer is set) |
| Paragraph        | No (0 pts unless manually graded) |
| Linear Scale     | Yes (any in-range pick) |

(Scoring lives in `modules/exam/take.php` lines 322–383.)

There's no separate "activate" step required after creating —
`create_exam` deactivates the previous exam and inserts the new one
with `is_active = 1`.

### Set Exam Slot

**DO:** open `/staff/exam/slots`. (Backed by `modules/exam/staff_slots.php`.)

This page has three modes, chosen by query string:

- No params → college selector grid (Admin / SSO only).
- `?college=...` → card grid of slots for that college, plus
  the **+ Add Slot** dashed card, plus the awaiting-applicants
  list for the same college.
- `?slot=...` → roster table for one slot, with the
  proctor's Generate / Extend code controls.

Pick a college, then **+ Add Slot**. Fields the form requires:

- Date
- Start time, End time (per-slot, not per-exam)
- Room label
- Department (auto-filled from the college view)
- Capacity (defaults to `school_settings.exam_room_capacity` =
  35; capped overall by `exam_daily_cap` = 3000)

There's also **Batch Create** for multiple rooms on the same day.

Once a student has all documents approved, `auto_assign_exam_slot()`
in `core/automation.php` puts them in the earliest open slot in
their department (or any open slot if there's no department-specific
one), increments `filled`, and fires a notification. No manual
matching.

### Set Interview Slot

**DO:** open `/staff/interviews/setup`. (Backed by
`modules/interview/staff_setup.php`, gated to SSO + Admin.)

Same college-then-add-session pattern. Each Session row carries:

- Department (College)
- Date
- Start time, End time
- Capacity (defaults to 30 in `add_session`)
- Assigned interviewer — required, must be a user
- Location label (e.g. "Room 201" or "Desk A")
- Location notes (free text, optional)

(See validation in `staff_setup.php`: *"Please assign an interviewer
to this session."*)

The interviewer assigned here is the **only** person who'll see
that session's applicants on the live queue, with `created_by` as
the legacy fallback (`COALESCE(s.assigned_to, s.created_by)` in
`staff_queue.php`).

Once a student passes the exam, `assign_interview_slot()` in
`core/interview_scheduler.php` auto-books them into the
least-filled session in their department and marks them
`checked_in` immediately — students never have to "check in"
manually.

---

## 3. SET MAX SLOTS / TIER THRESHOLDS — DEAN (Chavez)

Presenter: log in as Dean

Dean is oversight + standards-setting for their own college only.
They cannot create or delete courses, edit any other college's
courses, or release results.

**DO:** open `/admin/courses`. (Backed by
`modules/settings/admin_courses.php`, which gates writes by role.)

Dean writes are scoped server-side. From the code:

```
// Dean can only edit thresholds for courses in their own college.
$writableCourses = $canManageCourses
    ? $allCourses
    : array_values(array_intersect($allCourses, $scopedCourses));
```

For each course in my college I can edit:

- **Max Slots** — the enrollment cap. Once accepted students
  hit this cap, registration to the course is blocked (enforced
  at `/register` in `modules/auth/register.php` against
  `course_caps.max_slots`).
- **High threshold** (rank 7–10 → "High" tier)
- **Average threshold** (rank below High but ≥ this → "Average")

**Passing = Average and above** (the code derives `pass_from` from
`avg_from` automatically — see `staff_courses` line 172). Anything
below the Average threshold fails the exam.

Every change here lands in the audit log
(`audit_log('course_caps_updated', ...)` and
`audit_log('passing_scores_updated', ...)`).

Note: Dean does NOT see this page's Add Course / Delete Course
buttons — those are rendered only when `$canManageCourses` is true.

---

## 4. CREATE ACCOUNT — STUDENT (Jj Bassig)

Presenter: log in as a new applicant

**DO:** open `/register`. (Backed by `modules/auth/register.php`.)

If `admissions_is_open()` is false (no window set, or today is
outside it), this page just shows an "Admissions Closed" card with
the window dates. No form.

When open, the form collects:

- First / Middle / Last name + Suffix
- Birthdate, Sex (M/F)
- Street address + Barangay (must match the hardcoded list of 30
  Pasig City barangays)
- Phone, Email
- Password (min 8 chars) + Confirm
- Applicant type: Freshman / Transferee / Foreign
- Course applied
- SHS Strand (Freshmen only)
- hCaptcha — only if `HCAPTCHA_SITE_KEY` is configured

The course-cap check runs at submit time
(`register.php` lines 106–125): if accepted students for the chosen
course already equal `course_caps.max_slots` for this school year,
the form blocks with *"This course has reached its enrollment cap…"*.
Capped courses are also visually hidden / disabled in the dropdown
via the `$fullCourses` array prepared on line 276.

Also enforced: no duplicate name+birthdate pair, no duplicate email,
and for freshmen the strand must be in the allowed list for the
chosen course (`get_all_strand_map()`).

**DO:** submit → land on `/verify-pending`.

Verification is two-channel. The system emails BOTH a one-click
magic link AND a 6-digit code (see `generate_verify_credentials()`
+ `send_verification_email()` invoked from `register.php` line
249). The student can use either.

**DO:** verify → log in.

After login the student sees the **4-step stepper**
(`views/partials/stepper.php`):

> Submit Documents → Entrance Exam → Interview → Result

**DO:** open `/student/documents`. Upload required documents — the
list comes from `docs_for_type($applicant_type)` so it varies by
applicant type (Freshman / Transferee / Foreign). Each upload runs
`api/auto_validate` (format, size, integrity).

**DO:** submit application. The applicant's `overall_status`
flips from `pending` → `documents` → `submitted` and SSO can now
review.

---

## 5. APPROVE DOCUMENTS — SSO (Huenda)

Presenter: log in as SSO

**DO:** open `/staff/applicants`. (Backed by
`modules/documents/staff_review.php`, gated to SSO + Admin.)

Every applicant who has uploaded shows up here. Search, filter,
and bulk-select are all in the toolbar.

**DO:** click an applicant → review each document.

Per-document actions (`modules/documents/staff_action.php`):

- **Approve** — accept it as valid.
- **Request Resubmission** — requires a written reason; sets the
  doc back to `rejected`, rolls the applicant back to `documents`
  status, and fires an in-app notification with the reason.
- **Approve All** — approve every uploaded/under-review doc for
  this applicant in one click.
- **Unapprove** — revert a single approval (only allowed while
  the applicant hasn't yet taken the exam).

There is **no** plain "Reject" button — the codebase removed it
deliberately. Request Resubmission has the same end state but
also notifies the student, so it's the only path back.

The moment every required doc for an applicant is `approved`:

```
UPDATE applicants
   SET overall_status = "exam",
       documents_approved_at = NOW()
 WHERE id = ?;
notify_stage_transition($id, 'exam');
auto_assign_exam_slot($id);   // earliest open dept slot
```

So advancement → exam → slot assignment → notification all happen
in one server hop.

**DO:** bulk-approve several students using
**Approve Selected** (`bulk_approve_selected`) or
**Approve All Pending Reviews** (`approve_all_in_review`) from the
toolbar — same advance + auto-assign logic, just in a batch.

---

## 6. GENERATE EXAM CODE — PROCTOR (Lowhel)

Presenter: log in as Proctor

Proctors handle the exam room on exam day. The sidebar
(`views/partials/nav_proctor.php`) only shows Dashboard and
Exam Slots — nothing else.

**DO:** open `/staff/exam/slots`. Proctor lands directly on their
own college's slot grid (no college selector — proctors can only
manage one college).

Click into the room. Inside, the page renders the roster for that
slot and exposes the code controls — gated by:

```
$canGenerateCodeFor = function (string $slotDept) ... {
    if ($isAdmin || $isSSO) return true;
    if ($isProctor && $slotDept !== '' && $slotDept === $staffDept) return true;
    return false;
};
```

So a Proctor can ONLY generate a code for a room in their own
department.

**DO:** click **Generate Code**. The system runs
`generate_exam_password()` (`core/helpers.php` line 602):

- **6-character** code, uppercase letters + digits
- Avoids ambiguous chars (no `0/O`, no `1/I/L`)
- Valid for **`EXAM_PASSWORD_EXPIRY_SECONDS = 300`** = **5 minutes**

(Yes — the on-screen helper text under the roster reads
"Codes are valid for 5 minutes.")

**DO:** read the code aloud. Students enter it at `/student/exam`
to start.

If 5 minutes isn't enough:

- **Extend** — keeps the same code, resets `password_issued_at = NOW()`
  so the 5-minute countdown restarts.
- **New** (Generate again) — issues a fresh code and invalidates the
  current one.

Both actions are audited (`exam_slot_code_extended` /
`exam_slot_code_generated`).

**DO:** show the student side. The student types the code; the
exam renders Google-Forms style. On submit:

- Objective questions auto-grade in `modules/exam/take.php` (MC,
  Checkboxes, Short Answer with exact-match if a key is set,
  Linear Scale, Paragraph = 0 pts).
- `score_to_rank()` maps the raw score to a **1–10 rank** by
  percentage.
- `exam_passed()` compares the rank against the course's
  `pass_from` threshold.
- Pass → applicant flips to `interview` status and
  `assign_interview_slot()` immediately books an interview.
- Fail → applicant stays at `exam` and the result screen shows
  "Suggested alternative courses" derived from `suggest_alt_courses()`.

---

## 7. CONDUCT INTERVIEW — PROFESSOR (Cabiles)

Presenter: log in as Professor (`staff`)

Professor's sidebar (`views/partials/nav_staff.php`) has only
Dashboard and Interview Queue. They cannot touch documents, exam,
or results.

**DO:** open `/staff/interviews/queue`. (Backed by
`modules/interview/staff_queue.php`.)

Scope rules (from the file header):

- Admin / SSO see everyone (SSO is bounced to setup if they land
  here — SSO doesn't conduct).
- Dean sees every row whose slot belongs to their own college
  (oversight, read-only).
- Professor sees only rows on a session **they personally own**
  (`COALESCE(s.assigned_to, s.created_by) = $staffId`).

Statuses visible: `scheduled`, `checked_in`, `in_progress`,
`completed`, `no_show`. Students are auto-checked-in when
their interview slot is assigned, so most rows arrive as
`checked_in` without any manual click.

**Auto no-show** is fully automatic — every page load, this query
flips any still-waiting / in-progress row past its end time to
`no_show` + `absent`:

```
UPDATE interview_queue q
JOIN   interview_slots s ON s.id = q.slot_id
SET    q.status            = "no_show",
       q.interview_status  = "absent",
       q.attendance_status = "absent",
       q.evaluated_at      = COALESCE(q.evaluated_at, NOW())
WHERE  q.status IN ("scheduled","checked_in","in_progress")
  AND  <slot ended>;
```

There is **no manual "No-show" button** in the queue UI — the page
header says so explicitly.

**DO:** filter by date / session using the toolbar dropdowns. Only
dates with actual queue rows in the user's scope are shown — no
dead options.

**DO:** click **Call Next** (`staff_call_next.php`). The query
picks the lowest-`queue_number` `checked_in` row on today's slots
owned by the logged-in interviewer and advances it to
`in_progress`. If nobody is waiting, the page flashes
"No applicants are waiting in the queue."

**DO:** click into an applicant — the side drawer
(`views/partials/applicant_drawer.php`) shows name, course,
applicant type, exam pass/fail with score, documents, and an
inline notes field.

**DO:** record the evaluation. The modal posts
`complete_with_evaluation` (`modules/interview/staff_action.php`
lines 57–118) with:

- `evaluation_result` = `pass` or `fail` (required)
- `interview_notes` (free text, optional)

Server-side guards:

- Dean and SSO are blocked (*"Only Professors / Admin can record
  an evaluation."*).
- The slot's `slot_date` MUST be today — past dates have
  auto-flipped to no-show; future dates haven't happened yet.

On save, the row gets `status=completed`, `interview_status=completed`,
`attendance_status=present`, and `evaluated_at=NOW()`. The applicant
stays in `interview` status — this is a **recommendation**, not the
final decision. SSO/Admin still has to release.

If a student doesn't show, no cleanup is needed — the slot's end
time is the timer. The student gets pushed to
`/staff/interviews/absent` (Admin / SSO) where reschedules are
handled, and they can also file a self-service reschedule request
from `/student/interview` (`api/reschedule_request`).

---

## 8. RELEASE FINAL RESULTS — SSO / ADMIN

Presenter: log in as SSO (or Admin)

This is the **last gate**. The release page is gated to SSO,
Admin, and Dean — but Dean is read-only there. Only SSO and Admin
can press the release buttons. **Dean does NOT release.**

(From `modules/results/staff_action.php`: `Auth::requireRole(ROLE_SSO, ROLE_ADMIN);`
and from `modules/results/staff_manage.php` header: *"Dean is
read-only — never sees release/edit buttons."*)

**DO:** open `/staff/results`.

Five buckets, computed by a single SQL CASE expression:

```
CASE
  WHEN a.overall_status = 'withdrawn'                THEN 'withdrawn'
  WHEN ar.result IS NOT NULL                         THEN 'released'
  WHEN er.passed = 0 OR iq.evaluation_result='fail'  THEN 'ready_reject'
  WHEN er.passed = 1 AND iq.evaluation_result='pass' THEN 'ready_accept'
  ELSE 'awaiting'
END
```

- **Awaiting** — exam done, interview not yet evaluated.
- **Ready: Accept** — exam passed AND Professor marked Pass.
- **Ready: Reject** — exam failed OR Professor marked Fail.
- **Released** — final decision already sent.
- **Withdrawn** — student pulled out of the cycle.

For Dean, the list is **dept-scoped** server-side
(`a.course_applied IN (...dean's college courses...)`) — they see
their own college only, but with read-only badges.

**DO:** click into **Ready: Accept**. Each row has a single
"Release as Accept" button.

The server **computes** the decision — there's no Accept-vs-Reject
toggle at release time. From `staff_action.php` lines 104–117:

```
if ($examPassed === 0 || $interviewRes === 'fail') {
    $decision = 'rejected';
} elseif ($examPassed === 1 && $interviewRes === 'pass') {
    $decision = 'accepted';
}
```

So pressing release on a Ready: Accept row → `accepted`. Pressing
release on a Ready: Reject row → `rejected`. The applicant gets the
result on their dashboard and via `notify_stage_transition($id,
'released', ...)`.

**Edit / override after release** is **Admin-only** and requires a
written `remarks` reason — this is the only place a "written
reason" is enforced, and it's logged as
`admission_result_override`.

**DO:** bulk release. The toolbar's **Release Selected** posts
`release_selected` (`modules/results/staff_bulk.php`). It walks
each selected applicant and applies the same `examPassed +
evaluation_result` rule — anyone still `awaiting` is silently
skipped.

**Auto Release** (`/staff/results/auto-release`, POST) runs
`auto_release_results()` from `core/automation.php`: it walks
**every** applicant in Ready: Accept or Ready: Reject and releases
them in one batch. It does NOT touch Awaiting and does NOT bulk-reject
unreleased applicants — that path doesn't exist in the codebase.

Once admissions close, Admin can pull the full CSV from
`/admin/results` (`modules/results/admin_export.php`) — name,
email, type, course, school year, stage, result, remarks,
released-at, exam score, total items.

---

## End

Thank you. The system enforces the **right person doing the right
job at the right stage**:

- SSO sets up, reviews documents, and releases.
- Proctor runs exam-day codes.
- Professor conducts interviews and recommends pass/fail.
- Dean oversees their own college (caps, thresholds, read-only on
  Results).
- Admin owns everything plus override + audit.
- Student moves through 4 stages, one at a time.

Everything that doesn't need a human runs itself — exam-slot
assignment, interview-slot assignment, auto-check-in, auto no-show,
exam auto-grading, notifications, and audit logging. Every
significant action lands in `/admin/audit-log` so the trail is
intact.
