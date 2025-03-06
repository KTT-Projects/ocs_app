<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config/Database.php';
require_once 'config/Auth.php';
require_once 'config/Response.php';

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit(0);
}

// Only allow POST requests for actual API calls
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  Response::error('Method not allowed', 405);
}

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
  Response::error('Invalid input format');
}

// Required fields
$required_fields = ['email', 'password'];
foreach ($required_fields as $field) {
  if (!isset($data[$field]) || empty($data[$field])) {
    Response::error("Missing required field: $field");
  }
}

// Get posted OTP if provided
$otp = isset($data['otp']) ? $data['otp'] : null;

// Initialize database connection
$database = new Database();
$db = $database->getConnection();
$auth = new Auth($db);

// Attempt login
$result = $auth->login($data['email'], $data['password']);

if (!$result) {
  Response::error('Invalid email or password', 401);
}

// Handle response based on login status
if (isset($result['status'])) {
  if ($result['status'] === 'needs_verification') {
    // Create mailer instance
    require_once 'config/Mailer.php';
    $mailer = new Mailer();

    // Send verification email with OTP
    $verificationOtp = $auth->getUserByEmail($data['email'])['verification_otp'];
    if ($mailer->sendVerificationEmail($data['email'], $verificationOtp)) {
      Response::json([
        'status' => 'needs_verification',
        'message' => 'Please enter the verification code sent to your email',
        'user_id' => $result['user_id']
      ]);
    } else {
      Response::error('Failed to send verification email', 500);
    }
  } else if ($result['status'] === 'success') {
    Response::json([
      'status' => 'success',
      'message' => 'Login successful',
      'token' => $result['token'],
      'user' => $result['user']
    ]);
  }
} else if (isset($result['error'])) {
  Response::error($result['error'], 400);
} else {
  Response::error('Invalid credentials', 401);
}
