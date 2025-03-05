<?php
require_once 'config/Database.php';
require_once 'config/Response.php';

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

$database = new Database();
$db = $database->getConnection();
$response = new Response();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    $response->error('Invalid request method', 405);
    exit();
}

// Get token from query string
$token = isset($_GET['token']) ? $_GET['token'] : null;

if (!$token) {
    $response->error('Verification token is required', 400);
    exit();
}

try {
    // Find user with matching token
    $query = 'SELECT id FROM users WHERE verification_token = ? AND is_verified = 0';
    $stmt = $db->prepare($query);
    $stmt->execute([$token]);

    if ($stmt->rowCount() === 0) {
        $response->error('Invalid or expired verification token', 400);
        exit();
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Update user as verified
    $query = 'UPDATE users SET is_verified = 1, verification_token = NULL WHERE id = ?';
    $stmt = $db->prepare($query);
    $stmt->execute([$user['id']]);

    $response->success('Email verified successfully');

} catch (PDOException $e) {
    $response->error('Database error: ' . $e->getMessage(), 500);
}