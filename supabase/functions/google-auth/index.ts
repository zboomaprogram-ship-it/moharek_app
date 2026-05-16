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

  const url = new URL(req.url)
  const path = url.pathname.split('/').pop()

  if (path === 'authorize') {
    return handleAuthorize(req)
  } else if (path === 'callback') {
    return handleCallback(req)
  }

  return new Response(JSON.stringify({ error: 'Not found' }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status: 404,
  })
})

async function handleAuthorize(req: Request) {
  const GOOGLE_CLIENT_ID = Deno.env.get('GOOGLE_CLIENT_ID')
  const REDIRECT_URI = `${Deno.env.get('SUPABASE_URL')}/functions/v1/google-auth/callback`
  
  const companyId = new URL(req.url).searchParams.get('company_id')
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'Missing company_id' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }

  const scope = [
    'https://www.googleapis.com/auth/webmasters.readonly',
    'https://www.googleapis.com/auth/analytics.readonly',
    'https://www.googleapis.com/auth/business.manage',
    'openid',
    'email',
    'profile'
  ].join(' ')

  const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth')
  authUrl.searchParams.set('client_id', GOOGLE_CLIENT_ID!)
  authUrl.searchParams.set('redirect_uri', REDIRECT_URI)
  authUrl.searchParams.set('response_type', 'code')
  authUrl.searchParams.set('scope', scope)
  authUrl.searchParams.set('access_type', 'offline')
  authUrl.searchParams.set('prompt', 'consent')
  authUrl.searchParams.set('state', companyId)

  return new Response(null, {
    status: 302,
    headers: {
      Location: authUrl.toString(),
    },
  })
}

async function handleCallback(req: Request) {
  const GOOGLE_CLIENT_ID = Deno.env.get('GOOGLE_CLIENT_ID')
  const GOOGLE_CLIENT_SECRET = Deno.env.get('GOOGLE_CLIENT_SECRET')
  const REDIRECT_URI = `${Deno.env.get('SUPABASE_URL')}/functions/v1/google-auth/callback`

  const url = new URL(req.url)
  const code = url.searchParams.get('code')
  const companyId = url.searchParams.get('state')

  if (!code || !companyId) {
    return new Response('Missing code or state', { status: 400 })
  }

  // Exchange code for tokens
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: GOOGLE_CLIENT_ID!,
      client_secret: GOOGLE_CLIENT_SECRET!,
      redirect_uri: REDIRECT_URI,
      grant_type: 'authorization_code',
    }),
  })

  const tokens = await tokenResponse.json()

  if (tokens.error) {
    return new Response(JSON.stringify(tokens), { status: 500 })
  }

  // Store tokens in database
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { error } = await supabase
    .from('oauth_tokens')
    .upsert({
      company_id: companyId,
      provider: 'google',
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      expires_at: new Date(Date.now() + tokens.expires_in * 1000).toISOString(),
      scopes: tokens.scope.split(' '),
    }, { onConflict: 'company_id, provider' })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  return new Response('Successfully connected to Google! You can close this window.', {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  })
}
