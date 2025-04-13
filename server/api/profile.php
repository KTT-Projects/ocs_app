<?php
require_once 'config/Database.php';
require_once 'config/Response.php';
require_once 'config/Auth.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Invalid request method', 405);
}

// Get authorization header
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

    // Decode JWT token
    $token_parts = explode('.', $token);
    if (count($token_parts) !== 3) {
        Response::error('Invalid token format', 401);
    }

    $payload = json_decode(base64_decode(strtr($token_parts[1], '-_', '+/')), true);
    
    if (!$payload || !isset($payload['user_id']) || time() >= $payload['exp']) {
        Response::error('Invalid or expired token', 401);
    }

    // Get user data
    $query = "SELECT 
        u.id,
        u.email,
        up.display_name,
        up.avatar_url,
        up.bio,
        up.allow_dm,
        r.name as role_name,
        ei.name as institution_name,
        u.grade
    FROM users u
    JOIN roles r ON u.role_id = r.id
    LEFT JOIN educational_institutions ei ON u.institution_id = ei.id
    LEFT JOIN user_profiles up ON u.id = up.user_id
    WHERE u.id = ? AND u.is_verified = 1";

    $stmt = $db->prepare($query);
    $stmt->execute([$payload['user_id']]);

    if ($stmt->rowCount() === 0) {
        Response::error('User not found', 404);
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Format response
    $profile = [
        'id' => $user['id'],
        'email' => $user['email'],
        'name' => $user['display_name'],
        'avatar' => $user['avatar_url'],
        'bio' => $user['bio'],
        'allow_dm' => (bool)$user['allow_dm'],
        'role' => $user['role_name'],
        'institution' => $user['institution_name'],
        'grade' => $user['grade']
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
