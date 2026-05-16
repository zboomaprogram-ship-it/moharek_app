-- 1. DROP EVERYTHING FIRST (To ensure fresh columns)
DROP TABLE IF EXISTS public.ticket_messages CASCADE;
DROP TABLE IF EXISTS public.support_tickets CASCADE;
DROP TABLE IF EXISTS public.campaigns CASCADE;

-- 2. CREATE TABLES
CREATE TABLE public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    description TEXT,
    priority TEXT DEFAULT 'normal',
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    platform TEXT,
    status TEXT DEFAULT 'planned',
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    budget DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Add columns to existing invoices table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='invoices' AND column_name='title') THEN
        ALTER TABLE public.invoices ADD COLUMN title TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='invoices' AND column_name='payment_url') THEN
        ALTER TABLE public.invoices ADD COLUMN payment_url TEXT;
    END IF;
END $$;

-- 4. Enable RLS
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

-- 5. POLICIES
CREATE POLICY "Clients can view own tickets" ON public.support_tickets
    FOR SELECT USING (client_id = auth.uid());

CREATE POLICY "Clients can create tickets" ON public.support_tickets
    FOR INSERT WITH CHECK (client_id = auth.uid());

CREATE POLICY "Admins can view all tickets" ON public.support_tickets
    FOR ALL USING (is_admin());

CREATE POLICY "Users can see messages for their tickets" ON public.ticket_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.support_tickets 
            WHERE id = ticket_id AND (client_id = auth.uid() OR is_admin())
        )
    );

CREATE POLICY "Users can insert messages for their tickets" ON public.ticket_messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.support_tickets 
            WHERE id = ticket_id AND (client_id = auth.uid() OR is_admin())
        )
    );

CREATE POLICY "Clients can view own invoices" ON public.invoices
    FOR SELECT USING (project_id IN (SELECT my_project_ids()));

CREATE POLICY "Admins can manage invoices" ON public.invoices
    FOR ALL USING (is_admin());

CREATE POLICY "Clients can view own campaigns" ON public.campaigns
    FOR SELECT USING (project_id IN (SELECT my_project_ids()));

CREATE POLICY "Admins can manage campaigns" ON public.campaigns
    FOR ALL USING (is_admin());
