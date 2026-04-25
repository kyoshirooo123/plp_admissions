<?php
// ============================================================
// modules/results/staff_manage.php
// M6 — Staff: release admission results
// ============================================================

require_once CORE_PATH . '/bootstrap.php';
Auth::requireRole(ROLE_STAFF, ROLE_ADMIN);

$db      = db();
$staffId = Auth::id();

$search  = trim($_GET['q'] ?? '');
$filter  = $_GET['result'] ?? '';
$page    = max(1, (int)($_GET['page'] ?? 1));

$where  = ["a.overall_status IN ('released','exam','interview')"];
$params = [];

if ($search) {
    $where[]       = '(u.name LIKE :q OR u.email LIKE :q OR a.course_applied LIKE :q)';
    $params[':q']  = '%' . $search . '%';
}
if ($filter) {
    $where[]           = 'ar.result = :result';
    $params[':result'] = $filter;
}
$whereStr = implode(' AND ', $where);

$result = paginate(
    $db,
    "SELECT COUNT(*) FROM applicants a
     JOIN users u ON u.id=a.user_id
     LEFT JOIN admission_results ar ON ar.applicant_id=a.id
     WHERE $whereStr",
    "SELECT a.*, u.name AS student_name, u.email,
            ar.result AS admission_result, ar.remarks AS admission_remarks, ar.released_at,
            er.score  AS exam_score, er.total_items AS exam_total,
            er.rank_score AS exam_rank, er.passed AS exam_passed,
            iq.status AS interview_status, iq.interview_notes
     FROM applicants a
     JOIN users u ON u.id=a.user_id
     LEFT JOIN admission_results ar ON ar.applicant_id=a.id
     LEFT JOIN exam_results       er ON er.applicant_id=a.id
     LEFT JOIN interview_queue    iq ON iq.applicant_id=a.id
     WHERE $whereStr
     ORDER BY a.updated_at DESC",
    $params, $page, 25
);

ob_start();
?>

<?php if ($msg = Session::getFlash('success')): ?>
    <div class="alert alert-success" style="margin-bottom:var(--space-4)"><?= e($msg) ?></div>
<?php endif; ?>
<?php if ($msg = Session::getFlash('error')): ?>
    <div class="alert alert-error" style="margin-bottom:var(--space-4)"><?= e($msg) ?></div>
<?php endif; ?>

<!-- Filters -->
<div style="display:flex;gap:var(--space-3);margin-bottom:var(--space-5);flex-wrap:wrap">
    <form method="GET" style="flex:1;max-width:360px">
        <input type="hidden" name="result" value="<?= e($filter) ?>">
        <div style="position:relative">
            <svg width="16" height="16" fill="none" viewBox="0 0 24 24"
                 style="position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--text-tertiary)">
                <path stroke="currentColor" stroke-width="2" stroke-linecap="round" d="M21 21l-4.35-4.35m0 0A7 7 0 105.65 5.65a7 7 0 0011 11.35z"/>
            </svg>
            <input type="text" name="q" value="<?= e($search) ?>" class="form-control"
                   style="padding-left:38px" placeholder="Search…">
        </div>
    </form>
    <div style="display:flex;gap:var(--space-2)">
        <?php foreach (['' => 'All', 'accepted' => 'Accepted', 'waitlisted' => 'Waitlisted', 'rejected' => 'Rejected'] as $val => $lbl): ?>
            <a href="?result=<?= urlencode($val) ?>&q=<?= urlencode($search) ?>"
               class="btn <?= $filter===$val ? 'btn-primary' : 'btn-ghost' ?> btn-sm"><?= $lbl ?></a>
        <?php endforeach; ?>
    </div>
</div>

