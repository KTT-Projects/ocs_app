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
$required_fields = ['email', 'password'];
foreach ($required_fields as $field) {
  if (!isset($data[$field]) || empty($data[$field])) {
    Response::error("Missing required field: $field");
  }
}

// Initialize database connection
$database = new Database();
$db = $database->getConnection();
$auth = new Auth($db);

// Attempt login
$result = $auth->login($data['email'], $data['password']);

if (!$result) {
  Response::error('Invalid email or password', 401);
}

if (isset($result['error'])) {
  Response::error($result['error'], 403);
}

// Return JWT token and user data
Response::success([
  'token' => $result['token'],
  'user' => $result['user']
]);
