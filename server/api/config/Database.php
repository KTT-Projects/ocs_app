<?php
class Database
{
  private $host = "";
  private $db_name = "";
  private $username = "";
  private $password = "";
  private $conn;

  public function getConnection()
  {
    $this->conn = null;

    try {
      // Test the connection first
      $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name;
      try {
        $this->conn = new PDO($dsn, $this->username, $this->password);
        $this->conn->exec("set names utf8mb4");
        $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Test query to verify connection and permissions
        $test = $this->conn->query("SELECT 1");
        if (!$test) {
          throw new PDOException("Database connection test failed");
        }
      } catch (PDOException $e) {
        error_log("Detailed database connection error: " . $e->getMessage());
        error_log("DSN (without credentials): " . $dsn);
        error_log("MySQL error code: " . $e->errorInfo[1] ?? 'unknown');
        throw new PDOException("Database connection failed: " . $e->getMessage());
      }
    } catch (PDOException $e) {
      error_log("Database Connection Error: " . $e->getMessage());
      throw new PDOException("Database connection failed. Please try again later.");
    }

    return $this->conn;
  }
}
