<?php
// CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Credentials: true");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit();
}

require_once 'config/Database.php';
require_once 'config/Auth.php';
require_once 'config/Response.php';
require_once 'config/PushNotificationService.php';

class StudyController
{
  private $db;
  private $auth;
  private $conn;
  private $push;
  private $hasQuestionMediaTable = null;
  private const BEST_ANSWER_POINTS = 50;
  private const BEST_ANSWER_EVENT_TYPE = 'BEST_ANSWER';
  private const MAX_TAG_COUNT = 5;
  private const MAX_TAG_LENGTH = 30;
  private const MAX_TAGS_STORAGE_LENGTH = 300;

  public function __construct()
  {
    $this->db = new Database();
    $this->conn = $this->db->getConnection();
    $this->auth = new Auth($this->conn);
    $this->push = new PushNotificationService($this->conn);
  }

  public function handleRequest()
  {
    $method = $_SERVER['REQUEST_METHOD'];
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    try {
      $userId = $this->getAuthorizedUserId();

      switch ($method) {
        case 'GET':
          if ($action === 'list') {
            $this->getQuestions();
          } else if ($action === 'detail') {
            $this->getQuestionDetail($userId);
          } else if ($action === 'answers') {
            $this->getAnswers();
          } else if ($action === 'ranking') {
            $this->getRanking($userId);
          } else {
            Response::error('Invalid action', 400);
          }
          break;
        case 'POST':
          if ($userId === null) {
            Response::error('Authorization header is required', 401);
            return;
          }

          if ($action === 'create') {
            $this->createQuestion($userId);
          } else if ($action === 'media') {
            $this->uploadQuestionMedia($userId);
          } else if ($action === 'answer') {
            $this->createAnswer($userId);
          } else if ($action === 'best') {
            $this->markBestAnswer($userId);
          } else {
            Response::error('Invalid action', 400);
          }
          break;
        default:
          Response::error('Method not allowed', 405);
      }
    } catch (Exception $e) {
      Response::error($e->getMessage(), 500);
    }
  }

