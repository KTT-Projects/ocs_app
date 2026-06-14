<?php

class ModerationService
{
  private $conn;
  private $entityMap = [
    'feed' => [
      'table' => 'feeds',
      'id_column' => 'id',
      'subject_column' => 'created_by',
      'text_columns' => ['display_name', 'description', 'rules'],
    ],
    'feed_post' => [
      'table' => 'feed_posts',
      'id_column' => 'id',
      'subject_column' => 'user_id',
      'text_columns' => ['title', 'content'],
    ],
    'comment' => [
      'table' => 'comments',
      'id_column' => 'id',
      'subject_column' => 'user_id',
      'text_columns' => ['content'],
    ],
    'study_question' => [
      'table' => 'study_questions',
      'id_column' => 'id',
      'subject_column' => 'author_user_id',
      'text_columns' => ['title', 'body', 'category'],
    ],
    'study_answer' => [
      'table' => 'study_answers',
      'id_column' => 'id',
      'subject_column' => 'author_user_id',
      'text_columns' => ['body'],
    ],
    'volunteer_opportunity' => [
      'table' => 'volunteer_opportunities',
      'id_column' => 'id',
      'subject_column' => 'organizer_id',
      'text_columns' => ['title', 'description', 'location'],
    ],
    'volunteer_reflection' => [
      'table' => 'volunteer_reflections',
      'id_column' => 'id',
      'subject_column' => 'created_by',
      'text_columns' => ['title', 'body'],
    ],
    'user_profile' => [
      'table' => 'user_profiles',
      'id_column' => 'user_id',
      'subject_column' => 'user_id',
      'text_columns' => ['display_name', 'bio'],
    ],
  ];

  public function __construct($db)
  {
    $this->conn = $db;
  }

  public function moderateText($userId, $entityType, array $fields, array $context = [])
  {
    $text = $this->buildModerationText($fields);
    $decision = 'approved';
    $severity = 'low';
    $reasons = [];
    $provider = null;
    $providerResponse = null;

    if ($text !== '') {
      $local = $this->runLocalRules($text);
      $decision = $local['decision'];
      $severity = $local['severity'];
      $reasons = $local['reasons'];

      $providerResult = $this->runOpenAIModeration($text);
      if ($providerResult !== null) {
        $provider = $providerResult['provider'];
        $providerResponse = $providerResult['response'];
        if ($providerResult['decision'] !== 'approved') {
          $decision = $this->strongerDecision($decision, $providerResult['decision']);
          $severity = $this->strongerSeverity($severity, $providerResult['severity']);
          $reasons = array_values(array_unique(array_merge($reasons, $providerResult['reasons'])));
        }
      }
    }

    return [
      'decision' => $decision,
      'status' => $this->statusForDecision($decision),
      'severity' => $severity,
      'reasons' => $reasons,
      'provider' => $provider,
      'provider_response' => $providerResponse,
      'snapshot' => [
        'entity_type' => $entityType,
        'fields' => $fields,
        'context' => $context,
      ],
      'message' => $this->messageForDecision($decision),
    ];
  }

  public function shouldRecordAutomaticCase(array $result)
  {
    return $result['decision'] !== 'approved';
  }

  public function recordAutomaticCase($entityType, $entityId, $subjectUserId, array $result)
  {
    if (!$this->shouldRecordAutomaticCase($result)) {
      return null;
    }

    return $this->createCase([
      'entity_type' => $entityType,
      'entity_id' => $entityId,
      'subject_user_id' => $subjectUserId,
      'reporter_user_id' => null,
      'source' => 'automatic',
      'decision' => $result['decision'],
      'status' => $result['status'],
      'severity' => $result['severity'],
      'reason_codes' => $result['reasons'],
      'content_snapshot' => $result['snapshot'],
      'provider' => $result['provider'],
      'provider_response' => $result['provider_response'],
    ]);
  }

