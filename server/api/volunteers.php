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
require_once 'config/PushNotificationService.php';

class VolunteerController
{
  private $db;
  private $auth;
  private $conn;
  private $push;
  private $allowedRoles = ['member','coordinator','admin'];
  private $allowedOpportunityTypes = ['volunteer','event'];

  public function __construct()
  {
    $this->db = new Database();
    $this->conn = $this->db->getConnection();
    $this->auth = new Auth($this->conn);
    $this->push = new PushNotificationService($this->conn);
  }

  private function userHasAnyRole($userId, $opportunityId, $roles)
  {
    try {
      // Organizer is always considered admin
      $q = "SELECT CASE WHEN vo.organizer_id = ? THEN 'admin' ELSE vp.role END as role
            FROM volunteer_opportunities vo
            LEFT JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.user_id = ?
            WHERE vo.id = ?";
      $s = $this->conn->prepare($q);
      $s->execute([$userId, $userId, $opportunityId]);
      $row = $s->fetch(PDO::FETCH_ASSOC);
      if (!$row) return false;
      $role = $row['role'] ?? 'member';
      return in_array($role, $roles);
    } catch (Exception $e) {
      return false;
    }
  }

  private function getRequestedOpportunityType()
  {
    $type = $_GET['type'] ?? $_GET['opportunity_type'] ?? 'volunteer';
    return in_array($type, $this->allowedOpportunityTypes) ? $type : 'volunteer';
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
        $decoded = $this->auth->decodeJWT($token);
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
          } else if ($action === 'attachments') {
            $this->getVolunteerAttachments($userId);
          } else if ($action === 'reflections') {
            $this->getVolunteerReflections($userId);
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
          } else if ($action === 'update_role') {
            $this->updateParticipantRole($userId);
          } else if ($action === 'upload_attachment') {
            $this->uploadVolunteerAttachment($userId);
          } else if ($action === 'delete_attachment') {
            $this->deleteVolunteerAttachment($userId);
          } else if ($action === 'create_reflection') {
            $this->createVolunteerReflection($userId);
          } else if ($action === 'upload_reflection_image') {
            $this->uploadReflectionImage($userId);
          } else if ($action === 'delete_reflection_image') {
            $this->deleteReflectionImage($userId);
          }
          break;
        case 'PATCH':
          if ($action === 'update') {
            $this->updateVolunteerOpportunity($userId);
          } else if ($action === 'update_reflection') {
            $this->updateVolunteerReflection($userId);
          }
          break;
        default:
          Response::error('Method not allowed', 405);
      }
    } catch (Exception $e) {
      Response::error($e->getMessage(), 500);
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

  // Check if user is the organizer or has admin role
      $checkQuery = "SELECT organizer_id FROM volunteer_opportunities WHERE id = ?";
      $checkStmt = $this->conn->prepare($checkQuery);
      $checkStmt->execute([$opportunityId]);
      $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);

  if (!$opportunity || !($opportunity['organizer_id'] == $userId || $this->userHasAnyRole($userId, $opportunityId, ['admin']))) {
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

      // optional: date and time updates
      if (isset($input['date'])) {
        $date = $input['date'];
        $dateTime = DateTime::createFromFormat('Y-m-d', $date);
        if (!$dateTime) {
          Response::error('Invalid date format', 400);
          return;
        }
        $updateFields[] = "date = ?";
        $params[] = $date;
      }

      if (isset($input['start_time'])) {
        if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/', $input['start_time'])) {
          Response::error('Invalid time format', 400);
          return;
        }
        $updateFields[] = "start_time = ?";
        $params[] = $input['start_time'];
      }
      if (isset($input['end_time'])) {
        if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/', $input['end_time'])) {
          Response::error('Invalid time format', 400);
          return;
        }
        $updateFields[] = "end_time = ?";
        $params[] = $input['end_time'];
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
      $opportunityType = $this->getRequestedOpportunityType();

      $query = "
        SELECT 
          vo.*,
          up.display_name as organizer_name,
          up.avatar_url as organizer_avatar,
          COUNT(DISTINCT vp.user_id) as participant_count,
          CASE 
            WHEN vo.required_participants IS NULL THEN 0
            WHEN COUNT(DISTINCT vp.user_id) >= vo.required_participants THEN 1
            ELSE 0
          END as is_full,
          CASE 
            WHEN vo.required_participants IS NULL THEN NULL
            ELSE GREATEST(vo.required_participants - COUNT(DISTINCT vp.user_id), 0)
          END as spots_remaining,
          COUNT(DISTINCT va.id) as attachment_count,
          (
            SELECT va2.file_url 
            FROM volunteer_attachments va2 
            WHERE va2.opportunity_id = vo.id AND va2.mime_type LIKE 'image/%' 
            ORDER BY va2.created_at DESC 
            LIMIT 1
          ) as cover_attachment_url,
          (SELECT COUNT(*) FROM volunteer_reflections vr WHERE vr.opportunity_id = vo.id) as reflection_count,
          (
            SELECT vr.id
            FROM volunteer_reflections vr
            WHERE vr.opportunity_id = vo.id
            ORDER BY vr.created_at DESC
            LIMIT 1
          ) as latest_reflection_id,
          (
            SELECT vr.created_at 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_at,
          (
            SELECT vr.title 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_title,
          (
            SELECT SUBSTRING(vr.body, 1, 160) 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_excerpt,
          CASE WHEN vp_user.user_id IS NOT NULL THEN 1 ELSE 0 END as is_participant,
          vp_user.status as participant_status,
          vp_user.hours_completed,
          vp_user.certificate_issued,
          vp_user.role as participant_role
        FROM volunteer_opportunities vo
        LEFT JOIN user_profiles up ON vo.organizer_id = up.user_id
        LEFT JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.status != 'cancelled'
        LEFT JOIN volunteer_attachments va ON vo.id = va.opportunity_id
        LEFT JOIN volunteer_participants vp_user ON vo.id = vp_user.opportunity_id AND vp_user.user_id = ?
        WHERE vo.opportunity_type = ?
      ";

      $params = [$userId, $opportunityType];

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
      $query .= " ORDER BY vo.date ASC, vo.start_time ASC";
          break;
        case 'newest':
        default:
          $query .= " ORDER BY vo.created_at DESC";
          break;
      }

      $stmt = $this->conn->prepare($query);
      $stmt->execute($params);
      $opportunities = $stmt->fetchAll(PDO::FETCH_ASSOC);

      foreach ($opportunities as &$opportunity) {
        $this->attachLatestReflectionImages($opportunity);
      }

      Response::success($opportunities);
    } catch (Exception $e) {
      Response::error('Failed to fetch volunteer opportunities: ' . $e->getMessage(), 500);
    }
  }

  public function getMyVolunteerOpportunities($userId)
  {
    try {
      $status = isset($_GET['status']) ? $_GET['status'] : null;
      $opportunityType = $this->getRequestedOpportunityType();

      $query = "
        SELECT 
          vo.*,
          up.display_name as organizer_name,
          up.avatar_url as organizer_avatar,
          COUNT(DISTINCT vp_all.user_id) as participant_count,
          CASE 
            WHEN vo.required_participants IS NULL THEN 0
            WHEN COUNT(DISTINCT vp_all.user_id) >= vo.required_participants THEN 1
            ELSE 0
          END as is_full,
          CASE 
            WHEN vo.required_participants IS NULL THEN NULL
            ELSE GREATEST(vo.required_participants - COUNT(DISTINCT vp_all.user_id), 0)
          END as spots_remaining,
          COUNT(DISTINCT va.id) as attachment_count,
          (
            SELECT va2.file_url 
            FROM volunteer_attachments va2 
            WHERE va2.opportunity_id = vo.id AND va2.mime_type LIKE 'image/%' 
            ORDER BY va2.created_at DESC 
            LIMIT 1
          ) as cover_attachment_url,
          (SELECT COUNT(*) FROM volunteer_reflections vr WHERE vr.opportunity_id = vo.id) as reflection_count,
          (
            SELECT vr.id
            FROM volunteer_reflections vr
            WHERE vr.opportunity_id = vo.id
            ORDER BY vr.created_at DESC
            LIMIT 1
          ) as latest_reflection_id,
          (
            SELECT vr.created_at 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_at,
          (
            SELECT vr.title 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_title,
          (
            SELECT SUBSTRING(vr.body, 1, 160) 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_excerpt,
          1 as is_participant,
          vp.status as participant_status,
          vp.hours_completed,
          vp.certificate_issued,
          vp.role as participant_role
        FROM volunteer_opportunities vo
        LEFT JOIN user_profiles up ON vo.organizer_id = up.user_id
        INNER JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.user_id = ?
        LEFT JOIN volunteer_participants vp_all ON vo.id = vp_all.opportunity_id AND vp_all.status != 'cancelled'
        LEFT JOIN volunteer_attachments va ON vo.id = va.opportunity_id
        WHERE vo.opportunity_type = ?
      ";

      $params = [$userId, $opportunityType];

      if ($status) {
        $query .= " AND vp.status = ?";
        $params[] = $status;
      }

      $query .= " GROUP BY vo.id ORDER BY vp.created_at DESC";

      $stmt = $this->conn->prepare($query);
      $stmt->execute($params);
      $opportunities = $stmt->fetchAll(PDO::FETCH_ASSOC);

      foreach ($opportunities as &$opportunity) {
        $this->attachLatestReflectionImages($opportunity);
      }

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
          CASE 
            WHEN vo.required_participants IS NULL THEN 0
            WHEN COUNT(DISTINCT vp.user_id) >= vo.required_participants THEN 1
            ELSE 0
          END as is_full,
          CASE 
            WHEN vo.required_participants IS NULL THEN NULL
            ELSE GREATEST(vo.required_participants - COUNT(DISTINCT vp.user_id), 0)
          END as spots_remaining,
          COUNT(DISTINCT va.id) as attachment_count,
          (
            SELECT va2.file_url 
            FROM volunteer_attachments va2 
            WHERE va2.opportunity_id = vo.id AND va2.mime_type LIKE 'image/%' 
            ORDER BY va2.created_at DESC 
            LIMIT 1
          ) as cover_attachment_url,
          (SELECT COUNT(*) FROM volunteer_reflections vr WHERE vr.opportunity_id = vo.id) as reflection_count,
          (
            SELECT vr.id
            FROM volunteer_reflections vr
            WHERE vr.opportunity_id = vo.id
            ORDER BY vr.created_at DESC
            LIMIT 1
          ) as latest_reflection_id,
          (
            SELECT vr.created_at 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_at,
          (
            SELECT vr.title 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_title,
          (
            SELECT SUBSTRING(vr.body, 1, 160) 
            FROM volunteer_reflections vr 
            WHERE vr.opportunity_id = vo.id 
            ORDER BY vr.created_at DESC 
            LIMIT 1
          ) as latest_reflection_excerpt,
          CASE WHEN vp_user.user_id IS NOT NULL THEN 1 ELSE 0 END as is_participant,
          vp_user.status as participant_status,
          vp_user.hours_completed,
          vp_user.certificate_issued,
          vp_user.role as participant_role
        FROM volunteer_opportunities vo
        LEFT JOIN user_profiles up ON vo.organizer_id = up.user_id
        LEFT JOIN volunteer_participants vp ON vo.id = vp.opportunity_id AND vp.status != 'cancelled'
        LEFT JOIN volunteer_attachments va ON vo.id = va.opportunity_id
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

      $attachments = $this->fetchAttachments($id);
      $opportunity['attachments'] = $attachments;
      $this->attachLatestReflectionImages($opportunity);

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
      $opportunityType = isset($input['opportunity_type']) && in_array($input['opportunity_type'], $this->allowedOpportunityTypes)
        ? $input['opportunity_type']
        : 'volunteer';

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
        (title, description, organizer_id, location, date, start_time, end_time, required_participants, status, opportunity_type) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)
      ";

      $stmt = $this->conn->prepare($query);
      $result = $stmt->execute([
        $title, $description, $userId, $location, $date, $startTime, $endTime, $requiredParticipants, $opportunityType
      ]);

      if ($result) {
        $opportunityId = $this->conn->lastInsertId();

        // Automatically add the creator as a participant with approved status
        try {
          $participantStmt = $this->conn->prepare(
            "INSERT INTO volunteer_participants (opportunity_id, user_id, status, role) VALUES (?, ?, 'approved', 'admin')"
          );
          $participantStmt->execute([$opportunityId, $userId]);
        } catch (Exception $e) {
          // If adding the participant fails, log the error but continue
          error_log('Failed to add organizer as participant: ' . $e->getMessage());
        }

        $this->notifyOpportunityCreated($userId, intval($opportunityId), $title, $opportunityType, $location);
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
      $checkQuery = "SELECT status, required_participants, organizer_id, title, opportunity_type FROM volunteer_opportunities WHERE id = ?";
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
        // Check participant limit before re-applying
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
        $this->notifyOpportunityApplication($userId, $opportunityId, $opportunity);
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

  private function notifyOpportunityCreated($actorUserId, $opportunityId, $title, $opportunityType, $location)
  {
    try {
      $recipients = $this->push->getActiveUserIdsExcept($actorUserId);
      $actorName = $this->push->getDisplayName($actorUserId);
      $isEvent = $opportunityType === 'event';
      $notificationTitle = $isEvent ? "$actorName created an event" : "$actorName created a volunteer opportunity";

      $this->push->sendToUsers($recipients, $isEvent ? 'event_created' : 'volunteer_created', $notificationTitle, $title, [
        'type' => $isEvent ? 'event_created' : 'volunteer_created',
        'entity_type' => 'volunteer_opportunity',
        'entity_id' => $opportunityId,
        'opportunity_id' => $opportunityId,
        'opportunity_type' => $opportunityType,
        'location' => $location,
        'route' => 'volunteer_opportunity_details'
      ], $actorUserId);
    } catch (Exception $e) {
      error_log('Failed to enqueue opportunity push notification: ' . $e->getMessage());
    }
  }

  private function notifyOpportunityApplication($actorUserId, $opportunityId, array $opportunity)
  {
    try {
      $organizerId = intval($opportunity['organizer_id'] ?? 0);
      if ($organizerId <= 0 || $organizerId === intval($actorUserId)) return;

      $actorName = $this->push->getDisplayName($actorUserId);
      $isEvent = ($opportunity['opportunity_type'] ?? 'volunteer') === 'event';
      $notificationTitle = $isEvent ? "$actorName joined your event" : "$actorName applied to your opportunity";

      $this->push->sendToUsers([$organizerId], $isEvent ? 'event_application' : 'volunteer_application', $notificationTitle, $opportunity['title'] ?? 'Opportunity', [
        'type' => $isEvent ? 'event_application' : 'volunteer_application',
        'entity_type' => 'volunteer_opportunity',
        'entity_id' => $opportunityId,
        'opportunity_id' => $opportunityId,
        'opportunity_type' => $opportunity['opportunity_type'] ?? 'volunteer',
        'route' => 'volunteer_opportunity_details'
      ], $actorUserId);
    } catch (Exception $e) {
      error_log('Failed to enqueue opportunity application push notification: ' . $e->getMessage());
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

  // Check if user can manage participants (organizer, coordinator, or admin)
  $checkQuery = "SELECT organizer_id FROM volunteer_opportunities WHERE id = ?";
  $checkStmt = $this->conn->prepare($checkQuery);
  $checkStmt->execute([$opportunityId]);
  $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);

  if (!$opportunity || !($opportunity['organizer_id'] == $userId || $this->userHasAnyRole($userId, $opportunityId, ['coordinator','admin']))) {
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

  public function updateParticipantRole($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['opportunity_id']) || !isset($input['user_id']) || !isset($input['role'])) {
        Response::error('Opportunity ID, user ID, and role are required', 400);
        return;
      }

      $opportunityId = intval($input['opportunity_id']);
      $targetUserId = intval($input['user_id']);
      $role = $input['role'];

      if (!in_array($role, $this->allowedRoles)) {
        Response::error('Invalid role', 400);
        return;
      }

      // Only organizer or admin can change roles
      if (!$this->userHasAnyRole($userId, $opportunityId, ['admin'])) {
        Response::error('Permission denied', 403);
        return;
      }

      $updateQuery = "UPDATE volunteer_participants SET role = ?, updated_at = CURRENT_TIMESTAMP WHERE opportunity_id = ? AND user_id = ?";
      $stmt = $this->conn->prepare($updateQuery);
      $result = $stmt->execute([$role, $opportunityId, $targetUserId]);

      if ($result) {
        Response::success(['message' => 'Participant role updated successfully']);
      } else {
        Response::error('Failed to update participant role', 500);
      }
    } catch (Exception $e) {
      Response::error('Failed to update participant role: ' . $e->getMessage(), 500);
    }
  }

  private function fetchAttachments($opportunityId)
  {
    $query = "SELECT id, opportunity_id, file_name, file_url, mime_type, file_size, uploaded_by, created_at FROM volunteer_attachments WHERE opportunity_id = ? ORDER BY created_at DESC";
    $stmt = $this->conn->prepare($query);
    $stmt->execute([$opportunityId]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  public function getVolunteerAttachments($userId)
  {
    try {
      if (!isset($_GET['opportunity_id'])) {
        Response::error('Opportunity ID is required', 400);
        return;
      }
      $opportunityId = intval($_GET['opportunity_id']);
      $attachments = $this->fetchAttachments($opportunityId);
      Response::success($attachments);
    } catch (Exception $e) {
      Response::error('Failed to fetch attachments: ' . $e->getMessage(), 500);
    }
  }

  private function canManageAttachments($userId, $opportunityId)
  {
    return $this->userHasAnyRole($userId, $opportunityId, ['admin', 'coordinator']);
  }

  public function uploadVolunteerAttachment($userId)
  {
    try {
      if (!isset($_GET['opportunity_id'])) {
        Response::error('Opportunity ID is required', 400);
        return;
      }
      $opportunityId = intval($_GET['opportunity_id']);

      if (!$this->canManageAttachments($userId, $opportunityId)) {
        Response::error('Permission denied', 403);
        return;
      }

      if (!isset($_FILES['attachment'])) {
        Response::error('No file provided', 400);
        return;
      }

      $file = $_FILES['attachment'];
      if ($file['error'] !== UPLOAD_ERR_OK) {
        Response::error('File upload failed', 400);
        return;
      }

      if ($file['size'] > 10 * 1024 * 1024) {
        Response::error('File too large. Max 10MB allowed.', 400);
        return;
      }

      $finfo = finfo_open(FILEINFO_MIME_TYPE);
      $mimeType = finfo_file($finfo, $file['tmp_name']);
      finfo_close($finfo);

      $allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
      if (!in_array($mimeType, $allowedTypes)) {
        Response::error('Invalid file type. Only JPG, PNG, and PDF are allowed.', 400);
        return;
      }

      $uploadDir = __DIR__ . '/../uploads/volunteer_attachments/';
      if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0755, true);
      }

      $extension = '';
      if ($mimeType === 'image/jpeg') $extension = 'jpg';
      else if ($mimeType === 'image/png') $extension = 'png';
      else if ($mimeType === 'application/pdf') $extension = 'pdf';

      $filename = uniqid('vol_attach_') . '.' . $extension;
      $filepath = $uploadDir . $filename;

      if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        Response::error('Failed to save file', 500);
        return;
      }

      $fileUrl = '/uploads/volunteer_attachments/' . $filename;

      $insert = "INSERT INTO volunteer_attachments (opportunity_id, file_name, file_url, mime_type, file_size, uploaded_by) VALUES (?, ?, ?, ?, ?, ?)";
      $stmt = $this->conn->prepare($insert);
      $stmt->execute([$opportunityId, $file['name'], $fileUrl, $mimeType, $file['size'], $userId]);
      $attachmentId = $this->conn->lastInsertId();

      $attachment = [
        'id' => intval($attachmentId),
        'opportunity_id' => $opportunityId,
        'file_name' => $file['name'],
        'file_url' => $fileUrl,
        'mime_type' => $mimeType,
        'file_size' => intval($file['size']),
        'uploaded_by' => $userId,
        'created_at' => date('Y-m-d H:i:s')
      ];

      Response::success($attachment, 'Attachment uploaded');
    } catch (Exception $e) {
      Response::error('Failed to upload attachment: ' . $e->getMessage(), 500);
    }
  }

  public function deleteVolunteerAttachment($userId)
  {
    try {
      if (!isset($_POST['attachment_id'])) {
        Response::error('Attachment ID is required', 400);
        return;
      }

      $attachmentId = intval($_POST['attachment_id']);

      $query = "SELECT opportunity_id, file_url FROM volunteer_attachments WHERE id = ?";
      $stmt = $this->conn->prepare($query);
      $stmt->execute([$attachmentId]);
      $attachment = $stmt->fetch(PDO::FETCH_ASSOC);

      if (!$attachment) {
        Response::error('Attachment not found', 404);
        return;
      }

      $opportunityId = intval($attachment['opportunity_id']);

      if (!$this->canManageAttachments($userId, $opportunityId)) {
        Response::error('Permission denied', 403);
        return;
      }

      $delete = $this->conn->prepare("DELETE FROM volunteer_attachments WHERE id = ?");
      $delete->execute([$attachmentId]);

      $path = __DIR__ . '/../' . ltrim($attachment['file_url'], '/');
      if (file_exists($path)) {
        unlink($path);
      }

      Response::success(null, 'Attachment deleted');
    } catch (Exception $e) {
      Response::error('Failed to delete attachment: ' . $e->getMessage(), 500);
    }
  }

  private function fetchReflectionImages($reflectionId)
  {
    $query = "SELECT id, reflection_id, file_name, file_url, mime_type, file_size, uploaded_by, created_at FROM volunteer_reflection_images WHERE reflection_id = ? ORDER BY created_at DESC";
    $stmt = $this->conn->prepare($query);
    $stmt->execute([$reflectionId]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  private function attachLatestReflectionImages(&$opportunity)
  {
    $latestReflectionId = isset($opportunity['latest_reflection_id']) ? intval($opportunity['latest_reflection_id']) : 0;
    $opportunity['latest_reflection_images'] = $latestReflectionId > 0
      ? $this->fetchReflectionImages($latestReflectionId)
      : [];
    unset($opportunity['latest_reflection_id']);
  }

  private function canManageReflections($userId, $opportunityId)
  {
    return $this->userHasAnyRole($userId, $opportunityId, ['admin']);
  }

  public function getVolunteerReflections($userId)
  {
    try {
      if (!isset($_GET['opportunity_id'])) {
        Response::error('Opportunity ID is required', 400);
        return;
      }

      $opportunityId = intval($_GET['opportunity_id']);
      $query = "
        SELECT vr.*, up.display_name as author_name, up.avatar_url as author_avatar
        FROM volunteer_reflections vr
        LEFT JOIN user_profiles up ON vr.created_by = up.user_id
        WHERE vr.opportunity_id = ?
        ORDER BY vr.created_at DESC
      ";
      $stmt = $this->conn->prepare($query);
      $stmt->execute([$opportunityId]);
      $reflections = $stmt->fetchAll(PDO::FETCH_ASSOC);

      foreach ($reflections as &$reflection) {
        $reflection['images'] = $this->fetchReflectionImages($reflection['id']);
      }

      Response::success($reflections);
    } catch (Exception $e) {
      Response::error('Failed to fetch reflections: ' . $e->getMessage(), 500);
    }
  }

  public function createVolunteerReflection($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['opportunity_id']) || !isset($input['body'])) {
        Response::error('Opportunity ID and body are required', 400);
        return;
      }

      $opportunityId = intval($input['opportunity_id']);
      $title = isset($input['title']) && trim($input['title']) !== '' ? trim($input['title']) : 'Reflection';
      $body = trim($input['body']);

      if (empty($body)) {
        Response::error('Reflection cannot be empty', 400);
        return;
      }

      if (!$this->canManageReflections($userId, $opportunityId)) {
        Response::error('Permission denied', 403);
        return;
      }

      $insert = "INSERT INTO volunteer_reflections (opportunity_id, title, body, created_by) VALUES (?, ?, ?, ?)";
      $stmt = $this->conn->prepare($insert);
      $stmt->execute([$opportunityId, $title, $body, $userId]);
      $reflectionId = $this->conn->lastInsertId();

      $profileStmt = $this->conn->prepare("SELECT display_name, avatar_url FROM user_profiles WHERE user_id = ?");
      $profileStmt->execute([$userId]);
      $profile = $profileStmt->fetch(PDO::FETCH_ASSOC);

      $reflection = [
        'id' => intval($reflectionId),
        'opportunity_id' => $opportunityId,
        'title' => $title,
        'body' => $body,
        'created_by' => $userId,
        'author_name' => $profile['display_name'] ?? null,
        'author_avatar' => $profile['avatar_url'] ?? null,
        'created_at' => date('Y-m-d H:i:s'),
        'updated_at' => date('Y-m-d H:i:s'),
        'images' => []
      ];

      // Mark opportunity as completed when a reflection is posted
      $statusUpdate = $this->conn->prepare("UPDATE volunteer_opportunities SET status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE id = ? AND status != 'completed'");
      $statusUpdate->execute([$opportunityId]);

      Response::success($reflection, 'Reflection created');
    } catch (Exception $e) {
      Response::error('Failed to create reflection: ' . $e->getMessage(), 500);
    }
  }

  public function updateVolunteerReflection($userId)
  {
    try {
      $input = json_decode(file_get_contents('php://input'), true);

      if (!isset($input['reflection_id'])) {
        Response::error('Reflection ID is required', 400);
        return;
      }

      $reflectionId = intval($input['reflection_id']);

      $check = $this->conn->prepare("SELECT opportunity_id FROM volunteer_reflections WHERE id = ?");
      $check->execute([$reflectionId]);
      $reflection = $check->fetch(PDO::FETCH_ASSOC);

      if (!$reflection) {
        Response::error('Reflection not found', 404);
        return;
      }

      $opportunityId = intval($reflection['opportunity_id']);

      if (!$this->canManageReflections($userId, $opportunityId)) {
        Response::error('Permission denied', 403);
        return;
      }

      $fields = [];
      $params = [];

      if (isset($input['title'])) {
        $fields[] = "title = ?";
        $params[] = trim($input['title']);
      }

      if (isset($input['body'])) {
        $body = trim($input['body']);
        if (empty($body)) {
          Response::error('Reflection cannot be empty', 400);
          return;
        }
        $fields[] = "body = ?";
        $params[] = $body;
      }

      if (empty($fields)) {
        Response::error('No fields to update', 400);
        return;
      }

      $fields[] = "updated_at = CURRENT_TIMESTAMP";
      $params[] = $reflectionId;

      $update = "UPDATE volunteer_reflections SET " . implode(', ', $fields) . " WHERE id = ?";
      $stmt = $this->conn->prepare($update);
      $stmt->execute($params);

      $refetch = $this->conn->prepare("
        SELECT vr.*, up.display_name as author_name, up.avatar_url as author_avatar
        FROM volunteer_reflections vr
        LEFT JOIN user_profiles up ON vr.created_by = up.user_id
        WHERE vr.id = ?
      ");
      $refetch->execute([$reflectionId]);
      $updated = $refetch->fetch(PDO::FETCH_ASSOC);
      $updated['images'] = $this->fetchReflectionImages($reflectionId);

      // Ensure the opportunity is marked completed once a reflection exists
      $statusUpdate = $this->conn->prepare("UPDATE volunteer_opportunities SET status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE id = ?");
      $statusUpdate->execute([$opportunityId]);

      Response::success($updated, 'Reflection updated');
    } catch (Exception $e) {
      Response::error('Failed to update reflection: ' . $e->getMessage(), 500);
    }
  }

  public function uploadReflectionImage($userId)
  {
    try {
      if (!isset($_GET['reflection_id'])) {
        Response::error('Reflection ID is required', 400);
        return;
      }

      $reflectionId = intval($_GET['reflection_id']);

      $check = $this->conn->prepare("SELECT opportunity_id FROM volunteer_reflections WHERE id = ?");
      $check->execute([$reflectionId]);
      $reflection = $check->fetch(PDO::FETCH_ASSOC);

      if (!$reflection) {
        Response::error('Reflection not found', 404);
        return;
      }

      $opportunityId = intval($reflection['opportunity_id']);

      if (!$this->canManageReflections($userId, $opportunityId)) {
        Response::error('Permission denied', 403);
        return;
      }

      if (!isset($_FILES['image'])) {
        Response::error('No file provided', 400);
        return;
      }

      $file = $_FILES['image'];
      if ($file['error'] !== UPLOAD_ERR_OK) {
        Response::error('File upload failed', 400);
        return;
      }

      if ($file['size'] > 8 * 1024 * 1024) {
        Response::error('File too large. Max 8MB allowed.', 400);
        return;
      }

      $finfo = finfo_open(FILEINFO_MIME_TYPE);
      $mimeType = finfo_file($finfo, $file['tmp_name']);
      finfo_close($finfo);

      $allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
      if (!in_array($mimeType, $allowedTypes)) {
        Response::error('Invalid file type. Only JPG, PNG, and WEBP are allowed.', 400);
        return;
      }

      $uploadDir = __DIR__ . '/../uploads/volunteer_reflections/';
      if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0755, true);
      }

      $extension = 'jpg';
      if ($mimeType === 'image/png') $extension = 'png';
      else if ($mimeType === 'image/webp') $extension = 'webp';

      $filename = uniqid('vol_reflect_') . '.' . $extension;
      $filepath = $uploadDir . $filename;

      if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        Response::error('Failed to save file', 500);
        return;
      }

      $fileUrl = '/uploads/volunteer_reflections/' . $filename;

      $insert = "INSERT INTO volunteer_reflection_images (reflection_id, file_name, file_url, mime_type, file_size, uploaded_by) VALUES (?, ?, ?, ?, ?, ?)";
      $stmt = $this->conn->prepare($insert);
      $stmt->execute([$reflectionId, $file['name'], $fileUrl, $mimeType, $file['size'], $userId]);
      $imageId = $this->conn->lastInsertId();

      $image = [
        'id' => intval($imageId),
        'reflection_id' => $reflectionId,
        'file_name' => $file['name'],
        'file_url' => $fileUrl,
        'mime_type' => $mimeType,
        'file_size' => intval($file['size']),
        'uploaded_by' => $userId,
        'created_at' => date('Y-m-d H:i:s')
      ];

      Response::success($image, 'Reflection image uploaded');
    } catch (Exception $e) {
      Response::error('Failed to upload reflection image: ' . $e->getMessage(), 500);
    }
  }

  public function deleteReflectionImage($userId)
  {
    try {
      if (!isset($_POST['image_id'])) {
        Response::error('Image ID is required', 400);
        return;
      }

      $imageId = intval($_POST['image_id']);

      $query = "
        SELECT vri.reflection_id, vri.file_url, vr.opportunity_id
        FROM volunteer_reflection_images vri
        JOIN volunteer_reflections vr ON vri.reflection_id = vr.id
        WHERE vri.id = ?
      ";
      $stmt = $this->conn->prepare($query);
      $stmt->execute([$imageId]);
      $image = $stmt->fetch(PDO::FETCH_ASSOC);

      if (!$image) {
        Response::error('Image not found', 404);
        return;
      }

      if (!$this->canManageReflections($userId, intval($image['opportunity_id']))) {
        Response::error('Permission denied', 403);
        return;
      }

      $delete = $this->conn->prepare("DELETE FROM volunteer_reflection_images WHERE id = ?");
      $delete->execute([$imageId]);

      $path = __DIR__ . '/../' . ltrim($image['file_url'], '/');
      if (file_exists($path)) {
        unlink($path);
      }

      Response::success(null, 'Reflection image deleted');
    } catch (Exception $e) {
      Response::error('Failed to delete reflection image: ' . $e->getMessage(), 500);
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
        SELECT vp.*, vo.title, vo.description, vo.date, vo.start_time, vo.end_time, up.display_name
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
        
        Date: {$participation['date']} Time: {$participation['start_time']} - {$participation['end_time']}
        Hours Completed: {$participation['hours_completed']}
        
        Date of Completion: {$participation['updated_at']}
      ";

      // In a real implementation, you would generate a proper PDF certificate
      header('Content-Type: text/plain; charset=UTF-8');
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
