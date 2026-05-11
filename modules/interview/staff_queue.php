<?php
// ============================================================
// modules/interview/staff_queue.php
//
// Live interview queue — single unified page that lists every
// auto-assigned applicant. Each row exposes a single "Evaluation"
// action that opens a modal where the interviewer records notes
// plus a Pass / Fail decision.
//
// • Staff see every applicant assigned to a session they own
//   (assigned_to with created_by fallback for legacy rows).
// • Admins see everyone.
// • No-show is fully automatic: once a slot's end time has
//   passed (or, for slots without an explicit end time, one hour
//   after the start time), any still-waiting / still-in-progress
//   row is flipped to no_show right when the page loads. There is
//   no manual "No-show" button anywhere in the UI.
// ============================================================

require_once CORE_PATH . '/bootstrap.php';
Auth::requireRole(ROLE_STAFF, ROLE_SSO, ROLE_DEAN, ROLE_ADMIN);

// SSO is a setup-only role — they create sessions and assign interviewers
// but they don't conduct interviews themselves, so they have no business
// on the live queue. Bounce them straight to Interview Setup if they end
// up here (typed URL, stale bookmark, etc.).
if (Auth::role() === ROLE_SSO) {
    redirect('/staff/interviews/setup');
}

$db        = db();
$staffId   = Auth::id();
$today     = date('Y-m-d');
$role      = Auth::role();
$isAdmin   = $role === ROLE_ADMIN;
$isSSO     = $role === ROLE_SSO;
$isDean    = $role === ROLE_DEAN;
// Admin and SSO see every queue row across colleges. Dean sees every
// row whose slot belongs to their own college (oversight).
// Professor sees only rows on a session they personally own.
$canSeeAll = $isAdmin || $isSSO;
$staffDept = (string) user_department($staffId);

// ----------------------------------------------------------------
// College scoping for Admin / SSO
//
// Admin and SSO have access to every college's queue, which is too
// much to render as a single mixed table. Instead, on first visit
// they get a college-picker landing (`_queue_college_select.php`);
// drilling into one sets `?college=...` and we scope the query.
// `?college=__all__` is an explicit "show me everything" escape
// hatch so the unified view stays reachable.
//
// Dean and Professor never reach the picker — Dean is auto-scoped
// to their own department, Professor to their own owned sessions.
// ----------------------------------------------------------------
$collegeFilter = trim((string)($_GET['college'] ?? ''));
$showAll       = ($collegeFilter === '__all__');
if ($canSeeAll && $collegeFilter === '') {
    // Admin/SSO landing without a college - hand off to the picker.
    include __DIR__ . '/_queue_college_select.php';
    return;
}

// ----------------------------------------------------------------
// Date filter — slot-derived
//
// The queue used to show every slot_date in one list, which made it
// impossible for a Professor running today's session to focus only on
// the people actually walking in today. The dropdown is now built
// from the distinct slot_dates that ACTUALLY have queue rows in the
// caller's scope, so there are no dead options ("Past dates (0)")
// and no surprises ("Today" empty when the session is tomorrow).
//
// `?date=` accepts either:
//   YYYY-MM-DD — exact slot date (must be one of the dates the scope
//                actually has rows for; otherwise we fall back to
//                today if today is in the list, else "all")
//   all        — no date filter
//
// Default: today if today is in the list, else the soonest upcoming
// date in the list, else "all".
// ----------------------------------------------------------------
$availableDateScopeSql = '';
$availableDateScopeParams = [];
if ($canSeeAll && !$showAll) {
    $availableDateScopeSql    = ' WHERE s.department = ?';
    $availableDateScopeParams = [$collegeFilter];
} elseif ($canSeeAll) {
    $availableDateScopeSql    = '';
    $availableDateScopeParams = [];
} elseif ($isDean && $staffDept !== '') {
    $availableDateScopeSql    = ' WHERE s.department = ?';
    $availableDateScopeParams = [$staffDept];
} else {
    $availableDateScopeSql    = ' WHERE COALESCE(s.assigned_to, s.created_by) = ?';
    $availableDateScopeParams = [$staffId];
}
$availableDatesStmt = $db->prepare(
    'SELECT s.slot_date, COUNT(q.id) AS row_count
       FROM interview_queue q
       JOIN interview_slots s ON s.id = q.slot_id'
    . $availableDateScopeSql .
    ' GROUP BY s.slot_date
      ORDER BY s.slot_date ASC'
);
$availableDatesStmt->execute($availableDateScopeParams);
$availableDates = $availableDatesStmt->fetchAll();