<div class="card" style="padding:0;overflow:hidden">
    <table class="table">
        <thead>
            <tr>
                <th>Applicant</th>
                <th>Course</th>
                <th>Exam Score</th>
                <th>Interview</th>
                <th>Result</th>
                <th>Released</th>
                <th style="width:100px"></th>
            </tr>
        </thead>
        <tbody>
        <?php if (empty($result['data'])): ?>
            <tr><td colspan="7" style="text-align:center;color:var(--text-tertiary);padding:var(--space-8)">No applicants found.</td></tr>
        <?php else: ?>
            <?php foreach ($result['data'] as $row): ?>
                <tr>
                    <td>
                        <div style="font-weight:var(--weight-medium)"><?= e($row['student_name']) ?></div>
                        <div style="font-size:var(--text-sm);color:var(--text-tertiary)"><?= e($row['email']) ?></div>
                        <div style="margin-top:2px">
                            <span class="badge badge-<?= $row['overall_status'] ?>"><?= e(ucfirst(str_replace('_',' ',$row['overall_status']))) ?></span>
                        </div>
                    </td>
                    <td style="font-size:var(--text-sm)"><?= e($row['course_applied']) ?></td>

                    <!-- Exam score -->
                    <td>
                        <?php if ($row['exam_score'] !== null): ?>
                            <?php
                                $rank     = $row['exam_rank'] > 0 ? (int)$row['exam_rank']
                                            : score_to_rank((int)$row['exam_score'], (int)($row['exam_total'] ?: 1));
                                $tierInfo = rank_tier_info($rank);
                                $passed   = $row['exam_passed'] !== null
                                            ? (bool)$row['exam_passed']
                                            : exam_passed((int)$row['exam_score'], (int)($row['exam_total'] ?: 1), $row['course_applied']);
                                $pct      = $row['exam_total'] > 0 ? round(($row['exam_score'] / $row['exam_total']) * 100) : 0;
                            ?>
                            <!-- Rank circle + raw score -->
                            <div style="display:flex;align-items:center;gap:var(--space-2)">
                                <div style="width:32px;height:32px;border-radius:50%;
                                            background:<?= $tierInfo['bg'] ?>;
                                            border:2px solid <?= $tierInfo['color'] ?>;
                                            display:flex;align-items:center;justify-content:center;
                                            font-weight:var(--weight-bold);font-size:var(--text-sm);
                                            color:<?= $tierInfo['color'] ?>;
                                            flex-shrink:0">
                                    <?= $rank ?>
                                </div>
                                <div>
                                    <div style="font-size:var(--text-xs);font-weight:var(--weight-medium)">
                                        <?= (int)$row['exam_score'] ?>/<?= (int)$row['exam_total'] ?>
                                        <span style="color:var(--text-tertiary)">(<?= $pct ?>%)</span>
                                    </div>
                                    <div style="display:flex;align-items:center;gap:4px;margin-top:2px">
                                        <span style="font-size:10px;font-weight:var(--weight-semibold);
                                                     color:<?= $tierInfo['color'] ?>"><?= $tierInfo['label'] ?></span>
                                        <span style="font-size:10px;color:var(--text-tertiary)">·</span>
                                        <?php if ($passed): ?>
                                            <span style="font-size:10px;color:#22c55e;font-weight:var(--weight-semibold)">✓ Passed</span>
                                        <?php else: ?>
                                            <span style="font-size:10px;color:#ef4444;font-weight:var(--weight-semibold)">✗ Failed</span>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </div>
                            <!-- Suggest button if failed -->
                            <?php if (!$passed): ?>
                                <?php $alts = suggest_alt_courses((int)$row['exam_score'], (int)($row['exam_total'] ?: 1), $row['course_applied']); ?>
                                <?php if (!empty($alts)): ?>
                                <button class="btn btn-ghost btn-sm" style="margin-top:var(--space-1);font-size:10px;padding:2px 8px;color:var(--warning)"
                                        onclick="openSuggestModal(
                                            <?= $row['id'] ?>,
                                            <?= htmlspecialchars(json_encode($row['student_name']), ENT_QUOTES) ?>,
                                            <?= htmlspecialchars(json_encode($alts), ENT_QUOTES) ?>,
                                            <?= $rank ?>)">
                                    💡 Suggest course
                                </button>
                                <?php else: ?>
                                <div style="font-size:10px;color:var(--text-tertiary);margin-top:4px">No alt. courses available</div>
                                <?php endif; ?>
                            <?php endif; ?>
                        <?php else: ?>
                            <span style="color:var(--text-tertiary);font-size:var(--text-sm)">—</span>
                        <?php endif; ?>
                    </td>

                    <!-- Interview status -->
                    <td>
                        <?php if ($row['interview_status']): ?>
                            <?php
                                $iMap = [
                                    'scheduled'   => ['badge-info',    'Scheduled'],
                                    'checked_in'  => ['badge-info',    'Checked In'],
                                    'in_progress' => ['badge-review',  'In Progress'],
                                    'completed'   => ['badge-approved','Completed'],
                                    'no_show'     => ['badge-rejected','No-show'],
                                ];
                                [$ibadge, $ilabel] = $iMap[$row['interview_status']] ?? ['badge-neutral', ucfirst($row['interview_status'])];
                            ?>
                            <span class="badge <?= $ibadge ?>"><?= $ilabel ?></span>
                            <?php if ($row['interview_notes']): ?>
                                <div style="font-size:var(--text-xs);color:var(--text-tertiary);
                                             margin-top:var(--space-1);max-width:180px;
                                             white-space:nowrap;overflow:hidden;text-overflow:ellipsis"
                                     title="<?= e($row['interview_notes']) ?>">
                                    <?= e($row['interview_notes']) ?>
                                </div>
                            <?php endif; ?>
                        <?php else: ?>
                            <span style="color:var(--text-tertiary);font-size:var(--text-sm)">—</span>
                        <?php endif; ?>
                    </td>

                    <!-- Admission result -->
                    <td>
                        <?php if ($row['admission_result']): ?>
                            <span class="badge badge-<?= $row['admission_result'] ?>"><?= e(RESULT_LABELS[$row['admission_result']]) ?></span>
                            <?php if ($row['admission_remarks']): ?>
                                <div style="font-size:var(--text-xs);color:var(--text-tertiary);
                                             margin-top:var(--space-1);max-width:160px;
                                             white-space:nowrap;overflow:hidden;text-overflow:ellipsis"
                                     title="<?= e($row['admission_remarks']) ?>">
                                    <?= e($row['admission_remarks']) ?>
                                </div>
                            <?php endif; ?>
                        <?php else: ?>
                            <span style="color:var(--text-tertiary);font-size:var(--text-sm)">Pending</span>
                        <?php endif; ?>
                    </td>

                    <td style="font-size:var(--text-sm);color:var(--text-tertiary)">
                        <?= $row['released_at'] ? format_date($row['released_at'], 'M j, Y') : '—' ?>
                    </td>
                    <td>
                        <button class="btn btn-secondary btn-sm"
                                onclick="openReleaseModal(<?= $row['id'] ?>, <?= htmlspecialchars(json_encode($row['student_name']), ENT_QUOTES) ?>, <?= htmlspecialchars(json_encode($row['admission_result']), ENT_QUOTES) ?>, <?= htmlspecialchars(json_encode($row['admission_remarks'] ?? ''), ENT_QUOTES) ?>)">
                            <?= $row['admission_result'] ? 'Edit' : 'Release' ?>
                        </button>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</div>

