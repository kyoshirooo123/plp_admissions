---
title: "PLP Admissions — Presentation Script"
subtitle: "System flow walkthrough · Bilingual speaker script (Tagalog + English)"
author: "Pamantasan ng Lungsod ng Pasig"
date: "Verified against `baseline` after the latest project zip merge"
---

# System Flow Explanation for Presentation

**System Name:** PLP Admissions System
**Institution:** Pamantasan ng Lungsod ng Pasig
**Roles:** Admin · SSO · Dean · Professor (Staff) · Proctor · Student

> Every claim in this script is grounded in the actual code on `baseline`.
> Inline file references point at the exact module that backs the behaviour
> so the demo and the system stay in sync. Routes are registered in
> `public/index.php`. Role gates come from `Auth::requireRole(...)` at the
> top of each module.

> **Role redesign quick reference**
>
> - **Professor (`staff`)** — interviews students and records a Pass /
>   Decline. *Recommendation only.*
> - **Dean** — final decision-maker on Results. Picks Accept or Reject per
>   row in their college; overriding the Professor's recommendation
>   requires a written reason.
> - **SSO** — operations. Sets up exams, rooms, interview sessions;
>   approves documents; handles exam / interview reschedules and
>   bulk-move workflows. **Does NOT release results.**
> - **Admin** — superset of everything + override an already-released
>   result + Close Admissions.
> - **Proctor** — issues exam-room access codes for their own college on
>   exam day.
> - **Student** — applies, uploads docs, takes the exam, sits the
>   interview, sees the result.

---

## 1. Overall System Flow

The PLP Admissions System manages the entire student admissions process —
from the moment a student registers online until they receive their final
admission result and confirm their enrollment.

**Step-by-step overview:**

1. **Student Registration** — Student creates an account, fills personal
   info, selects a course, verifies their email.
2. **Document Submission** — Student uploads required documents
   (birth certificate, government ID, school records, etc.).
3. **Document Review** — SSO / Admin reviews and Approves or Requests
   Resubmission per document. (There is no plain "Reject" — Request
   Resubmission is the only path back.)
4. **Entrance Exam** — Once documents are approved, the student is
   auto-assigned to an exam room. On exam day they log in, enter the
   access code, and take the exam.
5. **Interview** — Students who pass the exam are auto-assigned and
   auto-checked-in to an interview slot in their department. A Professor
   conducts the interview and records **Pass** or **Decline**
   (recommendation only).
6. **Results** — The Dean (with Admin oversight) reviews the
   recommendation and picks **Accept** or **Reject** per row.
   Overriding the Professor's recommendation requires a written reason.
7. **Enrollment Confirmation** — Accepted students confirm or decline
   their slot within 7 days.

### Speaker Script (Tagalog)

> "Good day po. Allow us to present the PLP Admissions System, na ginawa
> para i-digitalize ang buong admissions process ng Pamantasan ng Lungsod
> ng Pasig.
>
> Ang overall flow po nito ay ganito: una, magre-register ang student at
> magve-verify ng email. Pagka-verified na, mag-a-upload siya ng mga
> required documents — birth certificate, school records, at iba pa.
> I-re-review po ito ng SSO o Admin.
>
> Pagka-approve ng lahat ng documents, automatic po na maa-assign ang
> student sa exam slot. Pagka-take niya ng exam at pumasa, automatic din
> po siyang maa-assign sa interview queue ng kanyang department, at
> automatic siya na naka-check in. Pagkatapos ng interview, ang Professor
> po ang magbibigay ng recommendation — Pass o Decline. Ang Dean naman
> po ang gumagawa ng final decision — Accept o Reject. Pag iba sa
> recommendation, kailangan po niyang magbigay ng written reason at
> naka-log ito sa audit trail.
>
> Pagka-released po ng result, may 7 days ang Accepted student para
> mag-confirm ng enrollment. Lahat po ng actions sa system ay naka-log
> para sa transparency at accountability."

### Speaker Script (English)

> "Good day. Allow us to present the PLP Admissions System, built to
> digitalize the entire admissions process of Pamantasan ng Lungsod ng
> Pasig.
>
> The overall flow goes like this: first, the student registers and
> verifies their email. Once verified, they upload the required
> documents — birth certificate, school records, and so on. The SSO or
> Admin reviews each document.
>
> Once all documents are approved, the student is automatically assigned
> to an exam slot. When they take the exam and pass, they are
> automatically assigned to the interview queue for their department and
> are automatically checked in. After the interview, the Professor
> records a recommendation — Pass or Decline. The Dean is the one who
> makes the final decision — Accept or Reject. Whenever the Dean's
> decision differs from the Professor's recommendation, the system
> requires a written reason, which is logged in the audit trail.
>
> Once a result is released, the Accepted student has 7 days to confirm
> enrollment. Every action in the system is logged in the audit trail
> for transparency and accountability."

---

## 2. Admin Side

The Admin has full control over the system. They can configure settings,
manage users, review documents, monitor exams and interviews, release
results (override), close the admissions cycle, and view audit logs.

### 2.1 Dashboard

**What it's for:** The Admin's landing page. Quick overview of the
current admissions cycle — counts per stage, quick shortcuts, summary
charts.

**What the user can do:** view the funnel chart (Pending, Submitted,
Exam, Interview, Released, Withdrawn); view counts per course; switch
school year via the dropdown.

**What the system automatically does:** aggregates counts from the
`applicants` table grouped by `overall_status`; renders a Chart.js bar
chart.

**Flow:** Admin logs in → lands on `/admin/dashboard` → dashboard loads
current-year data → can switch school year via dropdown → clicking a
status label navigates to the filtered applicant list.

**Output:** Visual summary of the entire admissions funnel.

#### Speaker Script (Tagalog)

> "Ito po ang Admin Dashboard. Pagka-login ng Admin, dito po siya unang
> lalapag. Makikita niya dito ang overview ng buong admissions — ilan
> ang nag-apply, ilan na ang na-approve ang documents, ilan na ang
> nag-exam, nag-interview, at na-release na ang result. May chart po ito
> para sa visual representation ng data."

#### Speaker Script (English)

> "This is the Admin Dashboard. The Admin lands here on login. It shows
> the overview of the entire admissions cycle — how many have applied,
> how many have had documents approved, how many have taken the exam,
> the interview, and how many results have been released. There is a
> chart for the visual representation of the data."