$availableDateMap = [];
foreach ($availableDates as $d) {
    $availableDateMap[(string)$d['slot_date']] = (int)$d['row_count'];
}

// Resolve requested filter against the list of dates we actually have.
$dateFilterRaw = (string)($_GET['date'] ?? '');
$dateFilter    = 'all';
if ($dateFilterRaw === 'all') {
    $dateFilter = 'all';
} elseif ($dateFilterRaw !== '' && isset($availableDateMap[$dateFilterRaw])) {
    $dateFilter = $dateFilterRaw;
} else {
    // No filter requested (or one that no longer applies) — default
    // to today if it's in the list, else the soonest upcoming date,
    // else "all".
    if (isset($availableDateMap[$today])) {
        $dateFilter = $today;
    } else {
        $futureDate = null;
        foreach (array_keys($availableDateMap) as $d) {
            if ($d >= $today) { $futureDate = $d; break; }
        }
        $dateFilter = $futureDate ?? 'all';
    }
}

$dateWhereSql    = '';
$dateWhereParams = [];
if ($dateFilter !== 'all') {
    $dateWhereSql      = ' AND s.slot_date = ?';
    $dateWhereParams[] = $dateFilter;
}

// ----------------------------------------------------------------
// Desk strip — find this interviewer's most-recent (or upcoming)
// physical location so the staff sees where to send walk-ins. Purely
// informational; it does NOT scope the table below. Only Professors
// have a personal desk; oversight roles (Admin/SSO/Dean) skip this.
// ----------------------------------------------------------------
$deskLabel = '';
$deskNotes = '';
if (!$isAdmin && !$isSSO && !$isDean) {
    try {
        $deskStmt = $db->prepare(
            'SELECT location_label, location_notes
               FROM interview_slots
              WHERE COALESCE(assigned_to, created_by) = ?
                AND location_label != ""
              ORDER BY ABS(DATEDIFF(slot_date, ?)) ASC, slot_time ASC
              LIMIT 1'
        );
        $deskStmt->execute([$staffId, $today]);
        $deskRow = $deskStmt->fetch();
        if ($deskRow) {
            $deskLabel = $deskRow['location_label'] ?? '';
            $deskNotes = $deskRow['location_notes'] ?? '';
        }
    } catch (\Throwable $e) {}

    if (!$deskLabel) {
        try {
            $deskStmt = $db->prepare('SELECT desk_label, desk_notes FROM users WHERE id=?');
            $deskStmt->execute([$staffId]);
            $deskRow   = $deskStmt->fetch();
            $deskLabel = $deskRow['desk_label'] ?? '';
            $deskNotes = $deskRow['desk_notes'] ?? '';
        } catch (\Throwable $e) {}
    }
}

// ----------------------------------------------------------------
// Schema upgrades — evaluation columns
// ----------------------------------------------------------------
try { $db->query("SELECT evaluation_result FROM interview_queue LIMIT 0"); }
catch (\Throwable $e) {
    $db->exec("ALTER TABLE interview_queue ADD COLUMN evaluation_result VARCHAR(10) DEFAULT NULL AFTER interview_notes");
}
try { $db->query("SELECT evaluated_at FROM interview_queue LIMIT 0"); }
catch (\Throwable $e) {
    $db->exec("ALTER TABLE interview_queue ADD COLUMN evaluated_at DATETIME DEFAULT NULL AFTER evaluation_result");
}