<!-- Pagination -->
<?php if ($result['last_page'] > 1): ?>
    <div style="display:flex;justify-content:center;gap:var(--space-2);margin-top:var(--space-6)">
        <?php for ($i = 1; $i <= $result['last_page']; $i++): ?>
            <a href="?result=<?= urlencode($filter) ?>&q=<?= urlencode($search) ?>&page=<?= $i ?>"
               class="btn <?= $i === $result['current_page'] ? 'btn-primary' : 'btn-ghost' ?> btn-sm" style="min-width:36px"><?= $i ?></a>
        <?php endfor; ?>
    </div>
<?php endif; ?>

<!-- Suggest course modal -->
<div id="suggest-modal" class="modal-backdrop" style="display:none">
    <div class="modal" style="max-width:460px">
        <div class="modal-header">
            <div class="modal-title">Suggest Alternative Course</div>
            <button class="btn-icon" onclick="document.getElementById('suggest-modal').style.display='none'">
                <?= icon('ic_fluent_dismiss_24_regular', 18) ?>
            </button>
        </div>
        <form method="POST" id="suggest-form">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="suggest_course">
            <div class="modal-body" style="display:flex;flex-direction:column;gap:var(--space-4)">
                <div style="background:var(--bg-subtle);border-radius:var(--radius-md);padding:var(--space-3) var(--space-4);font-size:var(--text-sm)">
                    Applicant: <strong id="suggest-name"></strong><br>
                    <span style="font-size:var(--text-xs);color:var(--text-tertiary)">
                        Exam rank: <strong id="suggest-rank"></strong>/10 — did not pass applied course threshold.
                    </span>
                </div>
                <div>
                    <label class="form-label">Suggest a course where their score qualifies:</label>
                    <div id="suggest-course-list" style="display:flex;flex-direction:column;gap:var(--space-2);margin-top:var(--space-2)"></div>
                </div>
                <div>
                    <label class="form-label">Note for applicant (optional)</label>
                    <textarea name="suggest_note" class="form-control" rows="2"
                              placeholder="e.g. We recommend you consider this course based on your exam results…"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-ghost" onclick="document.getElementById('suggest-modal').style.display='none'">Cancel</button>
                <button type="submit" class="btn btn-primary">Send Suggestion</button>
            </div>
        </form>
    </div>
