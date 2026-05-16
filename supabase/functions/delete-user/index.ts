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

    const { user_id } = await req.json()

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'User ID is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // 1. Cleanup references that would block deletion (Foreign Key constraints)
    // We nullify these references so the profile can be safely deleted
    
    // Nullify AM in projects
    await supabaseAdmin.from('projects').update({ account_manager_id: null }).eq('account_manager_id', user_id)
    
    // Nullify assignments in journey stages
    await supabaseAdmin.from('journey_stages').update({ assigned_to: null }).eq('assigned_to', user_id)
    
    // Nullify assignments in tasks
    await supabaseAdmin.from('tasks').update({ assigned_to: null }).eq('assigned_to', user_id)
    
    // Nullify actor in activity feed
    await supabaseAdmin.from('activity_feed').update({ actor_id: null }).eq('actor_id', user_id)
    
    // Nullify uploader in files
    await supabaseAdmin.from('files').update({ uploaded_by: null }).eq('uploaded_by', user_id)
    
    // Note: We don't nullify messages.sender_id because we usually want to keep chat history.
    // However, if messages.sender_id is a RESTRICT constraint, we must nullify it or delete messages.
    // Given the error "Database error deleting user", it's likely one of these.
    await supabaseAdmin.from('messages').update({ sender_id: null }).eq('sender_id', user_id)

    // 2. Delete Profile
    // We delete profile explicitly first because Auth delete might be slower or have its own triggers
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .delete()
      .eq('id', user_id)
    
    if (profileError) {
      throw new Error(`Database error deleting profile: ${profileError.message}`)
    }

    // 3. Delete Auth User
    const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(user_id)
    if (authError) throw authError

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message ?? 'Unknown error' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
