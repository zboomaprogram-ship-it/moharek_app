import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') || '063a237d-bbf9-4aac-8791-ef5e57752801'
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')

serve(async (req) => {
  try {
    // Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Find all active packages that are expiring in exactly 7 days
    // We can use a Postgres function or do it here. 
    // For simplicity, we'll fetch packages expiring between 7 and 8 days from now
    const now = new Date()
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
    const eightDaysFromNow = new Date(now.getTime() + 8 * 24 * 60 * 60 * 1000)

    const { data: packages, error } = await supabase
      .from('packages')
      .select('*, projects(client_id, name)')
      .eq('status', 'active')
      .gte('end_date', sevenDaysFromNow.toISOString())
      .lt('end_date', eightDaysFromNow.toISOString())

    if (error) {
      throw error
    }

    if (!packages || packages.length === 0) {
      return new Response(JSON.stringify({ message: "No packages expiring soon." }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const responses = []

    for (const pkg of packages) {
      const clientId = pkg.projects?.client_id
      const projectName = pkg.projects?.name

      if (!clientId) continue

      const notificationData = {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: [clientId],
        channel_for_external_user_ids: "push",
        headings: {
          en: "Package Expiring Soon \u26A0\uFE0F",
          ar: "باقة شارفت على الانتهاء \u26A0\uFE0F"
        },
        contents: {
          en: `Your package for ${projectName} will expire in 7 days. Please renew to avoid service interruption.`,
          ar: `باقتك الخاصة بمشروع ${projectName} ستنتهي خلال 7 أيام. يرجى التجديد لتجنب توقف الخدمة.`
        },
        data: {
          type: "package_expiry",
          project_id: pkg.project_id
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

      responses.push(await response.json())
    }

    return new Response(JSON.stringify({ success: true, notifications_sent: responses.length, data: responses }), {
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
