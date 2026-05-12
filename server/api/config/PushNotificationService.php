<?php

class PushNotificationService
{
  private $conn;
  private $projectId;
  private $serviceAccountPath;
  private $serviceAccountJson;
  private $accessToken = null;
  private $accessTokenExpiresAt = 0;

  private const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
  private const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
  private const VALID_PLATFORMS = ['ios', 'android', 'web'];
  private const MAX_ATTEMPTS = 3;

  public function __construct($db)
  {
    $this->conn = $db;
    $this->projectId = $this->env('FCM_PROJECT_ID');
    $this->serviceAccountPath = $this->env('GOOGLE_APPLICATION_CREDENTIALS') ?: $this->env('FCM_SERVICE_ACCOUNT_PATH');
    $this->serviceAccountJson = $this->env('FCM_SERVICE_ACCOUNT_JSON');
    if (empty($this->serviceAccountJson) && $this->env('FCM_SERVICE_ACCOUNT_JSON_BASE64')) {
      $decoded = base64_decode($this->env('FCM_SERVICE_ACCOUNT_JSON_BASE64'), true);
      $this->serviceAccountJson = $decoded === false ? null : $decoded;
    }
  }

  public function isConfigured()
  {
    return !empty($this->projectId) && (!empty($this->serviceAccountPath) || !empty($this->serviceAccountJson));
  }

  public function registerDevice($userId, $platform, $token, $deviceId = null, $appVersion = null, $locale = null)
  {
    $platform = strtolower(trim((string)$platform));
    $token = trim((string)$token);
    $deviceId = $this->emptyToNull($deviceId);
    $appVersion = $this->emptyToNull($appVersion);
    $locale = $this->emptyToNull($locale);

    if (!in_array($platform, self::VALID_PLATFORMS, true)) {
      throw new InvalidArgumentException('Invalid push platform');
    }
    if ($token === '') {
      throw new InvalidArgumentException('Push token is required');
    }

    $tokenHash = hash('sha256', $token);
    $query = "INSERT INTO push_devices
                (user_id, platform, fcm_token, token_hash, device_id, app_version, locale, enabled, last_registered_at, last_seen_at)
              VALUES
                (:user_id, :platform, :fcm_token, :token_hash, :device_id, :app_version, :locale, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
              ON DUPLICATE KEY UPDATE
                user_id = VALUES(user_id),
                platform = VALUES(platform),
                fcm_token = VALUES(fcm_token),
                device_id = VALUES(device_id),
                app_version = VALUES(app_version),
                locale = VALUES(locale),
                enabled = 1,
                last_registered_at = CURRENT_TIMESTAMP,
                last_seen_at = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':platform', $platform);
    $stmt->bindValue(':fcm_token', $token);
    $stmt->bindValue(':token_hash', $tokenHash);
    $stmt->bindValue(':device_id', $deviceId);
    $stmt->bindValue(':app_version', $appVersion);
    $stmt->bindValue(':locale', $locale);
    $stmt->execute();

    if ($deviceId !== null) {
      $this->disableStaleDeviceTokens($userId, $deviceId, $tokenHash);
    }

    return [
      'token_hash' => $tokenHash,
      'platform' => $platform
    ];
  }

