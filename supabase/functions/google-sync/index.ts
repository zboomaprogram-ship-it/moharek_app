import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // 1. Fetch all projects with Google tokens
  const { data: projects, error: projectsError } = await supabase
    .from('projects')
    .select('*, companies!inner(oauth_tokens(*))')
    .not('company_id', 'is', null)

  if (projectsError) {
    return new Response(JSON.stringify({ error: projectsError.message }), { status: 500 })
  }

  const syncResults = []

  for (const project of projects) {
    const tokens = project.companies.oauth_tokens.find((t: any) => t.provider === 'google')
    if (!tokens) continue

    try {
      const accessToken = await getValidAccessToken(tokens)
      
      if (project.gsc_site_url) {
        await syncGSCData(supabase, project, accessToken)
      }
      
      if (project.ga4_property_id) {
        await syncGA4Data(supabase, project, accessToken)
      }

      syncResults.push({ project_id: project.id, status: 'success' })
    } catch (e) {
      console.error(`Sync failed for project ${project.id}:`, e)
      syncResults.push({ project_id: project.id, status: 'failed', error: e.message })
    }
  }

  return new Response(JSON.stringify({ results: syncResults }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})

async function getValidAccessToken(tokens: any) {
  if (new Date(tokens.expires_at) > new Date(Date.now() + 60000)) {
    return tokens.access_token
  }

  // Refresh token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    body: new URLSearchParams({
      client_id: Deno.env.get('GOOGLE_CLIENT_ID')!,
      client_secret: Deno.env.get('GOOGLE_CLIENT_SECRET')!,
      refresh_token: tokens.refresh_token,
      grant_type: 'refresh_token',
    }),
  })

  const data = await response.json()
  return data.access_token
}

async function syncGSCData(supabase: any, project: any, accessToken: string) {
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  const dateStr = yesterday.toISOString().split('T')[0]

  try {
    const response = await fetch(`https://www.googleapis.com/webmasters/v3/sites/${encodeURIComponent(project.gsc_site_url)}/searchAnalytics/query`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        startDate: dateStr,
        endDate: dateStr,
        dimensions: ['query'],
        rowLimit: 50,
      }),
    })

    if (!response.ok) {
      const err = await response.text()
      throw new Error(`GSC API error: ${err}`)
    }

    const data = await response.json()
    
    if (data.rows && data.rows.length > 0) {
      const totalClicks = data.rows.reduce((sum: number, row: any) => sum + row.clicks, 0)
      const totalImpressions = data.rows.reduce((sum: number, row: any) => sum + row.impressions, 0)
      
      // Upsert clicks for the day
      await supabase.from('results').insert([
        {
          project_id: project.id,
          result_type: 'seo',
          metric_label: 'Daily Clicks (GSC)',
          metric_name: 'gsc_clicks',
          metric_value: totalClicks,
          metric_unit: 'Clicks',
          recorded_at: dateStr,
        },
        {
          project_id: project.id,
          result_type: 'seo',
          metric_label: 'Daily Impressions (GSC)',
          metric_name: 'gsc_impressions',
          metric_value: totalImpressions,
          metric_unit: 'Imps',
          recorded_at: dateStr,
        }
      ])
    }
  } catch (e) {
    console.error(`GSC Sync failed for ${project.id}:`, e)
  }
}

async function syncGA4Data(supabase: any, project: any, accessToken: string) {
  const propertyId = project.ga4_property_id
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  const dateStr = yesterday.toISOString().split('T')[0]

  try {
    const response = await fetch(`https://analyticsdata.googleapis.com/v1beta/properties/${propertyId}:runReport`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        dateRanges: [{ startDate: dateStr, endDate: dateStr }],
        metrics: [
          { name: 'activeUsers' },
          { name: 'sessions' },
          { name: 'conversions' }
        ],
      }),
    })

    if (!response.ok) {
      const err = await response.text()
      throw new Error(`GA4 API error: ${err}`)
    }

    const data = await response.json()
    
    if (data.rows && data.rows.length > 0) {
      const metrics = data.rows[0].metricValues
      
      await supabase.from('results').insert([
        {
          project_id: project.id,
          result_type: 'conversion',
          metric_label: 'Daily Visitors (GA4)',
          metric_name: 'ga4_users',
          metric_value: parseInt(metrics[0].value),
          metric_unit: 'Users',
          recorded_at: dateStr,
        },
        {
          project_id: project.id,
          result_type: 'conversion',
          metric_label: 'Daily Sessions (GA4)',
          metric_name: 'ga4_sessions',
          metric_value: parseInt(metrics[1].value),
          metric_unit: 'Sessions',
          recorded_at: dateStr,
        },
        {
          project_id: project.id,
          result_type: 'leads',
          metric_label: 'Daily Conversions (GA4)',
          metric_name: 'ga4_conversions',
          metric_value: parseInt(metrics[2].value),
          metric_unit: 'Conversions',
          recorded_at: dateStr,
        }
      ])
    }
  } catch (e) {
    console.error(`GA4 Sync failed for ${project.id}:`, e)
  }
}
