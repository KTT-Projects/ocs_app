-- Add volunteer opportunities table
CREATE TABLE IF NOT EXISTS volunteer_opportunities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NULL,
    organizer VARCHAR(255) NOT NULL,
    organizer_contact VARCHAR(255) NULL,
    max_participants INT NOT NULL DEFAULT 0,
    tags JSON NULL,
    image_url VARCHAR(500) NULL,
    created_by INT NOT NULL,
    status ENUM('open', 'full', 'completed', 'cancelled') NOT NULL DEFAULT 'open',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add volunteer registrations table
CREATE TABLE IF NOT EXISTS volunteer_registrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    opportunity_id INT NOT NULL,
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    status ENUM('registered', 'completed', 'cancelled') NOT NULL DEFAULT 'registered',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (opportunity_id) REFERENCES volunteer_opportunities(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_opportunity (user_id, opportunity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add indexes for better performance
CREATE INDEX idx_volunteer_opportunities_status ON volunteer_opportunities(status);
CREATE INDEX idx_volunteer_opportunities_start_date ON volunteer_opportunities(start_date);
CREATE INDEX idx_volunteer_opportunities_created_by ON volunteer_opportunities(created_by);
CREATE INDEX idx_volunteer_registrations_user_id ON volunteer_registrations(user_id);
CREATE INDEX idx_volunteer_registrations_opportunity_id ON volunteer_registrations(opportunity_id);
CREATE INDEX idx_volunteer_registrations_registered_at ON volunteer_registrations(registered_at);

-- Add sample volunteer opportunities (optional)
INSERT INTO volunteer_opportunities (title, description, location, start_date, end_date, organizer, organizer_contact, max_participants, created_by, status) VALUES
('Beach Cleanup', 'Help us clean up the local beach and protect marine life.', 'Osakikamijima Beach', '2025-08-15T09:00:00+09:00', '2025-08-15T12:00:00+09:00', 'Environmental Club', 'env@osakikamijima.edu', 50, 1, 'open'),
('Community Garden', 'Join us in maintaining the community garden and growing fresh vegetables.', 'Central Park Garden', '2025-08-20T14:00:00+09:00', '2025-08-20T17:00:00+09:00', 'Green Initiative', 'green@osakikamijima.edu', 20, 1, 'open'),
('Elderly Care Visit', 'Spend time with elderly residents at the local care facility.', 'Sunshine Care Home', '2025-08-25T10:00:00+09:00', '2025-08-25T12:00:00+09:00', 'Community Services', 'community@osakikamijima.edu', 15, 1, 'open'),
('School Library Helper', 'Assist librarians with organizing books and helping students.', 'Osakikamijima Elementary School Library', '2025-09-01T15:00:00+09:00', '2025-09-01T17:00:00+09:00', 'School Administration', 'admin@osakikamijima.edu', 10, 1, 'open'),
('Sports Event Volunteer', 'Help with local sports event setup and coordination.', 'Osakikamijima Sports Complex', '2025-09-10T08:00:00+09:00', '2025-09-10T18:00:00+09:00', 'Sports Federation', 'sports@osakikamijima.edu', 30, 1, 'open');
