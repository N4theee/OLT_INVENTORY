-- Add unique human-readable item codes (e.g. YOF_INS01, CED_MSC_MIC01)
ALTER TABLE inventory_items
ADD COLUMN IF NOT EXISTS item_code TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS inventory_items_item_code_unique
ON inventory_items (item_code)
WHERE item_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS inventory_items_item_code_search_idx
ON inventory_items (item_code);
