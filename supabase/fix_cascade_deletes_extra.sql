-- =======================================================
-- EXTRA CASCADE & SET NULL CONSTRAINTS FOR MOHAREK & RABHAN
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

-- 1. Project level cascades
SELECT safe_recreate_fkey('invitations', 'invitations_project_id_fkey', 'project_id', 'projects', 'id', 'CASCADE');

-- 2. Profile level set nulls & cascades
SELECT safe_recreate_fkey('projects', 'projects_account_manager_id_fkey', 'account_manager_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('files', 'files_uploaded_by_fkey', 'uploaded_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('journey_stages', 'journey_stages_assigned_to_fkey', 'assigned_to', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('tasks', 'tasks_assigned_to_fkey', 'assigned_to', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('messages', 'messages_sender_id_fkey', 'sender_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('activity_feed', 'activity_feed_actor_id_fkey', 'actor_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('ecom_metrics', 'ecom_metrics_published_by_fkey', 'published_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('growth_engines', 'growth_engines_last_updated_by_fkey', 'last_updated_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('invitations', 'invitations_invited_by_fkey', 'invited_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('invitations', 'invitations_assigned_am_id_fkey', 'assigned_am_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('admin_logs', 'admin_logs_actor_id_fkey', 'actor_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('profiles', 'profiles_created_by_fkey', 'created_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('tasks', 'tasks_created_by_fkey', 'created_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('meetings', 'meetings_initiated_by_fkey', 'initiated_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('task_attachments', 'task_attachments_uploaded_by_fkey', 'uploaded_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('task_comments', 'task_comments_author_id_fkey', 'author_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('voice_updates', 'voice_updates_recorded_by_fkey', 'recorded_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('support_tickets', 'support_tickets_submitted_by_fkey', 'submitted_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('support_tickets', 'support_tickets_assigned_to_fkey', 'assigned_to', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('ticket_replies', 'ticket_replies_author_id_fkey', 'author_id', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('rabhan_weekly_summaries', 'rabhan_weekly_summaries_created_by_fkey', 'created_by', 'profiles', 'id', 'SET NULL');

-- Moharek specific constraints
SELECT safe_recreate_fkey('fcm_tokens', 'fcm_tokens_user_id_fkey', 'user_id', 'profiles', 'id', 'CASCADE');
SELECT safe_recreate_fkey('engine_progress', 'engine_progress_updated_by_fkey', 'updated_by', 'profiles', 'id', 'SET NULL');
SELECT safe_recreate_fkey('support_ticket_messages', 'support_ticket_messages_sender_id_fkey', 'sender_id', 'profiles', 'id', 'SET NULL');

-- Clean up helper function
DROP FUNCTION IF EXISTS public.safe_recreate_fkey;