// ----------------------------------------------------------------
// AUTO NO-SHOW
// Flip any still-waiting / in-progress queue row whose slot has
// already finished into status='no_show' AND interview_status='absent'.
// This runs on every page load so the table always reflects reality
// without anyone having to click a button.
//
// "Finished" means:
//   • slot_date is before today, OR
//   • slot_date is today AND end_time is set AND end_time <= NOW, OR
//   • slot_date is today AND end_time is NULL AND slot_time is set
//     AND the start time was more than an hour ago.
//
// Updating BOTH status and interview_status is intentional: the
// pending-queue filter used by bulk_assign_pending_applicants()
// excludes rows where interview_status IN ('pending','completed'),
// so leaving interview_status at 'pending' would keep the no-show
// applicant permanently locked out of auto-rebooking. Flipping to
// 'absent' both surfaces them on /staff/interviews/absent and lets
// the scheduler pick them up on the next slot creation.
// ----------------------------------------------------------------
try {
    $autoNoShow = $db->prepare(
        'UPDATE interview_queue q
         JOIN   interview_slots s ON s.id = q.slot_id
         SET    q.status           = "no_show",
                q.interview_status = "absent",
                q.attendance_status = "absent",
                q.evaluated_at      = COALESCE(q.evaluated_at, NOW())
         WHERE  q.status IN ("scheduled", "checked_in", "in_progress")
           AND (
                 s.slot_date < CURDATE()
              OR (s.slot_date = CURDATE()
                  AND s.end_time IS NOT NULL
                  AND s.end_time <= CURTIME())
              OR (s.slot_date = CURDATE()
                  AND s.end_time IS NULL
                  AND s.slot_time IS NOT NULL
                  AND ADDTIME(s.slot_time, "01:00:00") <= CURTIME())
           )'
    );
    $autoNoShow->execute();
} catch (\Throwable $e) {
    // Schema differences shouldn't block the page from rendering
    error_log('auto-no-show update failed: ' . $e->getMessage());
}

// ----------------------------------------------------------------
// Load the queue rows.
// • Staff: every row attached to a session they own.
// • Admin: every row, period.
// ----------------------------------------------------------------
$selectCols =
    'SELECT q.id          AS queue_id,
            q.queue_number,
            q.status,
            q.checked_in_at,
            q.interview_notes,
            q.evaluation_result,
            q.evaluated_at,
            a.id          AS app_id,
            a.course_applied,
            a.applicant_type,
            u.name        AS student_name,
            u.first_name,
            u.middle_name,
            u.last_name,
            u.suffix,
            u.email       AS student_email,
            u.department  AS student_department,
            s.id          AS slot_id,
            s.slot_date   AS slot_date,
            s.slot_time   AS slot_time,
            s.end_time    AS slot_end_time,
            s.department  AS slot_department
     FROM   interview_queue q
     JOIN   interview_slots s ON s.id = q.slot_id
     JOIN   applicants a      ON a.id = q.applicant_id
     JOIN   users u           ON u.id = a.user_id ';

$orderTail =
    ' ORDER BY
         FIELD(q.status, "in_progress", "checked_in", "scheduled", "completed", "no_show"),
         q.queue_number ASC,
         q.created_at   ASC';

if ($canSeeAll && !$showAll) {
    // Admin / SSO with a specific college picked - scope by slot department.
    $stmt = $db->prepare(
        $selectCols .
        ' WHERE s.department = ?' . $dateWhereSql .
        $orderTail
    );
    $stmt->execute(array_merge([$collegeFilter], $dateWhereParams));
} elseif ($canSeeAll) {
    // Admin / SSO with the explicit "all" escape hatch - every row, every college.
    $stmt = $db->prepare(
        $selectCols .
        ($dateWhereSql !== '' ? ' WHERE 1 ' . $dateWhereSql : '') .
        $orderTail
    );
    $stmt->execute($dateWhereParams);
} elseif ($isDean) {
    // Dean — every row whose slot is in their college (oversight).
    // Fall back to the COALESCE(assigned_to, created_by) ownership rule
    // when the dean has no department on file, so they at least see
    // sessions tied to their own user id (rare edge case).
    if ($staffDept !== '') {
        $stmt = $db->prepare(
            $selectCols .
            ' WHERE s.department = ?' . $dateWhereSql .
            $orderTail
        );
        $stmt->execute(array_merge([$staffDept], $dateWhereParams));
    } else {
        $stmt = $db->prepare(
            $selectCols .
            ' WHERE COALESCE(s.assigned_to, s.created_by) = ?' . $dateWhereSql .
            $orderTail
        );
        $stmt->execute(array_merge([$staffId], $dateWhereParams));
    }
} else {
    // Professor — only rows on a session they personally own.
    $stmt = $db->prepare(
        $selectCols .
        ' WHERE COALESCE(s.assigned_to, s.created_by) = ?' . $dateWhereSql .
        $orderTail
    );
    $stmt->execute(array_merge([$staffId], $dateWhereParams));
}
$rows = $stmt->fetchAll();

