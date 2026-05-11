<?php
// ============================================================
// modules/interview/staff_absent.php
//
// Two-tab page for SSO / Admin / Staff to handle interview
// scheduling exceptions:
//
//   Tab 1 — Absent Students      (interview_queue.interview_status = 'absent')
//   Tab 2 — Reschedule Requests  (reschedule_requests.status = 'pending')
//
// URL:
//   GET  /staff/interviews/absent[?tab=requests|absent]
//   POST /staff/interviews/absent
//     action=reschedule          → bulk-reschedule selected absent applicants
//     action=approve_request     → approve a student's reschedule request
//                                  (deletes their current queue row, reruns
//                                   assign_interview_slot for them)
//     action=reject_request      → reject a student's reschedule request
// ============================================================

require_once CORE_PATH . '/bootstrap.php';
Auth::requireRole(ROLE_STAFF, ROLE_SSO, ROLE_ADMIN);

// Make sure reschedule_requests exists before any read/write below.
ensure_reschedule_requests_table();

$db      = db();
$staffId = Auth::id();

$errors  = [];
$success = [];
$activeTab = (($_GET['tab'] ?? '') === 'requests') ? 'requests' : 'absent';

// ----------------------------------------------------------------
// POST handlers
// ----------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = $_POST['action'] ?? '';

    if ($action === 'reschedule') {
        $applicantIds = $_POST['applicant_ids'] ?? [];
        if (!is_array($applicantIds)) { $applicantIds = []; }
        $applicantIds = array_values(array_unique(array_map('intval', $applicantIds)));
        $applicantIds = array_filter($applicantIds, fn($v) => $v > 0);

        $targetSlotId = (int)($_POST['target_slot_id'] ?? 0);

        if (empty($applicantIds)) {
            $errors[] = 'Please select at least one absent applicant to reschedule.';
        } else {
            $ok = 0;
            $fail = 0;
            foreach ($applicantIds as $aid) {
                try {
                    $newSlot = reschedule_absent_applicant(
                        $aid,
                        $targetSlotId > 0 ? $targetSlotId : null,
                        $staffId
                    );
                    if ($newSlot) $ok++; else $fail++;
                } catch (Throwable $e) {
                    error_log('reschedule_absent_applicant failed: ' . $e->getMessage());
                    $fail++;
                }
            }
            if ($ok > 0) {
                Session::flash('success',
                    "Rescheduled {$ok} applicant(s)."
                    . ($fail > 0 ? " {$fail} could not be rescheduled (no open slot)." : ''));
            } else {
                Session::flash('error',
                    'No applicants could be rescheduled — make sure there are open slots for their department.');
            }
            redirect('/staff/interviews/absent');
        }
    }

    if ($action === 'approve_request' || $action === 'reject_request') {
        $requestId    = (int)($_POST['request_id'] ?? 0);
        $targetSlotId = (int)($_POST['target_slot_id'] ?? 0);
        if ($requestId <= 0) {
            Session::flash('error', 'Invalid request.');
            redirect('/staff/interviews/absent?tab=requests');
        }

        $rrStmt = $db->prepare(
            'SELECT rr.id, rr.applicant_id, rr.queue_id, rr.status,
                    a.user_id
               FROM reschedule_requests rr
               JOIN applicants a ON a.id = rr.applicant_id
              WHERE rr.id = ? LIMIT 1'
        );
        $rrStmt->execute([$requestId]);
        $rr = $rrStmt->fetch();

        if (!$rr) {
            Session::flash('error', 'Reschedule request not found.');
            redirect('/staff/interviews/absent?tab=requests');
        }
        if ($rr['status'] !== 'pending') {
            Session::flash('error', 'This request has already been reviewed.');
            redirect('/staff/interviews/absent?tab=requests');
        }

        if ($action === 'approve_request') {
            // Delete the student's existing queue row so assign_interview_slot
            // can place them on a fresh one (UNIQUE INDEX on applicant_id).
            $db->prepare('DELETE FROM interview_queue WHERE applicant_id = ?')
               ->execute([(int)$rr['applicant_id']]);

            // Keep applicant in 'interview' status so the scheduler picks
            // them up either via the target slot or auto-assign.
            $db->prepare(
                'UPDATE applicants SET overall_status = "interview"
                  WHERE id = ? AND overall_status IN ("interview","released")'
            )->execute([(int)$rr['applicant_id']]);

            $newSlotId = null;
            try {
                $newSlotId = assign_interview_slot(
                    (int)$rr['applicant_id'],
                    $staffId,
                    $targetSlotId > 0 ? $targetSlotId : null
                );
            } catch (Throwable $e) {
                error_log('approve_request assign_interview_slot failed: ' . $e->getMessage());
            }

            $db->prepare(
                'UPDATE reschedule_requests
                    SET status      = "approved",
                        reviewed_by = ?,
                        reviewed_at = NOW()
                  WHERE id = ?'
            )->execute([$staffId, $requestId]);

            audit_log(
                'reschedule_request_approved',
                "Approved reschedule request #{$requestId} for applicant {$rr['applicant_id']}"
                . ($newSlotId ? " → slot #{$newSlotId}" : ' (no slot available)'),
                'applicant',
                (int)$rr['applicant_id']
            );

            if ($newSlotId) {
                $slotStmt = $db->prepare('SELECT slot_date, slot_time FROM interview_slots WHERE id = ?');
                $slotStmt->execute([$newSlotId]);
                $slotInfo = $slotStmt->fetch();
                if ($slotInfo && (int)$rr['user_id'] > 0) {
                    create_notification(
                        (int)$rr['user_id'],
                        'interview_rescheduled',
                        'Reschedule Approved',
                        'Your reschedule request was approved. New interview: '
                            . date('F j, Y', strtotime($slotInfo['slot_date']))
                            . ' at ' . date('g:i A', strtotime($slotInfo['slot_time'])) . '.',
                        '/student/interview'
                    );
                }
                Session::flash('success', 'Reschedule approved and applicant rebooked.');
            } else {
                if ((int)$rr['user_id'] > 0) {
                    create_notification(
                        (int)$rr['user_id'],
                        'interview_rescheduled',
                        'Reschedule Approved',
                        'Your reschedule request was approved. You will be auto-assigned to the next available slot.',
                        '/student/interview'
                    );
                }
                Session::flash('success', 'Reschedule approved. No open slot right now — they will be auto-assigned when one is created.');
            }
            redirect('/staff/interviews/absent?tab=requests');
        }

        // reject_request
        $db->prepare(
            'UPDATE reschedule_requests
                SET status      = "denied",
                    reviewed_by = ?,
                    reviewed_at = NOW()
              WHERE id = ?'
        )->execute([$staffId, $requestId]);

        audit_log(
            'reschedule_request_rejected',
            "Rejected reschedule request #{$requestId} for applicant {$rr['applicant_id']}",
            'applicant',
            (int)$rr['applicant_id']
        );

        if ((int)$rr['user_id'] > 0) {
            create_notification(
                (int)$rr['user_id'],
                'interview_rescheduled',
                'Reschedule Denied',
                'Your reschedule request was reviewed and not approved. Please attend your original interview slot.',
                '/student/interview'
            );
        }
        Session::flash('success', 'Reschedule request rejected.');
        redirect('/staff/interviews/absent?tab=requests');
    }
}

