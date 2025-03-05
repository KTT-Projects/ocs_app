<?php
class Auth
{
  private $conn;
  private $table_name = "users";
  private $secret_key = "your_secret_key"; // Should be in environment variables in production

  public function __construct($db)
  {
    $this->conn = $db;
  }

  private function base64url_encode($data)
  {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
  }

  private function generateJWT($user_id, $email, $role_id)
  {
    $header = json_encode([
      'typ' => 'JWT',
      'alg' => 'HS256'
    ]);

    $payload = json_encode([
      'user_id' => $user_id,
      'email' => $email,
      'role_id' => $role_id,
      'exp' => time() + (60 * 60 * 24) // 24 hours
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

  public function validatePassword($input, $stored_hash)
  {
    return password_verify($input, $stored_hash);
  }

  public function hashPassword($password)
  {
    return password_hash($password, PASSWORD_DEFAULT);
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

  public function createUser($email, $password, $role_id, $institution_id, $student_id = null)
  {
    try {
      $verification_token = $this->generateVerificationToken();
      $password_hash = $this->hashPassword($password);

      $query = "INSERT INTO " . $this->table_name . "
                    (email, password_hash, role_id, institution_id, student_id, verification_token)
                    VALUES (?, ?, ?, ?, ?, ?)";

      $stmt = $this->conn->prepare($query);

      if ($stmt->execute([
        $email,
        $password_hash,
        $role_id,
        $institution_id,
        $student_id,
        $verification_token
      ])) {
        return [
          'user_id' => $this->conn->lastInsertId(),
          'verification_token' => $verification_token
        ];
      }
      return false;
    } catch (PDOException $e) {
      return false;
    }
  }

  public function login($email, $password)
  {
    $user = $this->getUserByEmail($email);

    if ($user && $this->validatePassword($password, $user['password_hash'])) {
      if (!$user['is_verified']) {
        return ['error' => 'Account not verified'];
      }

      return [
        'token' => $this->generateJWT($user['id'], $user['email'], $user['role_id']),
        'user' => [
          'id' => $user['id'],
          'email' => $user['email'],
          'role' => $user['role_name']
        ]
      ];
    }

    return false;
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