// Format name as "SURNAME SUFFIX, FIRST MIDDLE" (uses shared helper)
function queue_format_name(array $r): string {
    return format_full_name($r);
}

// Status badge mapping — "Waiting" covers scheduled + checked_in, since
// auto-checkin collapses those two states into one user-facing label.
function queue_status_badge(string $status): array {
    return match ($status) {
        'scheduled'   => ['Waiting',     'badge-info'],
        'checked_in'  => ['Waiting',     'badge-info'],
        'in_progress' => ['In Progress', 'badge-approved'],
        'completed'   => ['Done',        'badge-approved'],
        'no_show'     => ['No-show',     'badge-rejected'],
        default       => [ucfirst($status), 'badge-info'],
    };
}

ob_start();
?>

<style>
@keyframes pulse-dot {
    0%,100%{opacity:1;transform:scale(1)}
    50%   {opacity:.5;transform:scale(1.3)}
}

/* Make the table card stretch to fill the .page area so the gap below the
   card matches the .page horizontal padding (var(--space-8) = 32px). Same
   pattern used on the Results page. */
.page:has(.iq-table-card) { display:flex; flex-direction:column; }
.iq-table-card { flex:1; min-height:300px; }

/* Toolbar above the table (search + count). Matches the look of the
   Results page top bar. */
.iq-toolbar {
    display:flex;
    align-items:center;
    gap:var(--space-3);
    margin-bottom:var(--space-4);
    flex-wrap:wrap;
}
.iq-toolbar .iq-search-wrap {
    position:relative;
    flex:1;
    min-width:240px;
    max-width:420px;
}
.iq-toolbar .iq-search-wrap input {
    width:100%;
    padding:0 var(--space-3) 0 32px;
    height:36px;
    min-height:36px;
    font-size:var(--text-sm);
    border:1px solid var(--border);
    border-radius:var(--radius-sm);
    background:var(--bg-elevated);
    color:var(--text-primary);
}
.iq-toolbar .iq-count {
    font-size:var(--text-xs);
    color:var(--text-tertiary);
    white-space:nowrap;
}

/* Row tints by status, matches existing badge palette. */
.iq-row-in-progress td { background: rgba(45,106,79,0.06); }
.iq-row-no-show     td,
.iq-row-completed   td { color: var(--text-tertiary); }

.iq-name-cell      { font-weight: var(--weight-medium); }
.iq-name-cell .sub {
    display:block;
    font-size:var(--text-xs);
    color:var(--text-tertiary);
    font-weight:var(--weight-regular);
    margin-top:2px;
}

.iq-eval-summary {
    font-size:var(--text-xs);
    color:var(--text-tertiary);
    max-width:240px;
    white-space:nowrap;
    overflow:hidden;
    text-overflow:ellipsis;
}

