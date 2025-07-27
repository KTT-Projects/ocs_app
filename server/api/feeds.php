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

class FeedController
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
        $userId = $decoded['user_id'];
      } elseif (!($method === 'GET' && $action === 'list')) {
        Response::error('Authorization header is required', 401);
        return;
      }

      switch ($method) {
        case 'GET':
          if ($action === 'list') {
            $this->getFeeds($userId);
          } else if ($action === 'joined') {
            $this->getJoinedFeeds($userId);
          } else if ($action === 'posts') {
            $this->getFeedPosts();
          } else if ($action === 'home') {
            $this->getHomeFeed($userId);
          } else if ($action === 'members') {
            $this->getFeedMembers();
          }
          break;
        case 'POST':
          if ($action === 'create') {
            $this->createFeed($userId);
          } else if ($action === 'join') {
            $this->joinFeed($userId);
          } else if ($action === 'leave') {
            $this->leaveFeed($userId);
          } else if ($action === 'post') {
            $this->createPost($userId);
          } else if ($action === 'vote') {
            $this->vote($userId);
          } else if ($action === 'reorder') {
            $this->reorderFeeds($userId);
          } else if ($action === 'icon') {
            $this->uploadIcon($userId);
          }
          break;
        case 'PATCH':
          if ($action === 'update') {
            $this->updateFeed($userId);
          }
          break;
        default:
          Response::error('Method not allowed', 405);
      }
    } catch (Exception $e) {
      Response::error($e->getMessage(), 500);
    }
  }

  private function getFeeds($userId = null)
  {
    // Get sort option from query (default: population)
    $sort = isset($_GET['sort']) ? $_GET['sort'] : 'population';

    // Fetch feeds with membership information
    $query = "SELECT f.*,
                  COUNT(DISTINCT fm1.user_id) as member_count,
                  COUNT(DISTINCT fp.id) as post_count";
    if ($userId !== null) {
      $query .= ", EXISTS(SELECT 1 FROM feed_members fm2 WHERE fm2.feed_id = f.id AND fm2.user_id = :user_id) as is_member";
    } else {
      $query .= ", 0 as is_member";
    }
    $query .= " FROM feeds f
                  LEFT JOIN feed_members fm1 ON f.id = fm1.feed_id
                  LEFT JOIN feed_posts fp ON f.id = fp.feed_id";
    $query .= " GROUP BY f.id";
    if ($sort === 'activity') {
      $query .= " ORDER BY MAX(fp.created_at) DESC";
    } else {
      $query .= " ORDER BY member_count DESC";
    }
    $stmt = $this->conn->prepare($query);
    if ($userId !== null) {
      $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    }
    $stmt->execute();
    $feeds = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $feed) {
      if ($userId === null || $feed['is_member'] == 0) {
        $feeds[] = $feed;
      }
    }
    Response::success($feeds, 'Feeds retrieved successfully');
  }

  private function getJoinedFeeds($userId)
  {
    // Get feed_order from users table
    $feedOrderQuery = "SELECT feed_order FROM users WHERE id = :user_id";
    $feedOrderStmt = $this->conn->prepare($feedOrderQuery);
    $feedOrderStmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $feedOrderStmt->execute();
    $feedOrderRaw = $feedOrderStmt->fetch(PDO::FETCH_ASSOC)['feed_order'];
    $orderedFeedIds = $feedOrderRaw ? array_map('intval', json_decode($feedOrderRaw, true)) : [];

    // Fetch only joined feeds by iterating feed_order
    $joinedFeeds = [];
    $validFeedIds = [];
    if (!empty($orderedFeedIds)) {
      $inClause = implode(',', array_map('intval', $orderedFeedIds));
      $query = "SELECT f.*,
                  fm2.role as member_role,
                  COUNT(DISTINCT fm1.user_id) as member_count,
                  COUNT(DISTINCT fp.id) as post_count
                  FROM feeds f
                  JOIN feed_members fm2 ON f.id = fm2.feed_id AND fm2.user_id = :user_id
                  LEFT JOIN feed_members fm1 ON f.id = fm1.feed_id
                  LEFT JOIN feed_posts fp ON f.id = fp.feed_id
                  WHERE f.id IN ($inClause)
                  GROUP BY f.id";
      $stmt = $this->conn->prepare($query);
      $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
      $stmt->execute();
      $feedsMap = [];
      foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $feed) {
        $feedsMap[$feed['id']] = $feed;
      }
      foreach ($orderedFeedIds as $feedId) {
        if (isset($feedsMap[$feedId])) {
          $feed = $feedsMap[$feedId];
          $feed['is_member'] = 1;
          $joinedFeeds[] = $feed;
          $validFeedIds[] = $feedId;
        }
      }
      // Remove invalid IDs from feed_order
      if (count($validFeedIds) !== count($orderedFeedIds)) {
        $updateOrderQuery = "UPDATE users SET feed_order = :feed_order WHERE id = :user_id";
        $updateOrderStmt = $this->conn->prepare($updateOrderQuery);
        $updateOrderStmt->bindParam(':feed_order', json_encode($validFeedIds));
        $updateOrderStmt->bindParam(':user_id', $userId);
        $updateOrderStmt->execute();
      }
    }
    Response::success($joinedFeeds, 'Joined feeds retrieved successfully');
  }

  private function reorderFeeds($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['feed_order']) || !is_array($data['feed_order'])) {
      Response::error('feed_order array is required', 400);
      return;
    }

    // Update feed_order in users table
    $updateOrderQuery = "UPDATE users SET feed_order = :feed_order WHERE id = :user_id";
    $updateOrderStmt = $this->conn->prepare($updateOrderQuery);
    $feedOrder = array_map('intval', $data['feed_order']);
    $updateOrderStmt->bindParam(':feed_order', json_encode($feedOrder));
    $updateOrderStmt->bindParam(':user_id', $userId);
    $updateOrderStmt->execute();

    Response::success(null, 'Feed order updated successfully');
  }

  private function uploadIcon($userId)
  {
    if (!isset($_GET['feed_id'])) {
      Response::error('Feed ID is required', 400);
      return;
    }

    $feedId = intval($_GET['feed_id']);

    // Check that the user is an admin or moderator of the feed
    $query = "SELECT role FROM feed_members WHERE feed_id = :feed_id AND user_id = :user_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $role = $stmt->fetchColumn();
    if (!$role || !in_array($role, ['admin', 'moderator'])) {
      Response::error('Insufficient permissions', 403);
      return;
    }

    if (!isset($_FILES['icon'])) {
      Response::error('No icon file provided', 400);
      return;
    }

    $file = $_FILES['icon'];
    if ($file['error'] !== UPLOAD_ERR_OK) {
      Response::error('File upload failed', 400);
      return;
    }

    // Validate file type
    $allowedTypes = ['image/jpeg', 'image/png'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);

    if (!in_array($mimeType, $allowedTypes)) {
      Response::error('Invalid file type. Only JPEG and PNG are allowed.', 400);
      return;
    }

    // Prepare uploads directory
    $uploadDir = __DIR__ . '/../uploads/feed_icons/';
    if (!file_exists($uploadDir)) {
      mkdir($uploadDir, 0755, true);
    }

    $extension = $mimeType === 'image/jpeg' ? 'jpg' : 'png';
    $filename = uniqid('feed_icon_') . '.' . $extension;
    $filepath = $uploadDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
      Response::error('Failed to save file', 500);
      return;
    }

    // Fetch current icon URL to remove old file
    $query = "SELECT icon_url FROM feeds WHERE id = :feed_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->execute();
    $oldIconUrl = $stmt->fetchColumn();

    // Update database
    $iconUrl = '/uploads/feed_icons/' . $filename;
    $query = "UPDATE feeds SET icon_url = :icon_url WHERE id = :feed_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':icon_url', $iconUrl);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->execute();

    if ($oldIconUrl) {
      $oldPath = __DIR__ . '/../' . ltrim($oldIconUrl, '/');
      if (file_exists($oldPath)) {
        unlink($oldPath);
      }
    }

    Response::json([
      'status' => 'success',
      'icon_url' => $iconUrl
    ]);
  }

  private function getFeedPosts()
  {
    if (!isset($_GET['feed_id'])) {
      Response::error('Feed ID is required', 400);
      return;
    }

    $feedId = $_GET['feed_id'];
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = 20;
    $offset = ($page - 1) * $limit;

    $query = "SELECT fp.*, 
                  u.email,
                  up.display_name,
                  up.avatar_url,
                  (SELECT COUNT(*) FROM comments WHERE post_id = fp.id) as comment_count
                  FROM feed_posts fp 
                  JOIN users u ON fp.user_id = u.id 
                  JOIN user_profiles up ON u.id = up.user_id
                  WHERE fp.feed_id = :feed_id 
                  ORDER BY fp.score DESC, fp.created_at DESC
                  LIMIT :limit OFFSET :offset";

    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId);
    $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    Response::success($posts, 'Posts retrieved successfully');
  }

  private function getFeedMembers()
  {
    if (!isset($_GET['feed_id'])) {
      Response::error('Feed ID is required', 400);
      return;
    }

    $feedId = intval($_GET['feed_id']);

    $query = "SELECT u.id, up.display_name, up.avatar_url, fm.role
                FROM feed_members fm
                JOIN users u ON fm.user_id = u.id
                JOIN user_profiles up ON u.id = up.user_id
                WHERE fm.feed_id = :feed_id";

    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->execute();
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

    Response::success($members, 'Members retrieved successfully');
  }

  private function getHomeFeed($userId)
  {
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = 20;
    $offset = ($page - 1) * $limit;

    $query = "SELECT fp.*, 
                  f.name as feed_name,
                  f.display_name as feed_display_name,
                  u.email,
                  up.display_name,
                  up.avatar_url,
                  (SELECT COUNT(*) FROM comments WHERE post_id = fp.id) as comment_count
                  FROM feed_posts fp 
                  JOIN feeds f ON fp.feed_id = f.id
                  JOIN users u ON fp.user_id = u.id 
                  JOIN user_profiles up ON u.id = up.user_id
                  JOIN feed_members fm ON f.id = fm.feed_id
                  WHERE fm.user_id = :user_id 
                  ORDER BY fp.score DESC, fp.created_at DESC
                  LIMIT :limit OFFSET :offset";

    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':user_id', $userId);
    $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    Response::success($posts, 'Home feed retrieved successfully');
  }

  private function createFeed($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['display_name']) || !isset($data['description'])) {
      Response::error('Display name and description are required', 400);
      return;
    }

    // Start transaction
    $this->conn->beginTransaction();

    try {
      // Create feed - use display_name for both name and display_name
      // Format name for database storage: lowercase, replace spaces with underscores
      $baseName = strtolower(str_replace(' ', '_', $data['display_name']));

      // Check if name exists and append number if needed
      $name = $baseName;
      $counter = 1;
      while (true) {
        $query = "SELECT COUNT(*) FROM feeds WHERE name = :name";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':name', $name);
        $stmt->execute();
        if ($stmt->fetchColumn() == 0) {
          break;
        }
        $name = $baseName . '_' . $counter;
        $counter++;
      }

      $displayName = $data['display_name'];
      $description = $data['description'];
      $rules = $data['rules'] ?? null;

      $query = "INSERT INTO feeds (name, display_name, description, created_by, rules) 
                     VALUES (:name, :display_name, :description, :created_by, :rules)";

      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':name', $name);
      $stmt->bindParam(':display_name', $displayName);
      $stmt->bindParam(':description', $description);
      $stmt->bindParam(':created_by', $userId);
      $stmt->bindParam(':rules', $rules);
      $stmt->execute();

      $feedId = $this->conn->lastInsertId();

      // Add creator as admin
      $query = "INSERT INTO feed_members (feed_id, user_id, role) 
                     VALUES (:feed_id, :user_id, 'admin')";

      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':feed_id', $feedId);
      $stmt->bindParam(':user_id', $userId);
      $stmt->execute();

      // Update feed_order for creator
      $feedOrderQuery = "SELECT feed_order FROM users WHERE id = :user_id";
      $feedOrderStmt = $this->conn->prepare($feedOrderQuery);
      $feedOrderStmt->bindParam(':user_id', $userId);
      $feedOrderStmt->execute();
      $feedOrderRaw = $feedOrderStmt->fetch(PDO::FETCH_ASSOC)['feed_order'];
      $orderedFeedIds = $feedOrderRaw ? json_decode($feedOrderRaw, true) : [];
      array_unshift($orderedFeedIds, intval($feedId));
      $updateOrderQuery = "UPDATE users SET feed_order = :feed_order WHERE id = :user_id";
      $updateOrderStmt = $this->conn->prepare($updateOrderQuery);
      $updateOrderStmt->bindParam(':feed_order', json_encode($orderedFeedIds));
      $updateOrderStmt->bindParam(':user_id', $userId);
      $updateOrderStmt->execute();

      $this->conn->commit();
      Response::success(['id' => $feedId], 'Feed created successfully');
    } catch (Exception $e) {
      $this->conn->rollBack();
      throw $e;
    }
  }

  private function joinFeed($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['feed_id'])) {
      Response::error('Feed ID is required', 400);
      return;
    }

    $feedId = intval($data['feed_id']);

    // Add to feed_members if not already present
    $query = "INSERT INTO feed_members (feed_id, user_id, role)
                 VALUES (:feed_id, :user_id, 'member')
                 ON DUPLICATE KEY UPDATE role = 'member'";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId);
    $stmt->execute();

    // Update feed_order in users table
    $feedOrderQuery = "SELECT feed_order FROM users WHERE id = :user_id";
    $feedOrderStmt = $this->conn->prepare($feedOrderQuery);
    $feedOrderStmt->bindParam(':user_id', $userId);
    $feedOrderStmt->execute();
    $feedOrderRaw = $feedOrderStmt->fetch(PDO::FETCH_ASSOC)['feed_order'];
    $orderedFeedIds = $feedOrderRaw ? array_map('intval', json_decode($feedOrderRaw, true)) : [];
    $index = array_search($feedId, $orderedFeedIds);
    if ($index !== false) {
      array_splice($orderedFeedIds, $index, 1);
    }
    array_unshift($orderedFeedIds, $feedId);
    $updateOrderQuery = "UPDATE users SET feed_order = :feed_order WHERE id = :user_id";
    $updateOrderStmt = $this->conn->prepare($updateOrderQuery);
    $updateOrderStmt->bindParam(':feed_order', json_encode($orderedFeedIds));
    $updateOrderStmt->bindParam(':user_id', $userId);
    $updateOrderStmt->execute();

    Response::success(null, 'Joined feed successfully');
  }

  // (Duplicate leaveFeed and deleteFeed methods removed)

  private function leaveFeed($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['feed_id'])) {
      Response::error('Feed ID is required', 400);
      return;
    }

    $feedId = intval($data['feed_id']);

    // Check current role
    $query = "SELECT role FROM feed_members WHERE feed_id = :feed_id AND user_id = :user_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $role = $stmt->fetchColumn();

    if (!$role) {
      Response::error('Not a member of this feed', 400);
      return;
    }

    if ($role === 'admin') {
      $query = "SELECT COUNT(*) FROM feed_members WHERE feed_id = :feed_id";
      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->execute();
      $memberCount = (int)$stmt->fetchColumn();

      if ($memberCount > 1) {
        if (!isset($data['new_admin_id'])) {
          Response::error('New admin ID required', 400);
          return;
        }
        $newAdminId = intval($data['new_admin_id']);

        // Ensure new admin is a member
        $query = "SELECT COUNT(*) FROM feed_members WHERE feed_id = :feed_id AND user_id = :new_user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
        $stmt->bindParam(':new_user_id', $newAdminId, PDO::PARAM_INT);
        $stmt->execute();
        if ($stmt->fetchColumn() == 0) {
          Response::error('New admin must be a member of the feed', 400);
          return;
        }

        $query = "UPDATE feed_members SET role = 'admin' WHERE feed_id = :feed_id AND user_id = :new_admin_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
        $stmt->bindParam(':new_admin_id', $newAdminId, PDO::PARAM_INT);
        $stmt->execute();
      } else {
        // Last admin leaving - delete the feed entirely
        $this->deleteFeed($feedId);
      }
    }

    // Remove from feed_members
    $query = "DELETE FROM feed_members WHERE feed_id = :feed_id AND user_id = :user_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();

    // Update feed_order in users table
    $feedOrderQuery = "SELECT feed_order FROM users WHERE id = :user_id";
    $feedOrderStmt = $this->conn->prepare($feedOrderQuery);
    $feedOrderStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $feedOrderStmt->execute();
    $feedOrderRaw = $feedOrderStmt->fetch(PDO::FETCH_ASSOC)['feed_order'];
    $orderedFeedIds = $feedOrderRaw ? array_map('intval', json_decode($feedOrderRaw, true)) : [];
    $index = array_search($feedId, $orderedFeedIds);
    if ($index !== false) {
      array_splice($orderedFeedIds, $index, 1);
      $updateOrderQuery = "UPDATE users SET feed_order = :feed_order WHERE id = :user_id";
      $updateOrderStmt = $this->conn->prepare($updateOrderQuery);
      $updateOrderStmt->bindParam(':feed_order', json_encode($orderedFeedIds));
      $updateOrderStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
      $updateOrderStmt->execute();
    }

    Response::success(null, 'Left feed successfully');
  }

  private function deleteFeed($feedId)
  {
    // Remove all related data and the feed itself
    $this->conn->beginTransaction();
    try {
      $query = "SELECT id FROM feed_posts WHERE feed_id = :feed_id";
      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->execute();
      $postIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

      if (!empty($postIds)) {
        $in = implode(',', array_map('intval', $postIds));
        $this->conn->exec("DELETE FROM feed_votes WHERE post_id IN ($in)");
        $this->conn->exec("DELETE FROM comments WHERE post_id IN ($in)");
        $this->conn->exec("DELETE FROM feed_posts WHERE id IN ($in)");
      }

      $stmt = $this->conn->prepare("DELETE FROM feed_members WHERE feed_id = :feed_id");
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->execute();

      $stmt = $this->conn->prepare("DELETE FROM feeds WHERE id = :feed_id");
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->execute();

      $this->conn->commit();
    } catch (Exception $e) {
      $this->conn->rollBack();
      throw $e;
    }
  }

  private function updateFeed($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['feed_id'])) {
      Response::error('Feed ID is required', 400);
      return;
    }

    $feedId = intval($data['feed_id']);

    // Ensure user is admin
    $query = "SELECT role FROM feed_members WHERE feed_id = :feed_id AND user_id = :user_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $role = $stmt->fetchColumn();

    if ($role !== 'admin') {
      Response::error('Insufficient permissions', 403);
      return;
    }

    $fields = [];
    $params = [':feed_id' => $feedId];
    if (isset($data['display_name'])) {
      $fields[] = 'display_name = :display_name';
      $params[':display_name'] = $data['display_name'];
    }
    if (isset($data['description'])) {
      $fields[] = 'description = :description';
      $params[':description'] = $data['description'];
    }
    if (array_key_exists('rules', $data)) {
      $fields[] = 'rules = :rules';
      $params[':rules'] = $data['rules'];
    }

    if (!empty($fields)) {
      $query = 'UPDATE feeds SET ' . implode(', ', $fields) . ' WHERE id = :feed_id';
      $stmt = $this->conn->prepare($query);
      foreach ($params as $k => $v) {
        if ($k === ':feed_id') {
          $stmt->bindValue($k, $v, PDO::PARAM_INT);
        } else {
          $stmt->bindValue($k, $v);
        }
      }
      $stmt->execute();
    }

    if (isset($data['admin_id']) && intval($data['admin_id']) !== $userId) {
      $newAdminId = intval($data['admin_id']);
      $query = "SELECT COUNT(*) FROM feed_members WHERE feed_id = :feed_id AND user_id = :uid";
      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->bindParam(':uid', $newAdminId, PDO::PARAM_INT);
      $stmt->execute();
      if ($stmt->fetchColumn() == 0) {
        Response::error('New admin must be a member of the feed', 400);
        return;
      }

      $stmt = $this->conn->prepare("UPDATE feed_members SET role = 'admin' WHERE feed_id = :feed_id AND user_id = :uid");
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->bindParam(':uid', $newAdminId, PDO::PARAM_INT);
      $stmt->execute();

      $stmt = $this->conn->prepare("UPDATE feed_members SET role = 'member' WHERE feed_id = :feed_id AND user_id = :uid");
      $stmt->bindParam(':feed_id', $feedId, PDO::PARAM_INT);
      $stmt->bindParam(':uid', $userId, PDO::PARAM_INT);
      $stmt->execute();
    }

    Response::success(null, 'Feed updated successfully');
  }

  private function createPost($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['feed_id']) || !isset($data['title']) || !isset($data['content'])) {
      Response::error('Feed ID, title and content are required', 400);
      return;
    }

    // Verify user is a member of the feed
    $query = "SELECT COUNT(*) FROM feed_members 
                 WHERE feed_id = :feed_id AND user_id = :user_id";

    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':feed_id', $data['feed_id']);
    $stmt->bindValue(':user_id', $userId);
    $stmt->execute();

    if ($stmt->fetchColumn() == 0) {
      Response::error('You must be a member of this feed to post', 403);
      return;
    }

    $query = "INSERT INTO feed_posts (feed_id, user_id, title, content, media_url, media_type) 
                 VALUES (:feed_id, :user_id, :title, :content, :media_url, :media_type)";

    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':feed_id', $data['feed_id']);
    $stmt->bindValue(':user_id', $userId);
    $stmt->bindValue(':title', $data['title']);
    $stmt->bindValue(':content', $data['content']);
    $stmt->bindValue(':media_url', $data['media_url'] ?? null);
    $stmt->bindValue(':media_type', $data['media_type'] ?? 'none');
    $stmt->execute();

    $postId = $this->conn->lastInsertId();
    Response::success(['id' => $postId], 'Post created successfully');
  }

  private function vote($userId)
  {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['post_id']) || !isset($data['vote_type'])) {
      Response::error('Post ID and vote type are required', 400);
      return;
    }

    if (!in_array($data['vote_type'], ['upvote', 'downvote'])) {
      Response::error('Invalid vote type', 400);
      return;
    }

    // Start transaction
    $this->conn->beginTransaction();

    try {
      // Add or update vote
      $query = "INSERT INTO feed_votes (post_id, user_id, vote_type) 
                     VALUES (:post_id, :user_id, :vote_type)
                     ON DUPLICATE KEY UPDATE vote_type = :vote_type";

      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':post_id', $data['post_id']);
      $stmt->bindParam(':user_id', $userId);
      $stmt->bindParam(':vote_type', $data['vote_type']);
      $stmt->execute();

      // Update post scores
      $query = "UPDATE feed_posts 
                     SET upvotes = (
                         SELECT COUNT(*) FROM feed_votes 
                         WHERE post_id = :post_id AND vote_type = 'upvote'
                     ),
                     downvotes = (
                         SELECT COUNT(*) FROM feed_votes 
                         WHERE post_id = :post_id AND vote_type = 'downvote'
                     )
                     WHERE id = :post_id";

      $stmt = $this->conn->prepare($query);
      $stmt->bindParam(':post_id', $data['post_id']);
      $stmt->execute();

      // Calculate and update score using Reddit's algorithm
      $query = "UPDATE feed_posts SET score = :score WHERE id = :post_id";

      $stmt = $this->conn->prepare($query);
      $score = $this->calculateScore($data['post_id']);
      $stmt->bindParam(':score', $score);
      $stmt->bindParam(':post_id', $data['post_id']);
      $stmt->execute();

      $this->conn->commit();
      Response::success(null, 'Vote recorded successfully');
    } catch (Exception $e) {
      $this->conn->rollBack();
      throw $e;
    }
  }

  private function validateJWT($token)
  {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
      return false;
    }

    $header = base64_decode(str_pad(strtr($parts[0], '-_', '+/'), 4 - ((strlen($parts[0]) % 4) ?: 4), '='));
    $payload = base64_decode(str_pad(strtr($parts[1], '-_', '+/'), 4 - ((strlen($parts[1]) % 4) ?: 4), '='));
    $signature = base64_decode(str_pad(strtr($parts[2], '-_', '+/'), 4 - ((strlen($parts[2]) % 4) ?: 4), '='));

    $headerData = json_decode($header, true);
    $payloadData = json_decode($payload, true);

    // Verify header
    if (!isset($headerData['typ']) || $headerData['typ'] !== 'JWT' || !isset($headerData['alg']) || $headerData['alg'] !== 'HS256') {
      return false;
    }

    // Verify expiration
    if (!isset($payloadData['exp']) || $payloadData['exp'] < time()) {
      return false;
    }

    // Verify signature
    $secret_key = "kttProjects2024SecretKey"; // Should match Auth class
    $base64UrlHeader = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64UrlPayload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
    $signatureCheck = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret_key, true);

    if ($signature !== $signatureCheck) {
      return false;
    }

    return $payloadData;
  }

  private function calculateScore($postId)
  {
    // Get post data
    $query = "SELECT created_at, upvotes, downvotes FROM feed_posts WHERE id = :post_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':post_id', $postId);
    $stmt->execute();
    $post = $stmt->fetch(PDO::FETCH_ASSOC);

    $s = $post['upvotes'] - $post['downvotes'];
    $order = log10(max(abs($s), 1));
    $sign = $s > 0 ? 1 : ($s < 0 ? -1 : 0);

    // Get seconds since 2025-01-01 00:00:00
    $epoch = strtotime('2025-01-01 00:00:00');
    $seconds = strtotime($post['created_at']) - $epoch;

    return round($sign * $order + $seconds / 45000, 7);
  }
}

$controller = new FeedController();
$controller->handleRequest();
