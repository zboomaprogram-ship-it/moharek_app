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

    const body = await req.json()
    const { email, password, full_name, is_team, role, project_ids } = body

    // 1. Common Validation
    if (!email || !password || !full_name) {
      return new Response(
        JSON.stringify({ error: 'All fields (email, password, name) are required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    if (is_team) {
      // TEAM MEMBER FLOW
      if (!role) {
        return new Response(
          JSON.stringify({ error: 'Role is required for team members' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true
      })
      if (authError) throw authError

      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .insert({
          id: authUser.user.id,
          full_name,
          role: role,
          is_active: true
        })
      if (profileError) throw profileError

      // Assign projects if AM
      if (role === 'account_manager' && project_ids && Array.isArray(project_ids)) {
        await supabaseAdmin
          .from('projects')
          .update({ account_manager_id: authUser.user.id })
          .in('id', project_ids)
      }

      return new Response(
        JSON.stringify({ success: true, user_id: authUser.user.id }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )

    } else {
      // CLIENT FLOW
      const { company_name, project_name, account_manager_id } = body
      if (!company_name || !project_name) {
        return new Response(
          JSON.stringify({ error: 'Company and Project names are required for clients' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true
      })
      if (authError) throw authError

      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .insert({
          id: authUser.user.id,
          full_name,
          company_name,
          role: 'client'
        })
      if (profileError) throw profileError

      const { data: project, error: projectError } = await supabaseAdmin
        .from('projects')
        .insert({
          client_id: authUser.user.id,
          name: project_name,
          status: 'active',
          current_stage: 'audit',
          account_manager_id: account_manager_id || null
        })
        .select()
        .single()
      if (projectError) throw projectError

      return new Response(
        JSON.stringify({ success: true, user_id: authUser.user.id, project }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message ?? 'Unknown error' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
