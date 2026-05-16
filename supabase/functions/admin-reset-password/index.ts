import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (req) => {
  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 })
  }

  // Verify caller is admin (must have valid JWT with admin role)
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  try {
    const { user_id, new_password } = await req.json()

    if (!user_id || !new_password) {
      return new Response(JSON.stringify({ error: 'user_id and new_password are required' }), { status: 400 })
    }

    if (new_password.length < 8) {
      return new Response(JSON.stringify({ error: 'Password must be at least 8 characters' }), { status: 400 })
    }

    // Use service role to update the user's password
    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    const { error } = await adminClient.auth.admin.updateUserById(user_id, {
      password: new_password,
    })

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 400 })
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
