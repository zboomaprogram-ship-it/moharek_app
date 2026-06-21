-- Add signature_url to contracts table
ALTER TABLE public.contracts ADD COLUMN IF NOT EXISTS signature_url TEXT;

-- Add client_id to chat_channels and link them
ALTER TABLE public.chat_channels ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Update existing chat_channels to have the correct client_id based on their project_id
UPDATE public.chat_channels cc
SET client_id = p.client_id
FROM public.projects p
WHERE cc.project_id = p.id AND cc.client_id IS NULL;

-- Update RLS for chat_channels to allow access by client_id
DROP POLICY IF EXISTS "chat_channels_select" ON public.chat_channels;
CREATE POLICY "chat_channels_select" ON public.chat_channels FOR SELECT USING (
  project_id IN (SELECT my_project_ids())
  OR client_id = auth.uid()
  OR (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'account_manager')
);

-- Update get_or_create_chat_channel to handle client_id
CREATE OR REPLACE FUNCTION public.get_or_create_chat_channel(p_project_id uuid, p_client_id uuid DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_channel_id uuid;
  v_client_id uuid;
BEGIN
  -- Determine the client_id if not explicitly provided
  IF p_client_id IS NULL THEN
    SELECT client_id INTO v_client_id FROM public.projects WHERE id = p_project_id;
  ELSE
    v_client_id := p_client_id;
  END IF;

  -- Try to find an existing channel by client_id first to preserve history across projects
  IF v_client_id IS NOT NULL THEN
    SELECT id INTO v_channel_id FROM public.chat_channels WHERE client_id = v_client_id LIMIT 1;
    
    -- If found, ensure it is linked to the new project
    IF v_channel_id IS NOT NULL THEN
      UPDATE public.chat_channels SET project_id = p_project_id WHERE id = v_channel_id AND (project_id IS NULL OR project_id != p_project_id);
      RETURN v_channel_id;
    END IF;
  END IF;

  -- Fallback to finding by project_id
  SELECT id INTO v_channel_id FROM public.chat_channels WHERE project_id = p_project_id LIMIT 1;

  IF v_channel_id IS NULL THEN
    INSERT INTO public.chat_channels (project_id, client_id, name)
    VALUES (p_project_id, v_client_id, 'Project Chat')
    RETURNING id INTO v_channel_id;
  END IF;

  RETURN v_channel_id;
END;
$$;
