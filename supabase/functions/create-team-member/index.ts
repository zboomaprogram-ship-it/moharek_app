import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const { email, password, full_name, role, project_ids } = await req.json()

    if (!email || !password || !full_name || !role) {
      return new Response(
        JSON.stringify({ error: 'Email, password, name and role are required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // 1. Create Auth User
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    })

    if (authError) throw authError

    // 2. Create Profile
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: authUser.user.id,
        full_name,
        role: role,
        team_role: role // Needed for RLS is_admin() check
      })

    if (profileError) throw profileError

    // 3. Assign Projects if role is account_manager
    if (role === 'account_manager' && project_ids && project_ids.length > 0) {
      const { error: assignError } = await supabaseAdmin
        .from('projects')
        .update({ account_manager_id: authUser.user.id })
        .in('id', project_ids)

      if (assignError) throw assignError
    }

    return new Response(
      JSON.stringify({ success: true, user: { id: authUser.user.id, email } }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message ?? 'Unknown error' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
