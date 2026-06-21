-- =======================================================
-- EXTRA CONSTRAINTS FOR MESSAGES & CHAT CHANNELS
-- =======================================================

CREATE OR REPLACE FUNCTION public.safe_recreate_fkey(
    p_table_name text,
    p_constraint_name text,
    p_column_name text,
    p_ref_table text,
    p_ref_column text,
    p_on_delete_rule text
) RETURNS void AS $$
BEGIN
    -- Check if table and column exist in public schema
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = p_table_name 
          AND column_name = p_column_name
    ) THEN
        EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I', p_table_name, p_constraint_name);
        EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES public.%I(%I) ON DELETE %s', 
            p_table_name, p_constraint_name, p_column_name, p_ref_table, p_ref_column, p_on_delete_rule);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Recreate messages constraints
SELECT safe_recreate_fkey('messages', 'messages_channel_id_fkey', 'channel_id', 'chat_channels', 'id', 'CASCADE');
SELECT safe_recreate_fkey('messages', 'messages_linked_task_id_fkey', 'linked_task_id', 'tasks', 'id', 'SET NULL');

-- Clean up helper function
DROP FUNCTION IF EXISTS public.safe_recreate_fkey;
