<?php
// CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config/Database.php';
require_once 'config/Auth.php';
require_once 'config/Response.php';

class FeedController {
    private $db;
    private $auth;
    private $conn;

    public function __construct() {
        $this->db = new Database();
        $this->conn = $this->db->getConnection();
        $this->auth = new Auth($this->conn);
    }

    public function handleRequest() {
        $method = $_SERVER['REQUEST_METHOD'];
        $action = isset($_GET['action']) ? $_GET['action'] : '';

        try {
            // Get authorization header
            $headers = getallheaders();
            if (!isset($headers['Authorization']) && !($method === 'GET' && $action === 'list')) {
                Response::error('Authorization header is required', 401);
                return;
            }

            // Verify JWT for all requests except GET feeds
            if (!($method === 'GET' && $action === 'list')) {
                $token = str_replace('Bearer ', '', $headers['Authorization']);
                $decoded = $this->validateJWT($token);
                if (!$decoded) {
                    Response::error('Invalid or expired token', 401);
                    return;
                }
                $userId = $decoded['user_id'];
            }

            switch ($method) {
                case 'GET':
                    if ($action === 'list') {
                        $this->getFeeds();
                    } else if ($action === 'posts') {
                        $this->getFeedPosts();
                    } else if ($action === 'home') {
                        $this->getHomeFeed($userId);
                    }
                    break;
                case 'POST':
                    if ($action === 'create') {
                        $this->createFeed($userId);
                    } else if ($action === 'join') {
                        $this->joinFeed($userId);
                    } else if ($action === 'post') {
                        $this->createPost($userId);
                    } else if ($action === 'vote') {
                        $this->vote($userId);
                    } else if ($action === 'reorder') {
                        $this->reorderFeeds($userId);
                    }
                    break;
                default:
                    Response::error('Method not allowed', 405);
            }
        } catch (Exception $e) {
            Response::error($e->getMessage(), 500);
        }
    }

    private function getFeeds() {
        // Get user ID from token if available
        $headers = getallheaders();
        $userId = null;
        if (isset($headers['Authorization'])) {
            $token = str_replace('Bearer ', '', $headers['Authorization']);
            $decoded = $this->validateJWT($token);
            if ($decoded) {
                $userId = $decoded['user_id'];
            }
        }

        // Modified query to include display_order
        $query = "SELECT f.*, 
                  COUNT(DISTINCT fm1.user_id) as member_count,
                  COUNT(DISTINCT fp.id) as post_count,
                  IF(fm2.user_id IS NOT NULL, 1, 0) as is_member,
                  COALESCE(fm2.display_order, 0) as display_order
                  FROM feeds f 
                  LEFT JOIN feed_members fm1 ON f.id = fm1.feed_id 
                  LEFT JOIN feed_posts fp ON f.id = fp.feed_id 
                  LEFT JOIN feed_members fm2 ON f.id = fm2.feed_id AND fm2.user_id = :user_id
                  GROUP BY f.id 
                  ORDER BY fm2.display_order ASC, member_count DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();
        $feeds = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        Response::success($feeds, 'Feeds retrieved successfully');
    }

    private function reorderFeeds($userId) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['feed_orders']) || !is_array($data['feed_orders'])) {
            Response::error('Feed orders array is required', 400);
            return;
        }

        $this->conn->beginTransaction();

        try {
            foreach ($data['feed_orders'] as $feedOrder) {
                if (!isset($feedOrder['feed_id']) || !isset($feedOrder['order'])) {
                    throw new Exception('Feed ID and order are required for each feed');
                }

                $query = "UPDATE feed_members 
                         SET display_order = :order 
                         WHERE feed_id = :feed_id AND user_id = :user_id";
                
                $stmt = $this->conn->prepare($query);
                $stmt->bindParam(':order', $feedOrder['order'], PDO::PARAM_INT);
                $stmt->bindParam(':feed_id', $feedOrder['feed_id'], PDO::PARAM_INT);
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->execute();
            }

            $this->conn->commit();
            Response::success(null, 'Feed order updated successfully');
        } catch (Exception $e) {
            $this->conn->rollBack();
            throw $e;
        }
    }

    private function getFeedPosts() {
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

    private function getHomeFeed($userId) {
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

    private function createFeed($userId) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['name']) || !isset($data['display_name']) || !isset($data['description'])) {
            Response::error('Name, display name and description are required', 400);
            return;
        }

        // Start transaction
        $this->conn->beginTransaction();

        try {
            // Create feed
            $query = "INSERT INTO feeds (name, display_name, description, created_by, rules) 
                     VALUES (:name, :display_name, :description, :created_by, :rules)";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':name', $data['name']);
            $stmt->bindParam(':display_name', $data['display_name']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':created_by', $userId);
            $stmt->bindParam(':rules', $data['rules'] ?? null);
            $stmt->execute();
            
            $feedId = $this->conn->lastInsertId();

            // Add creator as admin
            $query = "INSERT INTO feed_members (feed_id, user_id, role) 
                     VALUES (:feed_id, :user_id, 'admin')";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':feed_id', $feedId);
            $stmt->bindParam(':user_id', $userId);
            $stmt->execute();

            $this->conn->commit();
            Response::success(['id' => $feedId], 'Feed created successfully');
        } catch (Exception $e) {
            $this->conn->rollBack();
            throw $e;
        }
    }

    private function joinFeed($userId) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['feed_id'])) {
            Response::error('Feed ID is required', 400);
            return;
        }

        // Get current max display_order for user
        $query = "SELECT COALESCE(MAX(display_order), 0) as max_order 
                 FROM feed_members 
                 WHERE user_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        $maxOrder = $stmt->fetch(PDO::FETCH_ASSOC)['max_order'];

        $query = "INSERT INTO feed_members (feed_id, user_id, display_order) 
                 VALUES (:feed_id, :user_id, :display_order)
                 ON DUPLICATE KEY UPDATE role = 'member'";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':feed_id', $data['feed_id']);
        $stmt->bindParam(':user_id', $userId);
        $displayOrder = $maxOrder + 1;
        $stmt->bindParam(':display_order', $displayOrder);
        $stmt->execute();

        Response::success(null, 'Joined feed successfully');
    }

    private function createPost($userId) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['feed_id']) || !isset($data['title']) || !isset($data['content'])) {
            Response::error('Feed ID, title and content are required', 400);
            return;
        }

        // Verify user is a member of the feed
        $query = "SELECT COUNT(*) FROM feed_members 
                 WHERE feed_id = :feed_id AND user_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':feed_id', $data['feed_id']);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        
        if ($stmt->fetchColumn() == 0) {
            Response::error('You must be a member of this feed to post', 403);
            return;
        }

        $query = "INSERT INTO feed_posts (feed_id, user_id, title, content, media_url, media_type) 
                 VALUES (:feed_id, :user_id, :title, :content, :media_url, :media_type)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':feed_id', $data['feed_id']);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':title', $data['title']);
        $stmt->bindParam(':content', $data['content']);
        $stmt->bindParam(':media_url', $data['media_url'] ?? null);
        $stmt->bindParam(':media_type', $data['media_type'] ?? 'none');
        $stmt->execute();

        $postId = $this->conn->lastInsertId();
        Response::success(['id' => $postId], 'Post created successfully');
    }

    private function vote($userId) {
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

    private function validateJWT($token) {
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

    private function calculateScore($postId) {
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
