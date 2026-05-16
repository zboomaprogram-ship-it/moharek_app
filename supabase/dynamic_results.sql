-- Create result_categories table
CREATE TABLE IF NOT EXISTS result_categories (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
    name_ar text NOT NULL,
    name_en text NOT NULL,
    icon text, -- Store icon name like 'search', 'campaign', etc.
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE result_categories ENABLE ROW LEVEL SECURITY;

-- Policies for result_categories
CREATE POLICY "Users can view categories for their projects" 
ON result_categories FOR SELECT 
USING (
    project_id IN (
        SELECT id FROM projects WHERE client_id = auth.uid()
    ) OR 
    EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'account_manager', 'seo_team', 'ads_team')
    )
);

CREATE POLICY "Admins can manage categories" 
ON result_categories FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'account_manager')
    )
);

-- Update results table to link to category
ALTER TABLE results ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES result_categories(id) ON DELETE SET NULL;

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE result_categories;
