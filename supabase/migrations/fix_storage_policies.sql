-- Storage policies for image uploads (run if uploads fail)
-- Ensure bucket "inventory-images" exists and is PUBLIC in Supabase Dashboard.

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Public upload access" ON storage.objects;
DROP POLICY IF EXISTS "Public update access" ON storage.objects;
DROP POLICY IF EXISTS "Public delete access" ON storage.objects;

CREATE POLICY "Public read access" ON storage.objects
  FOR SELECT USING (bucket_id = 'inventory-images');

CREATE POLICY "Public upload access" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'inventory-images');

CREATE POLICY "Public update access" ON storage.objects
  FOR UPDATE USING (bucket_id = 'inventory-images');

CREATE POLICY "Public delete access" ON storage.objects
  FOR DELETE USING (bucket_id = 'inventory-images');
