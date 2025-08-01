<?php
require_once 'config/Database.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get the action from the URL
$action = $_GET['action'] ?? '';

// Initialize database connection
try {
    $database = new Database();
    $db = $database->getConnection();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']);
    exit;
}

// Get the authorization header
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? '';

// Extract token from Bearer token
if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
    $token = $matches[1];
} else {
    $token = '';
}

// Verify token and get user info
if (!empty($token)) {
    try {
        $stmt = $db->prepare("SELECT id, email, role FROM users WHERE token = ? AND token_expiry > NOW()");
        $stmt->execute([$token]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            http_response_code(401);
            echo json_encode(['status' => 'error', 'message' => 'Invalid or expired token']);
            exit;
        }
        
        $userId = $user['id'];
        $userRole = $user['role'];
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Database error']);
        exit;
    }
} else {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Authorization token required']);
    exit;
}

// Handle different actions
switch ($action) {
    case 'list':
        getVolunteerOpportunities($db, $userId);
        break;
        
    case 'create':
        createVolunteerOpportunity($db, $userId, $userRole);
        break;
        
    case 'update':
        updateVolunteerOpportunity($db, $userId, $userRole);
        break;
        
    case 'delete':
        deleteVolunteerOpportunity($db, $userId, $userRole);
        break;
        
    case 'register':
        registerForOpportunity($db, $userId);
        break;
        
    case 'unregister':
        unregisterFromOpportunity($db, $userId);
        break;
        
    case 'my_history':
        getUserVolunteerHistory($db, $userId);
        break;
        
    case 'certificate':
        downloadCertificate($db, $userId);
        break;
        
    default:
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
        break;
}

