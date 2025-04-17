<?php
require_once 'config/Database.php';
require_once 'config/Response.php';
require_once 'config/Security.php';
require_once 'config/Mailer.php';

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

if (!isset($data->email)) {
    Response::error('Email is required');
    exit();
}

$email = trim($data->email);

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    Response::error('Invalid email format');
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Check if user exists
    $query = 'SELECT id FROM users WHERE email = :email LIMIT 1';
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $email);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        Response::error('User not found');
        exit();
    }

    // Generate 6-digit code
    $resetCode = sprintf('%06d', random_int(0, 999999));
    $expiry = date('Y-m-d H:i:s', strtotime('+1 hour'));

    // Store reset code in database
    $query = 'UPDATE users SET reset_token = :code, reset_token_expiry = :expiry WHERE email = :email';
    $stmt = $db->prepare($query);
    $stmt->bindParam(':code', $resetCode);
    $stmt->bindParam(':expiry', $expiry);
    $stmt->bindParam(':email', $email);
    $stmt->execute();

    // Send bilingual reset email
    $emailBodyEn = "Your password reset code is: $resetCode\n\n" .
                   "This code will expire in 1 hour.\n\n" .
                   "If you did not request this password reset, please ignore this email.\n\n" .
                   "Best regards,\nOCS Team";

    $emailBodyJa = "パスワードリセット用の認証コード：$resetCode\n\n" .
                   "このコードは1時間後に期限切れとなります。\n\n" .
                   "このパスワードリセットをリクエストしていない場合は、このメールを無視してください。\n\n" .
                   "よろしくお願いいたします。\nOCSチーム";

    if (Mailer::sendBilingual(
        $email,
        "Password Reset Code",
        "パスワードリセット認証コード",
        $emailBodyEn,
        $emailBodyJa
    )) {
        Response::success('Password reset instructions sent to your email');
    } else {
        Response::error('Failed to send reset email');
    }

} catch (Exception $e) {
    Response::error('Database error: ' . $e->getMessage());
}