// ----------------------------------------------------------------
// Load absent applicants + their previous slot
// ----------------------------------------------------------------
$absent = $db->query(
    'SELECT q.id            AS queue_id,
            q.applicant_id,
            q.evaluated_at,
            s.id             AS slot_id,
            s.slot_date      AS missed_date,
            s.slot_time      AS missed_time,
            s.department     AS missed_department,
            a.course_applied,
            u.name           AS student_name,
            u.first_name, u.middle_name, u.last_name, u.suffix,
            u.email          AS student_email,
            u.department     AS student_department
       FROM interview_queue q
       JOIN applicants a ON a.id = q.applicant_id
       JOIN users u      ON u.id = a.user_id
  LEFT JOIN interview_slots s ON s.id = q.slot_id
      WHERE q.interview_status = "absent"
      ORDER BY q.evaluated_at DESC, q.id DESC'
)->fetchAll();

// ----------------------------------------------------------------
// Load open slots (used as reschedule targets)
// ----------------------------------------------------------------
$today   = date('Y-m-d');
$nowTime = date('H:i:s');
$stmt = $db->prepare(
    'SELECT s.id, s.slot_date, s.slot_time, s.end_time, s.department, s.capacity,
            (SELECT COUNT(*) FROM interview_queue q
              WHERE q.slot_id = s.id
                AND q.interview_status IN ("pending","completed")) AS booked
       FROM interview_slots s
      WHERE s.status = "open"
        AND s.slot_date >= ?
        AND NOT (s.slot_date = ? AND s.end_time IS NOT NULL AND s.end_time <= ?)
      ORDER BY s.slot_date ASC, s.slot_time ASC'
);
$stmt->execute([$today, $today, $nowTime]);
$openSlots = array_filter(
    $stmt->fetchAll(),
    fn($s) => (int)$s['booked'] < (int)$s['capacity']
);

