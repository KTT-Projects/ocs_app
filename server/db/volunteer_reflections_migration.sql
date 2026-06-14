-- Migration: reflections for volunteer opportunities
USE on294_ocs;

CREATE TABLE IF NOT EXISTS volunteer_reflections (
  id INT AUTO_INCREMENT PRIMARY KEY,
  opportunity_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  created_by INT NOT NULL,
  moderation_status ENUM('approved','pending','hidden','blocked') NOT NULL DEFAULT 'approved',
  moderation_reason VARCHAR(255) NULL,
  moderated_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (opportunity_id) REFERENCES volunteer_opportunities (id),
  FOREIGN KEY (created_by) REFERENCES users (id),
  INDEX idx_volunteer_reflection_opportunity (opportunity_id),
  INDEX idx_volunteer_reflection_created_by (created_by)
);

CREATE TABLE IF NOT EXISTS volunteer_reflection_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  reflection_id INT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(255) NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  file_size INT NULL,
  uploaded_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reflection_id) REFERENCES volunteer_reflections (id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users (id),
  INDEX idx_reflection_images_reflection (reflection_id),
  INDEX idx_reflection_images_uploaded_by (uploaded_by)
);
