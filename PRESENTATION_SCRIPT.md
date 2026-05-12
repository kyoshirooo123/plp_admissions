# PLP Admissions — Presentation Script

Direct, no-fluff script for each role. Read each line as the demo
clicks through. **DO:** lines are what to do on screen.

Every claim in this script is grounded in the code shipped in this
repo. Inline file references point at the exact module that backs
the behaviour so the demo and the system stay in sync. Routes are
registered in `public/index.php`. Role gates come from
`Auth::requireRole(...)` at the top of each module.

> Role redesign quick reference
>
> - **Professor (`staff`)** — interviews students and records a
>   Pass / Reject. *Recommendation only.*
> - **Dean** — final decision-maker on Results. Picks Accept or
>   Reject per row in their college; overriding the Professor's
>   recommendation requires a written reason.
> - **SSO** — operations. Sets up exams, rooms, interview
>   sessions; approves documents; handles exam / interview
>   reschedules. Does NOT release results.
> - **Admin** — superset of everything + override an already-
>   released result + Close Admissions.
> - **Proctor** — issues exam-room access codes for their own
>   college.
> - **Student** — applies, uploads docs, takes the exam, sits the
>   interview, sees the result.

---

## 1. INTRODUCTION — ADMIN

Presenter: (Admin demo) — show **Users** page

This is the PLP Admissions system. It runs the whole pipeline
from registration to released decisions in one place.

There are **6 roles**: Student, Proctor, Professor (`staff`), SSO,
Dean, Admin. Each role only sees the pages it can actually act on
— the sidebars in `views/partials/nav_*.php` are filtered per
role, so nobody sees a link that 403s when clicked.

**DO:** open `/admin/users` (`modules/settings/admin_users.php`).

To create an account: pick the role, then fill in Name, Email,
Password (min 8 chars), and Department. The code enforces:

- **Dean** accounts MUST be tied to a department.
- **Proctor** accounts MUST be tied to a department.
- SSO, Admin, and Professor (`staff`) are school-wide; department
  is optional for them.

(See the validation block in `modules/settings/admin_users.php` —
*"Dean accounts must be assigned to a department."*)

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
- **Exam Reschedules** (`/staff/exam/reschedule`) — review and
  approve/deny student exam-slot reschedule requests (with a
  red dot for pending). New flow — was not in the older script.
- **Interviews** (`/staff/interviews`) — landing or queue depending
  on role.
- **Interview Reschedules** (`/staff/interviews/absent?tab=requests`)
  — review and approve/deny interview reschedule requests.
- **Results** (`/staff/results`) — release decisions.
- **Users** (`/admin/users`) — Admin-only.
- **Audit Log** (`/admin/audit-log`) — Admin-only
  (`Auth::requireRole(ROLE_ADMIN)` in `modules/audit/log.php`).

Settings (`/admin/settings`, `modules/settings/admin.php`) is
Admin-only and covers School Branding (name, logo, accent color)
plus the Admin's own password change. CSV export of every result
is at `/admin/results` (`modules/results/admin_export.php`).

---

## 2. BUILD EXAM / SET EXAM SLOT / SET INTERVIEW SLOT — SSO (Huenda)

Presenter: log in as SSO

SSO is the operations role. They set up everything the student
walks through — the exam, the rooms, and the interview sessions.
SSO does NOT conduct interviews and does NOT release results
(those are Professor and Dean respectively, see sections 7 and 8).

### Build Exam

**DO:** open `/staff/exam` (`modules/exam/staff_manage.php`,
gated to SSO + Admin).

Click **Create Exam**. The title is auto-derived server-side as
`PLP Admissions Test ({current_school_year})` — I don't type it.
I just fill in the Description and tick the two shuffle toggles:

- Shuffle Questions
- Shuffle Choices

Both flags live on the `exams` row (`shuffle_questions`,
`shuffle_choices` in `database/schema.sql`), so no two students
get the same order.

