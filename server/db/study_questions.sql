-- Study Q&A (Question only) table setup
-- Run this on existing environments where the table does not exist yet.

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE on294_ocs;

CREATE TABLE IF NOT EXISTS study_questions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  author_user_id INT NOT NULL,
  title VARCHAR(300) NOT NULL,
  body TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  status ENUM ('open', 'resolved') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (author_user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS study_answers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  question_id INT NOT NULL,
  author_user_id INT NOT NULL,
  body TEXT NOT NULL,
  is_best BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (question_id) REFERENCES study_questions (id),
  FOREIGN KEY (author_user_id) REFERENCES users (id)
);

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

CREATE INDEX idx_study_questions_author ON study_questions (author_user_id);
CREATE INDEX idx_study_questions_status ON study_questions (status);
CREATE INDEX idx_study_questions_created_at ON study_questions (created_at);
CREATE INDEX idx_study_answers_question ON study_answers (question_id);
CREATE INDEX idx_study_answers_best ON study_answers (question_id, is_best);
CREATE INDEX idx_point_ledger_user ON point_ledger (user_id);
