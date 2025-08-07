<?php
// CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS");
header("Access-Control-Allow-Credentials: true");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit();
}

require_once 'config/Database.php';
require_once 'config/Auth.php';
require_once 'config/Response.php';

class VolunteerController
{
  private $db;
  private $auth;
  private $conn;

  public function __construct()
  {
    $this->db = new Database();
    $this->conn = $this->db->getConnection();
    $this->auth = new Auth($this->conn);
  }

  public function handleRequest()
  {
    $method = $_SERVER['REQUEST_METHOD'];
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    try {
      // Get authorization header
      $headers = getallheaders();
      $userId = null;
      if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
        $decoded = $this->validateJWT($token);
        if (!$decoded) {
          Response::error('Invalid or expired token', 401);
          return;
        }
        $userId = intval($decoded['user_id']);
      } elseif (!($method === 'GET' && $action === 'list')) {
        Response::error('Authorization header is required', 401);
        return;
      }

      switch ($method) {
        case 'GET':
          if ($action === 'list') {
            $this->getVolunteerOpportunities($userId);
          } else if ($action === 'my_opportunities') {
            $this->getMyVolunteerOpportunities($userId);
          } else if ($action === 'get') {
            $this->getVolunteerOpportunity($userId);
          } else if ($action === 'participants') {
            $this->getVolunteerParticipants($userId);
          } else if ($action === 'certificate') {
            $this->downloadCertificate($userId);
          }
          break;
        case 'POST':
          if ($action === 'create') {
            $this->createVolunteerOpportunity($userId);
          } else if ($action === 'apply') {
            $this->applyToOpportunity($userId);
          } else if ($action === 'cancel') {
            $this->cancelApplication($userId);
          } else if ($action === 'update_participant') {
            $this->updateParticipantStatus($userId);
          }
          break;
        case 'PATCH':
          if ($action === 'update') {
            $this->updateVolunteerOpportunity($userId);
          }
          break;
        default:
          Response::error('Method not allowed', 405);
      }
    } catch (Exception $e) {
      Response::error($e->getMessage(), 500);
    }
  }

  private function validateJWT($token)
  {
    try {
      // Simple JWT validation - in production use a proper JWT library
      $parts = explode('.', $token);
      if (count($parts) !== 3) {
        return false;
      }
      
      $payload = json_decode(base64_decode($parts[1]), true);
      if (!$payload || !isset($payload['user_id']) || !isset($payload['exp'])) {
        return false;
      }
      
      if ($payload['exp'] < time()) {
        return false;
      }
      
      return $payload;
    } catch (Exception $e) {
      return false;
    }
  }

  public function updateVolunteerOpportunity($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['id'])) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      $opportunityId = intval($input['id']);

      // Check if user is the organizer
      $checkQuery = "SELECT organizer_id FROM volunteer_opportunities WHERE id = ?";
      $checkStmt = $this->conn->prepare($checkQuery);
      $checkStmt->execute([$opportunityId]);
      $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);

      if (!$opportunity || $opportunity['organizer_id'] != $userId) {
        Response::error('Permission denied', 403);
        return;
      }

      $updateFields = [];
      $params = [];

      if (isset($input['title'])) {
        $updateFields[] = "title = ?";
        $params[] = trim($input['title']);
      }

      if (isset($input['description'])) {
        $updateFields[] = "description = ?";
        $params[] = trim($input['description']);
      }

      if (isset($input['location'])) {
        $updateFields[] = "location = ?";
        $params[] = trim($input['location']);
      }

      if (isset($input['status'])) {
        $validStatuses = ['open', 'filled', 'completed', 'cancelled'];
        if (in_array($input['status'], $validStatuses)) {
          $updateFields[] = "status = ?";
          $params[] = $input['status'];
        }
      }

      if (isset($input['required_participants'])) {
        $updateFields[] = "required_participants = ?";
        $params[] = $input['required_participants'] ? intval($input['required_participants']) : null;
      }

      if (empty($updateFields)) {
        Response::error('No fields to update', 400);
        return;
      }

      $updateFields[] = "updated_at = CURRENT_TIMESTAMP";
      $params[] = $opportunityId;

      $query = "UPDATE volunteer_opportunities SET " . implode(', ', $updateFields) . " WHERE id = ?";
      $stmt = $this->conn->prepare($query);
      $result = $stmt->execute($params);

      if ($result) {
        Response::success(['message' => 'Volunteer opportunity updated successfully']);
      } else {
        Response::error('Failed to update volunteer opportunity', 500);
      }
    } catch (Exception $e) {
      Response::error('Failed to update volunteer opportunity: ' . $e->getMessage(), 500);
    }
  }

  public function getVolunteerOpportunities($userId)
  {
    try {
      $status = isset($_GET['status']) ? $_GET['status'] : null;
      $sort = isset($_GET['sort']) ? $_GET['sort'] : 'newest';
      $search = isset($_GET['search']) ? $_GET['search'] : null;

      $query = "
        SELECT 
          vo.*,
          up.display_name as organizer_name,
          up.avatar_url as organizer_avatar,
          COUNT(DISTINCT vp.user_id) as participant_count,
          CASE WHEN vp_user.user_id IS NOT NULL THEN 1 ELSE 0 END as is_participant,
          vp_user.status as participant_status,
          vp_user.hours_completed,
          vp_user.certificate_issued
        FROM volunteer_opportunities vo
        LEFT JOIN user_profiles up ON vo.organizer_id = up.user_id
        LEFT JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.status != 'cancelled'
        LEFT JOIN volunteer_participants vp_user ON vo.id = vp_user.opportunity_id AND vp_user.user_id = ?
        WHERE 1=1
      ";

      $params = [$userId];

      if ($status) {
        $query .= " AND vo.status = ?";
        $params[] = $status;
      }

      if ($search) {
        $query .= " AND (vo.title LIKE ? OR vo.description LIKE ? OR vo.location LIKE ?)";
        $searchParam = "%$search%";
        $params[] = $searchParam;
        $params[] = $searchParam;
        $params[] = $searchParam;
      }

      $query .= " GROUP BY vo.id";

      // Add sorting
      switch ($sort) {
        case 'oldest':
          $query .= " ORDER BY vo.created_at ASC";
          break;
        case 'upcoming':
          $query .= " ORDER BY vo.start_date ASC";
          break;
        case 'newest':
        default:
          $query .= " ORDER BY vo.created_at DESC";
          break;
      }

      $stmt = $this->conn->prepare($query);
      $stmt->execute($params);
      $opportunities = $stmt->fetchAll(PDO::FETCH_ASSOC);

      Response::success($opportunities);
    } catch (Exception $e) {
      Response::error('Failed to fetch volunteer opportunities: ' . $e->getMessage(), 500);
    }
  }

  public function getMyVolunteerOpportunities($userId)
  {
    try {
      $status = isset($_GET['status']) ? $_GET['status'] : null;

      $query = "
        SELECT 
          vo.*,
          up.display_name as organizer_name,
          up.avatar_url as organizer_avatar,
          COUNT(DISTINCT vp_all.user_id) as participant_count,
          1 as is_participant,
          vp.status as participant_status,
          vp.hours_completed,
          vp.certificate_issued
        FROM volunteer_opportunities vo
        LEFT JOIN user_profiles up ON vo.organizer_id = up.user_id
        INNER JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.user_id = ?
        LEFT JOIN volunteer_participants vp_all ON vo.id = vp_all.opportunity_id AND vp_all.status != 'cancelled'
        WHERE 1=1
      ";

      $params = [$userId];

      if ($status) {
        $query .= " AND vp.status = ?";
        $params[] = $status;
      }

      $query .= " GROUP BY vo.id ORDER BY vp.created_at DESC";

      $stmt = $this->conn->prepare($query);
      $stmt->execute($params);
      $opportunities = $stmt->fetchAll(PDO::FETCH_ASSOC);

      Response::success($opportunities);
    } catch (Exception $e) {
      Response::error('Failed to fetch my volunteer opportunities: ' . $e->getMessage(), 500);
    }
  }

  public function getVolunteerOpportunity($userId)
  {
    try {
      $id = isset($_GET['id']) ? intval($_GET['id']) : 0;
      if (!$id) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      $query = "
        SELECT 
          vo.*,
          up.display_name as organizer_name,
          up.avatar_url as organizer_avatar,
          COUNT(DISTINCT vp.user_id) as participant_count,
          CASE WHEN vp_user.user_id IS NOT NULL THEN 1 ELSE 0 END as is_participant,
          vp_user.status as participant_status,
          vp_user.hours_completed,
          vp_user.certificate_issued
        FROM volunteer_opportunities vo
        LEFT JOIN user_profiles up ON vo.organizer_id = up.user_id
        LEFT JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.status != 'cancelled'
        LEFT JOIN volunteer_participants vp_user ON vo.id = vp_user.opportunity_id AND vp_user.user_id = ?
        WHERE vo.id = ?
        GROUP BY vo.id
      ";

      $stmt = $this->conn->prepare($query);
      $stmt->execute([$userId, $id]);
      $opportunity = $stmt->fetch(PDO::FETCH_ASSOC);

      if (!$opportunity) {
        Response::error('Opportunity not found', 404);
        return;
      }

      Response::success($opportunity);
    } catch (Exception $e) {
      Response::error('Failed to fetch volunteer opportunity: ' . $e->getMessage(), 500);
    }
  }

  public function createVolunteerOpportunity($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['title']) || !isset($input['description']) || 
          !isset($input['location']) || !isset($input['date']) || 
          !isset($input['start_time']) || !isset($input['end_time'])) {
        Response::error('Missing required fields', 400);
        return;
      }

      $title = trim($input['title']);
      $description = trim($input['description']);
      $location = trim($input['location']);
      $date = $input['date'];
      $startTime = $input['start_time'];
      $endTime = $input['end_time'];
      $requiredParticipants = isset($input['required_participants']) ? intval($input['required_participants']) : null;

      if (empty($title) || empty($description) || empty($location)) {
        Response::error('Title, description, and location cannot be empty', 400);
        return;
      }

      // Validate date and times
      $dateTime = DateTime::createFromFormat('Y-m-d', $date);
      
      if (!$dateTime) {
        Response::error('Invalid date format', 400);
        return;
      }

      // Validate time format (HH:MM:SS)
      if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/', $startTime) ||
          !preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/', $endTime)) {
        Response::error('Invalid time format', 400);
        return;
      }

      // Check if start time is before end time
      if (strtotime($startTime) >= strtotime($endTime)) {
        Response::error('End time must be after start time', 400);
        return;
      }

      $query = "
        INSERT INTO volunteer_opportunities 
        (title, description, organizer_id, location, date, start_time, end_time, required_participants, status) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'open')
      ";

      $stmt = $this->conn->prepare($query);
      $result = $stmt->execute([
        $title, $description, $userId, $location, $date, $startTime, $endTime, $requiredParticipants
      ]);

      if ($result) {
        $opportunityId = $this->conn->lastInsertId();

        // Automatically add the creator as a participant with approved status
        try {
          $participantStmt = $this->conn->prepare(
            "INSERT INTO volunteer_participants (opportunity_id, user_id, status) VALUES (?, ?, 'approved')"
          );
          $participantStmt->execute([$opportunityId, $userId]);
        } catch (Exception $e) {
          // If adding the participant fails, log the error but continue
          error_log('Failed to add organizer as participant: ' . $e->getMessage());
        }

        Response::success(['id' => $opportunityId, 'message' => 'Volunteer opportunity created successfully']);
      } else {
        Response::error('Failed to create volunteer opportunity', 500);
      }
    } catch (Exception $e) {
      Response::error('Failed to create volunteer opportunity: ' . $e->getMessage(), 500);
    }
  }

  public function applyToOpportunity($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['opportunity_id'])) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      $opportunityId = intval($input['opportunity_id']);

      // Check if opportunity exists and is open
      $checkQuery = "SELECT status, required_participants FROM volunteer_opportunities WHERE id = ?";
      $checkStmt = $this->conn->prepare($checkQuery);
      $checkStmt->execute([$opportunityId]);
      $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);

      if (!$opportunity) {
        Response::error('Opportunity not found', 404);
        return;
      }

      if ($opportunity['status'] !== 'open') {
        Response::error('This opportunity is no longer accepting applications', 400);
        return;
      }

      // Check if user already applied
      $existingQuery = "SELECT status FROM volunteer_participants WHERE opportunity_id = ? AND user_id = ?";
      $existingStmt = $this->conn->prepare($existingQuery);
      $existingStmt->execute([$opportunityId, $userId]);
      $existing = $existingStmt->fetch(PDO::FETCH_ASSOC);

      if ($existing) {
        if ($existing['status'] !== 'cancelled') {
          Response::error('You have already applied to this opportunity', 400);
          return;
        }
        // Update cancelled application
        $updateQuery = "UPDATE volunteer_participants SET status = 'applied', updated_at = CURRENT_TIMESTAMP WHERE opportunity_id = ? AND user_id = ?";
        $updateStmt = $this->conn->prepare($updateQuery);
        $result = $updateStmt->execute([$opportunityId, $userId]);
      } else {
        // Check participant limit
        if ($opportunity['required_participants']) {
          $countQuery = "SELECT COUNT(*) as count FROM volunteer_participants WHERE opportunity_id = ? AND status != 'cancelled'";
          $countStmt = $this->conn->prepare($countQuery);
          $countStmt->execute([$opportunityId]);
          $count = $countStmt->fetch(PDO::FETCH_ASSOC)['count'];

          if ($count >= $opportunity['required_participants']) {
            Response::error('This opportunity is full', 400);
            return;
          }
        }

        // Create new application
        $insertQuery = "INSERT INTO volunteer_participants (opportunity_id, user_id, status) VALUES (?, ?, 'applied')";
        $insertStmt = $this->conn->prepare($insertQuery);
        $result = $insertStmt->execute([$opportunityId, $userId]);
      }

      if ($result) {
        Response::success(['message' => 'Application submitted successfully']);
      } else {
        Response::error('Failed to submit application', 500);
      }
    } catch (Exception $e) {
      Response::error('Failed to apply to opportunity: ' . $e->getMessage(), 500);
    }
  }

  public function cancelApplication($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['opportunity_id'])) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      $opportunityId = intval($input['opportunity_id']);

      // Check if application exists
      $checkQuery = "SELECT status FROM volunteer_participants WHERE opportunity_id = ? AND user_id = ?";
      $checkStmt = $this->conn->prepare($checkQuery);
      $checkStmt->execute([$opportunityId, $userId]);
      $participation = $checkStmt->fetch(PDO::FETCH_ASSOC);

      if (!$participation) {
        Response::error('No application found for this opportunity', 404);
        return;
      }

      if ($participation['status'] === 'completed') {
        Response::error('Cannot cancel completed volunteer work', 400);
        return;
      }

      // Update status to cancelled
      $updateQuery = "UPDATE volunteer_participants SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP WHERE opportunity_id = ? AND user_id = ?";
      $updateStmt = $this->conn->prepare($updateQuery);
      $result = $updateStmt->execute([$opportunityId, $userId]);

      if ($result) {
        Response::success(['message' => 'Application cancelled successfully']);
      } else {
        Response::error('Failed to cancel application', 500);
      }
    } catch (Exception $e) {
      Response::error('Failed to cancel application: ' . $e->getMessage(), 500);
    }
  }

  public function getVolunteerParticipants($userId)
  {
    try {
      $opportunityId = isset($_GET['opportunity_id']) ? intval($_GET['opportunity_id']) : 0;
      if (!$opportunityId) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      // Check if user has permission to view participants (organizer or participant)
      $permissionQuery = "
        SELECT COUNT(*) as count 
        FROM volunteer_opportunities vo 
        LEFT JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.user_id = ?
        WHERE vo.id = ? AND (vo.organizer_id = ? OR vp.user_id IS NOT NULL)
      ";
      $permissionStmt = $this->conn->prepare($permissionQuery);
      $permissionStmt->execute([$userId, $opportunityId, $userId]);
      $hasPermission = $permissionStmt->fetch(PDO::FETCH_ASSOC)['count'] > 0;

      if (!$hasPermission) {
        Response::error('Permission denied', 403);
        return;
      }

      $query = "
        SELECT 
          vp.*,
          up.display_name as user_name,
          up.avatar_url as user_avatar,
          CONCAT('Grade ', u.grade) as user_grade,
          ei.name as user_institution
        FROM volunteer_participants vp
        LEFT JOIN user_profiles up ON vp.user_id = up.user_id
        LEFT JOIN users u ON vp.user_id = u.id
        LEFT JOIN educational_institutions ei ON u.institution_id = ei.id
        WHERE vp.opportunity_id = ? AND vp.status != 'cancelled'
        ORDER BY vp.created_at ASC
      ";

      $stmt = $this->conn->prepare($query);
      $stmt->execute([$opportunityId]);
      $participants = $stmt->fetchAll(PDO::FETCH_ASSOC);

      Response::success($participants);
    } catch (Exception $e) {
      Response::error('Failed to fetch participants: ' . $e->getMessage(), 500);
    }
  }

  public function updateParticipantStatus($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['opportunity_id']) || !isset($input['user_id']) || !isset($input['status'])) {
        Response::error('Opportunity ID, user ID, and status are required', 400);
        return;
      }

      $opportunityId = intval($input['opportunity_id']);
      $targetUserId = intval($input['user_id']);
      $status = $input['status'];
      $hoursCompleted = isset($input['hours_completed']) ? floatval($input['hours_completed']) : null;

      // Check if current user is the organizer
      $checkQuery = "SELECT organizer_id FROM volunteer_opportunities WHERE id = ?";
      $checkStmt = $this->conn->prepare($checkQuery);
      $checkStmt->execute([$opportunityId]);
      $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);

      if (!$opportunity || $opportunity['organizer_id'] != $userId) {
        Response::error('Permission denied', 403);
        return;
      }

      // Validate status
      $validStatuses = ['applied', 'approved', 'completed', 'cancelled'];
      if (!in_array($status, $validStatuses)) {
        Response::error('Invalid status', 400);
        return;
      }

      // Update participant status
      $updateQuery = "
        UPDATE volunteer_participants 
        SET status = ?, hours_completed = ?, certificate_issued = ?, updated_at = CURRENT_TIMESTAMP 
        WHERE opportunity_id = ? AND user_id = ?
      ";
      
      $certificateIssued = ($status === 'completed' && $hoursCompleted > 0) ? 1 : 0;
      
      $updateStmt = $this->conn->prepare($updateQuery);
      $result = $updateStmt->execute([$status, $hoursCompleted, $certificateIssued, $opportunityId, $targetUserId]);

      if ($result) {
        Response::success(['message' => 'Participant status updated successfully']);
      } else {
        Response::error('Failed to update participant status', 500);
      }
    } catch (Exception $e) {
      Response::error('Failed to update participant status: ' . $e->getMessage(), 500);
    }
  }

  public function downloadCertificate($userId)
  {
    try {
      $opportunityId = isset($_GET['opportunity_id']) ? intval($_GET['opportunity_id']) : 0;
      if (!$opportunityId) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      // Check if user completed this opportunity and certificate is issued
      $checkQuery = "
        SELECT vp.*, vo.title, vo.description, vo.start_date, vo.end_date, up.display_name
        FROM volunteer_participants vp
        JOIN volunteer_opportunities vo ON vp.opportunity_id = vo.id
        JOIN user_profiles up ON vp.user_id = up.user_id
        WHERE vp.opportunity_id = ? AND vp.user_id = ? AND vp.status = 'completed' AND vp.certificate_issued = 1
      ";
      
      $checkStmt = $this->conn->prepare($checkQuery);
      $checkStmt->execute([$opportunityId, $userId]);
      $participation = $checkStmt->fetch(PDO::FETCH_ASSOC);

      if (!$participation) {
        Response::error('Certificate not available', 404);
        return;
      }

      // Generate simple certificate content (in a real app, you'd use a PDF library)
      $certificateContent = "
        VOLUNTEER CERTIFICATE

        This is to certify that
        
        {$participation['display_name']}
        
        has successfully completed volunteer work for:
        {$participation['title']}
        
        Duration: {$participation['start_date']} to {$participation['end_date']}
        Hours Completed: {$participation['hours_completed']}
        
        Date of Completion: {$participation['updated_at']}
      ";

      // In a real implementation, you would generate a proper PDF certificate
      header('Content-Type: application/pdf');
      header('Content-Disposition: attachment; filename="volunteer_certificate_' . $opportunityId . '.txt"');
      echo $certificateContent;
      exit;

    } catch (Exception $e) {
      Response::error('Failed to generate certificate: ' . $e->getMessage(), 500);
    }
  }
}

// Create controller instance and handle request
$controller = new VolunteerController();
$controller->handleRequest();
?>
