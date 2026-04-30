-- Migration to update volunteer_opportunities table to single-day format
-- This script updates the existing table structure

USE on294_ocs;

-- Add new columns for single-day format
ALTER TABLE volunteer_opportunities 
ADD COLUMN date DATE AFTER location,
ADD COLUMN start_time TIME AFTER date,
ADD COLUMN end_time TIME AFTER start_time;

-- Update existing data by copying start_date to date column
UPDATE volunteer_opportunities 
SET date = start_date,
    start_time = '09:00:00',
    end_time = '17:00:00'
WHERE date IS NULL;

-- Make the new columns NOT NULL
ALTER TABLE volunteer_opportunities 
MODIFY COLUMN date DATE NOT NULL,
MODIFY COLUMN start_time TIME NOT NULL,
MODIFY COLUMN end_time TIME NOT NULL;

-- Drop the old columns
ALTER TABLE volunteer_opportunities 
DROP COLUMN start_date,
DROP COLUMN end_date;

-- Update the index
DROP INDEX idx_volunteer_date;
CREATE INDEX idx_volunteer_date ON volunteer_opportunities (date);