  public function unregisterDevice($userId, $token = null, $deviceId = null)
  {
    $token = $this->emptyToNull($token);
    $deviceId = $this->emptyToNull($deviceId);
    if ($token === null && $deviceId === null) {
      throw new InvalidArgumentException('Push token or device ID is required');
    }

    if ($token !== null) {
      $tokenHash = hash('sha256', trim((string)$token));
      $stmt = $this->conn->prepare("UPDATE push_devices SET enabled = 0, updated_at = CURRENT_TIMESTAMP WHERE user_id = :user_id AND token_hash = :token_hash");
      $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
      $stmt->bindValue(':token_hash', $tokenHash);
      $stmt->execute();
      return $stmt->rowCount();
    }

    $stmt = $this->conn->prepare("UPDATE push_devices SET enabled = 0, updated_at = CURRENT_TIMESTAMP WHERE user_id = :user_id AND device_id = :device_id");
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':device_id', $deviceId);
    $stmt->execute();
    return $stmt->rowCount();
  }

  public function listDevices($userId)
  {
    $stmt = $this->conn->prepare(
      "SELECT id, platform, token_hash, device_id, app_version, locale, enabled, last_registered_at, last_seen_at, created_at, updated_at
       FROM push_devices
       WHERE user_id = :user_id
       ORDER BY updated_at DESC"
    );
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  public function sendToUsers(array $userIds, $type, $title, $body, array $data = [], $actorUserId = null)
  {
    $userIds = $this->normalizeUserIds($userIds);
    if (empty($userIds)) {
      return ['queued' => 0, 'sent' => 0, 'failed' => 0, 'skipped' => 0];
    }

    $devices = $this->getActiveDevicesForUsers($userIds);
    $stats = ['queued' => 0, 'sent' => 0, 'failed' => 0, 'skipped' => 0];

    foreach ($devices as $device) {
      $notificationId = $this->enqueueNotification(
        intval($device['user_id']),
        intval($device['id']),
        $type,
        $title,
        $body,
        $data,
        $actorUserId
      );
      $stats['queued']++;

      if (!$this->isConfigured()) {
        continue;
      }

      $status = $this->sendNotificationById($notificationId);
      $stats[$status] = ($stats[$status] ?? 0) + 1;
    }

    return $stats;
  }

  public function flushPending($limit = 50)
  {
    $limit = max(1, min(200, intval($limit)));
    $query = "SELECT pn.id
              FROM push_notifications pn
              JOIN push_devices pd ON pd.id = pn.device_id
              WHERE pn.status IN ('pending', 'failed')
                AND pn.attempts < :max_attempts
                AND pd.enabled = 1
              ORDER BY pn.created_at ASC
              LIMIT :limit";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':max_attempts', self::MAX_ATTEMPTS, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->execute();
    $ids = array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));

    $stats = ['sent' => 0, 'failed' => 0, 'skipped' => 0, 'pending' => count($ids)];
    if (!$this->isConfigured()) {
      return $stats;
    }

    foreach ($ids as $id) {
      $status = $this->sendNotificationById($id);
      $stats[$status] = ($stats[$status] ?? 0) + 1;
    }
    return $stats;
  }

  public function getActiveUserIdsExcept($excludedUserId = null)
  {
    $query = "SELECT id FROM users WHERE is_active = 1 AND is_verified = 1";
    $params = [];
    if ($excludedUserId !== null) {
      $query .= " AND id != ?";
      $params[] = intval($excludedUserId);
    }
    $stmt = $this->conn->prepare($query);
    $stmt->execute($params);
    return array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));
  }

  public function getDisplayName($userId)
  {
    $stmt = $this->conn->prepare("SELECT display_name FROM user_profiles WHERE user_id = :user_id LIMIT 1");
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $name = $stmt->fetchColumn();
    return $name ?: 'Someone';
  }

  private function enqueueNotification($userId, $deviceId, $type, $title, $body, array $data, $actorUserId = null)
  {
    $entityType = $data['entity_type'] ?? ($data['type'] ?? null);
    $entityId = isset($data['entity_id']) ? intval($data['entity_id']) : null;

    $query = "INSERT INTO push_notifications
                (user_id, device_id, actor_user_id, type, entity_type, entity_id, title, body, data_json, status)
              VALUES
                (:user_id, :device_id, :actor_user_id, :type, :entity_type, :entity_id, :title, :body, :data_json, 'pending')";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':device_id', $deviceId, PDO::PARAM_INT);
    $stmt->bindValue(':actor_user_id', $actorUserId, $actorUserId === null ? PDO::PARAM_NULL : PDO::PARAM_INT);
    $stmt->bindValue(':type', substr((string)$type, 0, 50));
    $stmt->bindValue(':entity_type', $entityType === null ? null : substr((string)$entityType, 0, 50));
    $stmt->bindValue(':entity_id', $entityId, $entityId === null ? PDO::PARAM_NULL : PDO::PARAM_INT);
    $stmt->bindValue(':title', substr((string)$title, 0, 255));
    $stmt->bindValue(':body', substr((string)$body, 0, 500));
    $stmt->bindValue(':data_json', json_encode($this->stringifyData($data), JSON_UNESCAPED_UNICODE));
    $stmt->execute();
    return intval($this->conn->lastInsertId());
  }

  private function sendNotificationById($notificationId)
  {
    $query = "SELECT pn.*, pd.fcm_token, pd.platform, pd.enabled
              FROM push_notifications pn
              JOIN push_devices pd ON pd.id = pn.device_id
              WHERE pn.id = :id
              LIMIT 1";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':id', $notificationId, PDO::PARAM_INT);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
      return 'failed';
    }

    if (intval($row['enabled']) !== 1) {
      $this->updateNotificationStatus($notificationId, 'skipped', null, 'Device disabled');
      return 'skipped';
    }

    try {
      $data = json_decode($row['data_json'] ?? '{}', true);
      if (!is_array($data)) $data = [];
      $response = $this->sendToToken(
        $row['fcm_token'],
        $row['platform'],
        $row['title'],
        $row['body'],
        $data
      );
      $this->updateNotificationStatus($notificationId, 'sent', $response, null);
      return 'sent';
    } catch (Exception $e) {
      $message = $e->getMessage();
      $invalidToken = $this->isInvalidTokenError($message);
      $status = $invalidToken ? 'skipped' : 'failed';
      $this->updateNotificationStatus($notificationId, $status, null, $message);
      if ($invalidToken) {
        $this->disableDevice(intval($row['device_id']));
      }
      error_log('Push notification failed: ' . $message);
      return $status;
    }
  }

  private function sendToToken($token, $platform, $title, $body, array $data)
  {
    $accessToken = $this->getAccessToken();
    $url = 'https://fcm.googleapis.com/v1/projects/' . rawurlencode($this->projectId) . '/messages:send';
    $message = [
      'message' => [
        'token' => $token,
        'notification' => [
          'title' => $title,
          'body' => $body
        ],
        'data' => $this->stringifyData($data),
        'android' => [
          'priority' => 'HIGH',
          'notification' => [
            'channel_id' => 'ocs_app_activity',
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
          ]
        ],
        'apns' => [
          'headers' => [
            'apns-priority' => '10'
          ],
          'payload' => [
            'aps' => [
              'alert' => [
                'title' => $title,
                'body' => $body
              ],
              'sound' => 'default'
            ]
          ]
        ],
        'webpush' => [
          'notification' => [
            'title' => $title,
            'body' => $body,
            'icon' => '/icons/Icon-192.png'
          ],
          'fcm_options' => [
            'link' => $data['web_link'] ?? '/'
          ]
        ]
      ]
    ];

    return $this->postJson($url, $message, [
      'Authorization: Bearer ' . $accessToken,
      'Content-Type: application/json; charset=utf-8'
    ]);
  }

  private function getActiveDevicesForUsers(array $userIds)
  {
    if (empty($userIds)) return [];
    $placeholders = implode(',', array_fill(0, count($userIds), '?'));
    $query = "SELECT pd.*
              FROM push_devices pd
              JOIN users u ON u.id = pd.user_id
              WHERE pd.user_id IN ($placeholders)
                AND pd.enabled = 1
                AND u.is_active = 1";
    $stmt = $this->conn->prepare($query);
    $stmt->execute($userIds);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  private function getAccessToken()
  {
    if ($this->accessToken && time() < $this->accessTokenExpiresAt - 60) {
      return $this->accessToken;
    }

    $account = $this->loadServiceAccount();
    $now = time();
    $header = [
      'alg' => 'RS256',
      'typ' => 'JWT'
    ];
    if (!empty($account['private_key_id'])) {
      $header['kid'] = $account['private_key_id'];
    }

    $payload = [
      'iss' => $account['client_email'],
      'scope' => self::FCM_SCOPE,
      'aud' => $account['token_uri'] ?? self::DEFAULT_TOKEN_URI,
      'iat' => $now,
      'exp' => $now + 3600
    ];

    $unsigned = $this->base64urlEncode(json_encode($header)) . '.' . $this->base64urlEncode(json_encode($payload));
    $privateKey = openssl_pkey_get_private($account['private_key']);
    if (!$privateKey) {
      throw new RuntimeException('Invalid FCM service account private key');
    }
    $signature = '';
    if (!openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256)) {
      throw new RuntimeException('Failed to sign FCM access token assertion');
    }

    $jwt = $unsigned . '.' . $this->base64urlEncode($signature);
    $response = $this->postForm($account['token_uri'] ?? self::DEFAULT_TOKEN_URI, [
      'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion' => $jwt
    ]);

    if (empty($response['access_token'])) {
      throw new RuntimeException('FCM access token response did not include access_token');
    }

    $this->accessToken = $response['access_token'];
    $this->accessTokenExpiresAt = $now + intval($response['expires_in'] ?? 3600);
    return $this->accessToken;
  }

  private function loadServiceAccount()
  {
    $raw = null;
    if (!empty($this->serviceAccountJson)) {
      $raw = $this->serviceAccountJson;
    } elseif (!empty($this->serviceAccountPath) && is_readable($this->serviceAccountPath)) {
      $raw = file_get_contents($this->serviceAccountPath);
    }

    if (!$raw) {
      throw new RuntimeException('FCM service account credentials are not configured');
    }

    $account = json_decode($raw, true);
    if (!is_array($account) || empty($account['client_email']) || empty($account['private_key'])) {
      throw new RuntimeException('Invalid FCM service account JSON');
    }
    return $account;
  }

  private function postJson($url, array $payload, array $headers)
  {
    return $this->curlPost($url, json_encode($payload, JSON_UNESCAPED_UNICODE), $headers);
  }

  private function postForm($url, array $fields)
  {
    return $this->curlPost($url, http_build_query($fields), [
      'Content-Type: application/x-www-form-urlencoded'
    ]);
  }

  private function curlPost($url, $body, array $headers)
  {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_TIMEOUT, 12);
    $raw = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($raw === false) {
      throw new RuntimeException('Push HTTP request failed: ' . $error);
    }

    $decoded = json_decode($raw, true);
    if ($status < 200 || $status >= 300) {
      $message = is_array($decoded) ? json_encode($decoded, JSON_UNESCAPED_UNICODE) : $raw;
      throw new RuntimeException('Push HTTP ' . $status . ': ' . $message);
    }

    return is_array($decoded) ? $decoded : ['raw' => $raw];
  }

  private function updateNotificationStatus($notificationId, $status, $response = null, $errorMessage = null)
  {
    $query = "UPDATE push_notifications
              SET status = :status,
                  attempts = attempts + 1,
                  response = :response,
                  error_message = :error_message,
                  last_attempt_at = CURRENT_TIMESTAMP,
                  sent_at = CASE WHEN :sent_status = 'sent' THEN CURRENT_TIMESTAMP ELSE sent_at END
              WHERE id = :id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindValue(':status', $status);
    $stmt->bindValue(':response', $response === null ? null : json_encode($response, JSON_UNESCAPED_UNICODE));
    $stmt->bindValue(':error_message', $errorMessage);
    $stmt->bindValue(':sent_status', $status);
    $stmt->bindValue(':id', $notificationId, PDO::PARAM_INT);
    $stmt->execute();
  }

  private function disableDevice($deviceId)
  {
    $stmt = $this->conn->prepare("UPDATE push_devices SET enabled = 0, updated_at = CURRENT_TIMESTAMP WHERE id = :id");
    $stmt->bindValue(':id', $deviceId, PDO::PARAM_INT);
    $stmt->execute();
  }

  private function disableStaleDeviceTokens($userId, $deviceId, $activeTokenHash)
  {
    $stmt = $this->conn->prepare(
      "UPDATE push_devices
       SET enabled = 0, updated_at = CURRENT_TIMESTAMP
       WHERE user_id = :user_id
         AND device_id = :device_id
         AND token_hash != :token_hash"
    );
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':device_id', $deviceId);
    $stmt->bindValue(':token_hash', $activeTokenHash);
    $stmt->execute();
  }

  private function stringifyData(array $data)
  {
    $result = [];
    foreach ($data as $key => $value) {
      if ($value === null) continue;
      if (is_bool($value)) {
        $result[$key] = $value ? 'true' : 'false';
      } elseif (is_scalar($value)) {
        $result[$key] = (string)$value;
      } else {
        $result[$key] = json_encode($value, JSON_UNESCAPED_UNICODE);
      }
    }
    return $result;
  }

  private function normalizeUserIds(array $userIds)
  {
    $normalized = [];
    foreach ($userIds as $id) {
      $value = intval($id);
      if ($value > 0) $normalized[$value] = $value;
    }
    return array_values($normalized);
  }

  private function isInvalidTokenError($message)
  {
    return stripos($message, 'UNREGISTERED') !== false ||
      stripos($message, 'registration-token-not-registered') !== false ||
      stripos($message, 'Requested entity was not found') !== false;
  }

  private function base64urlEncode($data)
  {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
  }

  private function emptyToNull($value)
  {
    if ($value === null) return null;
    $value = trim((string)$value);
    return $value === '' ? null : $value;
  }

  private function env($key)
  {
    $value = getenv($key);
    return $value === false ? null : $value;
  }
}