function getVolunteerOpportunities($db, $userId) {
    try {
        $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
        $limit = 20;
        $offset = ($page - 1) * $limit;
        
        // Get search parameters
        $search = isset($_GET['search']) ? '%' . $_GET['search'] . '%' : '%';
        $status = isset($_GET['status']) ? $_GET['status'] : 'open';
        
        // Build query
        $whereClause = "WHERE (title LIKE ? OR description LIKE ? OR location LIKE ? OR tags LIKE ?)";
        $params = [$search, $search, $search, $search];
        
        if ($status !== 'all') {
            $whereClause .= " AND status = ?";
            $params[] = $status;
        }
        
        // Get total count for pagination
        $countQuery = "SELECT COUNT(*) as total FROM volunteer_opportunities $whereClause";
        $countStmt = $db->prepare($countQuery);
        $countStmt->execute($params);
        $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Get opportunities
        $query = "SELECT vo.*, 
                         (SELECT COUNT(*) FROM volunteer_registrations WHERE opportunity_id = vo.id) as registered_count,
                         (SELECT COUNT(*) FROM volunteer_registrations WHERE opportunity_id = vo.id AND user_id = ?) as is_registered
                  FROM volunteer_opportunities vo 
                  $whereClause 
                  ORDER BY vo.created_at DESC 
                  LIMIT ? OFFSET ?";
        
        $params[] = $userId;
        $params[] = $limit;
        $params[] = $offset;
        
        $stmt = $db->prepare($query);
        $stmt->execute($params);
        $opportunities = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format dates and add additional fields
        foreach ($opportunities as &$opportunity) {
            $opportunity['start_date'] = date('Y-m-d H:i:s', strtotime($opportunity['start_date']));
            $opportunity['end_date'] = $opportunity['end_date'] ? date('Y-m-d H:i:s', strtotime($opportunity['end_date'])) : null;
            $opportunity['created_at'] = date('Y-m-d H:i:s', strtotime($opportunity['created_at']));
            $opportunity['updated_at'] = date('Y-m-d H:i:s', strtotime($opportunity['updated_at']));
            $opportunity['is_registered'] = (bool)$opportunity['is_registered'];
            $opportunity['registered_count'] = (int)$opportunity['registered_count'];
        }
        
        echo json_encode([
            'status' => 'success',
            'data' => $opportunities,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ceil($total / $limit)
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to get opportunities: ' . $e->getMessage()]);
    }
}

function createVolunteerOpportunity($db, $userId, $userRole) {
    try {
        // Only allow admins and organizers to create opportunities
        if (!in_array($userRole, ['admin', 'organizer'])) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Permission denied']);
            return;
        }
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Validate required fields
        $required = ['title', 'description', 'location', 'start_date'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => "$field is required"]);
                return;
            }
        }
        
        // Prepare data
        $title = htmlspecialchars(strip_tags($data['title']));
        $description = htmlspecialchars(strip_tags($data['description']));
        $location = htmlspecialchars(strip_tags($data['location']));
        $startDate = date('Y-m-d H:i:s', strtotime($data['start_date']));
        $endDate = !empty($data['end_date']) ? date('Y-m-d H:i:s', strtotime($data['end_date'])) : null;
        $maxParticipants = isset($data['max_participants']) ? (int)$data['max_participants'] : 0;
        $organizer = !empty($data['organizer']) ? htmlspecialchars(strip_tags($data['organizer'])) : null;
        $organizerContact = !empty($data['organizer_contact']) ? htmlspecialchars(strip_tags($data['organizer_contact'])) : null;
        $tags = !empty($data['tags']) ? json_encode($data['tags']) : null;
        $status = 'open';
        
        // Check if start date is in the future
        if (strtotime($startDate) <= time()) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Start date must be in the future']);
            return;
        }
        
        // Insert into database
        $query = "INSERT INTO volunteer_opportunities 
                 (title, description, location, start_date, end_date, max_participants, 
                  organizer, organizer_contact, tags, status, created_by, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
        
        $stmt = $db->prepare($query);
        $stmt->execute([
            $title, $description, $location, $startDate, $endDate, $maxParticipants,
            $organizer, $organizerContact, $tags, $status, $userId
        ]);
        
        $opportunityId = $db->lastInsertId();
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Opportunity created successfully',
            'data' => [
                'id' => $opportunityId,
                'title' => $title,
                'description' => $description,
                'location' => $location,
                'start_date' => $startDate,
                'end_date' => $endDate,
                'max_participants' => $maxParticipants,
                'organizer' => $organizer,
                'organizer_contact' => $organizerContact,
                'tags' => $tags ? json_decode($tags) : null,
                'status' => $status,
                'created_by' => $userId,
                'created_at' => date('Y-m-d H:i:s'),
                'updated_at' => date('Y-m-d H:i:s'),
                'registered_count' => 0,
                'is_registered' => false
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to create opportunity: ' . $e->getMessage()]);
    }
}

function updateVolunteerOpportunity($db, $userId, $userRole) {
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        $opportunityId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        
        if (!$opportunityId) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity ID is required']);
            return;
        }
        
        // Check if user has permission to update this opportunity
        $checkQuery = "SELECT created_by, status FROM volunteer_opportunities WHERE id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$opportunityId]);
        $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$opportunity) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity not found']);
            return;
        }
        
        // Only creator or admin can update
        if ($opportunity['created_by'] != $userId && $userRole != 'admin') {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Permission denied']);
            return;
        }
        
        // Can't update completed or cancelled opportunities
        if (in_array($opportunity['status'], ['completed', 'cancelled'])) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Cannot update completed or cancelled opportunities']);
            return;
        }
        
        // Prepare update data
        $updateFields = [];
        $params = [];
        
        $allowedFields = ['title', 'description', 'location', 'start_date', 'end_date', 
                         'max_participants', 'organizer', 'organizer_contact', 'tags', 'status'];
        
        foreach ($allowedFields as $field) {
            if (isset($data[$field])) {
                $updateFields[] = "$field = ?";
                
                if ($field === 'start_date' || $field === 'end_date') {
                    $params[] = date('Y-m-d H:i:s', strtotime($data[$field]));
                } else {
                    $params[] = htmlspecialchars(strip_tags($data[$field]));
                }
            }
        }
        
        if (empty($updateFields)) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'No fields to update']);
            return;
        }
        
        $params[] = $opportunityId;
        $query = "UPDATE volunteer_opportunities SET " . implode(', ', $updateFields) . ", updated_at = NOW() WHERE id = ?";
        
        $stmt = $db->prepare($query);
        $stmt->execute($params);
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Opportunity updated successfully'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to update opportunity: ' . $e->getMessage()]);
    }
}