  public function createReport($reporterUserId, $entityType, $entityId, $reason, $details = '')
  {
    $entityType = $this->normalizeEntityType($entityType);
    if (!$entityType) {
      throw new InvalidArgumentException('Invalid report target');
    }

    $entityId = intval($entityId);
    if ($entityId <= 0) {
      throw new InvalidArgumentException('Invalid report target');
    }

    $entity = $this->getEntitySnapshot($entityType, $entityId);
    if (!$entity) {
      throw new RuntimeException('Reported content was not found');
    }

    $reason = $this->normalizeReportReason($reason);
    $details = trim((string)$details);

    $caseId = $this->findOpenCaseId($entityType, $entityId);
    if (!$caseId) {
      $caseId = $this->createCase([
        'entity_type' => $entityType,
        'entity_id' => $entityId,
        'subject_user_id' => $entity['subject_user_id'],
        'reporter_user_id' => $reporterUserId,
        'source' => 'report',
        'decision' => 'pending',
        'status' => 'pending',
        'severity' => 'low',
        'reason_codes' => [$reason],
        'content_snapshot' => [
          'entity_type' => $entityType,
          'fields' => $entity['fields'],
          'report_details' => $details,
        ],
        'provider' => null,
        'provider_response' => null,
      ]);
    }

    $insert = "INSERT IGNORE INTO moderation_reports
                 (case_id, entity_type, entity_id, reporter_user_id, reason, details)
               VALUES
                 (:case_id, :entity_type, :entity_id, :reporter_user_id, :reason, :details)";
    $stmt = $this->conn->prepare($insert);
    $stmt->bindValue(':case_id', $caseId, PDO::PARAM_INT);
    $stmt->bindValue(':entity_type', $entityType);
    $stmt->bindValue(':entity_id', $entityId, PDO::PARAM_INT);
    $stmt->bindValue(':reporter_user_id', $reporterUserId, PDO::PARAM_INT);
    $stmt->bindValue(':reason', $reason);
    $stmt->bindValue(':details', $details);
    $stmt->execute();

    $reportCount = $this->countReports($entityType, $entityId);
    if ($reportCount >= 3) {
      $this->applyModerationStatus($entityType, $entityId, 'hidden', 'Hidden after multiple user reports');
      $update = "UPDATE moderation_cases
                 SET status = 'hidden', severity = 'medium', updated_at = CURRENT_TIMESTAMP
                 WHERE id = :case_id";
      $caseStmt = $this->conn->prepare($update);
      $caseStmt->bindValue(':case_id', $caseId, PDO::PARAM_INT);
      $caseStmt->execute();
    }

    return [
      'case_id' => intval($caseId),
      'report_count' => $reportCount,
      'already_reported' => $stmt->rowCount() === 0,
    ];
  }

  public function getQueue($reviewerUserId, $status = 'pending', $limit = 50)
  {
    if (!$this->isGlobalModerator($reviewerUserId)) {
      throw new RuntimeException('Insufficient permissions');
    }

    $allowedStatuses = ['pending', 'hidden', 'blocked', 'approved', 'dismissed'];
    if (!in_array($status, $allowedStatuses, true)) {
      $status = 'pending';
    }
    $limit = max(1, min(100, intval($limit)));

    $query = "SELECT mc.*,
                     subject_profile.display_name AS subject_display_name,
                     reporter_profile.display_name AS reporter_display_name,
                     reviewer_profile.display_name AS reviewer_display_name,
                     COUNT(mr.id) AS report_count
              FROM moderation_cases mc
              LEFT JOIN user_profiles subject_profile ON subject_profile.user_id = mc.subject_user_id
              LEFT JOIN user_profiles reporter_profile ON reporter_profile.user_id = mc.reporter_user_id
              LEFT JOIN user_profiles reviewer_profile ON reviewer_profile.user_id = mc.reviewed_by
              LEFT JOIN moderation_reports mr ON mr.case_id = mc.id
              WHERE mc.status = :status
              GROUP BY mc.id
              ORDER BY mc.created_at DESC
              LIMIT :limit";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':status', $status);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->execute();

    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($items as &$item) {
      $item['id'] = intval($item['id']);
      $item['entity_id'] = intval($item['entity_id']);
      $item['subject_user_id'] = $item['subject_user_id'] !== null ? intval($item['subject_user_id']) : null;
      $item['reporter_user_id'] = $item['reporter_user_id'] !== null ? intval($item['reporter_user_id']) : null;
      $item['reviewed_by'] = $item['reviewed_by'] !== null ? intval($item['reviewed_by']) : null;
      $item['report_count'] = intval($item['report_count']);
      $item['reason_codes'] = $this->decodeJsonArray($item['reason_codes']);
      $item['content_snapshot'] = $this->decodeJsonArray($item['content_snapshot']);
    }
    unset($item);

    return $items;
  }