  private function getQuestions()
  {
    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $limit = 20;
    $offset = ($page - 1) * $limit;
    $q = isset($_GET['q']) ? trim($_GET['q']) : '';
    $tag = isset($_GET['tag']) ? trim($_GET['tag']) : '';
    $category = isset($_GET['category']) ? trim($_GET['category']) : '';
    if ($tag === '' && $category !== '') {
      // Backward compatibility.
      $tag = $category;
    }
    $status = isset($_GET['status']) ? trim($_GET['status']) : '';
    $sort = isset($_GET['sort']) ? trim($_GET['sort']) : 'latest';
    $unresolvedOnlyRaw = isset($_GET['unresolved_only']) ? strtolower(trim((string)$_GET['unresolved_only'])) : '';
    $unresolvedOnly = in_array($unresolvedOnlyRaw, ['1', 'true', 'yes'], true);

    if ($unresolvedOnly) {
      $status = 'open';
    }

    $allowedStatus = ['open', 'resolved'];
    if ($status !== '' && !in_array($status, $allowedStatus, true)) {
      $status = '';
    }

    $allowedSort = ['latest', 'newest', 'answers', 'unresolved'];
    if (!in_array($sort, $allowedSort, true)) {
      $sort = 'latest';
    }

    $where = [];
    $params = [];
    if ($q !== '') {
      // Search over title/body/tags.
      $where[] = "(sq.title LIKE :q OR sq.body LIKE :q OR sq.category LIKE :q)";
      $params[':q'] = '%' . $q . '%';
    }
    if ($tag !== '') {
      $where[] = "FIND_IN_SET(:tag, sq.category) > 0";
      $params[':tag'] = $tag;
    }
    if ($status !== '') {
      $where[] = "sq.status = :status";
      $params[':status'] = $status;
    }

    $orderBy = "sq.created_at DESC";
    if ($sort === 'answers') {
      $orderBy = "COALESCE(ac.answer_count, 0) DESC, sq.created_at DESC";
    } else if ($sort === 'unresolved') {
      $orderBy = "(CASE WHEN sq.status = 'open' THEN 0 ELSE 1 END) ASC, sq.created_at DESC";
    }

    $query = "SELECT sq.id,
                     sq.author_user_id,
                     sq.title,
                     sq.body,
                     sq.media_url,
                     sq.category,
                     sq.status,
                     sq.created_at,
                     sq.updated_at,
                     up.display_name,
                     up.avatar_url,
                     COALESCE(ac.answer_count, 0) AS answer_count,
                     (SELECT sa2.id FROM study_answers sa2 WHERE sa2.question_id = sq.id AND sa2.is_best = 1 LIMIT 1) AS best_answer_id
              FROM study_questions sq
              JOIN user_profiles up ON up.user_id = sq.author_user_id
              LEFT JOIN (
                SELECT question_id, COUNT(*) AS answer_count
                FROM study_answers
                GROUP BY question_id
              ) ac ON ac.question_id = sq.id";

    if (!empty($where)) {
      $query .= " WHERE " . implode(" AND ", $where);
    }

    $query .= " ORDER BY " . $orderBy . " LIMIT :limit OFFSET :offset";

    $stmt = $this->conn->prepare($query);
    foreach ($params as $key => $value) {
      $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $mediaMap = $this->getQuestionMediaMap($questions);
    foreach ($questions as &$question) {
      $question['tags'] = $this->parseStoredTags($question['category'] ?? '');
      $questionMedia = $mediaMap[intval($question['id'])] ?? [];
      if (!empty($questionMedia)) {
        $question['media_urls'] = $questionMedia;
        $question['media_url'] = $questionMedia[0];
      } else {
        $fallback = trim((string)($question['media_url'] ?? ''));
        $question['media_urls'] = $fallback !== '' ? [$fallback] : [];
      }
    }
    unset($question);
    Response::success($questions, 'Questions retrieved successfully');
  }

  private function getQuestionDetail($currentUserId)
  {
    if (!isset($_GET['question_id'])) {
      Response::error('Question ID is required', 400);
      return;
    }

    $questionId = intval($_GET['question_id']);
    if ($questionId <= 0) {
      Response::error('Question ID is required', 400);
      return;
    }

    $query = "SELECT sq.id,
                     sq.author_user_id,
                     sq.title,
                     sq.body,
                     sq.media_url,
                     sq.category,
                     sq.status,
                     sq.created_at,
                     sq.updated_at,
                     up.display_name,
                     up.avatar_url,
                     (SELECT COUNT(*) FROM study_answers sa WHERE sa.question_id = sq.id) AS answer_count,
                     (SELECT sa2.id FROM study_answers sa2 WHERE sa2.question_id = sq.id AND sa2.is_best = 1 LIMIT 1) AS best_answer_id
              FROM study_questions sq
              JOIN user_profiles up ON up.user_id = sq.author_user_id
              WHERE sq.id = :question_id
              LIMIT 1";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    $question = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$question) {
      Response::error('Question not found', 404);
      return;
    }

    $question['can_mark_best'] = $currentUserId !== null && intval($question['author_user_id']) === intval($currentUserId);
    $question['tags'] = $this->parseStoredTags($question['category'] ?? '');
    $questionMedia = $this->getQuestionMediaList(intval($question['id']));
    if (!empty($questionMedia)) {
      $question['media_urls'] = $questionMedia;
      $question['media_url'] = $questionMedia[0];
    } else {
      $fallback = trim((string)($question['media_url'] ?? ''));
      $question['media_urls'] = $fallback !== '' ? [$fallback] : [];
    }

    Response::success($question, 'Question retrieved successfully');
  }

