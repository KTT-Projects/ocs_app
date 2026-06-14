-- Moderation tables and content status fields
-- Safe to run more than once on existing environments.

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE on294_ocs;

CREATE TABLE IF NOT EXISTS moderation_cases (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT NOT NULL,
  subject_user_id INT NULL,
  reporter_user_id INT NULL,
  source ENUM('automatic', 'report', 'manual') NOT NULL DEFAULT 'automatic',
  decision ENUM('approved', 'pending', 'blocked') NOT NULL DEFAULT 'pending',
  status ENUM('pending', 'approved', 'hidden', 'blocked', 'dismissed') NOT NULL DEFAULT 'pending',
  severity ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'low',
  reason_codes TEXT NULL,
  content_snapshot MEDIUMTEXT NULL,
  provider VARCHAR(50) NULL,
  provider_response MEDIUMTEXT NULL,
  reviewed_by INT NULL,
  reviewer_note TEXT NULL,
  reviewed_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_mod_cases_status_created (status, created_at),
  KEY idx_mod_cases_entity (entity_type, entity_id),
  KEY idx_mod_cases_subject (subject_user_id),
  KEY idx_mod_cases_reporter (reporter_user_id),
  FOREIGN KEY (subject_user_id) REFERENCES users (id),
  FOREIGN KEY (reporter_user_id) REFERENCES users (id),
  FOREIGN KEY (reviewed_by) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS moderation_reports (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  case_id BIGINT NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT NOT NULL,
  reporter_user_id INT NOT NULL,
  reason ENUM('spam', 'harassment', 'hate', 'sexual', 'violence', 'self_harm', 'privacy', 'other') NOT NULL DEFAULT 'other',
  details TEXT NULL,
  status ENUM('open', 'reviewed', 'dismissed') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_reporter_entity (reporter_user_id, entity_type, entity_id),
  KEY idx_mod_reports_case (case_id),
  KEY idx_mod_reports_entity (entity_type, entity_id),
  KEY idx_mod_reports_status (status),
  FOREIGN KEY (case_id) REFERENCES moderation_cases (id),
  FOREIGN KEY (reporter_user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS moderation_actions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  case_id BIGINT NOT NULL,
  moderator_user_id INT NOT NULL,
  action ENUM('approve', 'restore', 'hide', 'block', 'dismiss') NOT NULL,
  note TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_mod_actions_case (case_id),
  KEY idx_mod_actions_moderator (moderator_user_id),
  FOREIGN KEY (case_id) REFERENCES moderation_cases (id),
  FOREIGN KEY (moderator_user_id) REFERENCES users (id)
);

-- feeds
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feeds' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE feeds ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feeds' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE feeds ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feeds' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE feeds ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- feed_posts
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feed_posts' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE feed_posts ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feed_posts' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE feed_posts ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feed_posts' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE feed_posts ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- comments
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'comments' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE comments ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'comments' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE comments ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'comments' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE comments ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- study_questions
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_questions' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE study_questions ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_questions' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE study_questions ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_questions' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE study_questions ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- study_answers
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_answers' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE study_answers ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_answers' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE study_answers ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_answers' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE study_answers ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- volunteer_opportunities
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_opportunities' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE volunteer_opportunities ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_opportunities' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE volunteer_opportunities ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_opportunities' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE volunteer_opportunities ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- volunteer_reflections
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_reflections' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE volunteer_reflections ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_reflections' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE volunteer_reflections ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_reflections' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE volunteer_reflections ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- user_profiles
SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profiles' AND COLUMN_NAME = 'moderation_status'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE user_profiles ADD COLUMN moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved'", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profiles' AND COLUMN_NAME = 'moderation_reason'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE user_profiles ADD COLUMN moderation_reason VARCHAR(255) NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_col := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profiles' AND COLUMN_NAME = 'moderated_at'
);
SET @sql := IF(@has_col = 0, "ALTER TABLE user_profiles ADD COLUMN moderated_at TIMESTAMP NULL DEFAULT NULL", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Indexes for moderation_status. Existing setups may already have some indexes.
SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feeds' AND INDEX_NAME = 'idx_feeds_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_feeds_moderation_status ON feeds (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'feed_posts' AND INDEX_NAME = 'idx_feed_posts_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_feed_posts_moderation_status ON feed_posts (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'comments' AND INDEX_NAME = 'idx_comments_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_comments_moderation_status ON comments (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_questions' AND INDEX_NAME = 'idx_study_questions_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_study_questions_moderation_status ON study_questions (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'study_answers' AND INDEX_NAME = 'idx_study_answers_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_study_answers_moderation_status ON study_answers (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_opportunities' AND INDEX_NAME = 'idx_volunteer_opportunities_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_volunteer_opportunities_moderation_status ON volunteer_opportunities (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'volunteer_reflections' AND INDEX_NAME = 'idx_volunteer_reflections_moderation_status');
SET @sql := IF(@has_idx = 0, "CREATE INDEX idx_volunteer_reflections_moderation_status ON volunteer_reflections (moderation_status)", "SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
