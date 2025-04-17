<?php
class Security
{
  // Rate limiting settings
  private $max_requests = 100;  // Maximum requests per window
  private $time_window = 3600;  // Time window in seconds (1 hour)
  private $conn;

  public function __construct($db)
  {
    $this->conn = $db;
    $this->createRateLimitTable();
  }

  private function createRateLimitTable()
  {
    try {
      $query = "CREATE TABLE IF NOT EXISTS rate_limits (
              id INT AUTO_INCREMENT PRIMARY KEY,
              ip_address VARCHAR(45) NOT NULL,
              endpoint VARCHAR(255) NOT NULL,
              request_count INT DEFAULT 1,
              window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              INDEX idx_ip_endpoint (ip_address, endpoint)
          )";
      $this->conn->exec($query);
    } catch (PDOException $e) {
      error_log("Failed to create rate_limits table: " . $e->getMessage());
      // Don't throw the error, as the table might already exist
      // or we might have read-only permissions
    }
  }

  public function checkRateLimit($ip_address, $endpoint)
  {
    // Clean up old records
    $cleanup = "DELETE FROM rate_limits WHERE window_start < DATE_SUB(NOW(), INTERVAL 1 HOUR)";
    $this->conn->exec($cleanup);

    // Check existing rate limit
    $query = "SELECT request_count, window_start FROM rate_limits
                  WHERE ip_address = ? AND endpoint = ?";
    $stmt = $this->conn->prepare($query);
    $stmt->execute([$ip_address, $endpoint]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
      if ($result['request_count'] >= $this->max_requests) {
        return false; // Rate limit exceeded
      }

      // Update counter
      $update = "UPDATE rate_limits SET request_count = request_count + 1
                       WHERE ip_address = ? AND endpoint = ?";
      $stmt = $this->conn->prepare($update);
      $stmt->execute([$ip_address, $endpoint]);
    } else {
      // Create new rate limit record
      $insert = "INSERT INTO rate_limits (ip_address, endpoint) VALUES (?, ?)";
      $stmt = $this->conn->prepare($insert);
      $stmt->execute([$ip_address, $endpoint]);
    }

    return true;
  }

  public function sanitizeInput($input)
  {
    if (is_array($input)) {
      return array_map([$this, 'sanitizeInput'], $input);
    }
    return htmlspecialchars(strip_tags($input), ENT_QUOTES, 'UTF-8');
  }

  public function validateStudentId($student_id)
  {
    // Only allow alphanumeric characters and common separators
    return preg_match('/^[A-Za-z0-9._-]+$/', $student_id);
  }

  public static function generateToken($length = 32)
  {
    // Generate a secure random token
    $token = bin2hex(random_bytes($length / 2));
    return $token;
  }

  public function getClientIp()
  {
    // Get IP address considering proxies
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
      return $_SERVER['HTTP_X_FORWARDED_FOR'];
    }
    return $_SERVER['REMOTE_ADDR'];
  }

  public function corsHeaders()
  {
    // Adjust these values based on your requirements
    // Allow requests from any origin during development
    $origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '*';
    header("Access-Control-Allow-Origin: $origin");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Max-Age: 86400'); // 24 hours
  }
}