  private function getAnswers()
  {
    if (!isset($_GET['question_id'])) {
      Response::error('Question ID is required', 400);
      return;
    }

    $questionId = intval($_GET['question_id']);
    if ($questionId <= 0) {
      Response::error('Question ID is required', 400);
      return;
    }

    $query = "SELECT sa.id,
                     sa.question_id,
                     sa.author_user_id,
                     sa.body,
                     sa.is_best,
                     sa.created_at,
                     sa.updated_at,
                     up.display_name,
                     up.avatar_url,
                     COALESCE((SELECT SUM(pl.points) FROM point_ledger pl WHERE pl.user_id = sa.author_user_id), 0) AS total_points
              FROM study_answers sa
              JOIN user_profiles up ON up.user_id = sa.author_user_id
              WHERE sa.question_id = :question_id
              ORDER BY sa.is_best DESC, sa.created_at ASC";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    $answers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    Response::success($answers, 'Answers retrieved successfully');
  }

  private function getRanking($currentUserId)
  {
    $period = isset($_GET['period']) ? trim($_GET['period']) : 'all';
    if ($period !== 'all') {
      Response::error('Invalid period', 400);
      return;
    }

    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;
    $limit = max(1, min(100, $limit));
    $offset = ($page - 1) * $limit;

    $totalUsersQuery = "SELECT COUNT(*) AS total_users
                        FROM (
                          SELECT pl.user_id
                          FROM point_ledger pl
                          GROUP BY pl.user_id
                        ) t";
    $totalUsersStmt = $this->conn->prepare($totalUsersQuery);
    $totalUsersStmt->execute();
    $totalUsers = intval($totalUsersStmt->fetch(PDO::FETCH_ASSOC)['total_users'] ?? 0);

    $rankingQuery = "SELECT ranked.rank,
                            ranked.user_id,
                            ranked.total_points,
                            up.display_name,
                            up.avatar_url
                     FROM (
                       SELECT ordered.user_id,
                              ordered.total_points,
                              (@row_num := @row_num + 1) AS rank
                       FROM (
                         SELECT pl.user_id, SUM(pl.points) AS total_points
                         FROM point_ledger pl
                         GROUP BY pl.user_id
                         ORDER BY total_points DESC, pl.user_id ASC
                       ) ordered
                       CROSS JOIN (SELECT @row_num := 0) vars
                     ) ranked
                     LEFT JOIN user_profiles up ON up.user_id = ranked.user_id
                     LIMIT :limit OFFSET :offset";
    $rankingStmt = $this->conn->prepare($rankingQuery);
    $rankingStmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $rankingStmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $rankingStmt->execute();
    $rows = $rankingStmt->fetchAll(PDO::FETCH_ASSOC);

    $items = array_map(function ($row) {
      return [
        'rank' => intval($row['rank']),
        'user_id' => intval($row['user_id']),
        'display_name' => $row['display_name'] ?? '',
        'avatar_url' => $row['avatar_url'],
        'points' => intval($row['total_points']),
        'badge' => null
      ];
    }, $rows);

    $myRank = null;
    if ($currentUserId !== null) {
      $myRankQuery = "SELECT ranked.rank,
                             ranked.user_id,
                             ranked.total_points,
                             up.display_name,
                             up.avatar_url
                      FROM (
                        SELECT ordered.user_id,
                               ordered.total_points,
                               (@row_num_my := @row_num_my + 1) AS rank
                        FROM (
                          SELECT pl.user_id, SUM(pl.points) AS total_points
                          FROM point_ledger pl
                          GROUP BY pl.user_id
                          ORDER BY total_points DESC, pl.user_id ASC
                        ) ordered
                        CROSS JOIN (SELECT @row_num_my := 0) vars
                      ) ranked
                      LEFT JOIN user_profiles up ON up.user_id = ranked.user_id
                      WHERE ranked.user_id = :user_id
                      LIMIT 1";
      $myRankStmt = $this->conn->prepare($myRankQuery);
      $myRankStmt->bindValue(':user_id', $currentUserId, PDO::PARAM_INT);
      $myRankStmt->execute();
      $myRankRow = $myRankStmt->fetch(PDO::FETCH_ASSOC);
      if ($myRankRow) {
        $myRank = [
          'rank' => intval($myRankRow['rank']),
          'user_id' => intval($myRankRow['user_id']),
          'display_name' => $myRankRow['display_name'] ?? '',
          'avatar_url' => $myRankRow['avatar_url'],
          'points' => intval($myRankRow['total_points']),
          'badge' => null
        ];
      } else {
        $profileQuery = "SELECT up.display_name, up.avatar_url
                         FROM user_profiles up
                         WHERE up.user_id = :user_id
                         LIMIT 1";
        $profileStmt = $this->conn->prepare($profileQuery);
        $profileStmt->bindValue(':user_id', $currentUserId, PDO::PARAM_INT);
        $profileStmt->execute();
        $profile = $profileStmt->fetch(PDO::FETCH_ASSOC);
        $displayName = '';
        $avatarUrl = null;
        if (is_array($profile)) {
          $displayName = $profile['display_name'] ?? '';
          $avatarUrl = $profile['avatar_url'] ?? null;
        }
        $myRank = [
          'rank' => null,
          'user_id' => intval($currentUserId),
          'display_name' => $displayName,
          'avatar_url' => $avatarUrl,
          'points' => 0,
          'badge' => null
        ];
      }
    }

    $response = [
      'items' => $items,
      'page' => $page,
      'limit' => $limit,
      'total_users' => $totalUsers,
      'has_more' => ($offset + count($items)) < $totalUsers,
      'my_rank' => $myRank
    ];

    Response::success($response, 'Study ranking retrieved successfully');
  }

