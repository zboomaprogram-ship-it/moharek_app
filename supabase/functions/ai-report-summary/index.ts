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

    const { report_data, project_context } = await req.json()

    const systemPrompt = `You are a Senior Growth Strategist at Moharek Growth Hub. 
    Your task is to transform raw marketing report data into a premium "Growth Story" for the client app.
    
    Project Context: ${JSON.stringify(project_context || {})}
    Report Data: ${JSON.stringify(report_data || {})}
    
    Response Format: You MUST return a valid JSON object with the following fields:
    - highlight_stat: A short, impactful statistic (e.g., "+42% Traffic Growth" or "150 Leads Generated").
    - highlight_context: A one-sentence explanation of the stat (e.g., "Resulting from our technical SEO overhaul").
    - manager_note: A 2-3 sentence personalized message summarizing the month's progress.
    - next_month_priorities: A string array containing 3 specific items to focus on next month.
    
    Guidelines:
    1. Tone: Premium, expert, and data-driven but accessible.
    2. Language: Provide the response in the language of the report (mostly Arabic).
    3. JSON Only: Do not include any text before or after the JSON object.`;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: "Generate the growth story JSON." }
        ],
        temperature: 0.5,
        response_format: { type: "json_object" },
      }),
    });

    const data = await response.json();
    const content = JSON.parse(data.choices[0].message.content);

    return new Response(
      JSON.stringify(content),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