/* Pass/Fail buttons inside the Evaluation modal */
.btn-pass { background: var(--success-bg, #d1fae5); color: var(--success, #15803d); border-color: var(--success, #15803d); }
.btn-fail { background: var(--error-bg, #fee2e2);   color: var(--error, #b91c1c);     border-color: var(--error, #b91c1c); }
</style>

<!-- ============================================================
     BACK BUTTON / CONTEXT HEADER
     ------------------------------------------------------------
     • Admin / SSO with a college filter (or all-mode): give them
       a way back to the college picker.
     • Dean and Professor land here directly from the sidebar
       (this IS their primary view), so no back button.
============================================================ -->
<?php if ($canSeeAll): ?>
    <div style="display:flex;align-items:center;gap:var(--space-3);margin-bottom:var(--space-5);flex-wrap:wrap">
        <a href="<?= e(url('/staff/interviews/queue')) ?>" class="btn btn-ghost btn-sm">
            ← Back to colleges
        </a>
        <span style="font-size:var(--text-sm);color:var(--text-secondary)">
            <?php if ($showAll): ?>
                <strong>All colleges</strong>
            <?php else: ?>
                <strong><?= e($collegeFilter) ?></strong>
            <?php endif; ?>
        </span>
    </div>
<?php endif; ?>

<!-- ============================================================
     DESK INFO STRIP (Professor only)
     Only shown when a desk location has been set for this professor
     by SSO / Admin during interview setup. If empty, render nothing
     — setup is not the professor's responsibility.
============================================================ -->
<?php if (!$isAdmin && !$isSSO && !$isDean && $deskLabel): ?>
    <div style="display:flex;align-items:center;gap:var(--space-3);
                 padding:var(--space-3) var(--space-4);margin-bottom:var(--space-4);
                 background:var(--bg-elevated);border:1px solid var(--border);
                 border-radius:var(--radius-md);font-size:var(--text-sm)">
        <?= icon('ic_fluent_location_24_regular', 13, 'color:var(--text-tertiary);flex-shrink:0') ?>
        <span style="font-weight:var(--weight-medium)"><?= e($deskLabel) ?></span>
        <?php if ($deskNotes): ?>
            <span style="color:var(--text-tertiary)"><?= e($deskNotes) ?></span>
        <?php endif; ?>
    </div>
<?php endif; ?>

<?php if (empty($rows)):
    // ----------------------------------------------------------------
    // Empty state — full-page, role-aware. We intentionally hide the
    // toolbar AND the table card so an empty queue isn't dressed up to
    // look like a populated one.
    // ----------------------------------------------------------------
    if ($canSeeAll && $showAll) {
        $emptyTitle = 'No interviews scheduled yet';
        $emptyBody  = 'Once SSO creates interview sessions and applicants are placed, they will show up here.';
    } elseif ($canSeeAll) {
        $emptyTitle = 'No interviews in ' . $collegeFilter . ' yet';
        $emptyBody  = 'Once a session in this college is scheduled and applicants are placed, they will show up here.';
    } elseif ($isDean) {
        $deptLabel  = $staffDept !== '' ? $staffDept : 'your college';
        $emptyTitle = 'No interviews in ' . $deptLabel . ' yet';
        $emptyBody  = 'Once a session in your college is scheduled and applicants are placed, they will show up here.';
    } else {
        $emptyTitle = 'No interviews assigned to you yet';
        $emptyBody  = 'Applicants will appear here automatically once SSO places them on a session you own.';
    }
?>
    <!--
        Use the same .iq-table-card wrapper a populated queue uses so the
        empty state extends the full width AND height of the page area
        (the .page:has(.iq-table-card) rule above turns the page into a
        flex column, and flex:1 makes this card claim the leftover space).
    -->
    <div class="card iq-table-card"
         style="padding:var(--space-12) var(--space-8);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:var(--space-3);text-align:center">
        <div style="width:56px;height:56px;border-radius:var(--radius-lg);background:var(--bg-subtle);color:var(--text-tertiary);display:flex;align-items:center;justify-content:center">
            <?= icon('ic_fluent_calendar_ltr_24_regular', 28) ?>
        </div>
        <div style="font-size:var(--text-base);font-weight:var(--weight-semibold);color:var(--text-primary)">
            <?= e($emptyTitle) ?>
        </div>
        <div style="max-width:480px;font-size:var(--text-sm);color:var(--text-tertiary);line-height:1.5">
            <?= e($emptyBody) ?>
        </div>
    </div>
<?php else: ?>

<!-- ============================================================
     TOOLBAR — search + date filter + count
============================================================ -->
<?php
// Preserve other GET params (college, etc.) when changing the date
// filter so we don't bounce the user back to the college picker.
$dateFilterBaseQuery = $_GET;
unset($dateFilterBaseQuery['date']);
$dateFilterBaseHref = url('/staff/interviews/queue') .
    (!empty($dateFilterBaseQuery) ? '?' . http_build_query($dateFilterBaseQuery) : '');
$dateFilterSep = (strpos($dateFilterBaseHref, '?') !== false) ? '&' : '?';
?>
<div class="iq-toolbar">
    <div class="iq-search-wrap">
        <?= icon('ic_fluent_search_24_filled', 14, 'position:absolute;left:10px;top:50%;transform:translateY(-50%);color:var(--text-tertiary);pointer-events:none') ?>
        <input type="search" id="iq-filter" placeholder="Filter by name or course…"
               autocomplete="off">
    </div>
    <?php
    // Build dropdown options from the dates that actually have queue
    // rows in the caller's scope. "All dates" is always offered as an
    // escape hatch.
    $dateOptions = [];
    if (!empty($availableDateMap)) {
        foreach ($availableDateMap as $d => $cnt) {
            $isToday    = ($d === $today);
            $isTomorrow = ($d === date('Y-m-d', strtotime('+1 day')));
            $isPast     = ($d < $today);
            $label = format_date($d);
            if ($isToday)         $label .= ' (Today)';
            elseif ($isTomorrow)  $label .= ' (Tomorrow)';
            elseif ($isPast)      $label .= ' (Past)';
            $label .= ' · ' . $cnt . ' applicant' . ($cnt === 1 ? '' : 's');
            $dateOptions[$d] = $label;
        }
    }
    $dateOptions['all'] = 'All dates · ' . array_sum($availableDateMap)
        . ' applicant' . (array_sum($availableDateMap) === 1 ? '' : 's');
    ?>
    <select id="iq-date-filter"
            style="height:36px;padding:0 var(--space-3);font-size:var(--text-sm);
                   border:1px solid var(--border);border-radius:var(--radius-sm);
                   background:var(--bg-elevated);color:var(--text-primary);min-width:240px"
            onchange="window.location.href = this.value">
        <?php foreach ($dateOptions as $val => $label):
            $href = $dateFilterBaseHref . $dateFilterSep . 'date=' . urlencode($val);
        ?>
            <option value="<?= e($href) ?>" <?= (string)$dateFilter === (string)$val ? 'selected' : '' ?>>
                <?= e($label) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <span class="iq-count">
        <?= count($rows) ?> applicant<?= count($rows) === 1 ? '' : 's' ?>
    </span>
</div>

<!-- ============================================================
     TABLE — full-page card matching documents/results pages
============================================================ -->
<div class="card iq-table-card" style="padding:0;overflow:hidden;display:flex;flex-direction:column">
    <table class="table" id="queue-table">
        <thead>
            <tr>
                <th>Applicant</th>
                <?php if ($canSeeAll && $showAll): ?>
                    <th style="width:140px">College</th>
                <?php endif; ?>
                <th>Course</th>
                <th style="width:120px">Type</th>
                <th style="width:120px">Status</th>
                <th style="width:140px">Actions</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($rows as $r):
            [$badgeText, $badgeClass] = queue_status_badge($r['status']);
            $rowClass  = 'iq-row-' . str_replace('_', '-', $r['status']);
            $name      = queue_format_name($r);
            $course    = $r['course_applied'] ?? '';
            $type      = $r['applicant_type'] ?? '';
            $isInProg  = $r['status'] === 'in_progress';
            $isFinal   = in_array($r['status'], ['completed', 'no_show'], true);
            $existing  = $r['interview_notes'] ?? '';
            $haystack  = strtolower($name . ' ' . $course . ' ' . $type);
            // Evaluation gating:
            //   • Dean = oversight only (read-only, mirrors Results page).
            //   • SSO  = setup-only (already bounced above, defensive here).
            //   • Row's slot_date must be today — past/future rows cannot be
            //     evaluated since the interview hasn't actually happened yet
            //     (or the slot has already auto-flipped to no-show).
            // Evaluation is only allowed on the day of the interview. Both the
            // "is today" check and the role guard match the server-side check
            // in modules/interview/staff_action.php so the UI never offers a
            // button the POST will reject.
            $rowDate    = isset($r['slot_date']) ? (string)$r['slot_date'] : '';
            $isTodayRow = $rowDate === $today;
            $canEval    = !$isDean && !$isSSO && $isTodayRow;
        ?>
            <tr class="<?= $rowClass ?>" data-name="<?= e($haystack) ?>">
                <td>
                    <button type="button"
                            class="iq-name-cell iq-name-cell-clickable"
                            data-applicant-panel="<?= (int)$r['app_id'] ?>"
                            title="View applicant details">
                        <span><?= e($name) ?></span>
                        <?php if ($r['evaluation_result']): ?>
                            <span class="sub">
                                Result:
                                <strong style="color:<?= $r['evaluation_result'] === 'pass' ? 'var(--success)' : 'var(--error)' ?>">
                                    <?= ucfirst($r['evaluation_result']) ?>
                                </strong>
                            </span>
                        <?php endif; ?>
                        <?php if ($isFinal && $existing !== ''): ?>
                            <span class="sub iq-eval-summary" title="<?= e($existing) ?>">
                                <?= e($existing) ?>
                            </span>
                        <?php endif; ?>
                    </button>
                </td>

                <?php if ($canSeeAll && $showAll): ?>
                    <td style="font-size:var(--text-sm)">
                        <?php $col = (string)($r['slot_department'] ?? ''); ?>
                        <?= $col !== '' ? e($col) : '<span style="color:var(--text-tertiary)">—</span>' ?>
                    </td>
                <?php endif; ?>

                <td style="font-size:var(--text-sm)">
                    <?= $course !== '' ? e($course) : '<span style="color:var(--text-tertiary)">—</span>' ?>
                </td>

                <td style="font-size:var(--text-sm)">
                    <?= $type !== '' ? e(ucfirst($type)) : '<span style="color:var(--text-tertiary)">—</span>' ?>
                </td>

                <td>
                    <span class="badge <?= $badgeClass ?>" style="font-size:var(--text-xs)">
                        <?php if ($isInProg): ?>
                            <span style="display:inline-block;width:6px;height:6px;border-radius:50%;
                                         background:#fff;animation:pulse-dot 1.4s infinite;margin-right:4px"></span>
                        <?php endif; ?>
                        <?= e($badgeText) ?>
                    </span>
                </td>

                <td>
                    <div class="iq-actions">
                        <button type="button"
                                class="btn btn-ghost btn-sm iq-view-btn"
                                data-applicant-panel="<?= (int)$r['app_id'] ?>"
                                title="View applicant details"
                                aria-label="View applicant details">
                            <?= icon('ic_fluent_eye_show_24_regular', 14) ?>
                        </button>
                        <?php if ($isFinal): ?>
                            <span style="font-size:var(--text-xs);color:var(--text-tertiary)">
                                <?php if ($r['status'] === 'no_show'): ?>
                                    Marked no-show
                                <?php else: ?>
                                    <?= $r['evaluation_result']
                                        ? e(ucfirst($r['evaluation_result']))
                                        : 'Completed' ?>
                                <?php endif; ?>
                            </span>
                        <?php elseif (!$canEval): ?>
                            <span style="font-size:var(--text-xs);color:var(--text-tertiary)"
                                  title="<?= $isDean
                                            ? 'Dean is read-only — only Professors / Admin can evaluate'
                                            : (!$isTodayRow ? 'Evaluation is only available on the interview\'s scheduled date' : '') ?>">
                                <?php if ($isDean): ?>
                                    Read only
                                <?php elseif (!$isTodayRow): ?>
                                    <?= e(format_date($r['slot_date'])) ?>
                                <?php else: ?>
                                    —
                                <?php endif; ?>
                            </span>
                        <?php else: ?>
                            <button type="button" class="btn btn-primary btn-sm"
                                    onclick="openEvalModal(
                                        <?= (int)$r['queue_id'] ?>,
                                        <?= htmlspecialchars(json_encode($name), ENT_QUOTES) ?>,
                                        <?= htmlspecialchars(json_encode($course), ENT_QUOTES) ?>,
                                        <?= htmlspecialchars(json_encode($type), ENT_QUOTES) ?>,
                                        <?= htmlspecialchars(json_encode($existing), ENT_QUOTES) ?>
                                    )">
                                <?= icon('ic_fluent_edit_24_regular', 13) ?>
                                Evaluation
                            </button>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>

    <!-- Filler below the last row so the empty space inherits a top divider line -->
    <div style="flex:1;border-top:1px solid var(--border)"></div>
</div>
<?php endif; // empty($rows) ?>

<!-- ============================================================
     EVALUATION MODAL — notes + Pass / Fail
============================================================ -->
<div id="eval-modal" class="modal-backdrop" style="display:none" aria-hidden="true">
    <div class="modal" style="max-width:480px">
        <div class="modal-header">
            <div class="modal-title">Interview Evaluation</div>
            <button class="btn-icon" type="button" onclick="closeEvalModal()">
                <?= icon('ic_fluent_dismiss_24_regular', 18) ?>
            </button>
        </div>

        <form method="POST" id="eval-form" action="">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="complete_with_evaluation">
            <input type="hidden" name="evaluation_result" id="eval-result-input" value="">

            <div class="modal-body" style="display:flex;flex-direction:column;gap:var(--space-4)">
                <div style="background:var(--bg-subtle);border-radius:var(--radius-md);
                            padding:var(--space-3) var(--space-4);font-size:var(--text-sm)">
                    Applicant: <strong id="eval-name"></strong>
                    <div style="font-size:var(--text-xs);color:var(--text-tertiary);margin-top:2px">
                        <span id="eval-type"></span>
                        <span id="eval-sep" style="margin:0 4px">·</span>
                        <span id="eval-course"></span>
                    </div>
                </div>

                <div>
                    <label class="form-label" for="eval-notes">Interview notes</label>
                    <textarea id="eval-notes" name="interview_notes" class="form-control"
                              rows="5" placeholder="Interview notes / evaluation remarks…"></textarea>
                </div>

                <div style="font-size:var(--text-xs);color:var(--text-tertiary)">
                    Choose Pass or Fail to finalize this interview.
                </div>
            </div>

            <div class="modal-footer" style="display:flex;gap:var(--space-2);justify-content:flex-end">
                <button type="button" class="btn btn-ghost" onclick="closeEvalModal()">Cancel</button>
                <button type="submit" class="btn btn-fail"
                        onclick="document.getElementById('eval-result-input').value='fail'">
                    <?= icon('ic_fluent_dismiss_24_regular', 13) ?> Fail
                </button>
                <button type="submit" class="btn btn-pass"
                        onclick="document.getElementById('eval-result-input').value='pass'">
                    <?= icon('ic_fluent_checkmark_24_regular', 13) ?> Pass
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ============================================================
     SCRIPT
============================================================ -->
<script>
// Live filter
document.getElementById('iq-filter')?.addEventListener('input', (e) => {
    const term = e.target.value.toLowerCase().trim();
    document.querySelectorAll('#queue-table tbody tr').forEach(tr => {
        const haystack = tr.dataset.name || '';
        tr.style.display = (!term || haystack.includes(term)) ? '' : 'none';
    });
});

// Evaluation modal handlers
const evalModal = document.getElementById('eval-modal');

function openEvalModal(queueId, name, course, type, notes) {
    document.getElementById('eval-form').action =
        '<?= e(url('/staff/interviews/')) ?>' + queueId;
    document.getElementById('eval-name').textContent  = name || '';
    document.getElementById('eval-course').textContent = course || '';
    document.getElementById('eval-type').textContent  = type
        ? type.charAt(0).toUpperCase() + type.slice(1)
        : '';
    document.getElementById('eval-sep').style.display =
        (course && type) ? '' : 'none';
    document.getElementById('eval-notes').value = notes || '';
    document.getElementById('eval-result-input').value = '';
    evalModal.style.display = 'flex';
    setTimeout(() => document.getElementById('eval-notes').focus(), 50);
}

function closeEvalModal() {
    evalModal.style.display = 'none';
}

evalModal.addEventListener('click', function (e) {
    if (e.target === evalModal) closeEvalModal();
});

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && evalModal.style.display === 'flex') {
        closeEvalModal();
    }
});