  private function createQuestion($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $title = trim($data['title'] ?? '');
    $body = trim($data['body'] ?? '');
    $mediaUrl = trim((string)($data['media_url'] ?? ''));
    $mediaUrls = $this->normalizeMediaUrlsInput($data['media_urls'] ?? [], $mediaUrl);
    $tagsInput = $data['tags'] ?? ($data['category'] ?? '');
    $tags = $this->normalizeTagsInput($tagsInput);

    if ($title === '') {
      Response::error('Title is required', 400);
      return;
    }
    if ($body === '') {
      Response::error('Body is required', 400);
      return;
    }
    if ($this->stringLength($title) > 300) {
      Response::error('Title must be less than 300 characters', 400);
      return;
    }
    if ($this->stringLength($body) > 5000) {
      Response::error('Body must be less than 5000 characters', 400);
      return;
    }
    if (count($tags) === 0) {
      Response::error('At least one tag is required', 400);
      return;
    }
    if (count($tags) > self::MAX_TAG_COUNT) {
      Response::error('Too many tags', 400);
      return;
    }
    foreach ($tags as $tag) {
      if ($this->stringLength($tag) > self::MAX_TAG_LENGTH) {
        Response::error('Tag must be less than 30 characters', 400);
        return;
      }
    }

    $tagsValue = implode(',', $tags);
    if ($this->stringLength($tagsValue) > self::MAX_TAGS_STORAGE_LENGTH) {
      Response::error('Tags must be less than 300 characters', 400);
      return;
    }
    foreach ($mediaUrls as $url) {
      if ($this->stringLength($url) > 255) {
        Response::error('Media URL must be less than 255 characters', 400);
        return;
      }
    }

    $query = "INSERT INTO study_questions (author_user_id, title, body, media_url, category, status)
              VALUES (:author_user_id, :title, :body, :media_url, :category, 'open')";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':author_user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':title', $title);
    $stmt->bindValue(':body', $body);
    $stmt->bindValue(':media_url', !empty($mediaUrls) ? $mediaUrls[0] : null);
    $stmt->bindValue(':category', $tagsValue);
    $stmt->execute();
    $questionId = intval($this->conn->lastInsertId());
    $this->insertQuestionMedia($questionId, $mediaUrls);
    $this->notifyStudyQuestionCreated($userId, $questionId, $title);

    Response::success(['id' => $questionId], 'Question created successfully');
  }

