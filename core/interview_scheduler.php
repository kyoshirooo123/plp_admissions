<?php
// ============================================================
// core/interview_scheduler.php
// Interview slot auto-assignment + department helpers
// ------------------------------------------------------------
// Exposes:
//   course_to_department(string $course): string
//   user_department(int $userId): string
//   assign_interview_slot(int $applicantId, ?int $actorUserId = null): ?int
//   reschedule_interview(int $applicantId, ?int $actorUserId = null): ?int
//   cancel_interview_slot(int $slotId, int $actorUserId): int
//   slot_is_available(array $slotRow): bool
//   departments_list(): array
// ============================================================

/**
 * Resolve the department (college) for a given course.
 * Checks the `course_departments` table first, falls back to the
 * COURSE_DEPARTMENT_MAP config constant.
 *
 * Returns '' when the course is unknown (caller decides how to
 * handle an empty department — usually leave it blank).
 */
function course_to_department(string $course): string
{
    static $cache = [];
    $key = trim($course);
    if ($key === '') return '';
    if (array_key_exists($key, $cache)) return $cache[$key];

    try {
        $stmt = db()->prepare(
            'SELECT d.name
               FROM course_departments cd
               JOIN departments d ON d.id = cd.department_id
              WHERE cd.course_name = ?
              LIMIT 1'
        );
        $stmt->execute([$key]);
        $row = $stmt->fetch();
        if ($row && !empty($row['name'])) {
            return $cache[$key] = (string)$row['name'];
        }
    } catch (\Throwable) {
        // Table may not exist yet (migration pending) — fall through.
    }

    return $cache[$key] = COURSE_DEPARTMENT_MAP[$key] ?? '';
}

/**
 * Return the department currently stored on a user row, or '' if none.
 */
