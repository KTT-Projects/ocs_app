-- Migration: add attachments for volunteer opportunities (images/PDFs)
USE on294_ocs;

CREATE TABLE IF NOT EXISTS volunteer_attachments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  opportunity_id INT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(255) NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  file_size INT NULL,
  uploaded_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (opportunity_id) REFERENCES volunteer_opportunities (id),
  FOREIGN KEY (uploaded_by) REFERENCES users (id),
  INDEX idx_volunteer_attachments_opportunity (opportunity_id),
  INDEX idx_volunteer_attachments_user (uploaded_by)
);
