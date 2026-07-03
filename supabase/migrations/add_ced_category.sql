-- Migration: add CED category column to inventory_items
-- Run this in Supabase SQL Editor if you already created the database.

ALTER TABLE inventory_items
ADD COLUMN IF NOT EXISTS ced_category TEXT;

ALTER TABLE inventory_items
DROP CONSTRAINT IF EXISTS inventory_items_ced_category_check;

ALTER TABLE inventory_items
ADD CONSTRAINT inventory_items_ced_category_check
CHECK (
  ced_category IS NULL
  OR ced_category IN ('Dancers', 'Musicians', 'Sound System', 'Sunday School', 'Technical')
);

CREATE INDEX IF NOT EXISTS idx_inventory_items_ced_category
ON inventory_items(ced_category);
