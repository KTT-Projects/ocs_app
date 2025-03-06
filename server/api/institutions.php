<?php
require_once __DIR__ . '/config/Database.php';
require_once __DIR__ . '/config/Response.php';

// Set headers
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

// Create database connection
$database = new Database();
$conn = $database->getConnection();

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit(0);
}

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
  case 'GET':
    // Check if specific ID is requested
    $id = isset($_GET['id']) ? $_GET['id'] : null;

    if ($id) {
      // Get specific institution
      $query = "SELECT * FROM educational_institutions WHERE id = :id";
      $stmt = $conn->prepare($query);
      $stmt->bindParam(':id', $id);
      $stmt->execute();

      if ($stmt->rowCount() > 0) {
        $institution = $stmt->fetch(PDO::FETCH_ASSOC);
        Response::success($institution);
      } else {
        Response::error("Institution not found", 404);
      }
    } else {
      // Get all institutions
      $query = "SELECT * FROM educational_institutions ORDER BY name";
      $stmt = $conn->prepare($query);
      $stmt->execute();

      $institutions = $stmt->fetchAll(PDO::FETCH_ASSOC);
      Response::success($institutions);
    }
    break;

  case 'POST':
    // Create new institution
    $data = json_decode(file_get_contents("php://input"));

    if (!isset($data->name) || !isset($data->email_domain)) {
      Response::error("Missing required fields", 400);
    }

    $query = "INSERT INTO educational_institutions (name, email_domain) VALUES (:name, :email_domain)";
    $stmt = $conn->prepare($query);

    $stmt->bindParam(':name', $data->name);
    $stmt->bindParam(':email_domain', $data->email_domain);

    if ($stmt->execute()) {
      $institution = [
        'id' => $conn->lastInsertId(),
        'name' => $data->name,
        'email_domain' => $data->email_domain
      ];
      Response::success($institution, "Institution created successfully");
    } else {
      Response::error("Failed to create institution");
    }
    break;

  case 'PUT':
    // Update existing institution
    $data = json_decode(file_get_contents("php://input"));

    if (!isset($data->id) || (!isset($data->name) && !isset($data->email_domain))) {
      Response::error("Missing required fields", 400);
    }

    $updateFields = [];
    $params = [':id' => $data->id];

    if (isset($data->name)) {
      $updateFields[] = "name = :name";
      $params[':name'] = $data->name;
    }

    if (isset($data->email_domain)) {
      $updateFields[] = "email_domain = :email_domain";
      $params[':email_domain'] = $data->email_domain;
    }

    $query = "UPDATE educational_institutions SET " . implode(", ", $updateFields) . " WHERE id = :id";
    $stmt = $conn->prepare($query);

    if ($stmt->execute($params)) {
      // Get updated institution
      $query = "SELECT * FROM educational_institutions WHERE id = :id";
      $stmt = $conn->prepare($query);
      $stmt->bindParam(':id', $data->id);
      $stmt->execute();

      $institution = $stmt->fetch(PDO::FETCH_ASSOC);
      Response::success($institution, "Institution updated successfully");
    } else {
      Response::error("Failed to update institution");
    }
    break;

  case 'DELETE':
    // Delete institution
    $data = json_decode(file_get_contents("php://input"));

    if (!isset($data->id)) {
      Response::error("Missing institution ID", 400);
    }

    // Check if institution is being used by any users
    $query = "SELECT COUNT(*) as count FROM users WHERE institution_id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $data->id);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result['count'] > 0) {
      Response::error("Cannot delete institution as it is being used by users", 400);
    }

    $query = "DELETE FROM educational_institutions WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $data->id);

    if ($stmt->execute()) {
      Response::success(null, "Institution deleted successfully");
    } else {
      Response::error("Failed to delete institution");
    }
    break;

  default:
    Response::error("Method not allowed", 405);
    break;
}
