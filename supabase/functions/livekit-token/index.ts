import { AccessToken } from 'npm:livekit-server-sdk';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const { room_name, participant_name, participant_identity } = await req.json();

    if (!room_name || !participant_name || !participant_identity) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

    const apiKey = Deno.env.get('LIVEKIT_API_KEY');
    const apiSecret = Deno.env.get('LIVEKIT_API_SECRET');
    const livekitUrl = Deno.env.get('LIVEKIT_URL');

    if (!apiKey || !apiSecret || !livekitUrl) {
      console.error('LiveKit keys are missing from environment variables');
      return new Response(JSON.stringify({ error: 'Server configuration error' }), { status: 500 });
    }

    const at = new AccessToken(
      apiKey,
      apiSecret,
      { identity: participant_identity, name: participant_name }
    );

    at.addGrant({
      roomJoin: true,
      room: room_name,
      canPublish: true,
      canSubscribe: true,
    });

    const token = await at.toJwt();

    return new Response(JSON.stringify({ token: token, url: livekitUrl }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error: any) {
    console.error('Error generating token:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