### 2.2 School Year

**What it's for:** Open and close the admissions window for each school
year.

**What the user can do:** set the admissions Open date, Close date, and
an optional Document Submission deadline. The school year label is
auto-derived from the open date (e.g. opening in 2026 → "2026-2027").

**What the system automatically does:** blocks student registration
outside the admissions window; blocks document submission after the doc
deadline; tags new applicants with the current school year.

**Flow:** Settings → School Year → fill Open + Close dates → optional
doc deadline → Save → stored in `school_settings`.

#### Speaker Script (Tagalog)

> "Sa School Year module, dito po sinu-set ng Admin kung kailan
> magbu-bukas at magsasara ang admissions. Halimbawa po, pag nag-set
> siya na June 1 hanggang August 31, sa mga dates lang po na 'yan
> makakapag-register ang students. Pag wala pa sa window o lagpas na,
> hindi po sila makakapag-sign up. May optional din po na Document
> Deadline — kung kailan ang deadline ng pag-submit ng documents."

#### Speaker Script (English)

> "In the School Year module, the Admin sets when admissions opens and
> closes. For example, if they set June 1 through August 31, students
> can only register within those dates. Outside the window — before or
> after — registration is blocked. There is also an optional Document
> Deadline that controls when document uploads are accepted."

### 2.3 Courses & Strands

**What it's for:** Manage the list of courses, their SHS strand
requirements, passing scores, and enrollment caps.

**What the user can do:** view all courses across all colleges; edit the
**High** and **Average** thresholds (rank 1–10) per course; edit
**Max Slots** per course per school year; edit allowed SHS strands per
course; add custom courses.

> Passing = Average and above. `pass_from` is derived from `avg_from` in
> code, not a separate field. Anything below Average fails the exam.

**What the system automatically does:** enforces the cap at registration
time and at result-release time; validates the student's SHS strand
against the course's allowed strands during registration.

**Flow:** Settings → Courses → see all courses with department,
`pass_from`, `max_slots`, and strands → Edit → Save → effective
immediately.

#### Speaker Script (Tagalog)

> "Dito naman po sa Courses & Strands, dito po naka-manage ang lahat ng
> courses na ino-offer ng PLP. Kaya po nating i-set ang Average at High
> thresholds — ang Average po ang minimum para pumasa sa exam, at ang
> High naman po ay para sa top-tier applicants. Kaya rin po nating
> i-set ang Max Slots per course para hindi mag-over ang enrollment.
> At para sa freshmen, may strand validation po — kailangan match ang
> SHS strand nila sa course."

#### Speaker Script (English)

> "In Courses & Strands, this is where all the programs PLP offers are
> managed. We can set the Average and High thresholds — Average is the
> minimum passing rank for the exam, and High flags the top-tier
> applicants. We can also set Max Slots per course so enrollment doesn't
> exceed capacity. For freshmen, the system validates the SHS strand
> against the course's allowed strands."

### 2.4 Documents

**What it's for:** SSO / Admin reviews documents uploaded by students.

**What the user can do:** view applicants in the queue; click into one
to see each uploaded document; per-document actions are:

- **Approve** — accept as valid.
- **Request Resubmission** — requires a written reason; sets the doc to
  `rejected`, rolls the applicant back to `documents` status, fires an
  in-app notification with the reason.
- **Approve All** — approve every uploaded / under-review doc in one
  click.
