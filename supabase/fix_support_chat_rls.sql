-- ============================================================
-- FIX SUPPORT CHAT RLS POLICY (Postgres 42501 Error)
-- Run this in your Supabase SQL Editor to resolve the crash
-- ============================================================

-- 1. Drop old SELECT and INSERT policies that referenced the incorrect column 'team_role'
DROP POLICY IF EXISTS "Users can view messages for their own tickets" ON public.support_ticket_messages;
DROP POLICY IF EXISTS "Users can send messages to their own tickets" ON public.support_ticket_messages;

-- 2. Create updated SELECT policy using unified is_admin() helper
CREATE POLICY "Users can view messages for their own tickets"
    ON public.support_ticket_messages FOR SELECT
    USING (
        ticket_id IN (
            SELECT id FROM public.support_tickets 
            WHERE project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid())
        ) OR 
        public.is_admin()
    );

-- 3. Create updated INSERT policy using unified is_admin() helper
CREATE POLICY "Users can send messages to their own tickets"
    ON public.support_ticket_messages FOR INSERT
    WITH CHECK (
        ticket_id IN (
            SELECT id FROM public.support_tickets 
            WHERE project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid())
        ) OR 
        public.is_admin()
    );