// ----------------------------------------------------------------
// Also load reschedule history per absent applicant (most recent 3)
// to surface "this is their 2nd miss" info for context.
// ----------------------------------------------------------------
$historyByApplicant = [];
if (!empty($absent)) {
    $ids  = array_map(fn($r) => (int)$r['applicant_id'], $absent);
    $in   = implode(',', array_fill(0, count($ids), '?'));
    $rows = $db->prepare(
        "SELECT applicant_id, from_slot_date, from_slot_time, rescheduled_at
           FROM reschedule_logs
          WHERE applicant_id IN ($in)
          ORDER BY rescheduled_at DESC"
    );
    $rows->execute($ids);
    foreach ($rows->fetchAll() as $h) {
        $historyByApplicant[(int)$h['applicant_id']][] = $h;
    }
}

// Check for today's sessions (needed for Live Queue tab)
$todayStmt = $db->prepare(
    'SELECT COUNT(*) FROM interview_slots WHERE created_by = ? AND slot_date = ?'
);
$todayStmt->execute([$staffId, $today]);
$hasToday = (int)$todayStmt->fetchColumn() > 0;

// ----------------------------------------------------------------
// Load pending reschedule requests submitted by students themselves
// (modules/api/reschedule_request.php writes these rows). Surface
// them on a dedicated tab so SSO/Admin can approve or reject each.
// ----------------------------------------------------------------
$rescheduleRequests = $db->query(
    'SELECT rr.id              AS request_id,
            rr.applicant_id,
            rr.queue_id,
            rr.reason,
            rr.status,
            rr.created_at       AS requested_at,
            a.course_applied,
            u.name              AS student_name,
            u.first_name, u.middle_name, u.last_name, u.suffix,
            u.email             AS student_email,
            u.department        AS student_department,
            s.slot_date         AS current_slot_date,
            s.slot_time         AS current_slot_time,
            s.department        AS current_department
       FROM reschedule_requests rr
       JOIN applicants a       ON a.id = rr.applicant_id
       JOIN users u            ON u.id = a.user_id
  LEFT JOIN interview_queue q  ON q.id  = rr.queue_id
  LEFT JOIN interview_slots s  ON s.id  = q.slot_id
      WHERE rr.status = "pending"
      ORDER BY rr.created_at ASC'
)->fetchAll();
$pendingRequestCount = count($rescheduleRequests);

ob_start();
?>

<?php foreach ($errors as $err): ?>
    <div class="alert alert-error" style="margin-bottom:var(--space-4)"><?= e($err) ?></div>
<?php endforeach; ?>
<?php foreach ($success as $s): ?>
    <div class="alert alert-success" style="margin-bottom:var(--space-4)"><?= e($s) ?></div>
<?php endforeach; ?>

<div style="margin-bottom:var(--space-5)">
    <a href="<?= url('/staff/interviews') ?>" class="btn btn-ghost btn-sm">← Back</a>
</div>

<!-- ============================================================
     Tab strip
============================================================ -->
<div style="display:flex;gap:var(--space-2);border-bottom:1px solid var(--border);margin-bottom:var(--space-5)">
    <a href="<?= e(url('/staff/interviews/absent')) ?>"
       style="padding:var(--space-3) var(--space-4);font-size:var(--text-sm);font-weight:var(--weight-medium);
              text-decoration:none;color:<?= $activeTab === 'absent' ? 'var(--text-primary)' : 'var(--text-tertiary)' ?>;
              border-bottom:2px solid <?= $activeTab === 'absent' ? 'var(--text-primary)' : 'transparent' ?>;
              margin-bottom:-1px">
        Absent Students
        <?php if (count($absent) > 0): ?>
            <span class="badge" style="margin-left:6px"><?= count($absent) ?></span>
        <?php endif; ?>
    </a>
    <a href="<?= e(url('/staff/interviews/absent?tab=requests')) ?>"
       style="padding:var(--space-3) var(--space-4);font-size:var(--text-sm);font-weight:var(--weight-medium);
              text-decoration:none;color:<?= $activeTab === 'requests' ? 'var(--text-primary)' : 'var(--text-tertiary)' ?>;
              border-bottom:2px solid <?= $activeTab === 'requests' ? 'var(--text-primary)' : 'transparent' ?>;
              margin-bottom:-1px">
        Reschedule Requests
        <?php if ($pendingRequestCount > 0): ?>
            <span class="badge badge-info" style="margin-left:6px"><?= $pendingRequestCount ?></span>
        <?php endif; ?>
    </a>
