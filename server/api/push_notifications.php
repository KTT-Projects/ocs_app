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
require_once 'config/PushNotificationService.php';

class PushNotificationController
{
  private $conn;
  private $auth;
  private $push;

  public function __construct()
  {
    $db = new Database();
    $this->conn = $db->getConnection();
    $this->auth = new Auth($this->conn);
    $this->push = new PushNotificationService($this->conn);
  }

  public function handleRequest()
  {
    $method = $_SERVER['REQUEST_METHOD'];
    $action = $_GET['action'] ?? '';

    try {
      if ($action === 'flush') {
        $this->flushPending();
        return;
      }

      $user = $this->requireUser();
      $userId = intval($user['user_id']);

      if ($method === 'GET') {
        if ($action === 'devices') {
          Response::success([
            'configured' => $this->push->isConfigured(),
            'devices' => $this->push->listDevices($userId)
          ], 'Push devices retrieved successfully');
          return;
        }
        Response::error('Invalid action', 400);
        return;
      }

      if ($method !== 'POST') {
        Response::error('Method not allowed', 405);
        return;
      }

      if ($action === 'register') {
        $this->registerDevice($userId);
      } else if ($action === 'unregister') {
        $this->unregisterDevice($userId);
      } else if ($action === 'test') {
        $this->sendTest($userId);
      } else {
        Response::error('Invalid action', 400);
      }
    } catch (InvalidArgumentException $e) {
      Response::error($e->getMessage(), 400);
    } catch (Exception $e) {
      Response::error($e->getMessage(), 500);
    }
  }

  private function registerDevice($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $result = $this->push->registerDevice(
      $userId,
      $data['platform'] ?? '',
      $data['token'] ?? '',
      $data['device_id'] ?? null,
      $data['app_version'] ?? null,
      $data['locale'] ?? null
    );

    Response::success($result, 'Push device registered successfully');
  }

  private function unregisterDevice($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
      Response::error('Invalid input format', 400);
      return;
    }

    $count = $this->push->unregisterDevice(
      $userId,
      $data['token'] ?? null,
      $data['device_id'] ?? null
    );

    Response::success(['disabled' => $count], 'Push device unregistered successfully');
  }

  private function sendTest($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) $data = [];

    $title = trim($data['title'] ?? 'OCS notification test');
    $body = trim($data['body'] ?? 'Push notifications are connected.');
    $stats = $this->push->sendToUsers([$userId], 'test', $title, $body, [
      'type' => 'test',
      'entity_type' => 'test',
      'entity_id' => 0,
      'route' => 'notifications'
    ], $userId);

    Response::success($stats, 'Push test queued successfully');
  }

  private function flushPending()
  {
    $secret = getenv('PUSH_FLUSH_SECRET');
    if ($secret) {
      $headers = getallheaders();
      $provided = $headers['X-Push-Secret'] ?? $headers['x-push-secret'] ?? ($_GET['secret'] ?? '');
      if (!hash_equals($secret, (string)$provided)) {
        Response::error('Invalid push flush secret', 403);
        return;
      }
    } else {
      $this->requireUser();
    }

    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;
    $stats = $this->push->flushPending($limit);
    Response::success([
      'configured' => $this->push->isConfigured(),
      'stats' => $stats
    ], 'Pending push notifications processed');
  }

  private function requireUser()
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
      Response::error('Authorization header is required', 401);
      return null;
    }

    $token = str_replace('Bearer ', '', $authorization);
    $decoded = $this->auth->decodeJWT($token);
    if (!$decoded) {
      Response::error('Invalid or expired token', 401);
      return null;
    }
    return $decoded;
  }
}

$controller = new PushNotificationController();
$controller->handleRequest();