function deleteVolunteerOpportunity($db, $userId, $userRole) {
    try {
        $opportunityId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        
        if (!$opportunityId) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity ID is required']);
            return;
        }
        
        // Check if user has permission to delete this opportunity
        $checkQuery = "SELECT created_by, status FROM volunteer_opportunities WHERE id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$opportunityId]);
        $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$opportunity) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity not found']);
            return;
        }
        
        // Only creator or admin can delete
        if ($opportunity['created_by'] != $userId && $userRole != 'admin') {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Permission denied']);
            return;
        }
        
        // Delete the opportunity
        $query = "DELETE FROM volunteer_opportunities WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$opportunityId]);
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Opportunity deleted successfully'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to delete opportunity: ' . $e->getMessage()]);
    }
}

function registerForOpportunity($db, $userId) {
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        $opportunityId = isset($data['opportunity_id']) ? (int)$data['opportunity_id'] : 0;
        
        if (!$opportunityId) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity ID is required']);
            return;
        }
        
        // Check if opportunity exists and is open
        $checkQuery = "SELECT status, max_participants, 
                         (SELECT COUNT(*) FROM volunteer_registrations WHERE opportunity_id = ?) as registered_count
                      FROM volunteer_opportunities WHERE id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$opportunityId, $opportunityId]);
        $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$opportunity) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity not found']);
            return;
        }
        
        if ($opportunity['status'] !== 'open') {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Registration is closed for this opportunity']);
            return;
        }
        
        // Check if already registered
        $checkRegQuery = "SELECT id FROM volunteer_registrations WHERE opportunity_id = ? AND user_id = ?";
        $checkRegStmt = $db->prepare($checkRegQuery);
        $checkRegStmt->execute([$opportunityId, $userId]);
        
        if ($checkRegStmt->fetch()) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Already registered for this opportunity']);
            return;
        }
        
        // Check if opportunity is full
        if ($opportunity['max_participants'] > 0 && $opportunity['registered_count'] >= $opportunity['max_participants']) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'This opportunity is full']);
            return;
        }
        
        // Register user
        $query = "INSERT INTO volunteer_registrations (opportunity_id, user_id, registered_at) VALUES (?, ?, NOW())";
        $stmt = $db->prepare($query);
        $stmt->execute([$opportunityId, $userId]);
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Successfully registered for opportunity'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to register: ' . $e->getMessage()]);
    }
}

function unregisterFromOpportunity($db, $userId) {
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        $opportunityId = isset($data['opportunity_id']) ? (int)$data['opportunity_id'] : 0;
        
        if (!$opportunityId) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity ID is required']);
            return;
        }
        
        // Check if opportunity exists
        $checkQuery = "SELECT status FROM volunteer_opportunities WHERE id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$opportunityId]);
        $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$opportunity) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity not found']);
            return;
        }
        
        // Check if registered
        $checkRegQuery = "SELECT id FROM volunteer_registrations WHERE opportunity_id = ? AND user_id = ?";
        $checkRegStmt = $db->prepare($checkRegQuery);
        $checkRegStmt->execute([$opportunityId, $userId]);
        
        if (!$checkRegStmt->fetch()) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Not registered for this opportunity']);
            return;
        }
        
        // Unregister user
        $query = "DELETE FROM volunteer_registrations WHERE opportunity_id = ? AND user_id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$opportunityId, $userId]);
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Successfully unregistered from opportunity'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to unregister: ' . $e->getMessage()]);
    }
}