</div>

<?php if ($activeTab === 'requests'): ?>

    <?php if (empty($rescheduleRequests)): ?>
        <div class="card" style="padding:var(--space-8);text-align:left;color:var(--text-tertiary)">
            No pending reschedule requests right now.
        </div>
    <?php else: ?>
        <div class="card" style="padding:0;overflow:hidden">
            <table class="table" style="width:100%;border-collapse:collapse">
                <thead>
                    <tr style="background:var(--bg-subtle);text-align:left;font-size:var(--text-xs);
                                color:var(--text-tertiary);text-transform:uppercase;letter-spacing:.06em">
                        <th style="padding:var(--space-3) var(--space-4)">Student</th>
                        <th style="padding:var(--space-3) var(--space-4)">Course / Dept</th>
                        <th style="padding:var(--space-3) var(--space-4)">Current Slot</th>
                        <th style="padding:var(--space-3) var(--space-4)">Reason</th>
                        <th style="padding:var(--space-3) var(--space-4)">Requested</th>
                        <th style="padding:var(--space-3) var(--space-4);width:280px">Action</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($rescheduleRequests as $req): ?>
                    <tr style="border-top:1px solid var(--border);font-size:var(--text-sm)">
                        <td style="padding:var(--space-3) var(--space-4)">
                            <div style="font-weight:var(--weight-medium)"><?= e(format_full_name($req)) ?></div>
                            <div style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                <?= e($req['student_email']) ?>
                            </div>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <div><?= e($req['course_applied'] ?: '—') ?></div>
                            <div style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                <?= e($req['student_department'] ?: 'no department') ?>
                            </div>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <?php if ($req['current_slot_date']): ?>
                                <?= format_date($req['current_slot_date']) ?>
                                <?php if ($req['current_slot_time']): ?>
                                    <div style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                        <?= format_time($req['current_slot_time']) ?>
                                    </div>
                                <?php endif; ?>
                            <?php else: ?>
                                <span style="color:var(--text-tertiary)">—</span>
                            <?php endif; ?>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4);max-width:280px">
                            <div style="white-space:pre-wrap;line-height:1.4"><?= e($req['reason']) ?></div>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4);font-size:var(--text-xs);color:var(--text-tertiary)">
                            <?= e(date('M j, g:i A', strtotime($req['requested_at']))) ?>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <div style="display:flex;gap:var(--space-2);flex-wrap:wrap;align-items:center">
                                <form method="POST" style="display:inline-flex;gap:var(--space-2);align-items:center;flex-wrap:wrap">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="approve_request">
                                    <input type="hidden" name="request_id" value="<?= (int)$req['request_id'] ?>">
                                    <select name="target_slot_id" class="form-control" style="max-width:220px;font-size:var(--text-xs)">
                                        <option value="0">Auto-assign next slot</option>
                                        <?php foreach ($openSlots as $s):
                                            $spotsLeft = (int)$s['capacity'] - (int)$s['booked'];
                                        ?>
                                            <option value="<?= (int)$s['id'] ?>">
                                                <?= format_date($s['slot_date']) ?>
                                                <?php if ($s['slot_time']): ?>at <?= format_time($s['slot_time']) ?><?php endif; ?>
                                                · <?= e($s['department'] ?: 'any') ?>
                                                (<?= $spotsLeft ?>)
                                            </option>
                                        <?php endforeach; ?>
                                    </select>
                                    <button type="submit" class="btn btn-primary btn-sm">Approve</button>
                                </form>
                                <form method="POST" style="display:inline-flex"
                                      onsubmit="return confirm('Reject this reschedule request?')">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="reject_request">
                                    <input type="hidden" name="request_id" value="<?= (int)$req['request_id'] ?>">
                                    <button type="submit" class="btn btn-ghost btn-sm">Reject</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <p style="font-size:var(--text-xs);color:var(--text-tertiary);margin-top:var(--space-2)">
            Approving removes the student's current queue row and books them into the chosen slot (or the next available one if "Auto-assign" is picked). Rejecting leaves their current slot intact.
        </p>
    <?php endif; ?>

<?php elseif (empty($absent)): ?>
    <div class="card" style="padding:var(--space-8);text-align:left;color:var(--text-tertiary)">
        No absent applicants right now.
    </div>
