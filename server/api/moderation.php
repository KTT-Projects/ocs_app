<?php
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
require_once 'config/ModerationService.php';

class ModerationController
{
  private $db;
  private $auth;
  private $conn;
  private $moderation;

  public function __construct()
  {
    $this->db = new Database();
    $this->conn = $this->db->getConnection();
    $this->auth = new Auth($this->conn);
    $this->moderation = new ModerationService($this->conn);
  }

  public function handleRequest()
  {
    $method = $_SERVER['REQUEST_METHOD'];
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    try {
      $userId = $this->getAuthorizedUserId();
      if ($userId === null) {
        Response::error('Authorization header is required', 401);
        return;
      }

      if ($method === 'GET' && $action === 'queue') {
        $this->getQueue($userId);
        return;
      }

      if ($method === 'POST' && $action === 'report') {
        $this->reportContent($userId);
        return;
      }

      if ($method === 'POST' && $action === 'review') {
        $this->reviewCase($userId);
        return;
      }

      Response::error('Invalid action', 400);
    } catch (InvalidArgumentException $e) {
      Response::error($e->getMessage(), 400);
    } catch (RuntimeException $e) {
      $message = $e->getMessage();
      $status = stripos($message, 'permission') !== false ? 403 : 404;
      Response::error($message, $status);
    } catch (Exception $e) {
      Response::error('Moderation request failed: ' . $e->getMessage(), 500);
    }
  }

  private function getQueue($userId)
  {
    $status = isset($_GET['status']) ? trim((string)$_GET['status']) : 'pending';
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;
    $items = $this->moderation->getQueue($userId, $status, $limit);
    Response::success(['items' => $items], 'Moderation queue retrieved successfully');
  }

  private function reportContent($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $entityType = $data['entity_type'] ?? '';
    $entityId = $data['entity_id'] ?? 0;
    $reason = $data['reason'] ?? 'other';
    $details = $data['details'] ?? '';

    $result = $this->moderation->createReport($userId, $entityType, $entityId, $reason, $details);
    Response::success($result, 'Report submitted successfully');
  }

  private function reviewCase($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $caseId = $data['case_id'] ?? 0;
    $action = $data['action'] ?? '';
    $note = $data['note'] ?? '';

    $case = $this->moderation->reviewCase($userId, $caseId, $action, $note);
    Response::success($case, 'Moderation case updated successfully');
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
    $decoded = $this->auth->decodeJWT($token);
    if (!$decoded) {
      Response::error('Invalid or expired token', 401);
      return null;
    }

    return intval($decoded['user_id']);
  }
}

$controller = new ModerationController();
$controller->handleRequest();
