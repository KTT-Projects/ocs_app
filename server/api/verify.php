<?php
require_once 'config/Database.php';
require_once 'config/Response.php';
require_once 'config/Auth.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  Response::error('Invalid request method', 405);
}

// Get JSON data
$data = json_decode(file_get_contents("php://input"), true);
$email = isset($data['email']) ? $data['email'] : null;
$otp = isset($data['otp']) ? $data['otp'] : null;

if (!$email || !$otp) {
  Response::error('Email and OTP are required', 400);
}

try {
  $database = new Database();
  $db = $database->getConnection();
  $auth = new Auth($db);

  // Find user with matching OTP that hasn't expired
  $query = 'SELECT u.*, r.name as role_name 
             FROM users u 
             JOIN roles r ON u.role_id = r.id 
             WHERE u.email = ? AND u.verification_otp = ? AND u.otp_expires_at > NOW()';
  $stmt = $db->prepare($query);
  $stmt->execute([$email, $otp]);

  if ($stmt->rowCount() === 0) {
    Response::error('Invalid or expired OTP. Please request a new code.', 400);
  }

  // Get user data from the earlier query
  $user = $stmt->fetch(PDO::FETCH_ASSOC);

  // Double check OTP matches exactly
  if ($user['verification_otp'] !== $otp) {
    Response::error('Invalid verification code', 400);
  }

  // Update user as verified and clear OTP
  $query = 'UPDATE users SET is_verified = 1, verification_otp = NULL, otp_expires_at = NULL WHERE id = ?';
  $stmt = $db->prepare($query);

  if ($stmt->execute([$user['id']])) {
    // After successful verification, attempt login
    $result = $auth->login($email, null, true); // true means skip password check since we've verified OTP

    if ($result && $result['status'] === 'success') {
      Response::json([
        'status' => 'success',
        'message' => 'Email verified successfully',
        'token' => $result['token'],
        'user' => $result['user']
      ]);
    } else {
      Response::error('Verification successful but login failed', 500);
    }
  } else {
    Response::error('Failed to update verification status', 500);
  }
} catch (PDOException $e) {
  Response::error('Database error: ' . $e->getMessage(), 500);
}
