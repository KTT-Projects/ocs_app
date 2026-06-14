-- Database setup for Osakikamijima Student Community Site
-- Enable UTF-8 character encoding
SET
  NAMES utf8mb4;

SET
  CHARACTER
SET
  utf8mb4;

-- Run this script while connected to the target application database.

-- Drop existing tables if they exist
DROP TABLE IF EXISTS notifications,
moderation_actions,
moderation_reports,
moderation_cases,
push_notifications,
notification_preferences,
push_devices,
post_attachments,
comments,
direct_messages,
chat_group_members,
group_messages,
event_participants,
volunteer_attachments,
volunteer_participants,
volunteer_reflection_images,
volunteer_reflections,
study_question_media,
study_questions,
study_answers,
point_ledger,
answers,
tutor_sessions,
feed_votes,
feed_posts,
feed_members,
user_skills,
user_profiles,
questions,
tutors,
events,
volunteer_opportunities,
feeds,
chat_groups,
users,
skills,
roles,
educational_institutions;

-- Educational institutions table
CREATE TABLE
  educational_institutions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email_domain VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  );

-- User roles table
CREATE TABLE
  roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

-- Users table
CREATE TABLE
  users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    institution_id INT NOT NULL,
    grade TINYINT CHECK (
      grade BETWEEN 7 AND 14
      OR grade = 99
    ), -- 99 represents OB
    is_verified BOOLEAN DEFAULT FALSE,
    verification_otp VARCHAR(6),
    otp_expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    reset_token VARCHAR(64) NULL,
    reset_token_expiry DATETIME NULL,
    feed_order TEXT,
    FOREIGN KEY (role_id) REFERENCES roles (id),
    FOREIGN KEY (institution_id) REFERENCES educational_institutions (id)
  );

-- User profiles table
CREATE TABLE
  user_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    grade VARCHAR(50),
    bio TEXT,
    avatar_url VARCHAR(255),
    contact_email VARCHAR(255),
    allow_dm BOOLEAN DEFAULT TRUE,
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Push notification devices
CREATE TABLE
  push_devices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    platform ENUM ('ios', 'android', 'web') NOT NULL,
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

-- Notification preferences
CREATE TABLE
  notification_preferences (
    user_id INT NOT NULL,
    category VARCHAR(50) NOT NULL,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, category),
    KEY idx_notification_preferences_category (category),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Push notification delivery queue
