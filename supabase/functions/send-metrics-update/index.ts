import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') || '063a237d-bbf9-4aac-8791-ef5e57752801'
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record

    // Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get the project to find the client_id
    const { data: project } = await supabase
      .from('projects')
      .select('client_id, name')
      .eq('id', record.project_id)
      .single()

    if (!project) {
      throw new Error('Project not found')
    }

    // Since we now use external_id in OneSignal (userId), we can just target external_id: client_id
    // But if we also stored onesignal_player_id, we could use include_player_ids
    
    // We will target the external_id which is the Supabase Auth user ID (client_id)
    const notificationData = {
      app_id: ONESIGNAL_APP_ID,
      include_external_user_ids: [project.client_id],
      channel_for_external_user_ids: "push",
      headings: {
        en: "Metrics Updated \uD83D\uDCCA",
        ar: "تحديث المقاييس \uD83D\uDCCA"
      },
      contents: {
        en: `Your e-commerce metrics for ${project.name} have been updated.`,
        ar: `تم تحديث مؤشرات الأداء لمشروع ${project.name}.`
      },
      data: {
        type: "metrics_update",
        project_id: record.project_id
      }
    }

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
      },
      body: JSON.stringify(notificationData)
    })

    const responseData = await response.json()
    console.log('OneSignal response:', responseData)

    return new Response(JSON.stringify({ success: true, data: responseData }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