  public function reviewCase($reviewerUserId, $caseId, $action, $note = '')
  {
    $caseId = intval($caseId);
    if ($caseId <= 0) {
      throw new InvalidArgumentException('Case ID is required');
    }

    $case = $this->getCase($caseId);
    if (!$case) {
      throw new RuntimeException('Moderation case not found');
    }

    if (!$this->canReviewEntity($reviewerUserId, $case['entity_type'], intval($case['entity_id']))) {
      throw new RuntimeException('Insufficient permissions');
    }

    $action = trim((string)$action);
    $note = trim((string)$note);
    $caseStatus = null;
    $contentStatus = null;
    $reportStatus = 'reviewed';

    switch ($action) {
      case 'approve':
      case 'restore':
        $caseStatus = 'approved';
        $contentStatus = 'approved';
        break;
      case 'hide':
        $caseStatus = 'hidden';
        $contentStatus = 'hidden';
        break;
      case 'block':
        $caseStatus = 'blocked';
        $contentStatus = 'blocked';
        break;
      case 'dismiss':
        $caseStatus = 'dismissed';
        $reportStatus = 'dismissed';
        if ($case['source'] === 'automatic') {
          $contentStatus = 'approved';
        }
        break;
      default:
        throw new InvalidArgumentException('Invalid moderation action');
    }

    $this->conn->beginTransaction();
    try {
      if ($contentStatus !== null) {
        $this->applyModerationStatus(
          $case['entity_type'],
          intval($case['entity_id']),
          $contentStatus,
          $note !== '' ? $note : ucfirst($action) . ' by moderator'
        );
      }

      $update = "UPDATE moderation_cases
                 SET status = :status,
                     reviewed_by = :reviewed_by,
                     reviewer_note = :reviewer_note,
                     reviewed_at = CURRENT_TIMESTAMP,
                     updated_at = CURRENT_TIMESTAMP
                 WHERE id = :case_id";
      $stmt = $this->conn->prepare($update);
      $stmt->bindValue(':status', $caseStatus);
      $stmt->bindValue(':reviewed_by', $reviewerUserId, PDO::PARAM_INT);
      $stmt->bindValue(':reviewer_note', $note);
      $stmt->bindValue(':case_id', $caseId, PDO::PARAM_INT);
      $stmt->execute();

      $insertAction = "INSERT INTO moderation_actions
                         (case_id, moderator_user_id, action, note)
                       VALUES
                         (:case_id, :moderator_user_id, :action, :note)";
      $actionStmt = $this->conn->prepare($insertAction);
      $actionStmt->bindValue(':case_id', $caseId, PDO::PARAM_INT);
      $actionStmt->bindValue(':moderator_user_id', $reviewerUserId, PDO::PARAM_INT);
      $actionStmt->bindValue(':action', $action);
      $actionStmt->bindValue(':note', $note);
      $actionStmt->execute();

      $reportUpdate = "UPDATE moderation_reports
                       SET status = :status, updated_at = CURRENT_TIMESTAMP
                       WHERE case_id = :case_id";
      $reportStmt = $this->conn->prepare($reportUpdate);
      $reportStmt->bindValue(':status', $reportStatus);
      $reportStmt->bindValue(':case_id', $caseId, PDO::PARAM_INT);
      $reportStmt->execute();

      $this->conn->commit();
    } catch (Exception $e) {
      if ($this->conn->inTransaction()) {
        $this->conn->rollBack();
      }
      throw $e;
    }

    return $this->getCase($caseId);
  }

