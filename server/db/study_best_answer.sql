-- Study Q&A: best answer / resolved setup for existing environments

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE on294_ocs;

-- Ensure study_questions.status exists
SET @has_status := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_questions'
    AND COLUMN_NAME = 'status'
);
SET @sql := IF(
  @has_status = 0,
  "ALTER TABLE study_questions ADD COLUMN status ENUM('open','resolved') NOT NULL DEFAULT 'open' AFTER category",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure study_answers table exists
CREATE TABLE IF NOT EXISTS study_answers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  question_id INT NOT NULL,
  author_user_id INT NOT NULL,
  body TEXT NOT NULL,
  is_best BOOLEAN DEFAULT FALSE,
  moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved',
  moderation_reason VARCHAR(255) NULL,
  moderated_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (question_id) REFERENCES study_questions (id),
  FOREIGN KEY (author_user_id) REFERENCES users (id)
);

-- Ensure point ledger table exists
CREATE TABLE IF NOT EXISTS point_ledger (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  ref_id INT NOT NULL,
  points INT UNSIGNED NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id),
  UNIQUE KEY uq_point_ledger_event_ref_user (event_type, ref_id, user_id)
);

-- Ensure study_answers.is_best exists for pre-existing tables
SET @has_is_best := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_answers'
    AND COLUMN_NAME = 'is_best'
);
SET @sql := IF(
  @has_is_best = 0,
  "ALTER TABLE study_answers ADD COLUMN is_best BOOLEAN NOT NULL DEFAULT FALSE AFTER body",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure indexes exist
SET @has_idx_questions_status := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_questions'
    AND INDEX_NAME = 'idx_study_questions_status'
);
SET @sql := IF(
  @has_idx_questions_status = 0,
  "CREATE INDEX idx_study_questions_status ON study_questions (status)",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_idx_questions_category := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_questions'
    AND INDEX_NAME = 'idx_study_questions_category'
);
SET @sql := IF(
  @has_idx_questions_category = 0,
  "CREATE INDEX idx_study_questions_category ON study_questions (category)",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_idx_answers_question := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_answers'
    AND INDEX_NAME = 'idx_study_answers_question'
);
SET @sql := IF(
  @has_idx_answers_question = 0,
  "CREATE INDEX idx_study_answers_question ON study_answers (question_id)",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_idx_point_ledger_user := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'point_ledger'
    AND INDEX_NAME = 'idx_point_ledger_user'
);
SET @sql := IF(
  @has_idx_point_ledger_user = 0,
  "CREATE INDEX idx_point_ledger_user ON point_ledger (user_id)",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_uq_point_ledger_event_ref_user := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'point_ledger'
    AND INDEX_NAME = 'uq_point_ledger_event_ref_user'
);
SET @sql := IF(
  @has_uq_point_ledger_event_ref_user = 0,
  "CREATE UNIQUE INDEX uq_point_ledger_event_ref_user ON point_ledger (event_type, ref_id, user_id)",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_idx_answers_best := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_answers'
    AND INDEX_NAME = 'idx_study_answers_best'
);
SET @sql := IF(
  @has_idx_answers_best = 0,
  "CREATE INDEX idx_study_answers_best ON study_answers (question_id, is_best)",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
