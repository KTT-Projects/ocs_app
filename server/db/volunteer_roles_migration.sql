-- Migration: add role column to volunteer_participants
USE on294_ocs;

ALTER TABLE volunteer_participants
  ADD COLUMN role ENUM('member','coordinator','admin') DEFAULT 'member' AFTER status;

-- Backfill organizer rows to admin role
UPDATE volunteer_participants vp
JOIN volunteer_opportunities vo ON vo.id = vp.opportunity_id AND vp.user_id = vo.organizer_id
SET vp.role = 'admin';