</div>

<!-- Release modal -->
<div id="release-modal" class="modal-backdrop" style="display:none">
    <div class="modal" style="max-width:420px">
        <div class="modal-header">
            <div class="modal-title">Release Result</div>
            <button class="btn-icon" onclick="document.getElementById('release-modal').style.display='none'">
                <?= icon('ic_fluent_dismiss_24_regular', 18) ?>
            </button>
        </div>
        <form method="POST" id="release-form" action="">
            <?= csrf_field() ?>
            <div class="modal-body" style="display:flex;flex-direction:column;gap:var(--space-4)">
                <p id="release-name" style="font-weight:var(--weight-medium)"></p>
                <div>
                    <label class="form-label">Decision <span style="color:var(--error)">*</span></label>
                    <select name="result" class="form-control" id="release-result" required>
                        <option value="">Select…</option>
                        <?php foreach (RESULT_LABELS as $val => $lbl): ?>
                            <option value="<?= $val ?>"><?= $lbl ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div>
                    <label class="form-label">Remarks (optional)</label>
                    <textarea name="remarks" class="form-control" rows="3" id="release-remarks"
                              placeholder="Additional notes for the applicant…"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-ghost" onclick="document.getElementById('release-modal').style.display='none'">Cancel</button>
                <button type="submit" class="btn btn-primary">Save Result</button>
            </div>
        </form>
    </div>
</div>
<script>
function openReleaseModal(appId, name, currentResult, currentRemarks) {
    document.getElementById('release-form').action = '<?= url('/staff/results/') ?>' + appId;
    document.getElementById('release-name').textContent = name;
    document.getElementById('release-result').value = currentResult || '';
    document.getElementById('release-remarks').value = currentRemarks || '';
    document.getElementById('release-modal').style.display = 'flex';
}
document.getElementById('release-modal').addEventListener('click', function(e){
    if(e.target===this) this.style.display='none';
});

// ── Course suggestion modal ────────────────────────────────────
function openSuggestModal(appId, name, alts, rank) {
    const modal = document.getElementById('suggest-modal');
    document.getElementById('suggest-name').textContent = name;
    document.getElementById('suggest-rank').textContent = rank;
    const list = document.getElementById('suggest-course-list');
    list.innerHTML = '';
    alts.forEach(function(course) {
        const li = document.createElement('label');
        li.style.cssText = 'display:flex;align-items:center;gap:10px;padding:10px 12px;border:1px solid var(--border);border-radius:var(--radius-md);cursor:pointer;font-size:var(--text-sm)';
        li.innerHTML = '<input type="radio" name="suggest_course" value="' + escHtml(course) + '" style="accent-color:var(--accent)"> ' + escHtml(course);
        list.appendChild(li);
    });
    document.getElementById('suggest-form').action = '<?= url('/staff/results/suggest/') ?>' + appId;
    modal.style.display = 'flex';
}
function escHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
document.getElementById('suggest-modal').addEventListener('click', function(e){
    if(e.target===this) this.style.display='none';
});
</script>

<?php
$content   = ob_get_clean();
$pageTitle = 'Admission Results';
$activeNav = 'results';
include VIEWS_PATH . '/layouts/app.php';