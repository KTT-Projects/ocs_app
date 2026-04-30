<?php
require_once 'config/Database.php';
require_once 'config/Response.php';
require_once 'config/Auth.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Credentials: true");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit(0);
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

  $payloadSegment = strtr($token_parts[1], '-_', '+/');
  $remainder = strlen($payloadSegment) % 4;
  if ($remainder) {
    $payloadSegment .= str_repeat('=', 4 - $remainder);
  }
  $payload = json_decode(base64_decode($payloadSegment), true);

  if (!$payload || !isset($payload['user_id']) || time() >= $payload['exp']) {
    Response::error('Invalid or expired token', 401);
  }

  // Create uploads directory if it doesn't exist
  $uploadDir = __DIR__ . '/../uploads/avatars/';
  if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
  }

  // Handle POST (web avatar upload) or PATCH (mobile update) request for updating profile settings
  if ($_SERVER['REQUEST_METHOD'] === 'PATCH' || $_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check if it's a multipart form data (file upload)
    if (strpos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false) {
      if (!isset($_FILES['avatar'])) {
        Response::error('No avatar file provided', 400);
      }

      $file = $_FILES['avatar'];
      if ($file['error'] !== UPLOAD_ERR_OK) {
        Response::error('File upload failed', 400);
      }

      // Validate file type
      $allowedTypes = ['image/jpeg', 'image/png'];
      $finfo = finfo_open(FILEINFO_MIME_TYPE);
      $mimeType = finfo_file($finfo, $file['tmp_name']);
      finfo_close($finfo);

      if (!in_array($mimeType, $allowedTypes)) {
        Response::error('Invalid file type. Only JPEG and PNG are allowed.', 400);
      }

      // Generate unique filename and prepare path
      $extension = $mimeType === 'image/jpeg' ? 'jpg' : 'png';
      $filename = uniqid('avatar_') . '.' . $extension;
      $filepath = $uploadDir . $filename;

      // Resize to max 256x256 without stretching
      list($width, $height) = getimagesize($file['tmp_name']);

      // Correct orientation for JPEGs using EXIF data when available
      if ($mimeType === 'image/jpeg') {
        $src = imagecreatefromjpeg($file['tmp_name']);
        if (function_exists('exif_read_data')) {
          $exif = @exif_read_data($file['tmp_name']);
          if ($exif && isset($exif['Orientation'])) {
            switch ($exif['Orientation']) {
              case 3:
                $src = imagerotate($src, 180, 0);
                break;
              case 6:
                $src = imagerotate($src, -90, 0);
                $width = imagesx($src);
                $height = imagesy($src);
                break;
              case 8:
                $src = imagerotate($src, 90, 0);
                $width = imagesx($src);
                $height = imagesy($src);
                break;
            }
          }
        }
      } else {
        $src = imagecreatefrompng($file['tmp_name']);
      }

      $maxSize = 256;
      $scale = min($maxSize / $width, $maxSize / $height, 1);
      $newWidth = (int)($width * $scale);
      $newHeight = (int)($height * $scale);

      $dst = imagecreatetruecolor($newWidth, $newHeight);
      if ($mimeType === 'image/png') {
        imagealphablending($dst, false);
        imagesavealpha($dst, true);
      }
      imagecopyresampled($dst, $src, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);

      if ($mimeType === 'image/jpeg') {
        imagejpeg($dst, $filepath, 90);
      } else {
        imagepng($dst, $filepath);
      }

      imagedestroy($src);
      imagedestroy($dst);

      // Get current avatar URL to delete the old file
      $query_get_old = "SELECT avatar_url FROM user_profiles WHERE user_id = :user_id";
      $stmt_get_old = $db->prepare($query_get_old);
      $stmt_get_old->execute(['user_id' => $payload['user_id']]);
      $old_avatar_url = $stmt_get_old->fetchColumn();

      // Update avatar_url in database
      $avatarUrl = '/uploads/avatars/' . $filename;
      $query_update = "UPDATE user_profiles SET avatar_url = :avatar_url WHERE user_id = :user_id";
      $stmt_update = $db->prepare($query_update);
      $stmt_update->execute([
        'avatar_url' => $avatarUrl,
        'user_id' => $payload['user_id']
      ]);

      // Delete old avatar file if it exists
      if ($old_avatar_url && !empty($old_avatar_url)) {
        $old_filepath = __DIR__ . '/../' . ltrim($old_avatar_url, '/'); // Ensure correct path
        if (file_exists($old_filepath)) {
          unlink($old_filepath);
        }
      }

      Response::json([
        'status' => 'success',
        'avatar_url' => $avatarUrl
      ]);
      exit;
    }

    // Handle regular profile updates
    $data = json_decode(file_get_contents('php://input'), true);

    $profileUpdateFields = [];
    $userUpdateFields = [];
    $profileParams = ['user_id' => $payload['user_id']];
    $userParams = ['user_id' => $payload['user_id']];

    if (isset($data['allow_dm'])) {
      $profileUpdateFields[] = "allow_dm = :allow_dm";
      $profileParams['allow_dm'] = $data['allow_dm'] ? 1 : 0;
    }
    if (isset($data['display_name'])) {
      $profileUpdateFields[] = "display_name = :display_name";
      $profileParams['display_name'] = $data['display_name'];
    }
    if (isset($data['bio'])) {
      $profileUpdateFields[] = "bio = :bio";
      $profileParams['bio'] = $data['bio'];
    }
    if (isset($data['grade'])) {
      $userUpdateFields[] = "grade = :grade";
      $userParams['grade'] = $data['grade'];
    }
    if (isset($data['institution_id'])) {
      $userUpdateFields[] = "institution_id = :institution_id";
      $userParams['institution_id'] = $data['institution_id'];
    }

    if (!empty($profileUpdateFields)) {
      $query = "UPDATE user_profiles SET " . implode(", ", $profileUpdateFields) . " WHERE user_id = :user_id";
      $stmt = $db->prepare($query);
      $stmt->execute($profileParams);
    }

    if (!empty($userUpdateFields)) {
      $query = "UPDATE users SET " . implode(", ", $userUpdateFields) . " WHERE id = :user_id";
      $stmt = $db->prepare($query);
      $stmt->execute($userParams);
    }
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
        u.grade,
        COALESCE((SELECT SUM(pl.points) FROM point_ledger pl WHERE pl.user_id = u.id), 0) AS total_points
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
