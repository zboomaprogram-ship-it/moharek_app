import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

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
    const apiKey = Deno.env.get('GROQ_API_KEY')
    if (!apiKey) {
      throw new Error('GROQ_API_KEY is not set')
    }

    const { prompt, history, context } = await req.json()

    if (!prompt) {
      return new Response(
        JSON.stringify({ error: 'Prompt is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const systemPrompt = `You are "Moharek Growth Assistant", a specialized marketing and growth AI for Moharek Growth Hub. 
    Your goal is to help clients understand their marketing results, strategy, and growth engines.
    
    Context about the user's project:
    ${JSON.stringify(context || {})}
    
    Guidelines:
    1. Be professional, encouraging, and data-driven.
    2. If the user asks about their "Engines", refer to Content, SEO, AI Visibility, Trust, and Conversion using the "engines" context.
    3. Use "recent_results" to explain performance and "recent_tasks" to explain what the team is doing.
    4. Refer to "upcoming_meetings" if the user asks about calls or meetings.
    5. Refer to "active_campaigns" if the user asks about ads or specific marketing channels.
    6. Speak in the language the user uses (Arabic or English).
    7. If you don't have specific data for a question, suggest they check their "Results" or "Reports" tab.`;

    const messages = [
      { role: "system", content: systemPrompt },
      ...(history || []).map((m: any) => ({
        role: m.role === 'user' ? 'user' : 'assistant',
        content: typeof m.parts === 'string' ? m.parts : m.parts?.[0]?.text || m.content
      })),
      { role: "user", content: prompt }
    ];

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: messages,
        temperature: 0.5,
        max_tokens: 1024,
      }),
    });

    const data = await response.json();
    
    if (!data.choices || !data.choices[0]) {
      throw new Error(data.error?.message || 'Failed to get a valid response from Groq API. Please check your API key.');
    }
    
    const text = data.choices[0].message.content;

    return new Response(
      JSON.stringify({ text }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