<?php else: ?>
    <form method="POST">
        <?= csrf_field() ?>
        <input type="hidden" name="action" value="reschedule">

        <div class="card" style="padding:0;overflow:hidden;margin-bottom:var(--space-4)">
            <table class="table" style="width:100%;border-collapse:collapse">
                <thead>
                    <tr style="background:var(--bg-subtle);text-align:left;font-size:var(--text-xs);
                                color:var(--text-tertiary);text-transform:uppercase;letter-spacing:.06em">
                        <th style="padding:var(--space-3) var(--space-4);width:36px">
                            <input type="checkbox" id="select-all">
                        </th>
                        <th style="padding:var(--space-3) var(--space-4)">Student</th>
                        <th style="padding:var(--space-3) var(--space-4)">Course / Dept</th>
                        <th style="padding:var(--space-3) var(--space-4)">Missed</th>
                        <th style="padding:var(--space-3) var(--space-4)">History</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($absent as $row):
                    $hist = $historyByApplicant[(int)$row['applicant_id']] ?? [];
                ?>
                    <tr style="border-top:1px solid var(--border);font-size:var(--text-sm)">
                        <td style="padding:var(--space-3) var(--space-4)">
                            <input type="checkbox"
                                   name="applicant_ids[]"
                                   value="<?= (int)$row['applicant_id'] ?>"
                                   class="js-select-row">
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <div style="font-weight:var(--weight-medium)"><?= e(format_full_name($row)) ?></div>
                            <div style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                <?= e($row['student_email']) ?>
                            </div>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <div><?= e($row['course_applied'] ?: '—') ?></div>
                            <div style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                <?= e($row['student_department'] ?: 'no department') ?>
                            </div>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <?php if ($row['missed_date']): ?>
                                <?= format_date($row['missed_date']) ?>
                                <?php if ($row['missed_time']): ?>
                                    <div style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                        <?= format_time($row['missed_time']) ?>
                                    </div>
                                <?php endif; ?>
                            <?php else: ?>
                                —
                            <?php endif; ?>
                        </td>
                        <td style="padding:var(--space-3) var(--space-4)">
                            <?php if (empty($hist)): ?>
                                <span style="color:var(--text-tertiary);font-size:var(--text-xs)">
                                    First miss
                                </span>
                            <?php else: ?>
                                <span style="font-size:var(--text-xs);color:var(--text-tertiary)">
                                    <?= count($hist) ?> previous reschedule<?= count($hist) === 1 ? '' : 's' ?>
                                </span>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <div class="card" style="padding:var(--space-4) var(--space-5);display:flex;align-items:center;gap:var(--space-3);flex-wrap:wrap">
            <label style="font-size:var(--text-sm);font-weight:var(--weight-medium)">Reschedule target:</label>
            <select name="target_slot_id" class="form-control" style="max-width:420px">
                <option value="0">Auto-assign (earliest matching slot)</option>
                <?php foreach ($openSlots as $s):
                    $spotsLeft = (int)$s['capacity'] - (int)$s['booked'];
                ?>
                    <option value="<?= (int)$s['id'] ?>">
                        <?= format_date($s['slot_date']) ?>
                        <?php if ($s['slot_time']): ?>
                            at <?= format_time($s['slot_time']) ?>
                        <?php endif; ?>
                        &nbsp;·&nbsp; <?= e($s['department'] ?: 'any dept') ?>
                        (<?= $spotsLeft ?> spot<?= $spotsLeft !== 1 ? 's' : '' ?> left)
                    </option>
                <?php endforeach; ?>
            </select>
            <div style="flex:1"></div>
            <button type="submit" class="btn btn-primary">Reschedule selected</button>
        </div>
        <p style="font-size:var(--text-xs);color:var(--text-tertiary);margin-top:var(--space-2)">
            Choosing "Auto-assign" will pick the earliest slot that matches each applicant's department.
            Reschedules are recorded in <code>reschedule_logs</code> for audit.
        </p>
    </form>

    <script>
        const selectAll = document.getElementById('select-all');
        if (selectAll) {
            selectAll.addEventListener('change', function () {
                document.querySelectorAll('.js-select-row').forEach(function (cb) {
                    cb.checked = selectAll.checked;
                });
            });
        }
    </script>
<?php endif; ?>

<?php
$content   = ob_get_clean();
$pageTitle = 'Absent Students';
$activeNav = 'reschedules';
include VIEWS_PATH . '/layouts/app.php';
