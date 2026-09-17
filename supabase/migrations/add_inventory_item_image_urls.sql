-- Add ordered multi-image support while retaining image_url compatibility.
ALTER TABLE inventory_items
  ADD COLUMN IF NOT EXISTS image_urls TEXT[] NOT NULL DEFAULT '{}';

-- Preserve every existing item's current image as its first gallery image.
UPDATE inventory_items
SET image_urls = ARRAY[image_url]
WHERE image_url IS NOT NULL
  AND image_url <> ''
  AND cardinality(image_urls) = 0;

ALTER TABLE inventory_items
  DROP CONSTRAINT IF EXISTS inventory_items_image_urls_max_10;

ALTER TABLE inventory_items
  ADD CONSTRAINT inventory_items_image_urls_max_10
  CHECK (cardinality(image_urls) <= 10);
