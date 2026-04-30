-- Study Q&A question media migration
-- Adds media_url column to study_questions for optional image attachment.

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE on294_ocs;

SET @has_media_url := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_questions'
    AND COLUMN_NAME = 'media_url'
);

SET @sql := IF(
  @has_media_url = 0,
  "ALTER TABLE study_questions ADD COLUMN media_url VARCHAR(255) NULL AFTER body",
  "SELECT 1"
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS study_question_media (
  id INT PRIMARY KEY AUTO_INCREMENT,
  question_id INT NOT NULL,
  media_url VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (question_id) REFERENCES study_questions (id)
);

SET @has_idx_study_question_media_question := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_question_media'
    AND INDEX_NAME = 'idx_study_question_media_question'
);

SET @sql := IF(
  @has_idx_study_question_media_question = 0,
  "CREATE INDEX idx_study_question_media_question ON study_question_media (question_id, sort_order)",
  "SELECT 1"
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