**DO:** add questions. The builder supports 6 question types,
each colour-coded by type (see `$SECTION_COLORS` in
`staff_manage.php`):

| Type             | Auto-graded?                                  |
|------------------|-----------------------------------------------|
| Multiple Choice  | Yes                                           |
| Checkboxes       | Yes                                           |
| Dropdown         | Yes                                           |
| Short Answer     | Yes (exact-match if a correct answer is set)  |
| Paragraph        | No (0 pts unless manually graded)             |
| Linear Scale     | Yes (any in-range pick)                       |

(Scoring lives in `modules/exam/take.php`.)

There's no separate "activate" step — `create_exam` deactivates
the previous exam and inserts the new one with `is_active = 1`.

### Set Exam Slot

**DO:** open `/staff/exam/slots` (`modules/exam/staff_slots.php`).

Three modes, chosen by query string:

- No params → college selector grid (Admin / SSO only).
- `?college=...` → card grid of slots for that college, the
  **+ Add Slot** dashed card, **Batch Create** for multiple rooms,
  and the awaiting-applicants list for the same college.
- `?slot=...` → roster for one slot, with the proctor's
  Generate / Extend code controls.

A slot row carries:

- Date
- **Opens** (`slot_time`) **and Closes** (`end_time`) — per-slot,
  not per-exam. Default close = opens + 90 minutes if the form
  leaves it blank. Close time must be **strictly after** opens
  (validated server-side; CHANGES.md documents the fix).
- Room label
- Department (auto-filled from the college view)
- Capacity (defaults to `school_settings.exam_room_capacity` =
  35; capped overall by `exam_daily_cap` = 3000)

After Add, the page silently re-runs `backfill_exam_slot_assignments()`
so any applicant who reached the exam stage *before* a matching
slot existed gets auto-assigned to this new one and the success
flash counts them (e.g. *"Auto-assigned 4 waiting applicant(s)."*).

Once a student has all documents approved, `auto_assign_exam_slot()`
in `core/automation.php` puts them in the earliest open slot in
their department (or any open slot if there's no department-specific
one), increments `filled`, and fires a notification. No manual
matching.

### Bulk Cancel & Move (new flow — typhoon scenario)

**DO:** open `/staff/exam/cancel-slot`
(`modules/exam/staff_cancel_slot.php`, SSO + Admin).

Pick the slot to cancel + a replacement slot of higher-or-equal
remaining capacity + a written reason. Submit. Every applicant
booked into the cancelled slot is moved to the new slot in a
single transaction with `FOR UPDATE` locks (so two admins can't
oversubscribe the target), and each affected student gets an
in-app notification + branded email with the reason.

### Set Interview Slot

**DO:** open `/staff/interviews/setup`
(`modules/interview/staff_setup.php`, SSO + Admin).

Same college-then-add-session pattern. Each Session row carries:

- Department (College)
- Date
- Start time, End time
- Capacity (defaults to 30 in `add_session`)
- **Assigned interviewer** — required, must be a user
- Location label (e.g. "Room 201" or "Desk A")
- Location notes (free text, optional)

