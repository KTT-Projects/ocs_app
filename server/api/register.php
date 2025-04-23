<?php
// Enable error reporting in development environment
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Set development mode (should be configured in production)
define('DEVELOPMENT_MODE', true);

require_once 'config/Database.php';
require_once 'config/Auth.php';
require_once 'config/Response.php';
require_once 'config/Mailer.php';
require_once 'config/Security.php';

try {
  // Initialize security
  $database = new Database();
  $db = $database->getConnection();
  if (!$db) {
    Response::error('Database connection failed');
  }
  $security = new Security($db);

  // Apply CORS headers
  $security->corsHeaders();

  // Only allow POST requests
  if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0); // Handle preflight request
  }

  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
  }

  // Check rate limit
  $client_ip = $security->getClientIp();
  if (!$security->checkRateLimit($client_ip, 'register')) {
    Response::error('Too many requests. Please try again later.', 429);
  }

  // Get posted data
  $data = json_decode(file_get_contents("php://input"), true);

  if (!$data) {
    Response::error('Invalid input format');
  }

  // Required fields
  $required_fields = ['email', 'password', 'institution_id', 'grade', 'display_name'];
  foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
      Response::error("Missing required field: $field", 400);
    }
  }

  // Sanitize inputs
  $data = $security->sanitizeInput($data);

  // Initialize auth
  $auth = new Auth($db);
  $mailer = new Mailer();

  // Validate email format
  if (!$auth->validateEmail($data['email'])) {
    Response::error('Invalid email format');
  }

  // Validate password strength
  $password_validation = $auth->validatePasswordStrength($data['password']);
  if (!$password_validation['valid']) {
    Response::error($password_validation['message']);
  }

  // Validate grade value
  $grade = intval($data['grade']);
  if (!($grade >= 7 && $grade <= 14 || $grade === 99)) {
    Response::error('Invalid grade value. Must be between G7 and G14, or OB (99).');
  }

  // Validate institution domain
  // if (!$auth->checkInstitutionDomain($data['email'], $data['institution_id'])) {
  //   Response::error('Email domain does not match the selected institution');
  // }

  // Check if user already exists
  if ($auth->getUserByEmail($data['email'])) {
    Response::error('Email already registered', 409);
  }

  // Get user information
  $bio = isset($data['bio']) ? trim($data['bio']) : null;
  $display_name = isset($data['display_name']) ? trim($data['display_name']) : null;
  $allow_dm = isset($data['allow_dm']) ? (bool)$data['allow_dm'] : true;

  if (empty($display_name)) {
    Response::error('Display name is required', 400);
  }

  if (strlen($display_name) > 100) {
    Response::error('Display name must be less than 100 characters', 400);
  }

  // Create user
  $result = $auth->createUser(
    $data['email'],
    $data['password'],
    1, // Default role_id for students
    $data['institution_id'],
    $grade,
    $display_name,
    $bio,
    $allow_dm
  );

  if (!$result) {
    Response::error('Failed to create user account');
  }

  // Get language from Accept-Language header (default to 'en' if not set)
  $lang = 'en';
  if (isset($_SERVER['HTTP_ACCEPT_LANGUAGE'])) {
    $lang = substr($_SERVER['HTTP_ACCEPT_LANGUAGE'], 0, 2);
    if (!in_array($lang, ['en', 'ja'])) {
      $lang = 'en';
    }
  }

  // Send verification email with OTP
  try {
    $emailSent = $mailer->sendVerificationEmail($data['email'], $result['verification_otp'], $lang);

    if (!$emailSent) {
      error_log("Failed to send verification email to: " . $data['email']);
      error_log("PHP mail() configuration status: " . ini_get('sendmail_path'));
      error_log("SMTP configuration: " . ini_get('SMTP') . ":" . ini_get('smtp_port'));
    }
  } catch (Exception $e) {
    error_log("Detailed email error: " . $e->getMessage());
    $emailSent = false;
  }

  Response::success([
    'message' => 'Registration successful. Please check your email to verify your account.',
    'email_sent' => $emailSent
  ]);
} catch (PDOException $e) {
  error_log("Database error: " . $e->getMessage());
  $error_message = DEVELOPMENT_MODE ?
    $e->getMessage() :
    'Database error occurred. Please try again later.';
  $error_details = DEVELOPMENT_MODE ? [
    'error_type' => 'PDOException',
    'error_code' => $e->getCode(),
    'error_file' => $e->getFile(),
    'error_line' => $e->getLine(),
    'stack_trace' => $e->getTraceAsString()
  ] : null;
  Response::error($error_message, 500, $error_details);
} catch (Exception $e) {
  error_log("Error: " . $e->getMessage());
  $error_message = DEVELOPMENT_MODE ?
    $e->getMessage() :
    'An unexpected error occurred. Please try again later.';
  $error_details = DEVELOPMENT_MODE ? [
    'error_type' => get_class($e),
    'error_code' => $e->getCode(),
    'error_file' => $e->getFile(),
    'error_line' => $e->getLine(),
    'stack_trace' => $e->getTraceAsString()
  ] : null;
  Response::error($error_message, 500, $error_details);
}
