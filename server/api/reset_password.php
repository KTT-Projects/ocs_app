<?php
require_once 'config/Database.php';
require_once 'config/Response.php';
require_once 'config/Security.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed');
    exit();
}

// Get posted data
$data = json_decode(file_get_contents('php://input'));

if (!isset($data->email) || !isset($data->code) || !isset($data->new_password)) {
    Response::error('Email, code and new password are required');
    exit();
}

$email = trim($data->email);
$code = trim($data->code);
$newPassword = $data->new_password;

// Validate inputs
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    Response::error('Invalid email format');
    exit();
}

if (strlen($code) !== 6 || !ctype_digit($code)) {
    Response::error('Invalid verification code format');
    exit();
}

if (strlen($newPassword) < 8) {
    Response::error('Password must be at least 8 characters long');
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Check if code exists and is valid
    $query = 'SELECT id FROM users WHERE email = :email AND reset_token = :code AND reset_token_expiry > NOW() LIMIT 1';
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':code', $code);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        Response::error('Invalid or expired verification code');
        exit();
    }

    // Update password and clear reset token
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
    $query = 'UPDATE users SET password = :password, reset_token = NULL, reset_token_expiry = NULL WHERE email = :email AND reset_token = :code';
    $stmt = $db->prepare($query);
    $stmt->bindParam(':password', $hashedPassword);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':code', $code);
    $stmt->execute();

    Response::success('Password has been reset successfully');

} catch (Exception $e) {
    Response::error('Database error: ' . $e->getMessage());
}
