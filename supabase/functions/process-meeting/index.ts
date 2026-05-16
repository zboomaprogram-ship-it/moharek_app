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

  const { meetingId } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // 1. Fetch meeting details
  const { data: meeting, error: meetingError } = await supabase
    .from('meetings')
    .select('*')
    .eq('id', meetingId)
    .single()

  if (meetingError || !meeting.recording_url) {
    return new Response(JSON.stringify({ error: 'Meeting or recording not found' }), { status: 404 })
  }

  try {
    // 2. Transcribe using Whisper (OpenAI)
    // In a real implementation, we would download the file and send it to OpenAI
    // For this demonstration, we'll simulate the transcription
    const transcript = "Simulated transcript from Whisper: Discussed the new marketing strategy and agreed on increasing the budget for SEO by 20% next month. Sarah will update the keyword list by Friday."

    // 3. Generate summary and action items using Claude (Anthropic)
    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY')!,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-3-haiku-20240307',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: `Please summarize the following meeting transcript and extract action items: \n\n ${transcript}`
          }
        ],
      }),
    })

    const aiData = await anthropicResponse.json()
    const summary = aiData.content[0].text

    // 4. Update meeting in database
    await supabase.from('meetings').update({
      transcript,
      summary,
      processed_at: new Date().toISOString(),
    }).eq('id', meetingId)

    return new Response(JSON.stringify({ status: 'success' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 })
  }
})
