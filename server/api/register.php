<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config/Database.php';
require_once 'config/Auth.php';
require_once 'config/Response.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  Response::error('Method not allowed', 405);
}

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
  Response::error('Invalid input format');
}

// Required fields
$required_fields = ['email', 'password', 'institution_id', 'student_id'];
foreach ($required_fields as $field) {
  if (!isset($data[$field]) || empty($data[$field])) {
    Response::error("Missing required field: $field");
  }
}

// Initialize database connection
$database = new Database();
$db = $database->getConnection();
$auth = new Auth($db);

// Validate email format
if (!$auth->validateEmail($data['email'])) {
  Response::error('Invalid email format');
}

// Validate password strength
if (strlen($data['password']) < 8) {
  Response::error('Password must be at least 8 characters long');
}

// Validate institution domain
if (!$auth->checkInstitutionDomain($data['email'], $data['institution_id'])) {
  Response::error('Email domain does not match the selected institution');
}

// Check if user already exists
if ($auth->getUserByEmail($data['email'])) {
  Response::error('Email already registered', 409);
}

// Create user
$result = $auth->createUser(
  $data['email'],
  $data['password'],
  1, // Default role_id for students
  $data['institution_id'],
  $data['student_id']
);

if (!$result) {
  Response::error('Failed to create user account');
}

// Send verification email (implement this according to your email service)
// For now, just return the verification token in the response
Response::success([
  'message' => 'Registration successful',
  'verification_token' => $result['verification_token']
]);
