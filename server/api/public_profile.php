<?php
require_once 'config/Database.php';
require_once 'config/Response.php';
require_once 'config/Auth.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Credentials: true");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit(0);
}

$headers = getallheaders();
$auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';

if (!$auth_header || !preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
  Response::error('Authorization token required', 401);
}

$token = $matches[1];

try {
  $database = new Database();
  $db = $database->getConnection();
  $auth = new Auth($db);

  // Validate JWT token
  $token_parts = explode('.', $token);
  if (count($token_parts) !== 3) {
    Response::error('Invalid token format', 401);
  }
  $payloadSegment = strtr($token_parts[1], '-_', '+/');
  $remainder = strlen($payloadSegment) % 4;
  if ($remainder) {
    $payloadSegment .= str_repeat('=', 4 - $remainder);
  }
  $payload = json_decode(base64_decode($payloadSegment), true);

  if (!$payload || time() >= $payload['exp']) {
    Response::error('Invalid or expired token', 401);
  }

  if (!isset($_GET['user_id'])) {
    Response::error('user_id is required', 400);
  }
  $userId = intval($_GET['user_id']);

  $query = "SELECT u.id,
                   up.display_name,
                   up.avatar_url,
                   up.bio,
                   up.allow_dm,
                   r.name as role_name,
                   ei.name as institution_name,
                   u.grade,
                   COALESCE((SELECT SUM(pl.points) FROM point_ledger pl WHERE pl.user_id = u.id), 0) AS total_points
            FROM users u
            JOIN roles r ON u.role_id = r.id
            LEFT JOIN educational_institutions ei ON u.institution_id = ei.id
            LEFT JOIN user_profiles up ON u.id = up.user_id
            WHERE u.id = ? AND u.is_verified = 1";
  $stmt = $db->prepare($query);
  $stmt->execute([$userId]);

  if ($stmt->rowCount() === 0) {
    Response::error('User not found', 404);
  }

  $user = $stmt->fetch(PDO::FETCH_ASSOC);

  $profile = [
    'id' => $user['id'],
    'name' => $user['display_name'],
    'avatar' => $user['avatar_url'],
    'bio' => $user['bio'],
    'allow_dm' => (bool)$user['allow_dm'],
    'role' => $user['role_name'],
    'institution' => $user['institution_name'],
    'grade' => $user['grade'],
    'total_points' => intval($user['total_points'] ?? 0)
  ];

  Response::json([
    'status' => 'success',
    'profile' => $profile
  ]);
} catch (PDOException $e) {
  Response::error('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
  Response::error('Server error: ' . $e->getMessage(), 500);
}
