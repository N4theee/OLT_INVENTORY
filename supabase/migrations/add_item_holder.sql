-- Migration: add item_holder column
ALTER TABLE inventory_items
ADD COLUMN IF NOT EXISTS item_holder TEXT NOT NULL DEFAULT 'Church';

ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS inventory_items_item_holder_check;

ALTER TABLE inventory_items
ADD CONSTRAINT inventory_items_item_holder_check
CHECK (item_holder IN ('Personal', 'Church'));

UPDATE inventory_items SET item_holder = 'Church' WHERE item_holder IS NULL;
