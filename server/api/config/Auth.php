<?php
class Auth
{
  private $conn;
  private $table_name = "users";
  private $secret_key = "kttProjects2024SecretKey"; // Hardcoded secret key
  private $issuer = "ocs_app_backend";
  private $audience = "ocs_app_clients";
  private $jwt_expiration = 86400; // 24 hours in seconds

  public function __construct($db)
  {
    $this->conn = $db;
  }

  private function base64url_encode($data)
  {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
  }

  private function base64url_decode($data)
  {
    $data = strtr($data, '-_', '+/');
    $padding = strlen($data) % 4;
    if ($padding) {
      $data .= str_repeat('=', 4 - $padding);
    }
    return base64_decode($data);
  }

  public function generateJWT($user_id, $email, $role_id)
  {
    $header = json_encode([
      'typ' => 'JWT',
      'alg' => 'HS256'
    ]);

    $payload = json_encode([
      'user_id' => $user_id,
      'email' => $email,
      'role_id' => $role_id,
      'iss' => $this->issuer,
      'aud' => $this->audience,
      'exp' => time() + $this->jwt_expiration,
      'iat' => time()
    ]);

    $base64UrlHeader = $this->base64url_encode($header);
    $base64UrlPayload = $this->base64url_encode($payload);

    $signature = hash_hmac(
      'sha256',
      $base64UrlHeader . "." . $base64UrlPayload,
      $this->secret_key,
      true
    );

    $base64UrlSignature = $this->base64url_encode($signature);

    return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
  }

  public function decodeJWT($token)
  {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
      return false;
    }

    [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;

    $header = json_decode($this->base64url_decode($encodedHeader), true);
    $payload = json_decode($this->base64url_decode($encodedPayload), true);
    $signatureProvided = $this->base64url_decode($encodedSignature);

    if (!$header || !$payload || $signatureProvided === false) {
      return false;
    }

    if (($header['typ'] ?? '') !== 'JWT' || ($header['alg'] ?? '') !== 'HS256') {
      return false;
    }

    if (!isset($payload['user_id'])) {
      return false;
    }

    $expectedSignature = hash_hmac('sha256', $encodedHeader . "." . $encodedPayload, $this->secret_key, true);
    if (!hash_equals($expectedSignature, $signatureProvided)) {
      return false;
    }

    if (!isset($payload['exp']) || $payload['exp'] < time()) {
      return false;
    }

    if (isset($payload['nbf']) && time() < $payload['nbf']) {
      return false;
    }

    if (($payload['iss'] ?? null) !== $this->issuer || ($payload['aud'] ?? null) !== $this->audience) {
      return false;
    }

    return $payload;
  }

  public function validatePassword($input, $stored_hash)
  {
    return password_verify($input, $stored_hash);
  }

  public function validatePasswordStrength($password)
  {
    if (strlen($password) < 8) {
      return ['valid' => false, 'message' => 'Password must be at least 8 characters long'];
    }

    return ['valid' => true];
  }

  public function hashPassword($password)
  {
    return password_hash($password, PASSWORD_DEFAULT, ['cost' => 12]);
  }

  public function generateVerificationToken()
  {
    return bin2hex(random_bytes(32));
  }

  public function validateEmail($email)
  {
    return filter_var($email, FILTER_VALIDATE_EMAIL);
  }

  public function checkInstitutionDomain($email, $institution_id)
  {
    $query = "SELECT email_domain FROM educational_institutions WHERE id = ?";
    $stmt = $this->conn->prepare($query);
    $stmt->execute([$institution_id]);

    if ($domain = $stmt->fetch(PDO::FETCH_COLUMN)) {
      $email_parts = explode('@', $email);
      return $email_parts[1] === $domain;
    }

    return false;
  }

  public function createUser($email, $password, $role_id, $institution_id, $grade, $display_name, $bio = null, $allow_dm = true)
  {
    try {
      // Generate 6-digit OTP
      $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
      // Set OTP expiration (10 minutes from now)
      $otp_expires = date('Y-m-d H:i:s', strtotime('+10 minutes'));
      $password_hash = $this->hashPassword($password);

      $query = "INSERT INTO " . $this->table_name . "
                  (email, password_hash, role_id, institution_id, grade, verification_otp, otp_expires_at)
                  VALUES (?, ?, ?, ?, ?, ?, ?)";

      $stmt = $this->conn->prepare($query);

      $this->conn->beginTransaction();
      
      if ($stmt->execute([
        $email,
        $password_hash,
        $role_id,
        $institution_id,
        $grade,
        $otp,
        $otp_expires
      ])) {
        $user_id = $this->conn->lastInsertId();
        
        // Create user profile
        if ($display_name) {
          $profile_query = "INSERT INTO user_profiles (user_id, display_name, bio, allow_dm) VALUES (?, ?, ?, ?)";
          $profile_stmt = $this->conn->prepare($profile_query);
          if (!$profile_stmt->execute([$user_id, $display_name, $bio, $allow_dm])) {
            $this->conn->rollBack();
            return false;
          }
        }

        $this->conn->commit();
        return [
          'user_id' => $user_id,
          'verification_otp' => $otp
        ];
      }
      $this->conn->rollBack();
      return false;
    } catch (PDOException $e) {
      error_log("Database error in createUser: " . $e->getMessage());
      return false;
    }
  }

  public function generateLoginOTP($user_id)
  {
    try {
      $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
      $otp_expires = date('Y-m-d H:i:s', strtotime('+10 minutes'));

      $query = "UPDATE " . $this->table_name . "
                SET verification_otp = ?, otp_expires_at = ?
                WHERE id = ?";

      $stmt = $this->conn->prepare($query);
      if ($stmt->execute([$otp, $otp_expires, $user_id])) {
        return $otp;
      }
      return false;
    } catch (PDOException $e) {
      error_log("Database error in generateLoginOTP: " . $e->getMessage());
      return false;
    }
  }

  public function login($email, $password, $skipPasswordCheck = false)
  {
    $user = $this->getUserByEmail($email);

    if (!$user) {
      return false;
    }

    if (!$skipPasswordCheck && !$this->validatePassword($password, $user['password_hash'])) {
      return false;
    }

    if (!$user['is_verified']) {
      // Generate and send OTP for verification
      $otp = $this->generateLoginOTP($user['id']);
      if ($otp) {
        return [
          'status' => 'needs_verification',
          'message' => 'OTP sent to email',
          'user_id' => $user['id']
        ];
      }
      return ['error' => 'Failed to generate OTP'];
    }

    return [
      'status' => 'success',
      'token' => $this->generateJWT($user['id'], $user['email'], $user['role_id']),
      'user' => [
        'id' => $user['id'],
        'email' => $user['email'],
        'role' => $user['role_name']
      ]
    ];
  }

  public function getUserByEmail($email)
  {
    $query = "SELECT u.*, r.name as role_name 
                 FROM " . $this->table_name . " u
                 JOIN roles r ON u.role_id = r.id
                 WHERE u.email = ?";

    $stmt = $this->conn->prepare($query);
    $stmt->execute([$email]);

    return $stmt->fetch(PDO::FETCH_ASSOC);
  }
}
