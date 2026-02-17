-- Study Q&A tag migration
-- Converts category storage to multi-tag CSV capacity.

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE on294_ocs;

SET @category_length := (
  SELECT CHARACTER_MAXIMUM_LENGTH
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'study_questions'
    AND COLUMN_NAME = 'category'
  LIMIT 1
);

SET @sql := IF(
  @category_length IS NOT NULL AND @category_length < 300,
  "ALTER TABLE study_questions MODIFY COLUMN category VARCHAR(300) NOT NULL",
  "SELECT 1"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