  public function applyModerationStatus($entityType, $entityId, $status, $reason = null)
  {
    $entityType = $this->normalizeEntityType($entityType);
    if (!$entityType) {
      throw new InvalidArgumentException('Invalid moderation target');
    }

    $allowed = ['approved', 'pending', 'hidden', 'blocked'];
    if (!in_array($status, $allowed, true)) {
      throw new InvalidArgumentException('Invalid moderation status');
    }

    $map = $this->entityMap[$entityType];
    $query = "UPDATE {$map['table']}
              SET moderation_status = :status,
                  moderation_reason = :reason,
                  moderated_at = CURRENT_TIMESTAMP
              WHERE {$map['id_column']} = :entity_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':status', $status);
    $stmt->bindValue(':reason', $reason);
    $stmt->bindValue(':entity_id', intval($entityId), PDO::PARAM_INT);
    $stmt->execute();
  }

  public function canReviewEntity($userId, $entityType, $entityId)
  {
    if ($this->isGlobalModerator($userId)) {
      return true;
    }

    $entityType = $this->normalizeEntityType($entityType);
    if (!$entityType) {
      return false;
    }
    $entityId = intval($entityId);

    if ($entityType === 'feed') {
      return $this->hasFeedModeratorRole($userId, $entityId);
    }
    if ($entityType === 'feed_post') {
      $stmt = $this->conn->prepare("SELECT feed_id FROM feed_posts WHERE id = :id LIMIT 1");
      $stmt->bindValue(':id', $entityId, PDO::PARAM_INT);
      $stmt->execute();
      $feedId = intval($stmt->fetchColumn());
      return $feedId > 0 && $this->hasFeedModeratorRole($userId, $feedId);
    }
    if ($entityType === 'comment') {
      $stmt = $this->conn->prepare(
        "SELECT fp.feed_id
         FROM comments c
         JOIN feed_posts fp ON fp.id = c.post_id
         WHERE c.id = :id
         LIMIT 1"
      );
      $stmt->bindValue(':id', $entityId, PDO::PARAM_INT);
      $stmt->execute();
      $feedId = intval($stmt->fetchColumn());
      return $feedId > 0 && $this->hasFeedModeratorRole($userId, $feedId);
    }
    if ($entityType === 'volunteer_opportunity') {
      return $this->hasVolunteerAdminRole($userId, $entityId);
    }
    if ($entityType === 'volunteer_reflection') {
      $stmt = $this->conn->prepare("SELECT opportunity_id FROM volunteer_reflections WHERE id = :id LIMIT 1");
      $stmt->bindValue(':id', $entityId, PDO::PARAM_INT);
      $stmt->execute();
      $opportunityId = intval($stmt->fetchColumn());
      return $opportunityId > 0 && $this->hasVolunteerAdminRole($userId, $opportunityId);
    }

    return false;
  }

  public function isGlobalModerator($userId)
  {
    $stmt = $this->conn->prepare(
      "SELECT r.name
       FROM users u
       JOIN roles r ON r.id = u.role_id
       WHERE u.id = :user_id
       LIMIT 1"
    );
    $stmt->bindValue(':user_id', intval($userId), PDO::PARAM_INT);
    $stmt->execute();
    $role = $stmt->fetchColumn();
    return in_array($role, ['admin', 'teacher'], true);
  }

  public function normalizeEntityType($entityType)
  {
    $entityType = trim((string)$entityType);
    return isset($this->entityMap[$entityType]) ? $entityType : null;
  }

  public function statusForDecision($decision)
  {
    if ($decision === 'blocked') {
      return 'blocked';
    }
    if ($decision === 'pending') {
      return 'pending';
    }
    return 'approved';
  }

  public function messageForDecision($decision)
  {
    if ($decision === 'blocked') {
      return 'This content appears to violate community rules.';
    }
    if ($decision === 'pending') {
      return 'This content was submitted and is waiting for review.';
    }
    return 'Content approved.';
  }

  private function createCase(array $data)
  {
    $query = "INSERT INTO moderation_cases
                (entity_type, entity_id, subject_user_id, reporter_user_id, source, decision, status, severity,
                 reason_codes, content_snapshot, provider, provider_response)
              VALUES
                (:entity_type, :entity_id, :subject_user_id, :reporter_user_id, :source, :decision, :status, :severity,
                 :reason_codes, :content_snapshot, :provider, :provider_response)";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':entity_type', $data['entity_type']);
    $stmt->bindValue(':entity_id', intval($data['entity_id']), PDO::PARAM_INT);
    $this->bindNullableInt($stmt, ':subject_user_id', $data['subject_user_id']);
    $this->bindNullableInt($stmt, ':reporter_user_id', $data['reporter_user_id']);
    $stmt->bindValue(':source', $data['source']);
    $stmt->bindValue(':decision', $data['decision']);
    $stmt->bindValue(':status', $data['status']);
    $stmt->bindValue(':severity', $data['severity']);
    $stmt->bindValue(':reason_codes', json_encode($data['reason_codes'], JSON_UNESCAPED_UNICODE));
    $stmt->bindValue(':content_snapshot', json_encode($data['content_snapshot'], JSON_UNESCAPED_UNICODE));
    $stmt->bindValue(':provider', $data['provider']);
    $stmt->bindValue(
      ':provider_response',
      $data['provider_response'] !== null ? json_encode($data['provider_response'], JSON_UNESCAPED_UNICODE) : null
    );
    $stmt->execute();
    return intval($this->conn->lastInsertId());
  }

  private function getCase($caseId)
  {
    $stmt = $this->conn->prepare("SELECT * FROM moderation_cases WHERE id = :id LIMIT 1");
    $stmt->bindValue(':id', intval($caseId), PDO::PARAM_INT);
    $stmt->execute();
    $case = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$case) {
      return null;
    }
    $case['id'] = intval($case['id']);
    $case['entity_id'] = intval($case['entity_id']);
    $case['reason_codes'] = $this->decodeJsonArray($case['reason_codes']);
    $case['content_snapshot'] = $this->decodeJsonArray($case['content_snapshot']);
    return $case;
  }

  private function findOpenCaseId($entityType, $entityId)
  {
    $stmt = $this->conn->prepare(
      "SELECT id
       FROM moderation_cases
       WHERE entity_type = :entity_type
         AND entity_id = :entity_id
         AND status IN ('pending', 'hidden')
       ORDER BY id DESC
       LIMIT 1"
    );
    $stmt->bindValue(':entity_type', $entityType);
    $stmt->bindValue(':entity_id', intval($entityId), PDO::PARAM_INT);
    $stmt->execute();
    $id = $stmt->fetchColumn();
    return $id ? intval($id) : null;
  }

  private function countReports($entityType, $entityId)
  {
    $stmt = $this->conn->prepare(
      "SELECT COUNT(*)
       FROM moderation_reports
       WHERE entity_type = :entity_type
         AND entity_id = :entity_id"
    );
    $stmt->bindValue(':entity_type', $entityType);
    $stmt->bindValue(':entity_id', intval($entityId), PDO::PARAM_INT);
    $stmt->execute();
    return intval($stmt->fetchColumn());
  }

  private function getEntitySnapshot($entityType, $entityId)
  {
    $map = $this->entityMap[$entityType];
    $columns = array_merge([$map['subject_column']], $map['text_columns']);
    $select = implode(', ', array_map(function ($column) {
      return $column;
    }, $columns));

    $query = "SELECT {$select}
              FROM {$map['table']}
              WHERE {$map['id_column']} = :entity_id
              LIMIT 1";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':entity_id', intval($entityId), PDO::PARAM_INT);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
      return null;
    }

    $fields = [];
    foreach ($map['text_columns'] as $column) {
      $fields[$column] = $row[$column] ?? null;
    }

    return [
      'subject_user_id' => intval($row[$map['subject_column']]),
      'fields' => $fields,
    ];
  }

  private function runLocalRules($text)
  {
    $decision = 'approved';
    $severity = 'low';
    $reasons = [];

    $blockedPatterns = [
      ['code' => 'targeted_self_harm', 'severity' => 'high', 'pattern' => '/\b(?:kill\s+yourself|kys)\b/i'],
      [
        'code' => 'violent_threat',
        'severity' => 'high',
        'pattern' => '/\b(?:(?:i(?:\s+am|\'m)?\s+)?(?:will|am\s+going\s+to|going\s+to|gonna|want\s+to|plan\s+to)\s+(?:\w+\s+){0,4}?(?:kill|hurt|shoot|stab|beat)\s+(?:you|u|him|her|them)|(?:kill|hurt|shoot|stab|beat)\s+(?:you|u|him|her|them)|shoot\s+up|bomb\s+threat)\b/i'
      ],
      ['code' => 'sexual_exploitation', 'severity' => 'high', 'pattern' => '/\b(?:send|share|post)\s+(?:nudes?|naked|explicit)\b/i'],
    ];

    foreach ($blockedPatterns as $rule) {
      if (preg_match($rule['pattern'], $text)) {
        $decision = 'blocked';
        $severity = $this->strongerSeverity($severity, $rule['severity']);
        $reasons[] = $rule['code'];
      }
    }

    $pendingPatterns = [
      ['code' => 'url_spam', 'severity' => 'medium', 'pattern' => '/(?:https?:\/\/|www\.)/i', 'min' => 4],
      ['code' => 'financial_scam', 'severity' => 'medium', 'pattern' => '/\b(?:free\s+money|guaranteed\s+returns?|crypto\s+investment|double\s+your\s+money)\b/i'],
      ['code' => 'private_identifier', 'severity' => 'medium', 'pattern' => '/\b(?:\d{3}-\d{2}-\d{4}|\d{4}\s?\d{4}\s?\d{4}\s?\d{4})\b/'],
      ['code' => 'adult_content', 'severity' => 'medium', 'pattern' => '/\b(?:porn|sex\s+chat|onlyfans)\b/i'],
    ];

    foreach ($pendingPatterns as $rule) {
      if (isset($rule['min'])) {
        preg_match_all($rule['pattern'], $text, $matches);
        $matched = count($matches[0]) >= $rule['min'];
      } else {
        $matched = preg_match($rule['pattern'], $text) === 1;
      }
      if ($matched) {
        $decision = $this->strongerDecision($decision, 'pending');
        $severity = $this->strongerSeverity($severity, $rule['severity']);
        $reasons[] = $rule['code'];
      }
    }

    return [
      'decision' => $decision,
      'severity' => $severity,
      'reasons' => array_values(array_unique($reasons)),
    ];
  }

  private function runOpenAIModeration($text)
  {
    $apiKey = $this->getOpenAIApiKey();
    if (!$apiKey || !function_exists('curl_init')) {
      return null;
    }

    $payload = json_encode([
      'model' => 'omni-moderation-latest',
      'input' => $text,
    ], JSON_UNESCAPED_UNICODE);

    $ch = curl_init('https://api.openai.com/v1/moderations');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
      'Authorization: Bearer ' . $apiKey,
      'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 8);

    $raw = curl_exec($ch);
    $status = intval(curl_getinfo($ch, CURLINFO_HTTP_CODE));
    $error = curl_error($ch);
    curl_close($ch);

    if ($raw === false || $status < 200 || $status >= 300) {
      error_log('OpenAI moderation failed: HTTP ' . $status . ' ' . $error);
      return null;
    }

    $decoded = json_decode($raw, true);
    if (!is_array($decoded) || empty($decoded['results'][0])) {
      return null;
    }

    $result = $decoded['results'][0];
    $flagged = !empty($result['flagged']);
    if (!$flagged) {
      return [
        'provider' => 'openai',
        'decision' => 'approved',
        'severity' => 'low',
        'reasons' => [],
        'response' => $decoded,
      ];
    }

    $categories = isset($result['categories']) && is_array($result['categories'])
      ? $result['categories']
      : [];
    $active = [];
    foreach ($categories as $category => $isFlagged) {
      if ($isFlagged) {
        $active[] = 'openai_' . str_replace(['/', '-'], '_', $category);
      }
    }

    $severeCategories = ['sexual/minors', 'violence/graphic', 'self-harm/intent', 'self-harm/instructions', 'harassment/threatening'];
    $hasSevere = false;
    foreach ($severeCategories as $category) {
      if (!empty($categories[$category])) {
        $hasSevere = true;
        break;
      }
    }

    return [
      'provider' => 'openai',
      'decision' => $hasSevere ? 'blocked' : 'pending',
      'severity' => $hasSevere ? 'high' : 'medium',
      'reasons' => !empty($active) ? $active : ['openai_flagged'],
      'response' => $decoded,
    ];
  }

  private function getOpenAIApiKey()
  {
    $envKey = getenv('OPENAI_API_KEY') ?: getenv('MODERATION_OPENAI_API_KEY');
    if ($envKey) {
      return $envKey;
    }

    $localConfig = __DIR__ . '/moderation.local.php';
    if (file_exists($localConfig)) {
      $config = include $localConfig;
      if (is_array($config) && !empty($config['openai_api_key'])) {
        return $config['openai_api_key'];
      }
    }

    return null;
  }

  private function hasFeedModeratorRole($userId, $feedId)
  {
    $stmt = $this->conn->prepare(
      "SELECT role
       FROM feed_members
       WHERE feed_id = :feed_id AND user_id = :user_id
       LIMIT 1"
    );
    $stmt->bindValue(':feed_id', intval($feedId), PDO::PARAM_INT);
    $stmt->bindValue(':user_id', intval($userId), PDO::PARAM_INT);
    $stmt->execute();
    $role = $stmt->fetchColumn();
    return in_array($role, ['admin', 'moderator'], true);
  }

  private function hasVolunteerAdminRole($userId, $opportunityId)
  {
    $stmt = $this->conn->prepare(
      "SELECT CASE WHEN vo.organizer_id = :user_id THEN 'admin' ELSE vp.role END AS role
       FROM volunteer_opportunities vo
       LEFT JOIN volunteer_participants vp ON vp.opportunity_id = vo.id AND vp.user_id = :user_id
       WHERE vo.id = :opportunity_id
       LIMIT 1"
    );
    $stmt->bindValue(':user_id', intval($userId), PDO::PARAM_INT);
    $stmt->bindValue(':opportunity_id', intval($opportunityId), PDO::PARAM_INT);
    $stmt->execute();
    $role = $stmt->fetchColumn();
    return in_array($role, ['admin', 'coordinator'], true);
  }

  private function buildModerationText(array $fields)
  {
    $parts = [];
    foreach ($fields as $key => $value) {
      $value = trim((string)$value);
      if ($value !== '') {
        $parts[] = $key . ': ' . $value;
      }
    }
    $text = implode("\n", $parts);
    if (function_exists('mb_substr')) {
      return mb_substr($text, 0, 12000, 'UTF-8');
    }
    return substr($text, 0, 12000);
  }

  private function normalizeReportReason($reason)
  {
    $reason = trim((string)$reason);
    $allowed = ['spam', 'harassment', 'hate', 'sexual', 'violence', 'self_harm', 'privacy', 'other'];
    return in_array($reason, $allowed, true) ? $reason : 'other';
  }

  private function strongerDecision($current, $candidate)
  {
    $rank = ['approved' => 0, 'pending' => 1, 'blocked' => 2];
    return $rank[$candidate] > $rank[$current] ? $candidate : $current;
  }

  private function strongerSeverity($current, $candidate)
  {
    $rank = ['low' => 0, 'medium' => 1, 'high' => 2];
    return $rank[$candidate] > $rank[$current] ? $candidate : $current;
  }

  private function bindNullableInt($stmt, $name, $value)
  {
    if ($value === null || $value === '') {
      $stmt->bindValue($name, null, PDO::PARAM_NULL);
    } else {
      $stmt->bindValue($name, intval($value), PDO::PARAM_INT);
    }
  }

  private function decodeJsonArray($value)
  {
    if ($value === null || $value === '') {
      return [];
    }
    $decoded = json_decode($value, true);
    return is_array($decoded) ? $decoded : [];
  }
}