CREATE TABLE
  push_notifications (
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
    status ENUM ('pending', 'sent', 'failed', 'skipped') NOT NULL DEFAULT 'pending',
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

-- Skills/Interests table
CREATE TABLE
  skills (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

-- User skills mapping
CREATE TABLE
  user_skills (
    user_id INT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level ENUM ('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, skill_id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (skill_id) REFERENCES skills (id)
  );

-- Feeds table (similar to subreddits)
CREATE TABLE
  feeds (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(30) NOT NULL,
    description TEXT,
    created_by INT NOT NULL,
    rules TEXT,
    banner_url VARCHAR(255),
    icon_url VARCHAR(255),
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users (id)
  );

-- Feed members table (for tracking joined feeds)
CREATE TABLE
  feed_members (
    feed_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM ('member', 'moderator', 'admin') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (feed_id, user_id),
    FOREIGN KEY (feed_id) REFERENCES feeds (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Feed posts table
CREATE TABLE
  feed_posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    feed_id INT NOT NULL,
    user_id INT NOT NULL,
    title VARCHAR(300) NOT NULL,
    content TEXT NOT NULL,
    media_url VARCHAR(255),
    media_type ENUM ('image', 'video', 'link', 'none') DEFAULT 'none',
    upvotes INT DEFAULT 0,
    downvotes INT DEFAULT 0,
    score DOUBLE DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (feed_id) REFERENCES feeds (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Feed votes table
CREATE TABLE
  feed_votes (
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    vote_type ENUM ('upvote', 'downvote') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES feed_posts (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Comments table (modified to work with feed_posts)
CREATE TABLE
  comments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    parent_comment_id INT,
    content TEXT NOT NULL,
    upvotes INT DEFAULT 0,
    downvotes INT DEFAULT 0,
    score DOUBLE DEFAULT 0,
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES feed_posts (id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (parent_comment_id) REFERENCES comments (id)
  );

-- Direct messages
CREATE TABLE
  direct_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users (id),
    FOREIGN KEY (receiver_id) REFERENCES users (id)
  );

-- Chat groups
CREATE TABLE
  chat_groups (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users (id)
  );

-- Chat group members
CREATE TABLE
  chat_group_members (
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id),
    FOREIGN KEY (group_id) REFERENCES chat_groups (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Group messages
CREATE TABLE
  group_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES chat_groups (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Events
CREATE TABLE
  events (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    organizer_id INT NOT NULL,
    category VARCHAR(50) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    location VARCHAR(255),
    max_participants INT,
    google_calendar_id VARCHAR(255),
    status ENUM ('draft', 'published', 'cancelled', 'completed') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_id) REFERENCES users (id)
  );

-- Event participants
CREATE TABLE
  event_participants (
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    status ENUM ('registered', 'waitlisted', 'cancelled') DEFAULT 'registered',
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES events (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Volunteer opportunities
CREATE TABLE
  volunteer_opportunities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    opportunity_type ENUM ('volunteer', 'event') NOT NULL DEFAULT 'volunteer',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    organizer_id INT NOT NULL,
    location VARCHAR(255),
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    required_participants INT,
    status ENUM ('open', 'filled', 'completed', 'cancelled') DEFAULT 'open',
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_id) REFERENCES users (id)
  );

-- Volunteer participants
CREATE TABLE
  volunteer_participants (
    opportunity_id INT NOT NULL,
    user_id INT NOT NULL,
    status ENUM ('applied', 'approved', 'completed', 'cancelled') DEFAULT 'applied',
    role ENUM ('member', 'coordinator', 'admin') DEFAULT 'member',
    hours_completed DECIMAL(5, 2),
    certificate_issued BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (opportunity_id, user_id),
    FOREIGN KEY (opportunity_id) REFERENCES volunteer_opportunities (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Volunteer attachments (images/PDFs shared with activities)
CREATE TABLE
  volunteer_attachments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    opportunity_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size INT,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (opportunity_id) REFERENCES volunteer_opportunities (id),
    FOREIGN KEY (uploaded_by) REFERENCES users (id),
    INDEX idx_volunteer_attachments_opportunity (opportunity_id),
    INDEX idx_volunteer_attachments_user (uploaded_by)
  );

-- Volunteer reflections
CREATE TABLE
  volunteer_reflections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    opportunity_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    created_by INT NOT NULL,
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (opportunity_id) REFERENCES volunteer_opportunities (id),
    FOREIGN KEY (created_by) REFERENCES users (id)
  );

-- Volunteer reflection images
CREATE TABLE
  volunteer_reflection_images (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reflection_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size INT NULL,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reflection_id) REFERENCES volunteer_reflections (id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users (id)
  );

-- Q&A questions
CREATE TABLE
  questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    subject VARCHAR(100) NOT NULL,
    has_latex BOOLEAN DEFAULT FALSE,
    view_count INT DEFAULT 0,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Study Q&A questions (Question-only phase)
CREATE TABLE
  study_questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    author_user_id INT NOT NULL,
    title VARCHAR(300) NOT NULL,
    body TEXT NOT NULL,
    media_url VARCHAR(255),
    category VARCHAR(300) NOT NULL,
    status ENUM ('open', 'resolved') DEFAULT 'open',
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_user_id) REFERENCES users (id)
  );

-- Study Q&A answers
CREATE TABLE
  study_answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    author_user_id INT NOT NULL,
    body TEXT NOT NULL,
    is_best BOOLEAN DEFAULT FALSE,
    moderation_status ENUM ('approved', 'pending', 'hidden', 'blocked') NOT NULL DEFAULT 'approved',
    moderation_reason VARCHAR(255) NULL,
    moderated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES study_questions (id),
    FOREIGN KEY (author_user_id) REFERENCES users (id)
  );

-- Study Q&A question media
CREATE TABLE
  study_question_media (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    media_url VARCHAR(255) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES study_questions (id)
  );

-- Point ledger (idempotent reward history)
CREATE TABLE
  point_ledger (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    ref_id INT NOT NULL,
    points INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id),
    UNIQUE KEY uq_point_ledger_event_ref_user (event_type, ref_id, user_id)
  );

-- Q&A answers
CREATE TABLE
  answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    has_latex BOOLEAN DEFAULT FALSE,
    is_best_answer BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Tutors
CREATE TABLE
  tutors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    subject VARCHAR(100) NOT NULL,
    grade_level VARCHAR(50) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Tutor sessions
CREATE TABLE
  tutor_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tutor_id INT NOT NULL,
    student_id INT NOT NULL,
    subject VARCHAR(100) NOT NULL,
    scheduled_start DATETIME NOT NULL,
    scheduled_end DATETIME NOT NULL,
    video_call_url VARCHAR(255),
    status ENUM ('scheduled', 'ongoing', 'completed', 'cancelled') DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tutor_id) REFERENCES users (id),
    FOREIGN KEY (student_id) REFERENCES users (id)
  );

-- Notifications
CREATE TABLE
  notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    related_id INT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

-- Moderation review queue
CREATE TABLE
  moderation_cases (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NOT NULL,
    subject_user_id INT NULL,
    reporter_user_id INT NULL,
    source ENUM ('automatic', 'report', 'manual') NOT NULL DEFAULT 'automatic',
    decision ENUM ('approved', 'pending', 'blocked') NOT NULL DEFAULT 'pending',
    status ENUM ('pending', 'approved', 'hidden', 'blocked', 'dismissed') NOT NULL DEFAULT 'pending',
    severity ENUM ('low', 'medium', 'high') NOT NULL DEFAULT 'low',
    reason_codes TEXT NULL,
    content_snapshot MEDIUMTEXT NULL,
    provider VARCHAR(50) NULL,
    provider_response MEDIUMTEXT NULL,
    reviewed_by INT NULL,
    reviewer_note TEXT NULL,
    reviewed_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_user_id) REFERENCES users (id),
    FOREIGN KEY (reporter_user_id) REFERENCES users (id),
    FOREIGN KEY (reviewed_by) REFERENCES users (id)
  );

CREATE TABLE
  moderation_reports (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    case_id BIGINT NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NOT NULL,
    reporter_user_id INT NOT NULL,
    reason ENUM ('spam', 'harassment', 'hate', 'sexual', 'violence', 'self_harm', 'privacy', 'other') NOT NULL DEFAULT 'other',
    details TEXT NULL,
    status ENUM ('open', 'reviewed', 'dismissed') NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_reporter_entity (reporter_user_id, entity_type, entity_id),
    FOREIGN KEY (case_id) REFERENCES moderation_cases (id),
    FOREIGN KEY (reporter_user_id) REFERENCES users (id)
  );

CREATE TABLE
  moderation_actions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    case_id BIGINT NOT NULL,
    moderator_user_id INT NOT NULL,
    action ENUM ('approve', 'restore', 'hide', 'block', 'dismiss') NOT NULL,
    note TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (case_id) REFERENCES moderation_cases (id),
    FOREIGN KEY (moderator_user_id) REFERENCES users (id)
  );