- **Unapprove** — revert a single approval (only allowed while the
  applicant hasn't yet taken the exam).
- Bulk: **Approve Selected**, **Approve All Pending Reviews**.

> There is **no plain "Reject"** button. Request Resubmission is the
> only path back, and it always sends the student the reason.

**What the system automatically does:** when every required doc is
approved → flips `overall_status` to `exam`, sets `documents_approved_at`,
fires `notify_stage_transition($id, 'exam')`, calls
`auto_assign_exam_slot($id)` (the earliest open slot in the applicant's
department) — all in one server hop. The OCR / "auto-validate" pipeline
has been retired in this build; uploads still run a basic file-type /
size / integrity check at submit time.

#### Speaker Script (Tagalog)

> "Ito po ang Document Review. Kapag nag-submit ang student ng
> documents, lalabas po sila dito sa review queue. Ire-review ng Admin
> o SSO staff ang bawat document. Pwede silang mag-Approve o
> mag-Request Resubmission with reason — wala pong plain reject button
> kasi gusto po nating laging may dahilan ang sinasabihan na student.
> Kapag lahat ng required documents ay na-approve na, automatic po na
> mag-a-advance ang student sa exam stage at maa-assign siya sa exam
> room."

#### Speaker Script (English)

> "This is Document Review. When a student submits their documents, they
> appear in the review queue. Admin or SSO staff reviews each one. They
> can Approve or Request Resubmission with a reason — there's no plain
> Reject button, because we want every student who gets sent back to
> know exactly why. Once every required document is approved, the
> student automatically advances to the exam stage and is auto-assigned
> to an exam room."

### 2.5 Exam (Build / Slots / Codes)

**What it's for:** SSO / Admin builds the entrance exam; SSO / Admin
adds exam rooms; Proctor / SSO / Admin issues access codes on exam day.

**What the user can do:**

- **Build the exam** at `/staff/exam`: Create Exam (title auto-derived
  as `PLP Admissions Test ({school_year})`), Description, Shuffle
  Questions, Shuffle Choices. Add questions in 6 types: Multiple Choice,
  Checkboxes, Dropdown, Short Answer, Paragraph, Linear Scale.
  Auto-grading happens for every type except Paragraph.
- **Manage exam rooms** at `/staff/exam/slots`: pick a college, **+ Add
  Slot** with Date, **Opens / Closes** (per-slot, not per-exam — default
  Close = Opens + 90 min if blank; Close must be strictly after Opens),
  Room label, Department, Capacity (default 35; daily cap 3000).
  **Batch Create** lets you stamp multiple rooms on the same day.
- **Generate access codes**: per-room **Generate Code** button.
  `generate_exam_password()` produces a **6-character** code (uppercase
  letters + digits, no ambiguous characters), valid for **5 minutes**
  (`EXAM_PASSWORD_EXPIRY_SECONDS = 300`). **Extend** resets the timer on
  the same code; **New** issues a fresh code.

**What the system automatically does:**

- When all docs are approved, drop the applicant into the next open
  exam room in their department (`auto_assign_exam_slot`).
- After Add Slot, silently re-run `backfill_exam_slot_assignments()` so
  waiting applicants get backfilled into the new slot (success flash
  reports the count).
- Auto-grade on submit, compute rank (1–10), pass/fail vs the course's
  `pass_from` (= the course's Average threshold).
- Pass → flip to `interview` and call `assign_interview_slot()`.
- Fail → stay at `exam`, render alternative-course suggestions from
  `suggest_alt_courses()`.

#### Speaker Script (Tagalog)

> "Sa Exam module, dito po ginagawa ng Admin o SSO ang entrance exam.
> Pwede silang mag-add ng questions — multiple choice, checkbox, short
> answer, at iba pa. Tapos mag-se-set sila ng exam rooms — with date,
> open at close time, room name, at capacity per department.
>
> Kapag na-approve na ang documents ng student, automatic po na
> maa-assign siya sa exam room. Sa exam day, ang Proctor po ang
> magbibigay ng access code — 6 characters, valid for 5 minutes. Pwede
> rin po i-Extend ang timer o mag-Generate ng bagong code kung
> kailangan. Pagka-submit ng student, automatic po ang grading — kung
> pasado, automatic na may interview na po siya. Kung hindi, may
> suggestion po ang system ng alternative courses."

#### Speaker Script (English)

> "In the Exam module, the Admin or SSO builds the entrance exam. They
> can add questions — multiple choice, checkbox, short answer, and so
> on. Then they set up exam rooms with date, opens/closes time, room
> label, and capacity per department.
>
> Once a student's documents are approved, they are auto-assigned to an
> exam room. On exam day, the Proctor generates the access code — 6
> characters, valid for 5 minutes. The Proctor can also Extend the
> timer or issue a New code if needed. When the student submits, the
> exam is auto-graded — if they pass, the interview is assigned
> automatically. If they fail, the system suggests alternative courses
> they could qualify for."

### 2.6 Exam Reschedules (NEW)

**What it's for:** Review and approve / deny student exam-reschedule
requests.

**What the user can do (SSO / Admin):** open `/staff/exam/reschedule`
→ see pending reschedule requests with the student's name, current slot,
requested reason, and timestamp → choose to **Approve** (assigns the
student to a chosen replacement slot or the earliest matching one) or
**Deny** with a reason. Read-only for Staff, Proctor, Dean.

**What the system automatically does:** the student requests from
`/student/exam` via the *Request Reschedule* button which posts to
`POST /api/exam-reschedule-request`. The endpoint validates the student
is at the exam stage, has a current slot, and isn't double-submitting.
On approval, the student's `applicant_exam_slots` row is updated and
notifications fire to SSO / Proctor / Dean / Admin.

#### Speaker Script (Tagalog)

> "Ito pong Exam Reschedules ay isa sa mga bagong flow. Kung hindi
> kayang i-attend ng student ang kanyang exam slot — halimbawa may
> sakit, may pamilyang emergency — pwede po siyang mag-request ng
> reschedule from his exam page. Mapupunta po ito dito sa /staff/exam/
> reschedule. Ang SSO o Admin po ang nag-aapprove o nag-deny. Kapag
> approved, automatic po na maa-assign siya sa bagong slot."

#### Speaker Script (English)

> "Exam Reschedules is one of the newer flows. If a student can't make
> their exam slot — say they're sick or have a family emergency — they
> can file a reschedule request from the exam page. The request lands
> here at /staff/exam/reschedule. The SSO or Admin approves or denies
> it. On approval, the student is auto-assigned to a new slot."

### 2.7 Interviews (Setup / Live Queue / Reschedules)

**What it's for:** SSO / Admin sets up sessions; Professors run the live
queue (see Section 4); SSO / Admin / Dean handles reschedules and
absent students.

**What the user can do:**

- **Setup** (`/staff/interviews/setup`): pick a college, **+ Add
  Session** with Date, Start time, End time, Capacity (default 30),
  Assigned interviewer (required), Location label, Location notes.
- **Queue / Absent** (`/staff/interviews/absent`): review no-shows and
  interview reschedule requests.
- **Bulk Cancel & Move** (`/staff/interviews/cancel-slot`, SSO + Dean +
  Admin): pick a slot to cancel + replacement slot + reason → every
  applicant in the cancelled slot is moved in a single locked
  transaction. Each affected student gets in-app + email notification.

**What the system automatically does:** on exam pass,
`assign_interview_slot()` auto-books the student into the least-filled
session in their department and marks them `checked_in` immediately
(no manual check-in). When a new session is created,
`bulk_assign_pending_applicants()` sweeps any waiting applicants into it.

#### Speaker Script (Tagalog)

> "Sa Interview module, dito po ina-organize ang interview process. Ang
> SSO o Admin po ang magse-set up ng sessions — with date, time, at
> assigned interviewer. Kapag pumasa ang student sa exam, automatic
> po siyang maa-assign sa session, at automatic na rin siyang
> checked-in. May Bulk Cancel & Move din po kung kailangan mag-cancel
> ng isang session, halimbawa kung may bagyo o emergency — automatic
> po lahat ng students sa cancelled na session ay maa-reschedule sa
> ibang session sa isang click lang."

#### Speaker Script (English)

> "In the Interview module, this is where the interview process is
> organized. The SSO or Admin sets up sessions — with date, time, and
> assigned interviewer. When a student passes the exam, they are
> auto-assigned to a session and are automatically checked in. The
> Bulk Cancel & Move feature lets staff cancel an entire session — for
> example during a typhoon — and move every affected student to a
> replacement session in a single click, with notifications going out
> automatically."

### 2.8 Results

**What it's for:** The Dean (per-college) and Admin (system-wide)
release final admission decisions. *Note:* SSO is locked out of this
page in the role redesign.

**What the user can do:** view applicants grouped into five buckets:

| Bucket             | Label in UI               | What it means                                   |
|--------------------|---------------------------|-------------------------------------------------|
| `awaiting`         | Awaiting interview        | Exam done, interview not yet evaluated.         |
| `ready_accept`     | **Recommended: Accept**   | Exam passed AND Professor marked Pass.          |
| `ready_reject`     | **Recommended: Decline**  | Exam failed OR Professor marked Decline.        |
| `released`         | Released                  | Final decision sent to applicant.               |
| `withdrawn`        | Withdrawn                 | Student pulled out of the cycle.                |

Per-row actions in the Recommended buckets:

- **Accept** (green) — matches the Professor's recommendation in the
  Accept bucket, or *overrides* in the Decline bucket.
- **Reject** (red) — matches the Decline recommendation, or *overrides*
  in the Accept bucket.
- Whenever the Dean's decision **differs** from the recommendation, an
  override modal demands a non-empty written reason. The reason is
  stored on `admission_results.remarks` and written to the audit log
  as `admission_result_override`.

Toolbar actions:

- **Bulk Accept** / **Bulk Reject** — tick rows in either Recommended
  bucket and release them all at once.
- **Auto Release** (Admin-only) — walks every applicant in both
  Recommended buckets and releases them with the matching decision.
  Skips Awaiting rows.
- **Close Admissions** (Admin-only, red) — opens a modal that demands
  a reason and confirms an irreversible bulk-reject. Rejects every
  applicant in the current cycle that isn't already Released or
  Withdrawn, with the supplied reason recorded per row.
- **Suggest Alternative Course** (Dean / Admin) — for failed-exam
  applicants who still qualify for a different course. Validates the
  applicant's rank against the suggested course's `pass_from`, then
  upserts a `course_suggestions` row that the student sees on their
  result page.

**What the system automatically does:** on release, upserts an
`admission_results` row (`result`, `remarks`, `released_by`,
`released_at`), sets `applicants.overall_status = 'released'`, calls
`notify_stage_transition`, and writes
`audit_log('admission_result_released', ...)`. The course-cap is
re-checked at acceptance time so a late Accept can't overfill a
course.

#### Speaker Script (Tagalog)

> "Ito po ang Results module — ang last gate ng buong system. Ang Dean
> po ang gumagawa ng final decision para sa kanyang college; ang Admin
> naman po ay may system-wide access. Ang SSO po ay wala nang access
> dito — sa role redesign po namin, naka-separate ang setup at decision
> roles.
>
> May limang buckets po dito: Awaiting, Recommended: Accept, Recommended:
> Decline, Released, Withdrawn. Sa bawat row ng Recommended buckets, may
> Accept at Reject buttons. Kapag iba ang sagot ng Dean sa
> recommendation ng Professor, may modal po na hihingi ng written reason
> — at nai-log po ito sa audit trail.
>
> May Bulk Accept at Bulk Reject din po; Admin-only ang Auto Release at
> ang Close Admissions — ang Close Admissions po ay irreversible
> bulk-reject ng lahat ng natitirang unreleased applicants, with a
> recorded reason per row.
>
> Para sa mga failed-exam applicants na qualified naman sa ibang course,
> may Suggest Alternative Course feature po para ma-redirect sila."

#### Speaker Script (English)

> "This is the Results module — the final gate of the whole system. The
> Dean makes the final decision for their college; the Admin has
> system-wide access. SSO no longer has access here — in the role
> redesign, setup and decision-making are deliberately separated.
>
> There are five buckets here: Awaiting, Recommended: Accept,
> Recommended: Decline, Released, and Withdrawn. Each row in the
> Recommended buckets exposes Accept and Reject buttons. Whenever the
> Dean's choice differs from the Professor's recommendation, a modal
> demands a written reason — and that reason is logged in the audit
> trail.
>
> There are also Bulk Accept and Bulk Reject buttons; Auto Release and
> Close Admissions are Admin-only — Close Admissions is an irreversible
> bulk-reject of every remaining unreleased applicant, with a recorded
> reason per row.
>
> For failed-exam applicants who still qualify for a different course,
> the Suggest Alternative Course feature lets staff redirect them."

### 2.9 Users

**What it's for:** Admin-only management of every staff / dean / SSO /
proctor / admin account.

**What the user can do:** view all accounts; create, edit, deactivate;
fields are Name, Email, Role, Department (required for Dean and
Proctor), Password (min 8 chars).

**What the system automatically does:** hash passwords with bcrypt
(cost 12); enforce unique email at the DB layer.

#### Speaker Script (Tagalog)

> "Sa Users module, dito po nagma-manage ang Admin ng mga accounts —
> Staff, Dean, SSO, Proctor, o another Admin. Required po ang
> department para sa Dean at Proctor. Lahat ng passwords po ay
> bcrypt-hashed, hindi po plaintext. Pwede rin po mag-deactivate ng
> account."

#### Speaker Script (English)

> "In the Users module, the Admin manages every account — Staff, Dean,
> SSO, Proctor, or another Admin. Department is required for Dean and
> Proctor accounts. All passwords are bcrypt-hashed, never stored as
> plaintext. The Admin can also deactivate accounts."

### 2.10 Audit Log

**What it's for:** Admin-only, read-only log of every important action
in the system.

**What the user can do:** view the log (actor, action, description,
entity, entity_id, IP address, timestamp); filter by actor / action /
date range.

**What the system automatically does:** every state-changing action
writes a row to `audit_logs` (gated by `Auth::requireRole(ROLE_ADMIN)`
on the page itself).

#### Speaker Script (Tagalog)

> "Ang Audit Log po ay ang record ng lahat ng important actions sa
> system. Halimbawa, kung sino ang nag-approve ng document, kung sino
> ang nag-release ng result, kung sino ang nag-override ng
> recommendation at ano ang reason — lahat po naka-record dito with
> timestamp at IP address. Hindi po ito pwede i-edit o i-delete kahit
> ng Admin — append-only po para sa transparency at security."

#### Speaker Script (English)

> "The Audit Log is the record of every important action in the system.
> For instance, who approved a document, who released a result, who
> overrode a recommendation and the reason — all logged here with
> timestamp and IP address. Even the Admin cannot edit or delete
> entries — the log is append-only by design, for transparency and
> security."

---

## 3. Dean Side

The Dean has per-college oversight + standards-setting + **release
authority on Results**. In the role redesign, the Dean is the final
decision-maker for their own college; SSO is locked out of Results.

### 3.1 Dashboard

Same layout as the Admin Dashboard, but the data is automatically
filtered to the Dean's college.

#### Speaker Script (Tagalog)

> "Ang Dean po ay may sariling Dashboard, pero naka-filter lang po ito
> sa kanyang college. Halimbawa, kung Dean ng College of Computer
> Studies siya, CCS applicants lang po ang makikita niya sa funnel
> chart."

#### Speaker Script (English)

> "The Dean has their own Dashboard, but it's filtered to their college
> only. For example, if they're the Dean of the College of Computer
> Studies, they see only CCS applicants in the funnel chart."

### 3.2 Courses & Strands

**What the Dean can do:** view all courses in their college; edit the
**Max Slots** (enrollment cap) for courses in their college only; edit
the **High** and **Average** thresholds for their courses. They
**cannot** add or delete courses (Admin only) and **cannot** edit other
colleges' courses (server-side enforced).

#### Speaker Script (Tagalog)

> "Sa Courses & Strands, ang Dean po ay pwede lang mag-edit ng max slots
> at ng tier thresholds — High at Average — para sa courses ng kanyang
> college. Pwedeng palitan ang BSIT cap from 100 to 120, halimbawa.
> Pero hindi siya pwede mag-add o mag-delete ng course — Admin lang po
> ang may ganoong access."

#### Speaker Script (English)

> "In Courses & Strands, the Dean can edit Max Slots and the tier
> thresholds — High and Average — for their college's courses only. They
> can adjust the BSIT cap from 100 to 120, for example. But they
> cannot add or delete courses — only the Admin has that access."

### 3.3 Interviews

**What the Dean can do:** view all interview sessions in their college
(read-only on the queue side); approve / deny interview reschedule
requests at `/staff/interviews/absent?tab=requests`; **bulk Cancel &
Move** interview sessions in their college via
`/staff/interviews/cancel-slot`.

The Dean is **not** in the auth gate for `record_interview_evaluation`
— they don't conduct interviews. Their oversight role on the queue is
read-only.

#### Speaker Script (Tagalog)

> "Sa Interviews, ang Dean po ay makikita niya ang lahat ng sessions sa
> kanyang college. Read-only po siya doon — hindi siya ang
> nagco-conduct, ang Professor po ang nagi-interview. Pero pwede po
> siyang mag-approve o mag-deny ng interview reschedule requests, at
> pwede siyang gumamit ng Bulk Cancel & Move kung may mga sessions
> na kailangan i-reschedule."

#### Speaker Script (English)

> "In Interviews, the Dean sees every session in their college. They're
> read-only there — the Professor is the one who conducts the
> interview. The Dean can approve or deny interview reschedule requests,
> and they can use Bulk Cancel & Move if entire sessions need to be
> rescheduled."

### 3.4 Results (PRIMARY DEAN FLOW)

**This is where the role redesign mattered most.** The Dean is the
release authority for their college. See Section 2.8 for the full Results
flow.

The Dean's view at `/staff/results` is **dept-scoped**: the SQL adds
`a.course_applied IN (...dean's college courses...)`, so they only see
their own college. Per-course slot-capacity panel at the top of the
page shows accepted vs `max_slots` per course.

The buttons on each row are **Accept** and **Reject**. Choosing the
button that contradicts the Professor's recommendation triggers the
override-reason modal. Bulk Accept / Bulk Reject work the same way.

The Dean **cannot** Auto Release or Close Admissions — those are
Admin-only.

#### Speaker Script (Tagalog)

> "Ito po ang pinaka-importante para sa Dean — ang Results page. Ang
> Dean po ang gumagawa ng final decision: Accept o Reject. Pag iba ang
> sagot niya sa recommendation ng Professor, may modal po na hihingi
> ng written reason — at nai-log ito.
>
> Naka-scope po ang view niya sa sariling college niya — kung CCS Dean,
> CCS applicants lang ang makikita niya. Pwedeng isa-isa o bulk. May
> per-course slot capacity panel din po para makita niya kung gaano
> kalapit ang course sa cap nito."

#### Speaker Script (English)

> "This is the most important part for the Dean — the Results page. The
> Dean makes the final decision: Accept or Reject. If their choice
> differs from the Professor's recommendation, a modal demands a written
> reason — which is logged.
>
> The view is scoped to their own college — if they're CCS Dean, they
> see only CCS applicants. Decisions can be made one at a time or in
> bulk. There's also a per-course slot capacity panel so the Dean can
> see how close each course is to its cap."

---

## 4. Staff Side (Professor)

Staff members (Professors) are the interviewers. They have the most
focused role — they run the live queue on interview day and submit a
Pass / Decline recommendation per applicant.

The Professor's sidebar (`views/partials/nav_staff.php`) has only
**Dashboard** and **Interview Queue**. They cannot touch documents,
exam, or results.

### 4.1 Dashboard

Quick summary: interviews scheduled today, upcoming sessions, recent
evaluations.

#### Speaker Script (Tagalog)

> "Ang Staff Dashboard po ay simple lang — makikita ng Professor kung
> ilan ang interview niya ngayong araw, upcoming sessions, at recent
> evaluations niya."

#### Speaker Script (English)

> "The Staff Dashboard is simple — the Professor sees how many
> interviews they have today, their upcoming sessions, and their recent
> evaluations."

### 4.2 Interview Queue

**What it's for:** Live queue of applicants assigned to the Professor's
sessions, in queue-number order.

**What the user can do:**

- See all checked-in applicants in their own sessions
  (`COALESCE(s.assigned_to, s.created_by) = self`), already ordered
  for them — in-progress on top, then waiting (`checked_in` /
  `scheduled`) by `queue_number ASC`, then completed / no-show at the
  bottom (`staff_queue.php` line 187 — the FIELD-ordered ORDER BY).
- Filter by date / by session — only dates with rows in the user's
  scope appear (no dead options).
- Click into the applicant's name → opens the side drawer with name,
  course, applicant type, exam pass/fail with score, documents, and
  an inline notes field.
- Click the **Evaluation** button on a row to open the evaluation
  modal — write notes, then click **Pass** or **Decline**
  (`evaluation_result` is stored as `pass` / `reject`).

**What the system automatically does:**

- The queue is **first-come, first-served by queue number**. There is
  **no "Call Next" button anywhere in the UI** — the next applicant
  is whoever sits at the top of the list. The legacy
  `staff_call_next.php` endpoint exists in the codebase but is dead
  code; nothing in `staff_queue.php` references or renders it.
- Students are auto-checked-in at slot-assignment time — there is no
  "I'm Here" or manual check-in step (see `assign_interview_slot()`
  in `core/interview_scheduler.php`).
- **Auto no-show**: every page load runs an UPDATE that flips any
  still-waiting / in-progress row past its slot's end time to
  `status=no_show` + `interview_status=absent` +
  `attendance_status=absent`. There is **no manual "No-show" button**
  in the queue UI either (`staff_queue.php` lines 13–17 are explicit
  about this).
- Auto no-shows are then **auto-rescheduled** to the next available
  slot in that department via `auto_reschedule_noshow()` (when
  `school_settings.auto_reschedule_noshows = '1'`, default on).
- On evaluation, the row gets `status=completed`, `interview_status=completed`,
  `attendance_status=present`, `evaluated_at=NOW()`, AND
  `applicants.overall_status` immediately flips to `released` so the
  applicant appears on Results right away.
- The evaluation can be recorded on **any date** — the previous build
  required it to be the slot's scheduled date; that gate has been
  removed.

> Important: Pass / Decline is a **recommendation only**. The Dean is
> the one who actually releases the result (see Sections 2.8 and 3.4).

#### Speaker Script (Tagalog)

> "Ito po ang pinakamahalaga para sa Professor — ang Live Queue. Sa
> interview day, bubuksan niya ito at makikita niya ang lahat ng
> students na naka-assign sa kanyang sessions, sa queue-number order.
>
> First come, first served po — walang manual na 'Call Next' button.
> Pagdating ng student at wala pang iniinterview, sasalang na siya
> agad. Pagkatapos, susunod naman ang next sa pila. Ina-evaluate po
> ng Professor ang applicant — magla-lagay ng notes, at pipiliin Pass
> o Decline. Recommendation lang po ito — ang Dean po ang gumagawa
> ng final decision.
>
> Pag hindi po dumating ang student, automatic na ima-flag siya as
> no-show o absent kapag tapos na ang slot — at automatic din pong
> marereschedule siya sa next available slot."

#### Speaker Script (English)

> "This is the most important screen for the Professor — the Live
> Queue. On interview day, the Professor opens this and sees every
> student assigned to their sessions, in queue-number order.
>
> It's first come, first served — there is no manual 'Call Next'
> button. The next applicant in the queue is up automatically; once
> the Professor finishes the current one, the next person in line
> moves up on their own. The Professor evaluates the applicant on the
> spot, writes notes, and picks Pass or Decline. This is a
> recommendation only — the Dean makes the final decision.
>
> If a student doesn't show, the system automatically flags them as
> no-show or absent once the slot ends — and auto-reschedules them to
> the next available slot."

---

## 5. SSO Side

The SSO is the operations role. They set up everything the student goes
through — the exam, the rooms, and the interview sessions — and they
approve documents. **They do NOT release results.**

The SSO sidebar (`views/partials/nav_staff.php` filtered by role)
includes: Dashboard, Documents, Exam, Exam Slots, Exam Reschedules,
Interviews, Interview Reschedules. SSO is locked out of `/staff/results`.

### 5.1 Documents (Approve)

Already covered under Admin Section 2.4 — same flow, same UI. The auth
gate is `Auth::requireRole(ROLE_SSO, ROLE_ADMIN)`.

### 5.2 Build Exam / Set Slots

Already covered under Admin Section 2.5 — `Auth::requireRole(ROLE_SSO,
ROLE_ADMIN)`.

### 5.3 Exam Slot Bulk Cancel & Move (NEW)

**What it's for:** Cancel an entire exam slot and move every applicant
in it to a replacement slot in one click. Built for the typhoon scenario
(or any emergency that nukes a planned exam).

**What the user can do (SSO + Admin):** open
`/staff/exam/cancel-slot` → pick the slot to cancel → pick a
replacement slot of higher-or-equal remaining capacity → enter a
written reason → submit.

**What the system automatically does:** locks the rows in a `FOR UPDATE`
transaction to prevent oversubscription, moves every booked applicant
to the new slot, fires an in-app notification + branded email per
affected student with the reason.

#### Speaker Script (Tagalog)

> "Ang Exam Slot Cancel & Move po ay isa sa mga bagong feature. Kung
> kailangan i-cancel ng SSO o Admin ang isang exam slot — halimbawa
> may bagyo o emergency — sa isang click po, malilipat ang lahat ng
> mga naka-book sa cancelled slot papunta sa replacement slot. May
> notification din po na auto-sent sa mga affected students with the
> reason."

#### Speaker Script (English)

> "Exam Slot Cancel & Move is one of the newer features. If the SSO or
> Admin needs to cancel an entire exam slot — say due to a typhoon or
> emergency — one click moves every applicant booked into that slot to
> a replacement slot. Notifications go out automatically to every
> affected student with the reason."

### 5.4 Exam Reschedules

Already covered under Admin Section 2.6.

### 5.5 Interview Slot Bulk Cancel & Move (NEW)

Mirror of the exam-side flow. Same UI, same locking, same notifications.
Auth gate is `Auth::requireRole(ROLE_SSO, ROLE_DEAN, ROLE_ADMIN)`
(Dean is in this gate because interview ownership lives in their
college).

---

## 6. Proctor Side (NEW)

The Proctor is a thin operational role for **exam day**. Their sidebar
(`views/partials/nav_proctor.php`) shows only **Dashboard** and **Exam
Slots** — nothing else.

### 6.1 Exam Slots

**What the user can do:** the Proctor lands directly on their own
college's slot grid (no college selector — they can only manage one
college). Inside a room, they see the roster + the code controls.

Auth on code generation:

```
$canGenerateCodeFor = function (string $slotDept) ... {
    if ($isAdmin || $isSSO) return true;
    if ($isProctor && $slotDept !== '' && $slotDept === $staffDept) return true;
    return false;
};
```

So a Proctor can ONLY generate a code for a room in their own
department.

**What the user does on exam day:**

1. Click **Generate Code** → `generate_exam_password()` produces a
   **6-character** code (uppercase letters + digits, no `0/O`, no
   `1/I/L`).
2. The code is valid for **5 minutes** (`EXAM_PASSWORD_EXPIRY_SECONDS =
   300`).
3. Read the code aloud. Students enter it at `/student/exam`.
4. **Extend** → keeps the same code, resets the 5-minute countdown.
5. **New** → issues a fresh code and invalidates the current one.
6. Both Extend and New are audited
   (`exam_slot_code_extended` / `exam_slot_code_generated`).

#### Speaker Script (Tagalog)

> "Ang Proctor po ang nag-pa-patakbo ng exam room sa exam day. Naka-
> scope siya sa sariling college niya. Pagdating ng exam time,
> i-click niya ang Generate Code button — 6 characters, valid for 5
> minutes. Babasahin niya ito sa mga students. Pwede rin po i-Extend
> kung kailangan ng dagdag oras, o mag-Generate ng bagong code kung
> may late arrivals. Lahat ng actions naka-log sa audit trail."

#### Speaker Script (English)

> "The Proctor runs the exam room on exam day. They are scoped to their
> own college only. When the exam starts, they click Generate Code —
> 6 characters, valid for 5 minutes. They read the code aloud to the
> students. They can Extend the timer if more time is needed, or
> generate a New code for late arrivals. Every action is logged to the
> audit trail."

---

## 7. Student Side

The Student's journey is the core of the system. They interact with
four main pages mapped to the 4-step stepper:

> **Submit Documents → Entrance Exam → Interview → Result**

### 7.1 Registration

**What it's for:** Create the application.

**What the user can do (`/register`):** fill First/Middle/Last name +
Suffix, Birthdate, Sex (M/F), Street + Barangay (must match the
hard-coded list of 30 Pasig City barangays), Phone, Email, Password
(≥ 8 chars), Applicant type (Freshman / Transferee / Foreign),
Course, SHS Strand (Freshmen only), hCaptcha.

**What the system automatically does:** if `admissions_is_open()`
returns false, shows a Closed card with the window dates and rejects
submissions. Otherwise validates the course cap at submit time
(`accepted_count ≥ max_slots` → block with *"This course has reached
its enrollment cap…"*). Capped courses are also hidden / disabled in
the dropdown. Email verification is two-channel: one-click magic link +
6-digit code (either works).

### 7.2 Submit Documents

**What it's for:** Upload the documents required for the applicant's
type.

**What the user can do (`/student/documents`):** see the list from
`docs_for_type($applicant_type)` (varies by type); upload each (PDF,
JPG, PNG, WEBP, ≤ 5 MB); click **Submit Application** when all required
docs are uploaded; **withdraw** before any staff approval.

**What the system automatically does:** runs a basic file-type / size /
integrity check at submit time. (The older OCR-based `api/auto-validate`
endpoint has been **retired in this build**.) On Submit, flips
`overall_status` from `documents` → `submitted`.

### 7.3 Entrance Exam

**What it's for:** Take the exam on exam day.

**What the user can do:** see assigned slot (date, time, room); on exam
day, enter the access code → take the exam → submit answers.

**Reschedule request:** if a student can't make their slot, the
**Request Reschedule** button on `/student/exam` posts to
`POST /api/exam-reschedule-request`. It inserts a pending row in
`exam_reschedule_requests` and notifies SSO / Proctor / Dean / Admin.

**What the system automatically does:** auto-saves answers every 60
seconds; on submit auto-grades, computes rank (1–10), determines
pass/fail vs the course's `pass_from`; on pass, auto-assigns interview
slot; on fail, renders alternative-course suggestions from
`suggest_alt_courses()`.

### 7.4 Interview

**What it's for:** See interview schedule and queue position.

**What the user can do:** view date, time, location, interviewer; see
real-time queue position ("You are #3 in line"); submit a reschedule
request from `/student/interview` (which posts to
`POST /api/reschedule-request`).

**What the system automatically does:** auto-checked-in at slot
assignment; updates queue position in real time; flips to `no_show` if
the slot ends without an evaluation.

### 7.5 Result

**What it's for:** See the final admission decision.

**What the user can do:** view Accepted / Rejected; if Accepted →
**Confirm Enrollment** or **Decline Slot** within 7 days; if a course
suggestion was made, accept or decline that too.

**What the system automatically does:** displays the decision once the
Dean / Admin releases it; auto-expires unconfirmed acceptances after
the deadline (`auto_expire_accepted_pending`); sends in-app + email
notification on release.

### Speaker Script (Tagalog) — Student Side Overall

> "Sa Student Side, ito po ang journey ng student: mag-rerehistro siya,
> magve-verify ng email, mag-a-upload ng documents, magta-take ng exam,
> at mag-a-attend ng interview. Lahat po automated — exam slot
> assignment, interview slot assignment, auto-check-in, at notifications.
> Wala pong manual pagpila o manual scheduling sa side ng student.
>
> Sa Result page po, pag Accepted siya, may 7 days siya para
> mag-Confirm o mag-Decline. Pag wala siyang ginawa within 7 days,
> automatic po na e-expire ang slot niya at maa-withdraw siya."

### Speaker Script (English) — Student Side Overall

> "On the Student Side, this is the student's journey: register, verify
> email, upload documents, take the exam, attend the interview. Every
> step is automated — exam slot assignment, interview slot assignment,
> auto-check-in, and notifications. No manual queueing or manual
> scheduling on the student's end.
>
> On the Result page, if they're Accepted, they have 7 days to Confirm
> or Decline. If they do nothing within 7 days, the slot expires
> automatically and the application is withdrawn."

---

## 8. Sample Presentation Script (Full)

Below is a smooth, continuous script that the team can read during the
presentation. It covers all roles and the complete flow. Bilingual —
Tagalog version first, English version second.

### Tagalog Version

> **Opening:**
>
> "Good day po sa ating panel at mga kasamahan. Ngayon po ay
> ipe-present namin ang aming PLP Admissions System — isang web-based
> application na ginawa para i-automate at i-digitalize ang buong
> admissions process ng Pamantasan ng Lungsod ng Pasig.
>
> Ang system po na ito ay may anim na user roles: **Admin, SSO, Dean,
> Professor, Proctor, at Student.** Bawat role po ay may kanya-kanyang
> access at responsibilities, naka-enforce sa code via `Auth::
> requireRole()`. Hindi po nakikita ng isang role ang link na 403 kung
> ipipindot — naka-filter na po ang sidebars per role.
>
> **Overall Flow:**
>
> Ang buong process po ay nagsisimula sa Student. Magre-register po
> siya, magve-verify ng email, tapos mag-a-upload ng required
> documents. I-re-review po ito ng SSO o Admin. Kapag lahat ng
> documents ay na-approve na, automatic po na maa-assign ang student sa
> entrance exam room.
>
> Sa exam day, ang Proctor po ang magbibigay ng 6-character access code
> na valid for 5 minutes. Ite-take ng student ang exam — automatic po
> ang grading. Kung pumasa, automatic po na maa-assign siya sa
> interview queue at automatic na siyang naka-check in.
>
> Sa interview, ang Professor po ang magko-conduct at magrere-record
> ng recommendation — Pass o Decline. Pagkatapos ng interview, ang Dean
> po ang gumagawa ng final decision sa Results page — Accept o Reject.
> Pag iba sa recommendation ng Professor, kailangan ng written reason.
>
> Pag-release ng result, automatic po na mano-notify ang student via
> email at in-app. Kung Accepted, may 7 days siya to confirm enrollment.
>
> **Admin Side:**
>
> Ang Admin po ang may pinaka-malawak na access. Siya ang
> nagco-configure ng School Year, Courses, at Settings; siya ang
> nag-c-create ng staff, dean, SSO, proctor, at admin accounts; at
> siya lang ang may access sa Audit Log. Pwede rin siyang gumawa ng
> Auto Release o Close Admissions sa Results page.
>
> **SSO Side:**
>
> Ang SSO po ang operations role. Siya ang nagbu-build ng exam,
> nagse-set up ng exam at interview slots, at nagre-review ng documents.
> Wala na siyang access sa Results — pero pwede siyang gumamit ng
> Bulk Cancel & Move kung kailangan i-reschedule ang isang buong session.
>
> **Dean Side:**
>
> Ang Dean naman po ang final decision-maker sa Results. Naka-scope siya
> sa sariling college niya. Pwede rin po siyang mag-adjust ng max slots
> at tier thresholds ng kanyang college's courses, at mag-handle ng
> interview reschedules.
>
> **Professor Side:**
>
> Ang Professor po ay ang interviewer. Siya ang nagpapatakbo ng Live
> Queue at siya ang nagrere-record ng Pass o Decline recommendation.
> Recommendation lang po ito — ang Dean ang nagde-decide ng final.
>
> **Proctor Side:**
>
> Ang Proctor po ay focused sa exam day lang. Siya ang nag-iissue ng
> access codes sa kanyang sariling college's exam rooms.
>
> **Student Side:**
>
> Ang student po ay nag-a-upload ng documents, nagta-take ng exam,
> ina-attend ang interview, at nagvi-view ng result. Pwede rin po
> siyang mag-request ng exam o interview reschedule kung kailangan.
>
> **Security and Audit:**
>
> Para po sa security, lahat ng passwords ay bcrypt-hashed (cost 12).
> May CSRF protection sa lahat ng forms, hCaptcha sa login at
> registration, login rate limiting (5 attempts → 15-minute lockout),
> at email verification sa students. 100% prepared statements sa lahat
> ng queries. Lahat ng important actions naka-log sa Audit Trail.
>
> **Closing:**
>
> In summary po, ang PLP Admissions System ay isang complete,
> organized, at secure na platform para sa admissions. Mula sa
> registration hanggang enrollment confirmation, automated at
> traceable po lahat. Maraming salamat po."

### English Version

> **Opening:**
>
> "Good day to our panel and colleagues. Today we will present our PLP
> Admissions System — a web-based application built to automate and
> digitalize the entire admissions process of Pamantasan ng Lungsod ng
> Pasig.
>
> The system supports six user roles: **Admin, SSO, Dean, Professor,
> Proctor, and Student.** Each role has its own access and
> responsibilities, enforced in code through `Auth::requireRole()`.
> No role ever sees a link that returns 403 on click — sidebars are
> filtered per role.
>
> **Overall Flow:**
>
> The whole process begins with the Student. They register, verify
> their email, then upload the required documents. The SSO or Admin
> reviews each one. Once all documents are approved, the student is
> automatically assigned to an entrance exam room.
>
> On exam day, the Proctor issues a 6-character access code that is
> valid for 5 minutes. The student takes the exam — grading is
> automatic. On pass, they're automatically assigned to the interview
> queue and auto-checked in.
>
> At the interview, the Professor conducts the session and records a
> recommendation — Pass or Decline. After the interview, the Dean
> makes the final decision on the Results page — Accept or Reject. If
> the Dean's choice differs from the Professor's recommendation, the
> system requires a written reason.
>
> On release, the student is automatically notified via email and
> in-app. If Accepted, they have 7 days to confirm enrollment.
>
> **Admin Side:**
>
> The Admin has the widest access. They configure School Year,
> Courses, and Settings; they create staff, dean, SSO, proctor, and
> admin accounts; and only the Admin has access to the Audit Log. The
> Admin can also trigger Auto Release or Close Admissions on the
> Results page.
>
> **SSO Side:**
>
> The SSO is the operations role. They build the exam, set up exam and
> interview slots, and review documents. SSO no longer has access to
> Results — but they can use the Bulk Cancel & Move flow when an
> entire session needs to be rescheduled.
>
> **Dean Side:**
>
> The Dean is the final decision-maker on Results, scoped to their own
> college. The Dean can also adjust max slots and tier thresholds for
> their college's courses and handle interview reschedules.
>
> **Professor Side:**
>
> The Professor is the interviewer. They run the Live Queue and record
> a Pass or Decline recommendation. This is a recommendation only —
> the Dean makes the final call.
>
> **Proctor Side:**
>
> The Proctor's scope is exam day. They issue access codes for their
> own college's exam rooms.
>
> **Student Side:**
>
> The student uploads documents, takes the exam, attends the
> interview, and views the result. They can also request an exam or
> interview reschedule when needed.
>
> **Security and Audit:**
>
> For security, all passwords are bcrypt-hashed (cost 12). There is
> CSRF protection on every form, hCaptcha on login and registration,
> login rate limiting (5 attempts → 15-minute lockout), and email
> verification for students. Every query uses prepared statements.
> Every important action is logged to the audit trail.
>
> **Closing:**
>
> In summary, the PLP Admissions System is a complete, organized, and
> secure platform for admissions. From registration through enrollment
> confirmation, everything is automated and traceable. Thank you very
> much."

---

*End of presentation script.*
