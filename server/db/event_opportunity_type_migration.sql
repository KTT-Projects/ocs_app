-- Migration: separate volunteer opportunities from event opportunities

USE on294_ocs;

ALTER TABLE volunteer_opportunities
ADD COLUMN opportunity_type ENUM('volunteer', 'event') NOT NULL DEFAULT 'volunteer' AFTER id;

CREATE INDEX idx_volunteer_opportunity_type ON volunteer_opportunities (opportunity_type);
CREATE INDEX idx_volunteer_type_date ON volunteer_opportunities (opportunity_type, date);