-- Insert default roles
INSERT INTO
  roles (name, description)
VALUES
  ('student', 'Regular student account'),
  (
    'teacher',
    'Teacher/faculty account with additional privileges'
  ),
  (
    'admin',
    'Administrator account with full system access'
  );

-- Create indexes for frequently accessed columns
CREATE INDEX idx_users_email ON users (email);

CREATE INDEX idx_feeds_name ON feeds (name);

CREATE INDEX idx_feed_posts_feed ON feed_posts (feed_id);

CREATE INDEX idx_feed_posts_score ON feed_posts (score);

CREATE INDEX idx_feed_posts_moderation_status ON feed_posts (moderation_status);

CREATE INDEX idx_comments_post ON comments (post_id);

CREATE INDEX idx_comments_moderation_status ON comments (moderation_status);

CREATE INDEX idx_events_date ON events (start_datetime);

CREATE INDEX idx_volunteer_date ON volunteer_opportunities (date);

CREATE INDEX idx_volunteer_opportunity_type ON volunteer_opportunities (opportunity_type);

CREATE INDEX idx_volunteer_type_date ON volunteer_opportunities (opportunity_type, date);

CREATE INDEX idx_volunteer_opportunities_moderation_status ON volunteer_opportunities (moderation_status);

CREATE INDEX idx_volunteer_reflections_opportunity ON volunteer_reflections (opportunity_id);

CREATE INDEX idx_volunteer_reflections_moderation_status ON volunteer_reflections (moderation_status);

CREATE INDEX idx_study_questions_moderation_status ON study_questions (moderation_status);

CREATE INDEX idx_study_answers_moderation_status ON study_answers (moderation_status);

CREATE INDEX idx_moderation_cases_status_created ON moderation_cases (status, created_at);

CREATE INDEX idx_moderation_cases_entity ON moderation_cases (entity_type, entity_id);

CREATE INDEX idx_moderation_reports_case ON moderation_reports (case_id);

CREATE INDEX idx_notifications_user ON notifications (user_id, is_read);

CREATE INDEX idx_study_questions_author ON study_questions (author_user_id);

CREATE INDEX idx_study_questions_status ON study_questions (status);

CREATE INDEX idx_study_questions_created_at ON study_questions (created_at);

CREATE INDEX idx_study_questions_category ON study_questions (category);

CREATE INDEX idx_study_answers_question ON study_answers (question_id);

CREATE INDEX idx_study_answers_best ON study_answers (question_id, is_best);

CREATE INDEX idx_study_question_media_question ON study_question_media (question_id, sort_order);

CREATE INDEX idx_point_ledger_user ON point_ledger (user_id);
