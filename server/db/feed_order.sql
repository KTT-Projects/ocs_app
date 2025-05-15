-- Add feed order column to feed_members table
ALTER TABLE feed_members
ADD COLUMN display_order INT DEFAULT 0;

-- Create index for efficient ordering
CREATE INDEX idx_feed_members_order ON feed_members (user_id, display_order);
