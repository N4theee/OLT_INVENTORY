-- Migration: update item status values and add Musicians CED category
-- Run in Supabase SQL Editor

ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS inventory_items_status_check;

UPDATE inventory_items SET status = 'Good condition' WHERE status = 'For Keeps';
UPDATE inventory_items SET status = 'Depreciated' WHERE status = 'For Disposal';

ALTER TABLE inventory_items
ADD CONSTRAINT inventory_items_status_check
CHECK (status IN ('Good condition', 'Needs repair', 'Depreciated'));

ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS inventory_items_ced_category_check;

ALTER TABLE inventory_items
ADD CONSTRAINT inventory_items_ced_category_check
CHECK (
  ced_category IS NULL
  OR ced_category IN (
    'Dancers',
    'Musicians',
    'Sound System',
    'Sunday School',
    'Technical'
  )
);
