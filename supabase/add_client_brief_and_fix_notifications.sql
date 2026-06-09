-- 1. Add client_brief JSONB column to the projects table
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS client_brief jsonb;

-- 1b. Add start_date column to the tasks table
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS start_date date;

-- 1b2. Add file_url column to the results table
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS file_url text;

-- 1c. Add onesignal_player_id column to the profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onesignal_player_id text;

-- 1d. Create packages table if not exists
CREATE TABLE IF NOT EXISTS public.packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  package_name TEXT NOT NULL,
  package_tier TEXT DEFAULT 'starter',
  status TEXT DEFAULT 'active',
  requests_limit INT DEFAULT 200,
  requests_used INT DEFAULT 0,
  notes TEXT,
  renews_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS and public policies for packages
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read/write access to packages" ON public.packages;
CREATE POLICY "Allow public read/write access to packages" ON public.packages FOR ALL USING (true) WITH CHECK (true);

-- 1e. Create ecom_metrics table if not exists
CREATE TABLE IF NOT EXISTS public.ecom_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  total_sales NUMERIC DEFAULT 0,
  prev_sales NUMERIC DEFAULT 0,
  orders_count INT DEFAULT 0,
  prev_orders INT DEFAULT 0,
  clicks INT DEFAULT 0,
  impressions INT DEFAULT 0,
  add_to_cart INT DEFAULT 0,
  roas NUMERIC DEFAULT 0,
  prev_roas NUMERIC DEFAULT 0,
  conversion_rate NUMERIC DEFAULT 0,
  net_profit NUMERIC DEFAULT 0,
  ad_spend NUMERIC DEFAULT 0,
  period_start TIMESTAMPTZ DEFAULT now(),
  period_end TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS and public policies for ecom_metrics
ALTER TABLE public.ecom_metrics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read/write access to ecom_metrics" ON public.ecom_metrics;
CREATE POLICY "Allow public read/write access to ecom_metrics" ON public.ecom_metrics FOR ALL USING (true) WITH CHECK (true);

-- 1f. Create growth_engines table if not exists
CREATE TABLE IF NOT EXISTS public.growth_engines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  engine_type TEXT NOT NULL,
  health_score INT DEFAULT 0,
  status TEXT DEFAULT 'pending',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, engine_type)
);

-- Enable RLS and public policies for growth_engines
ALTER TABLE public.growth_engines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read/write access to growth_engines" ON public.growth_engines;
CREATE POLICY "Allow public read/write access to growth_engines" ON public.growth_engines FOR ALL USING (true) WITH CHECK (true);

-- 2. Recreate the on_message_inserted trigger function to handle non-text messages safely (preventing NULL string concatenation)
CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  target_user_id    UUID;
  project_client_id UUID;
  project_am_id     UUID;
  sender_name       TEXT;
  display_body_ar   TEXT;
  display_body_en   TEXT;
BEGIN
  -- Skip system messages
  IF NEW.message_type = 'system' THEN RETURN NEW; END IF;

  -- Get the project's client and AM for this chat channel
  SELECT p.client_id, p.account_manager_id
  INTO project_client_id, project_am_id
  FROM public.chat_channels c
  JOIN public.projects p ON c.project_id = p.id
  WHERE c.id = NEW.channel_id;

  -- Determine recipient (notify the OTHER party)
  IF NEW.sender_id = project_client_id THEN
    target_user_id := project_am_id;
  ELSE
    target_user_id := project_client_id;
  END IF;

  IF target_user_id IS NULL THEN RETURN NEW; END IF;

  -- Get sender display name
  SELECT COALESCE(full_name, 'فريق ربحان')
  INTO sender_name
  FROM public.profiles
  WHERE id = NEW.sender_id;

  -- Build safe body text for notifications (avoiding null propagation on image, file, voice types)
  display_body_ar := COALESCE(sender_name, 'فريقك') || ': ' || COALESCE(
    LEFT(NEW.content, 100),
    CASE 
      WHEN NEW.message_type = 'image' THEN '📷 أرسل صورة'
      WHEN NEW.message_type = 'voice' THEN '🎤 أرسل رسالة صوتية'
      WHEN NEW.message_type = 'file' THEN '📎 أرسل ملفاً'
      ELSE 'رسالة جديدة'
    END
  );

  display_body_en := COALESCE(sender_name, 'Your team') || ': ' || COALESCE(
    LEFT(NEW.content, 100),
    CASE 
      WHEN NEW.message_type = 'image' THEN '📷 sent a photo'
      WHEN NEW.message_type = 'voice' THEN '🎤 sent a voice message'
      WHEN NEW.message_type = 'file' THEN '📎 sent a file'
      ELSE 'new message'
    END
  );

  -- Insert in-app notification row.
  -- The Database Webhook on notifications table fires send-notification
  -- Edge Function automatically.
  INSERT INTO public.notifications (
    user_id,
    type,
    title_ar,
    title_en,
    body_ar,
    body_en,
    is_read,
    metadata,
    created_at
  ) VALUES (
    target_user_id,
    'chat_message',
    '💬 رسالة جديدة',
    '💬 New Message',
    display_body_ar,
    display_body_en,
    false,
    jsonb_build_object(
      'sender_id',  NEW.sender_id,
      'channel_id', NEW.channel_id,
      'message_id', NEW.id,
      'table',      'messages',
      'record',     row_to_json(NEW)
    ),
    now()
  );

  RETURN NEW;
END;
$$;

-- 3. Re-create the trigger on messages
DROP TRIGGER IF EXISTS trigger_on_message_inserted ON public.messages;
CREATE TRIGGER trigger_on_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.on_message_inserted();

-- 4. Projects Update Policy: Allow clients to update their own project's client_brief
DROP POLICY IF EXISTS "Clients update own projects" ON public.projects;
CREATE POLICY "Clients update own projects" ON public.projects
  FOR UPDATE
  TO authenticated
  USING (client_id = auth.uid())
  WITH CHECK (client_id = auth.uid());

-- 5. Results Management Policy: Allow admins/AMs to manage results, and clients/members to view them
DROP POLICY IF EXISTS "Results access" ON public.results;
CREATE POLICY "Results access" ON public.results
  FOR SELECT
  TO authenticated
  USING (project_id IN (SELECT public.my_project_ids()) OR public.is_admin());

DROP POLICY IF EXISTS "Admins manage results" ON public.results;
CREATE POLICY "Admins manage results" ON public.results
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

