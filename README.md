# PLP Admissions

Pamantasan ng Lungsod ng Pasig — student admissions, document review, entrance exam, and interview scheduling system.

For the full end-to-end flow, role behaviour, automations, and edge cases, see [analysis.md](./analysis.md).

---

## Fresh install (Windows + XAMPP)

> **Back up your database first if one already exists** — `database/schema.sql` drops every application table before recreating it.

### 1. Clone into XAMPP's htdocs

```bat
cd C:\xampp\htdocs
git clone https://github.com/kyoshirooo123/plp_admissions.git plp-admissions
```

(macOS: `/Applications/XAMPP/htdocs/`. Linux: `/opt/lampp/htdocs/`.)

### 2. Create the database

Open the XAMPP **Shell** (or any terminal) and run:

```bat
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS plp_admissions CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

XAMPP's default MySQL root has no password — just press Enter.

### 3. Load the schema

```bat
mysql -u root -p plp_admissions < database\schema.sql
```

That single file:

- Drops every application table (clean reset).
- Creates the full schema, including the merged `interview_slots` (with `assigned_to`, `location_label`, `location_notes`).
- Seeds default school settings, departments, courses, passing scores, and an admin account.

### 4. Seed staff accounts (recommended)

```bat
mysql -u root -p plp_admissions < database\seed_users.sql
```

This inserts the staff/dean/SSO accounts. Default passwords:

| Email                                            | Password    |
|--------------------------------------------------|-------------|
| `admin@plp.edu.ph`                               | `Admin@123` |
| `sso@plp.edu.ph`                                 | `SSO@123`   |
| `dean.{ccs,con,cba,coe,cas,cen}@plp.edu.ph`      | `Dean@123`  |
| `staff.{ccs,con,cba,coe,cas,cen}@plp.edu.ph`     | `Staff@123` |

### 5. Seed demo applicants (for presentations)

```bat
mysql -u root -p plp_admissions < database\seed_demo.sql
```

Loads ~120 sample applicants spread across every funnel stage (pending docs, exam-taken, interview pipeline, accepted / rejected, withdrawn). Plus 36 interview sessions, 78 exam results, 299 notifications.

- Every demo student logs in with password `Student@123` and pattern `<first>.<last><###>@student.plp.edu.ph` (e.g. `maria.mendoza001@student.plp.edu.ph`).
- Demo students are inserted with `email_verified = 1` so they skip the verification gate.
- Every interview session is pre-assigned to the matching college's `staff.*` account, so each college only sees its own applicants in the live queue.
- The script is idempotent — re-running it clears the previous demo seed first.
- All dates are anchored to `CURDATE()` at load time, so today's interview queue is always populated.

### 6. Configure `.env`

```bat
cd C:\xampp\htdocs\plp-admissions
copy .env.example .env
```

Edit `.env`:

```env
HCAPTCHA_SITE_KEY=     # https://dashboard.hcaptcha.com (optional for local dev)
HCAPTCHA_SECRET_KEY=
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-gmail@gmail.com
SMTP_PASS=your-gmail-app-password   # https://myaccount.google.com/apppasswords — NOT your real Gmail password
SMTP_FROM_NAME=PLP Admissions
```

SMTP is used for the verification email and password-reset email. For local-only testing without SMTP, you can leave those blank and grab the verification code from the `users.email_verify_code` column directly.

### 7. Open the app

http://localhost/plp-admissions/public/

---

## Smoke test

1. Log in as `admin@plp.edu.ph` → you land on `/admin/dashboard`.
2. **Admin → Audit Log** → should be populated if you loaded `seed_demo.sql`.
3. **Staff → Interviews → Setup** → click into a college (e.g. CCS) → flat list of sessions for that college. **+ Add Session** asks for date, start/end time, capacity, interviewer, location label, location notes.
4. **Staff → Interviews → Live Queue** → today's queue loads. The location strip at the top shows the location of today's session for the logged-in interviewer.
5. Log out, log in as `staff.ccs@plp.edu.ph` / `Staff@123` → the live queue should show **only** CCS applicants.
6. Log in as a demo student (e.g. `maria.mendoza001@student.plp.edu.ph` / `Student@123`) → lands on `/student/documents` (not `/verify-pending`).
7. **Student → Interview** → if the student has been auto-assigned to an interview slot, the page shows their queue number, time, location, interviewer. No "I'm Here" button — check-in is automatic at slot assignment time.

---

## Notes & gotchas

- **`Class "PDOException" not found` or similar on first hit** — make sure `php_pdo_mysql` is enabled in `php.ini`. XAMPP enables it by default.
- **Verification email never arrives** — confirm `.env` SMTP credentials. As a fallback, read the 6-digit code straight from `users.email_verify_code` for the affected user.
- **hCaptcha errors on register/login during local dev** — either provide real keys in `.env`, or temporarily comment out the `hcaptcha_verify()` call in `modules/auth/login.php` and `modules/auth/register.php`.
- **"Today's queue is empty"** — re-run `seed_demo.sql`; dates are anchored to `CURDATE()` at load time, so a seed loaded weeks ago will have moved its "today" into the past.
- **Department scoping** — the live interview queue is scoped per-college; the document-review queue at `/staff/applicants` is intentionally global (it's the SSO doc-review pool). See [analysis.md §5](./analysis.md#5-department-scoping-who-sees-whom).
- **Future updates** — to pull new changes later: `cd C:\xampp\htdocs\plp-admissions && git pull`. The schema is destructive, so only re-run `schema.sql` if you're OK losing data.
- The legacy `_setup_desks.php` and `_setup_desk_schedule.php` files in `modules/interview/` are no-op leftovers from the desk/session merge. They're harmless and can be deleted manually if you want a clean tree.