function getUserVolunteerHistory($db, $userId) {
    try {
        $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
        $limit = 20;
        $offset = ($page - 1) * $limit;
        
        // Get user's volunteer history
        $query = "SELECT vo.*, vr.registered_at, vr.completed_at
                  FROM volunteer_opportunities vo
                  JOIN volunteer_registrations vr ON vo.id = vr.opportunity_id
                  WHERE vr.user_id = ?
                  ORDER BY vr.registered_at DESC
                  LIMIT ? OFFSET ?";
        
        $stmt = $db->prepare($query);
        $stmt->execute([$userId, $limit, $offset]);
        $history = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format dates
        foreach ($history as &$item) {
            $item['start_date'] = date('Y-m-d H:i:s', strtotime($item['start_date']));
            $item['end_date'] = $item['end_date'] ? date('Y-m-d H:i:s', strtotime($item['end_date'])) : null;
            $item['created_at'] = date('Y-m-d H:i:s', strtotime($item['created_at']));
            $item['updated_at'] = date('Y-m-d H:i:s', strtotime($item['updated_at']));
            $item['registered_at'] = date('Y-m-d H:i:s', strtotime($item['registered_at']));
            $item['completed_at'] = $item['completed_at'] ? date('Y-m-d H:i:s', strtotime($item['completed_at'])) : null;
        }
        
        echo json_encode([
            'status' => 'success',
            'data' => $history
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to get history: ' . $e->getMessage()]);
    }
}

function downloadCertificate($db, $userId) {
    try {
        $opportunityId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        
        if (!$opportunityId) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity ID is required']);
            return;
        }
        
        // Check if user is registered for this opportunity
        $checkQuery = "SELECT vo.title, vo.start_date, vo.end_date, vr.registered_at, vr.completed_at
                      FROM volunteer_opportunities vo
                      JOIN volunteer_registrations vr ON vo.id = vr.opportunity_id
                      WHERE vo.id = ? AND vr.user_id = ?";
        
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$opportunityId, $userId]);
        $opportunity = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$opportunity) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Opportunity not found or not registered']);
            return;
        }
        
        // Generate simple certificate content (in a real app, you'd use a PDF library)
        $certificateContent = generateCertificate($opportunity, $userId);
        
        // Set headers for file download
        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="volunteer_certificate_' . $opportunityId . '.pdf"');
        header('Content-Length: ' . strlen($certificateContent));
        
        echo $certificateContent;
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to generate certificate: ' . $e->getMessage()]);
    }
}

function generateCertificate($opportunity, $userId) {
    // This is a simplified certificate generator
    // In a real application, you would use a PDF library like TCPDF or FPDF
    
    $endDate = $opportunity['end_date'] ?: 'Present';
    $completedDate = $opportunity['completed_at'] ?: 'N/A';
    
    $html = <<<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Volunteer Certificate</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; }
        .certificate { border: 2px solid #333; padding: 50px; text-align: center; }
        .title { font-size: 24px; font-weight: bold; margin-bottom: 30px; }
        .content { font-size: 16px; line-height: 1.6; }
        .signature { margin-top: 50px; }
    </style>
</head>
<body>
    <div class="certificate">
        <div class="title">Certificate of Volunteer Service</div>
        <div class="content">
            <p>This certifies that</p>
            <p style="font-size: 20px; font-weight: bold;">User ID: $userId</p>
            <p>has successfully completed volunteer service for:</p>
            <p style="font-size: 18px; font-weight: bold;">{$opportunity['title']}</p>
            <p>Duration: {$opportunity['start_date']} to $endDate</p>
            <p>Date of Registration: {$opportunity['registered_at']}</p>
            <p>Date of Completion: $completedDate</p>
        </div>
        <div class="signature">
            <p>_________________________</p>
            <p>Community Organizer</p>
        </div>
    </div>
</body>
</html>
HTML;

    // Convert HTML to PDF (simplified - in real app use PDF library)
    // For now, return HTML content that can be saved as PDF
    return $html;
}
?>
