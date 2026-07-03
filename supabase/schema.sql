-- OLT Inventory Supabase Schema
-- Run this in the Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Departments table
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory items table
CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  department_id UUID NOT NULL REFERENCES departments(id),
  status TEXT NOT NULL CHECK (status IN ('Good condition', 'Needs repair', 'Depreciated')),
  item_holder TEXT NOT NULL DEFAULT 'Church' CHECK (item_holder IN ('Personal', 'Church')),
  image_url TEXT,
  notes TEXT,
  ced_category TEXT CHECK (
    ced_category IS NULL
    OR ced_category IN ('Dancers', 'Musicians', 'Sound System', 'Sunday School', 'Technical')
  ),
  date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Inventory logs table
CREATE TABLE IF NOT EXISTS inventory_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('Added', 'Updated', 'Deleted', 'Restored', 'Permanently Deleted')),
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_inventory_items_department ON inventory_items(department_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_deleted ON inventory_items(is_deleted);
CREATE INDEX IF NOT EXISTS idx_inventory_items_status ON inventory_items(status);
CREATE INDEX IF NOT EXISTS idx_inventory_items_ced_category ON inventory_items(ced_category);
CREATE INDEX IF NOT EXISTS idx_inventory_items_date_added ON inventory_items(date_added DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_logs_created ON inventory_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_logs_item ON inventory_logs(item_id);

-- Default departments
INSERT INTO departments (department_name) VALUES
  ('Pastors Department'),
  ('Board'),
  ('Men''s Department'),
  ('Women''s Department'),
  ('Youth Department'),
  ('CED'),
  ('Uncategorized')
ON CONFLICT (department_name) DO NOTHING;

-- Storage bucket (run in Supabase Dashboard > Storage or via API)
-- Bucket name: inventory-images
-- Public: true (for public URL access)

-- Storage policies (adjust if authentication is added later)
-- Allow public update (needed for upsert uploads)
CREATE POLICY "Public update access" ON storage.objects
  FOR UPDATE USING (bucket_id = 'inventory-images');

-- Allow public read
CREATE POLICY "Public read access" ON storage.objects
  FOR SELECT USING (bucket_id = 'inventory-images');

-- Allow public insert (for anon key without auth - adjust for production)
CREATE POLICY "Public upload access" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'inventory-images');

-- Allow public delete (for anon key without auth - adjust for production)
CREATE POLICY "Public delete access" ON storage.objects
  FOR DELETE USING (bucket_id = 'inventory-images');

-- Row Level Security (disabled for MVP without auth)
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all on departments" ON departments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on inventory_items" ON inventory_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on inventory_logs" ON inventory_logs FOR ALL USING (true) WITH CHECK (true);
