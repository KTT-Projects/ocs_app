<?php
class Database
{
  private $host = "mysql90.conoha.ne.jp";
  private $db_name = "on294_ocs";
  private $username = "on294_ocs";
  private $password = "ktdevsPro406$";
  private $conn;

  public function getConnection()
  {
    $this->conn = null;

    try {
      $this->conn = new PDO(
        "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
        $this->username,
        $this->password
      );
      $this->conn->exec("set names utf8mb4");
      $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
      error_log("Database Connection Error: " . $e->getMessage());
      throw new PDOException("Database connection failed. Please try again later.");
    }

    return $this->conn;
  }
}