  private function createAnswer($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $questionId = intval($data['question_id'] ?? 0);
    $body = trim($data['body'] ?? '');

    if ($questionId <= 0) {
      Response::error('Question ID is required', 400);
      return;
    }
    if ($body === '') {
      Response::error('Body is required', 400);
      return;
    }
    if ($this->stringLength($body) > 5000) {
      Response::error('Body must be less than 5000 characters', 400);
      return;
    }

    $checkQuery = "SELECT id, author_user_id, title FROM study_questions WHERE id = :question_id LIMIT 1";
    $checkStmt = $this->conn->prepare($checkQuery);
    $checkStmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
    $checkStmt->execute();
    $question = $checkStmt->fetch(PDO::FETCH_ASSOC);
    if (!$question) {
      Response::error('Question not found', 404);
      return;
    }

    $query = "INSERT INTO study_answers (question_id, author_user_id, body, is_best)
              VALUES (:question_id, :author_user_id, :body, 0)";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->bindValue(':author_user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':body', $body);
    $stmt->execute();
    $answerId = intval($this->conn->lastInsertId());
    $this->notifyStudyAnswerCreated($userId, $question, $answerId);

    Response::success(['id' => $answerId], 'Answer created successfully');
  }

  private function uploadQuestionMedia($userId)
  {
    if (!isset($_FILES['media'])) {
      Response::error('No media file provided', 400);
      return;
    }

    $file = $_FILES['media'];
    if ($file['error'] !== UPLOAD_ERR_OK) {
      Response::error('File upload failed', 400);
      return;
    }

    $allowedTypes = ['image/jpeg', 'image/png'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);

    if (!in_array($mimeType, $allowedTypes, true)) {
      Response::error('Invalid file type. Only JPEG and PNG are allowed.', 400);
      return;
    }

    $uploadDir = __DIR__ . '/../uploads/study_media/';
    if (!file_exists($uploadDir)) {
      mkdir($uploadDir, 0755, true);
    }

    $extension = $mimeType === 'image/jpeg' ? 'jpg' : 'png';
    $filename = uniqid('study_media_' . intval($userId) . '_') . '.' . $extension;
    $filepath = $uploadDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
      Response::error('Failed to save file', 500);
      return;
    }