function user_department(int $userId): string
{
    if ($userId <= 0) return '';
    static $cache = [];
    if (isset($cache[$userId])) return $cache[$userId];
    try {
        $stmt = db()->prepare('SELECT department FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $v = $stmt->fetchColumn();
        return $cache[$userId] = is_string($v) ? $v : '';
    } catch (\Throwable) {
        return $cache[$userId] = '';
    }
}

/**
 * Return the full list of department names (canonical order).
 * DB-first so admin-added departments show up; config fallback.
 */
function departments_list(): array
{
    try {
        $rows = db()->query('SELECT name FROM departments ORDER BY name')->fetchAll();
        if ($rows) return array_column($rows, 'name');
    } catch (\Throwable) {}
    return PLP_DEPARTMENTS;
}

/**
 * Is a given interview_slots row currently bookable?
 * Row must include: status, slot_date, end_time (nullable), capacity, booked.
 */
function slot_is_available(array $slot): bool
{
    if (($slot['status'] ?? '') !== 'open') return false;

    $today   = date('Y-m-d');
    $nowTime = date('H:i:s');
    $date    = (string)($slot['slot_date'] ?? '');
    if ($date === '' || $date < $today) return false;
    if ($date === $today
        && !empty($slot['end_time'])
        && (string)$slot['end_time'] <= $nowTime) {
        return false;
    }

    $cap    = (int)($slot['capacity'] ?? 0);
    $booked = (int)($slot['booked']   ?? 0);
    return $cap > 0 && $booked < $cap;
}

/**
 * Auto-assign the best available interview slot to an applicant.
 *
 * Algorithm:
 *   1. Resolve applicant's department from their course_applied.
 *   2. Inside a transaction, lock all open future slots matching
 *      that department (or any department when the applicant has
 *      none yet) and pick the one with the lowest booked count —
 *      earliest date as tie-breaker, earliest time next.  This is
 *      the "fair distribution" rule.
 *   3. Reject if the applicant already has an active queue row
 *      (prevents double-booking).
 *   4. Insert an interview_queue row and advance the applicant's
 *      overall_status.  Audit log under `interview_slot_auto_assigned`.
 *
 * Returns the chosen slot_id, or NULL when no slot is available.
 * Throws on unrecoverable DB errors so callers can surface messages.
 */
function assign_interview_slot(int $applicantId, ?int $actorUserId = null): ?int
{
    $pdo = db();

    // Load the applicant and current department eagerly so that we can
    // fall back gracefully if the department is missing.
    $stmt = $pdo->prepare(
        'SELECT a.id, a.user_id, a.course_applied, u.department
           FROM applicants a
           JOIN users u ON u.id = a.user_id
          WHERE a.id = ?
          LIMIT 1'
    );
    $stmt->execute([$applicantId]);
    $applicant = $stmt->fetch();
    if (!$applicant) return null;

    $department = (string)($applicant['department'] ?? '');
    if ($department === '') {
        $department = course_to_department((string)$applicant['course_applied']);
        // Opportunistically backfill the user row so future queries are fast.
        if ($department !== '') {
            try {
                $pdo->prepare('UPDATE users SET department = ? WHERE id = ? AND (department = "" OR department IS NULL)')
                    ->execute([$department, (int)$applicant['user_id']]);
            } catch (\Throwable) {}
        }
    }

    $pdo->beginTransaction();
    try {
        // Reject duplicate booking up front.
        $dup = $pdo->prepare('SELECT id FROM interview_queue WHERE applicant_id = ? LIMIT 1 FOR UPDATE');
        $dup->execute([$applicantId]);
        if ($dup->fetch()) {
            $pdo->rollBack();
            return null;
        }

        $today   = date('Y-m-d');
        $nowTime = date('H:i:s');

        // Candidate slots: open, not expired, not at capacity.
        // We MATCH the applicant's department; if they have none we
        // allow any department (backward compatibility).
        $params = [$today, $today, $nowTime];
        $sql = 'SELECT s.id, s.capacity,
                       (SELECT COUNT(*) FROM interview_queue q WHERE q.slot_id = s.id) AS booked
                  FROM interview_slots s
                 WHERE s.status = "open"
                   AND s.slot_date >= ?
                   AND NOT (s.slot_date = ? AND s.end_time IS NOT NULL AND s.end_time <= ?)';
        if ($department !== '') {
            $sql .= ' AND (s.department = ? OR s.department = "")';
            $params[] = $department;
        }
        $sql .= ' ORDER BY booked ASC, s.slot_date ASC, s.slot_time ASC, s.id ASC
                  FOR UPDATE';

        $q = $pdo->prepare($sql);
        $q->execute($params);
        $candidate = null;
        while ($row = $q->fetch()) {
            if ((int)$row['booked'] < (int)$row['capacity']) {
                $candidate = $row;
                break;
            }
        }

        if (!$candidate) {
            $pdo->rollBack();
            return null;
        }

        $slotId = (int)$candidate['id'];

        $pdo->prepare(
            'INSERT INTO interview_queue (slot_id, applicant_id, status)
             VALUES (?, ?, "scheduled")'
        )->execute([$slotId, $applicantId]);

        $pdo->prepare(
            'UPDATE applicants SET overall_status = "interview" WHERE id = ?'
        )->execute([$applicantId]);

        $pdo->commit();
    } catch (\Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    _audit_slot_change(
        'interview_slot_auto_assigned',
        "Auto-assigned applicant #{$applicantId} to slot #{$slotId} (dept: " . ($department ?: 'n/a') . ")",
        $slotId,
        $actorUserId
    );

    return $slotId;
}

/**
 * Re-assign an applicant whose current slot has become unavailable
 * (e.g. the staff cancelled it, the session closed, or the slot was
 * deleted).  Keeps their previous slot_id in the audit trail.
 *
 * Returns the new slot_id, or NULL when no alternative is available.
 */
function reschedule_interview(int $applicantId, ?int $actorUserId = null): ?int
{
    $pdo = db();

    $stmt = $pdo->prepare(
        'SELECT q.id, q.slot_id, s.status AS slot_status
           FROM interview_queue q
      LEFT JOIN interview_slots s ON s.id = q.slot_id
          WHERE q.applicant_id = ?
          LIMIT 1'
    );
    $stmt->execute([$applicantId]);
    $row = $stmt->fetch();

    $previousSlotId = $row ? (int)$row['slot_id'] : 0;

    if ($row) {
        // Drop the old row so assign_interview_slot can issue a new one.
        $pdo->prepare('DELETE FROM interview_queue WHERE id = ? AND status = "scheduled"')
            ->execute([(int)$row['id']]);
    }

    $newSlotId = assign_interview_slot($applicantId, $actorUserId);

    _audit_slot_change(
        'interview_slot_rescheduled',
        "Rescheduled applicant #{$applicantId} from slot #"
            . ($previousSlotId ?: 'none')
            . " to slot #" . ($newSlotId ?: 'none'),
        $newSlotId ?: $previousSlotId,
        $actorUserId
    );

    return $newSlotId;
}

/**
 * Cancel (close) an interview slot and auto-reschedule every applicant
 * currently booked into it.  Completed/in-progress rows are left alone.
 *
 * Returns the number of applicants that were rescheduled successfully.
 */
function cancel_interview_slot(int $slotId, int $actorUserId): int
{
    $pdo = db();

    $pdo->beginTransaction();
    try {
        $pdo->prepare('UPDATE interview_slots SET status = "closed" WHERE id = ?')
            ->execute([$slotId]);

        // Only reschedule people who have not checked in yet.
        $stmt = $pdo->prepare(
            'SELECT applicant_id FROM interview_queue
              WHERE slot_id = ? AND status = "scheduled"'
        );
        $stmt->execute([$slotId]);
        $applicants = array_map('intval', $stmt->fetchAll(\PDO::FETCH_COLUMN) ?: []);

        // Detach all scheduled rows from the slot before rebooking.
        $pdo->prepare(
            'DELETE FROM interview_queue
              WHERE slot_id = ? AND status = "scheduled"'
        )->execute([$slotId]);

        $pdo->commit();
    } catch (\Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    _audit_slot_change(
        'interview_slot_cancelled',
        "Closed slot #{$slotId}, rebooking " . count($applicants) . ' applicant(s)',
        $slotId,
        $actorUserId
    );

    $rebooked = 0;
    foreach ($applicants as $aid) {
        try {
            $newSlot = assign_interview_slot($aid, $actorUserId);
            if ($newSlot) $rebooked++;
        } catch (\Throwable $e) {
            error_log("reschedule_interview failed for applicant #{$aid}: " . $e->getMessage());
        }
    }

    return $rebooked;
}

/**
 * Update a user's department and write an audit entry.
 */
function set_user_department(int $userId, string $department, ?int $actorUserId = null): void
{
    $department = trim($department);
    if ($userId <= 0) return;

    $pdo = db();
    $stmt = $pdo->prepare('SELECT department FROM users WHERE id = ? LIMIT 1');
    $stmt->execute([$userId]);
    $previous = (string)($stmt->fetchColumn() ?: '');
    if ($previous === $department) return;

    $pdo->prepare('UPDATE users SET department = ? WHERE id = ?')
        ->execute([$department, $userId]);

    _audit_slot_change(
        'user_department_updated',
        "User #{$userId} department: '" . ($previous ?: 'n/a') . "' → '" . ($department ?: 'n/a') . "'",
        $userId,
        $actorUserId,
        'user'
    );
}

/**
 * Internal — thin audit_log() wrapper that tolerates calls made before
 * Auth::check() is meaningful (e.g. during registration).
 */
function _audit_slot_change(
    string  $action,
    string  $description,
    ?int    $entityId,
    ?int    $actorUserId = null,
    string  $entityType  = 'interview_slot'
): void {
    try {
        audit_log($action, $description, $entityType, $entityId);
    } catch (\Throwable) {
        // audit_log already swallows its own errors; belt-and-braces here.
    }
    // Always emit to error_log so ops has a trail even when audit table
    // is unavailable (slot assignment should never be silent).
    error_log(sprintf(
        '[interview] %s actor=%s entity=%s#%s — %s',
        $action,
        $actorUserId !== null ? (string)$actorUserId : 'system',
        $entityType,
        $entityId !== null ? (string)$entityId : 'n/a',
        $description
    ));
}