(See validation in `staff_setup.php`: *"Please assign an
interviewer to this session."*)

The interviewer assigned here is the **only** person who'll see
that session's applicants on the live queue, with `created_by`
as the legacy fallback (`COALESCE(s.assigned_to, s.created_by)`
in `staff_queue.php`).

Once a student passes the exam, `assign_interview_slot()` in
`core/interview_scheduler.php` auto-books them into the
least-filled session in their department and marks them
`checked_in` immediately — students never have to "check in"
manually.

### Bulk Cancel & Move (interview side)

**DO:** open `/staff/interviews/cancel-slot`
(`modules/interview/staff_cancel_slot.php`, SSO + Dean + Admin).

Mirror of the exam-side cancel-and-move. Reschedules every
applicant booked into one session into another in one click,
with full notifications and audit. Dean is added here because
interview ownership lives in their college.

---

## 3. SET MAX SLOTS / TIER THRESHOLDS — DEAN (Chavez)

Presenter: log in as Dean

Dean is oversight + standards-setting for their own college.
They cannot create or delete courses or edit any other college's
courses. **In the role redesign, Dean is also the release
authority on the Results page** (see section 8).

**DO:** open `/admin/courses` (`modules/settings/admin_courses.php`).

Dean writes are scoped server-side:

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

**Passing = Average and above** (the code derives `pass_from`
from `avg_from` automatically). Anything below the Average
threshold fails the exam.

Every change here lands in the audit log
(`audit_log('course_caps_updated', ...)` and
`audit_log('passing_scores_updated', ...)`).

Dean does NOT see the Add Course / Delete Course buttons —
those are rendered only when `$canManageCourses` is true.

---

## 4. CREATE ACCOUNT — STUDENT (Jj Bassig)

Presenter: log in as a new applicant

**DO:** open `/register` (`modules/auth/register.php`).

If `admissions_is_open()` is false (no window set, or today is
outside it), the page just shows an "Admissions Closed" card with
the window dates. No form.

When open, the form collects:

- First / Middle / Last name + Suffix
- Birthdate, Sex (M/F)
- Street address + Barangay (must match the hard-coded list of
  30 Pasig City barangays)
- Phone, Email
- Password (min 8 chars) + Confirm
- Applicant type: Freshman / Transferee / Foreign
- Course applied
- SHS Strand (Freshmen only)
- hCaptcha — only if `HCAPTCHA_SITE_KEY` is configured

The course-cap check runs at submit time: if accepted students
for the chosen course already equal `course_caps.max_slots`,
the form blocks with *"This course has reached its enrollment
cap…"*. Capped courses are also visually hidden / disabled in
the dropdown.

Also enforced: no duplicate name+birthdate pair, no duplicate
email, and for freshmen the strand must be in the allowed list
for the chosen course (`get_all_strand_map()`).

**DO:** submit → land on `/verify-pending`.

Verification is two-channel. The system emails BOTH a one-click
magic link AND a 6-digit code (`generate_verify_credentials()`
+ `send_verification_email()`). Either works.

**DO:** verify → log in.

After login the student sees the **4-step stepper**
(`views/partials/stepper.php`):

> Submit Documents → Entrance Exam → Interview → Result

**DO:** open `/student/documents`. Upload the required documents
— the list comes from `docs_for_type($applicant_type)` so it
varies by applicant type (Freshman / Transferee / Foreign).
Uploads run a quick file-type / size / integrity check at submit
time (the older OCR-based `api/auto-validate` endpoint has been
retired in this build).

**DO:** submit application. The applicant's `overall_status`
flips from `pending` → `documents` → `submitted` and SSO can now
review.

---

## 5. APPROVE DOCUMENTS — SSO (Huenda)

Presenter: log in as SSO

**DO:** open `/staff/applicants` (`modules/documents/staff_review.php`,
gated to SSO + Admin).

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
**Approve All Pending Reviews** (`approve_all_in_review`) from
the toolbar — same advance + auto-assign logic, just in a batch.

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
`generate_exam_password()` (`core/helpers.php`):

- **6-character** code, uppercase letters + digits
- Avoids ambiguous chars (no `0/O`, no `1/I/L`)
- Valid for **`EXAM_PASSWORD_EXPIRY_SECONDS = 300`** = **5 minutes**

(The on-screen helper text under the roster reads exactly that:
*"Codes are valid for 5 minutes."* Note: a stale comment near
the top of `staff_slots.php` still says "8-character" — the
implementation is 6.)

**DO:** read the code aloud. Students enter it at `/student/exam`
to start.

If 5 minutes isn't enough:

- **Extend** — keeps the same code, resets `password_issued_at = NOW()`
  so the 5-minute countdown restarts.
- **New** (Generate again) — issues a fresh code and invalidates
  the current one.

Both actions are audited (`exam_slot_code_extended` /
`exam_slot_code_generated`).

**DO:** show the student side. The student types the code; the
exam renders Google-Forms style. On submit:

- Objective questions auto-grade in `modules/exam/take.php`
  (MC, Checkboxes, Short Answer with exact-match if a key is
  set, Linear Scale, Paragraph = 0 pts).
- `score_to_rank()` maps the raw score to a **1–10 rank** by
  percentage.
- `exam_passed()` compares the rank against the course's
  `pass_from` threshold.
- Pass → applicant flips to `interview` status and
  `assign_interview_slot()` immediately books an interview.
- Fail → applicant stays at `exam` and the result screen shows
  "Suggested alternative courses" derived from
  `suggest_alt_courses()`.

### Student-side reschedule

If a student can't make their exam slot, they can fire a
self-service reschedule request from `/student/exam` (the
*Request Reschedule* button posts to
`POST /api/exam-reschedule-request`,
`modules/api/exam_reschedule_request.php`). It inserts a
pending row in `exam_reschedule_requests` and notifies SSO /
Proctor / Dean / Admin. Approval happens on
`/staff/exam/reschedule` (`modules/exam/staff_reschedule.php`)
— read-only for everyone except SSO + Admin, who can approve
(auto-assign to a chosen slot or earliest matching slot) or
deny with a reason.

---

## 7. CONDUCT INTERVIEW — PROFESSOR (Cabiles)

Presenter: log in as Professor (`staff`)

Professor's sidebar (`views/partials/nav_staff.php`) has only
Dashboard and Interview Queue. They cannot touch documents,
exam, or results.

**DO:** open `/staff/interviews/queue`
(`modules/interview/staff_queue.php`).

Scope rules (from the file header):

- Admin / SSO see everyone (SSO is bounced to setup if they
  land here — SSO doesn't conduct).
- Dean sees every row whose slot belongs to their own college
  (oversight, read-only).
- Professor sees only rows on a session **they personally own**
  (`COALESCE(s.assigned_to, s.created_by) = $staffId`).

Statuses visible: `scheduled`, `checked_in`, `in_progress`,
`completed`, `no_show`. Students are auto-checked-in the moment
their interview slot is assigned, so most rows arrive as
`checked_in` without any manual click.

**Auto no-show** is fully automatic — every page load, this
query flips any still-waiting / in-progress row past its end
time to `no_show` + `absent`:

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

There is **no manual "No-show" button** in the queue UI — the
page header says so explicitly.

**DO:** filter by date / session using the toolbar dropdowns.
Only dates with actual queue rows in the user's scope are shown
— no dead options.

**DO:** click **Call Next** (`staff_call_next.php`). The query
picks the lowest-`queue_number` `checked_in` row on today's
slots owned by the logged-in interviewer and advances it to
`in_progress`. If nobody is waiting, the page flashes
*"No applicants are waiting in the queue."*

**DO:** click into an applicant — the side drawer
(`views/partials/applicant_drawer.php`) shows name, course,
applicant type, exam pass/fail with score, documents, and an
inline notes field.

**DO:** record the evaluation. The modal posts
`complete_with_evaluation` (`modules/interview/staff_action.php`)
with:

- `evaluation_result` = **`pass` or `reject`** (required)
- `interview_notes` (free text, optional)

> Terminology change: the evaluation outcomes are **Pass / Decline**
> in the UI (stored as `pass` / `reject`). The previous build
> stored the negative side as `fail` — that's gone now.

Server-side guards:

- The auth gate (`Auth::requireRole(ROLE_STAFF, ROLE_SSO, ROLE_ADMIN)`)
  excludes Dean — Dean is read-only on the queue.
- An evaluation can now be recorded on **any date** — the
  previous build only allowed it on the slot's scheduled date;
  that check has been removed.

On save, the row gets `status=completed`, `interview_status=completed`,
`attendance_status=present`, `evaluated_at=NOW()`, AND the
applicant's `overall_status` flips to `released` so the row
immediately appears on the Results page. This is still a
**recommendation** — the Dean is the one who actually releases
(section 8).

### Marking absent / no-show

`mark_absent` exists for the rare case where Professor wants to
manually record an absence (e.g. student walked out). It sets
the full canonical absent state:

```
UPDATE interview_queue q ...
   SET q.status            = "no_show",
       q.interview_status  = "absent",
       q.attendance_status = "absent",
       q.evaluated_at      = NOW()
```

So the row correctly surfaces on `/staff/interviews/absent`
where SSO / Admin / Dean handle reschedules.

If a student doesn't show, no cleanup is needed — the slot's end
time is the timer. The student gets pushed to
`/staff/interviews/absent` where reschedules are handled, and
they can also file a self-service reschedule request from
`/student/interview` (`api/reschedule_request`).

---

## 8. RELEASE FINAL RESULTS — DEAN (Chavez)

Presenter: log in as Dean

This is the **last gate**. With the role redesign:

- **Dean** is the release authority on `/staff/results`.
- **Admin** has the same powers + can override an already-released
  row + can Close Admissions.
- **SSO is locked out of this page entirely**
  (`Auth::requireRole(ROLE_DEAN, ROLE_ADMIN)` at the top of
  `staff_manage.php`, `staff_action.php`, and `staff_bulk.php`).

**DO:** open `/staff/results`.

The page is dept-scoped for Dean: `a.course_applied IN (...dean's
college courses...)` — they only see their own college. Admin
sees everyone.

A panel at the top shows **per-course slot capacity** so the
Dean can see, at a glance, how many they've already accepted
vs. their `max_slots` cap (`course_caps`).

Five buckets, computed by a single SQL CASE:

```
CASE
  WHEN a.overall_status = 'withdrawn'                       THEN 'withdrawn'
  WHEN ar.result IS NOT NULL                                THEN 'released'
  WHEN er.passed = 0 OR iq.evaluation_result = 'reject'     THEN 'ready_reject'
  WHEN er.passed = 1 AND iq.evaluation_result = 'pass'      THEN 'ready_accept'
  ELSE 'awaiting'
END
```

| Bucket             | Label in UI            | What it means                                  |
|--------------------|------------------------|------------------------------------------------|
| `awaiting`         | Awaiting interview     | Exam done, interview not yet evaluated.        |
| `ready_accept`     | **Recommended: Accept**| Exam passed AND Professor marked Pass.         |
| `ready_reject`     | **Recommended: Decline**| Exam failed OR Professor marked Reject.       |
| `released`         | Released               | Final decision sent to applicant.              |
| `withdrawn`        | Withdrawn              | Student pulled out of the cycle.               |

The buckets are now named after the **recommendation**, not the
verdict — the recommendation is just an input to the Dean's
final call.

### Per-row release (Accept or Reject — Dean's call)

**DO:** click into **Recommended: Accept**.

Each row exposes TWO buttons in this bucket:

- **Accept** (green) — *matches* the Professor's recommendation.
  One click + confirm. Posts `action=release`,
  `decision=accepted`.
- **Reject** (red) — *overrides* the recommendation. Opens an
  override modal that demands a written `reason` (non-empty
  trim). Posts `action=release`, `decision=rejected`,
  `reason="..."`.

In **Recommended: Decline** the polarity is flipped — Reject is
the matching path, Accept is the override.

Override logic (`modules/results/staff_action.php`):

```
$recommended = ($examPassed === 0 || $interviewRes === 'reject')
    ? 'rejected'
    : (($examPassed === 1 && $interviewRes === 'pass') ? 'accepted' : null);

$isOverride = ($recommended !== null && $recommended !== $decision);

if ($isOverride && $reason === '') {
    Session::flash('error',
        'A written reason is required to release this applicant as '
        . ucfirst($decision) . ' against the Professor\'s recommendation.');
    redirect('/staff/results');
}

$remarks = $isOverride ? $reason : null;
```

So **every override is tied to a reason** and the reason is
stored on `admission_results.remarks` (and in the audit log) —
this is the audit trail the previous build only attached to
post-release edits.

Releasing an Awaiting row is blocked server-side:

```
if ($interviewRes !== 'pass' && $interviewRes !== 'reject' && $examPassed !== 0) {
    Session::flash('error', '...interview hasn\'t been recorded yet...');
}
```

So the Dean cannot release someone the Professor hasn't actually
seen.

On release, the system:

- Upserts an `admission_results` row (with `result`, `remarks`,
  `released_by`, `released_at`).
- Sets `applicants.overall_status = 'released'`.
- Calls `notify_stage_transition($id, 'released', 'Result: …')`
  → in-app + email.
- Writes the audit entry (`admission_result_released`).

### Bulk Accept / Bulk Reject

Toolbar buttons let the Dean tick rows in either Recommended
bucket and release them all at once
(`modules/results/staff_bulk.php`, `action=bulk_accept` /
`bulk_reject`). The server walks the selected ids, skips
already-released / withdrawn / awaiting rows, and applies the
same upsert + audit per applicant. If the bulk action contains
overrides, the toolbar prompts for a single shared reason.

### Auto Release (Admin only)

`POST /staff/results/auto-release`
(`modules/results/staff_auto_release.php`) is now **Admin-only**.
It calls `auto_release_results()` in `core/automation.php`,
which walks every applicant in Recommended: Accept and
Recommended: Decline and releases them with the matching
decision. It does NOT touch Awaiting rows and it does NOT
require a reason because every choice matches the recommendation
by construction.

### Course Suggestion (Dean / Admin)

A failed-exam applicant who still qualifies for a different
course can be steered there from the Results page. The
**Suggest Course** modal posts `POST /staff/results/suggest/{id}`
(`modules/results/staff_suggest.php`). The server validates that
the suggested course's `pass_from` threshold is met by the
applicant's stored `rank_score`, then upserts a row in
`course_suggestions` with status `pending`. The applicant sees
the suggestion on their result page and can accept it.

### Close Admissions (Admin only)

A red **Close Admissions** button in the toolbar (rendered only
when `$canCloseCycle = ($role === ROLE_ADMIN)`) opens a modal
that demands a reason and confirms an irreversible bulk-reject.
On submit, `modules/results/staff_bulk.php` (`action=close_admissions`)
selects every applicant in the current cycle that has no
`admission_results` row and isn't withdrawn, upserts a
`rejected` row with the supplied reason, flips
`overall_status=released`, notifies them, and writes
`admission_close_admissions` to the audit log per row.

This is the path the old script described — the previous build
didn't actually have it.

### Edit / Override after release (Admin only)

If a result is already released and someone needs to flip it,
that's the Edit action — still Admin-only, still requires a
written reason, still audited (`admission_result_override`).

### Export

Once admissions close, Admin can pull the full CSV from
`/admin/results` (`modules/results/admin_export.php`) — name,
email, type, course, school year, stage, result, remarks,
released-at, exam score, total items.

---

## End

Thank you. The system enforces the **right person doing the
right job at the right stage**:

- **SSO** sets up the exam, the rooms, and the interview
  sessions; approves documents; handles exam + interview
  reschedules.
- **Proctor** runs exam-day codes for their own college.
- **Professor** conducts interviews and records a Pass / Reject
  recommendation.
- **Dean** owns the final Accept / Reject release for their own
  college; overrides require a written reason.
- **Admin** owns everything plus Close Admissions + override
  edits + auto-release + audit-log access.
- **Student** moves through 4 stages, one at a time.

Everything that doesn't need a human runs itself — exam-slot
assignment, interview-slot assignment, auto-check-in, auto
no-show, exam auto-grading, notifications, audit logging, and
the new exam / interview cancel-and-move workflows. Every
significant action lands in `/admin/audit-log` so the trail is
intact.