    $mediaUrl = '/uploads/study_media/' . $filename;
    Response::json([
      'status' => 'success',
      'media_url' => $mediaUrl,
    ]);
  }

  private function markBestAnswer($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $answerId = intval($data['answer_id'] ?? 0);
    if ($answerId <= 0) {
      Response::error('Answer ID is required', 400);
      return;
    }

    $this->conn->beginTransaction();
    try {
      $targetQuery = "SELECT sa.id AS answer_id,
                             sa.question_id,
                             sa.author_user_id AS answer_author_user_id,
                             sq.author_user_id AS question_author_user_id,
                             sq.title AS question_title
                      FROM study_answers sa
                      JOIN study_questions sq ON sq.id = sa.question_id
                      WHERE sa.id = :answer_id
                      LIMIT 1
                      FOR UPDATE";
      $targetStmt = $this->conn->prepare($targetQuery);
      $targetStmt->bindValue(':answer_id', $answerId, PDO::PARAM_INT);
      $targetStmt->execute();
      $target = $targetStmt->fetch(PDO::FETCH_ASSOC);

      if (!$target) {
        $this->conn->rollBack();
        Response::error('Answer not found', 404);
        return;
      }

      if (intval($target['question_author_user_id']) !== intval($userId)) {
        $this->conn->rollBack();
        Response::error('Insufficient permissions', 403);
        return;
      }

      $questionId = intval($target['question_id']);
      $answerAuthorUserId = intval($target['answer_author_user_id']);

      $bestQuery = "SELECT id
                    FROM study_answers
                    WHERE question_id = :question_id
                      AND is_best = 1
                    LIMIT 1
                    FOR UPDATE";
      $bestStmt = $this->conn->prepare($bestQuery);
      $bestStmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
      $bestStmt->execute();
      $existingBest = $bestStmt->fetch(PDO::FETCH_ASSOC);
      if ($existingBest) {
        $this->conn->rollBack();
        Response::error('Best answer already selected', 400);
        return;
      }

      $updateBest = "UPDATE study_answers SET is_best = 1 WHERE id = :answer_id";
      $updateBestStmt = $this->conn->prepare($updateBest);
      $updateBestStmt->bindValue(':answer_id', $answerId, PDO::PARAM_INT);
      $updateBestStmt->execute();

      $resolveQuestion = "UPDATE study_questions SET status = 'resolved' WHERE id = :question_id";
      $resolveStmt = $this->conn->prepare($resolveQuestion);
      $resolveStmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
      $resolveStmt->execute();

      $ledgerQuery = "INSERT INTO point_ledger (user_id, event_type, ref_id, points)
                      VALUES (:user_id, :event_type, :ref_id, :points)
                      ON DUPLICATE KEY UPDATE id = id";
      $ledgerStmt = $this->conn->prepare($ledgerQuery);
      $ledgerStmt->bindValue(':user_id', $answerAuthorUserId, PDO::PARAM_INT);
      $ledgerStmt->bindValue(':event_type', self::BEST_ANSWER_EVENT_TYPE);
      $ledgerStmt->bindValue(':ref_id', $answerId, PDO::PARAM_INT);
      $ledgerStmt->bindValue(':points', self::BEST_ANSWER_POINTS, PDO::PARAM_INT);
      $ledgerStmt->execute();

      $this->conn->commit();
      $this->notifyBestAnswerSelected(
        $userId,
        $answerAuthorUserId,
        $questionId,
        $answerId,
        $target['question_title'] ?? 'your question'
      );
      Response::success(null, 'Best answer selected successfully');
    } catch (Exception $e) {
      if ($this->conn->inTransaction()) {
        $this->conn->rollBack();
      }
      throw $e;
    }
  }

  private function getAuthorizedUserId()
  {
    $headers = getallheaders();
    $authorization = null;
    foreach ($headers as $key => $value) {
      if (strtolower($key) === 'authorization') {
        $authorization = $value;
        break;
      }
    }

    if (!$authorization) {
      return null;
    }

    $token = str_replace('Bearer ', '', $authorization);
    $decoded = $this->validateJWT($token);
    if (!$decoded) {
      Response::error('Invalid or expired token', 401);
      return null;
    }
    return intval($decoded['user_id']);
  }

  private function notifyStudyQuestionCreated($actorUserId, $questionId, $questionTitle)
  {
    try {
      $recipients = $this->push->getActiveUserIdsExcept($actorUserId);
      $actorName = $this->push->getDisplayName($actorUserId);
      $this->push->sendToUsers($recipients, 'study_question', "$actorName asked a question", $questionTitle, [
        'type' => 'study_question',
        'entity_type' => 'study_question',
        'entity_id' => $questionId,
        'question_id' => $questionId,
        'route' => 'study_question_details'
      ], $actorUserId);
    } catch (Exception $e) {
      error_log('Failed to enqueue study question push notification: ' . $e->getMessage());
    }
  }

  private function notifyStudyAnswerCreated($actorUserId, array $question, $answerId)
  {
    try {
      $questionAuthorId = intval($question['author_user_id']);
      if ($questionAuthorId === intval($actorUserId)) return;

      $actorName = $this->push->getDisplayName($actorUserId);
      $this->push->sendToUsers([$questionAuthorId], 'study_answer', "$actorName answered your question", $question['title'] ?? 'Study question', [
        'type' => 'study_answer',
        'entity_type' => 'study_question',
        'entity_id' => intval($question['id']),
        'question_id' => intval($question['id']),
        'answer_id' => $answerId,
        'route' => 'study_question_details'
      ], $actorUserId);
    } catch (Exception $e) {
      error_log('Failed to enqueue study answer push notification: ' . $e->getMessage());
    }
  }

  private function notifyBestAnswerSelected($actorUserId, $answerAuthorUserId, $questionId, $answerId, $questionTitle)
  {
    try {
      if (intval($answerAuthorUserId) === intval($actorUserId)) return;

      $this->push->sendToUsers([intval($answerAuthorUserId)], 'study_best_answer', 'Your answer was selected', $questionTitle, [
        'type' => 'study_best_answer',
        'entity_type' => 'study_question',
        'entity_id' => $questionId,
        'question_id' => $questionId,
        'answer_id' => $answerId,
        'route' => 'study_question_details'
      ], $actorUserId);
    } catch (Exception $e) {
      error_log('Failed to enqueue best-answer push notification: ' . $e->getMessage());
    }
  }

  private function stringLength($value)
  {
    if (function_exists('mb_strlen')) {
      return mb_strlen($value, 'UTF-8');
    }
    return strlen($value);
  }

  private function parseStoredTags($stored)
  {
    $source = trim((string)$stored);
    if ($source === '') {
      return [];
    }
    $source = str_replace('、', ',', $source);

    $tags = array_map('trim', explode(',', $source));
    $tags = array_values(array_filter($tags, function ($tag) {
      return $tag !== '';
    }));

    $unique = [];
    $seen = [];
    foreach ($tags as $tag) {
      $key = function_exists('mb_strtolower') ? mb_strtolower($tag, 'UTF-8') : strtolower($tag);
      if (isset($seen[$key])) {
        continue;
      }
      $seen[$key] = true;
      $unique[] = $tag;
    }
    return $unique;
  }

  private function normalizeTagsInput($raw)
  {
    $items = [];
    if (is_array($raw)) {
      $items = $raw;
    } else {
      $text = trim((string)$raw);
      if ($text !== '') {
        $text = str_replace('、', ',', $text);
        $items = explode(',', $text);
      }
    }

    $normalized = [];
    $seen = [];
    foreach ($items as $item) {
      $tag = trim((string)$item);
      if ($tag === '') {
        continue;
      }
      $key = function_exists('mb_strtolower') ? mb_strtolower($tag, 'UTF-8') : strtolower($tag);
      if (isset($seen[$key])) {
        continue;
      }
      $seen[$key] = true;
      $normalized[] = $tag;
    }
    return $normalized;
  }

  private function normalizeMediaUrlsInput($raw, $fallback = '')
  {
    $items = [];
    if (is_array($raw)) {
      $items = $raw;
    } else {
      $text = trim((string)$raw);
      if ($text !== '') {
        $items = explode(',', $text);
      }
    }

    if (trim((string)$fallback) !== '') {
      $items[] = trim((string)$fallback);
    }

    $normalized = [];
    $seen = [];
    foreach ($items as $item) {
      $url = trim((string)$item);
      if ($url === '') {
        continue;
      }
      if (isset($seen[$url])) {
        continue;
      }
      $seen[$url] = true;
      $normalized[] = $url;
    }
    return $normalized;
  }

  private function hasQuestionMediaTable()
  {
    if ($this->hasQuestionMediaTable !== null) {
      return $this->hasQuestionMediaTable;
    }

    $query = "SELECT COUNT(*)
              FROM INFORMATION_SCHEMA.TABLES
              WHERE TABLE_SCHEMA = DATABASE()
                AND TABLE_NAME = 'study_question_media'";
    $stmt = $this->conn->prepare($query);
    $stmt->execute();
    $this->hasQuestionMediaTable = intval($stmt->fetchColumn()) > 0;
    return $this->hasQuestionMediaTable;
  }

  private function getQuestionMediaMap($questions)
  {
    if (empty($questions) || !$this->hasQuestionMediaTable()) {
      return [];
    }

    $ids = [];
    foreach ($questions as $question) {
      $id = intval($question['id'] ?? 0);
      if ($id > 0) {
        $ids[] = $id;
      }
    }
    if (empty($ids)) {
      return [];
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $query = "SELECT question_id, media_url
              FROM study_question_media
              WHERE question_id IN ($placeholders)
              ORDER BY question_id ASC, sort_order ASC, id ASC";
    $stmt = $this->conn->prepare($query);
    foreach ($ids as $idx => $id) {
      $stmt->bindValue($idx + 1, $id, PDO::PARAM_INT);
    }
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $map = [];
    foreach ($rows as $row) {
      $questionId = intval($row['question_id'] ?? 0);
      $url = trim((string)($row['media_url'] ?? ''));
      if ($questionId <= 0 || $url === '') {
        continue;
      }
      if (!isset($map[$questionId])) {
        $map[$questionId] = [];
      }
      $map[$questionId][] = $url;
    }
    return $map;
  }

  private function getQuestionMediaList($questionId)
  {
    $questionId = intval($questionId);
    if ($questionId <= 0 || !$this->hasQuestionMediaTable()) {
      return [];
    }

    $query = "SELECT media_url
              FROM study_question_media
              WHERE question_id = :question_id
              ORDER BY sort_order ASC, id ASC";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $urls = [];
    foreach ($rows as $row) {
      $url = trim((string)($row['media_url'] ?? ''));
      if ($url !== '') {
        $urls[] = $url;
      }
    }
    return $urls;
  }

  private function insertQuestionMedia($questionId, $mediaUrls)
  {
    $questionId = intval($questionId);
    if ($questionId <= 0 || empty($mediaUrls) || !$this->hasQuestionMediaTable()) {
      return;
    }

    $query = "INSERT INTO study_question_media (question_id, media_url, sort_order)
              VALUES (:question_id, :media_url, :sort_order)";
    $stmt = $this->conn->prepare($query);
    foreach ($mediaUrls as $index => $url) {
      $value = trim((string)$url);
      if ($value === '') {
        continue;
      }
      $stmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
      $stmt->bindValue(':media_url', $value);
      $stmt->bindValue(':sort_order', $index, PDO::PARAM_INT);
      $stmt->execute();
    }
  }

  private function validateJWT($token)
  {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
      return false;
    }

    $header = $this->base64url_decode($parts[0]);
    $payload = $this->base64url_decode($parts[1]);
    $signatureProvided = $this->base64url_decode($parts[2]);

    $headerData = json_decode($header, true);
    $payloadData = json_decode($payload, true);

    if (
      !isset($headerData['typ']) ||
      $headerData['typ'] !== 'JWT' ||
      !isset($headerData['alg']) ||
      $headerData['alg'] !== 'HS256'
    ) {
      return false;
    }

    if (!isset($payloadData['exp']) || $payloadData['exp'] < time()) {
      return false;
    }

    $secret_key = "kttProjects2024SecretKey";
    $signatureCheck = hash_hmac(
      'sha256',
      $parts[0] . "." . $parts[1],
      $secret_key,
      true
    );

    if (!hash_equals($signatureProvided, $signatureCheck)) {
      return false;
    }

    return $payloadData;
  }

  private function base64url_decode($data)
  {
    $data = strtr($data, '-_', '+/');
    $remainder = strlen($data) % 4;
    if ($remainder) {
      $data .= str_repeat('=', 4 - $remainder);
    }
    return base64_decode($data);
  }
}

$controller = new StudyController();
$controller->handleRequest();
