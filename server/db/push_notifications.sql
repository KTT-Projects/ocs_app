-- Push notification device registry and delivery queue.
-- FCM tokens are stored server-side; token_hash is used for unique lookups.

CREATE TABLE IF NOT EXISTS push_devices (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  platform ENUM('ios', 'android', 'web') NOT NULL,
  fcm_token TEXT NOT NULL,
  token_hash CHAR(64) NOT NULL,
  device_id VARCHAR(191) NULL,
  app_version VARCHAR(50) NULL,
  locale VARCHAR(16) NULL,
  enabled BOOLEAN DEFAULT TRUE,
  last_registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_push_devices_token_hash (token_hash),
  KEY idx_push_devices_user_enabled (user_id, enabled),
  KEY idx_push_devices_device (user_id, device_id),
  KEY idx_push_devices_platform (platform),
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS push_notifications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  device_id INT NULL,
  actor_user_id INT NULL,
  type VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50) NULL,
  entity_id INT NULL,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(500) NOT NULL,
  data_json TEXT NULL,
  status ENUM('pending', 'sent', 'failed', 'skipped') NOT NULL DEFAULT 'pending',
  attempts INT NOT NULL DEFAULT 0,
  response TEXT NULL,
  error_message TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_attempt_at TIMESTAMP NULL,
  sent_at TIMESTAMP NULL,
  KEY idx_push_notifications_status_created (status, created_at),
  KEY idx_push_notifications_user_created (user_id, created_at),
  KEY idx_push_notifications_entity (entity_type, entity_id),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (device_id) REFERENCES push_devices (id),
  FOREIGN KEY (actor_user_id) REFERENCES users (id)
);