// Submission guard — make sure the user actually clicked Pass or Fail
document.getElementById('eval-form').addEventListener('submit', function (e) {
    const decision = document.getElementById('eval-result-input').value;
    if (decision !== 'pass' && decision !== 'fail') {
        e.preventDefault();
        return false;
    }
    if (!confirm('Mark this interview as ' + (decision === 'pass' ? 'PASS' : 'FAIL') + '?')) {
        e.preventDefault();
        return false;
    }
});

// Auto-refresh every 60s, but pause when a textarea/input is focused or
// has been edited recently (so we don't blow away typed-but-unsaved notes,
// and so the modal doesn't get clobbered mid-evaluation).
let lastFocusTime = 0;
document.addEventListener('focusin', (e) => {
    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
        lastFocusTime = Date.now();
    }
});
document.addEventListener('input', (e) => {
    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
        lastFocusTime = Date.now();
    }
});
setInterval(() => {
    if (Date.now() - lastFocusTime < 120000) return;
    if (evalModal.style.display === 'flex') return;
    window.location.reload();
}, 60000);
</script>

<?php
// Slide-in applicant detail drawer (markup + JS opener).
include VIEWS_PATH . '/partials/applicant_drawer.php';

$content   = ob_get_clean();
if ($canSeeAll) {
    $pageTitle = $showAll
        ? 'Live Queue · All colleges'
        : 'Live Queue · ' . $collegeFilter;
} else {
    $pageTitle = 'Live Queue';
}
$activeNav = 'interviews';
$pageWide  = true;
include VIEWS_PATH . '/layouts/app.php';
