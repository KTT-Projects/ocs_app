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

class StudyController
{
  private $db;
  private $auth;
  private $conn;
  private const BEST_ANSWER_POINTS = 50;
  private const BEST_ANSWER_EVENT_TYPE = 'BEST_ANSWER';

  public function __construct()
  {
    $this->db = new Database();
    $this->conn = $this->db->getConnection();
    $this->auth = new Auth($this->conn);
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

    $query = "SELECT sq.id,
                     sq.author_user_id,
                     sq.title,
                     sq.body,
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
              ORDER BY sq.created_at DESC
              LIMIT :limit OFFSET :offset";

    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);
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
                     up.avatar_url
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

  private function createQuestion($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $title = trim($data['title'] ?? '');
    $body = trim($data['body'] ?? '');
    $category = trim($data['category'] ?? '');

    if ($title === '') {
      Response::error('Title is required', 400);
      return;
    }
    if ($body === '') {
      Response::error('Body is required', 400);
      return;
    }
    if ($category === '') {
      Response::error('Category is required', 400);
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
    if ($this->stringLength($category) > 100) {
      Response::error('Category must be less than 100 characters', 400);
      return;
    }

    $query = "INSERT INTO study_questions (author_user_id, title, body, category, status)
              VALUES (:author_user_id, :title, :body, :category, 'open')";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':author_user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':title', $title);
    $stmt->bindValue(':body', $body);
    $stmt->bindValue(':category', $category);
    $stmt->execute();

    Response::success(['id' => $this->conn->lastInsertId()], 'Question created successfully');
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

    $checkQuery = "SELECT id FROM study_questions WHERE id = :question_id LIMIT 1";
    $checkStmt = $this->conn->prepare($checkQuery);
    $checkStmt->bindValue(':question_id', $questionId, PDO::PARAM_INT);
    $checkStmt->execute();
    if (!$checkStmt->fetch(PDO::FETCH_ASSOC)) {
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

    Response::success(['id' => $this->conn->lastInsertId()], 'Answer created successfully');
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
                             sq.author_user_id AS question_author_user_id
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

  private function stringLength($value)
  {
    if (function_exists('mb_strlen')) {
      return mb_strlen($value, 'UTF-8');
    }
    return strlen($value);
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
