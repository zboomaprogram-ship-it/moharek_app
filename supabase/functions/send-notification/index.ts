import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Secrets ─────────────────────────────────────────────────────────────────
// Both flavors share the same Supabase project but have SEPARATE OneSignal apps.
// We send to BOTH apps using external_user_id so the correct one always receives.
const MOHAREK_ONESIGNAL_APP_ID  = Deno.env.get('ONESIGNAL_APP_ID')?.trim()           // Moharek app
const RABHAN_ONESIGNAL_APP_ID   = Deno.env.get('RABHAN_ONESIGNAL_APP_ID')?.trim()    // Rabhan app
const MOHAREK_ONESIGNAL_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')?.trim()
const RABHAN_ONESIGNAL_API_KEY  = Deno.env.get('RABHAN_ONESIGNAL_REST_API_KEY')?.trim()
const SUPABASE_URL              = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

// ── Notification templates ────────────────────────────────────────────────────
function buildTemplate(
  table: string,
  record: any,
  lang: 'ar' | 'en',
  firstName: string,
  senderName?: string,
) {
  const sender = senderName || (lang === 'ar' ? 'فريقك' : 'Your team')

  const t: Record<string, Record<'ar' | 'en', { title: string; body: string }>> = {
    messages: {
      ar: { title: '💬 رسالة جديدة', body: `${sender}: ${record?.content ? String(record.content).substring(0, 80) : 'راجع المحادثة'}` },
      en: { title: '💬 New Message',  body: `${sender}: ${record?.content ? String(record.content).substring(0, 80) : 'Check the chat'}` },
    },
    notifications: {
      ar: { title: record?.title_ar || '🔔 تنبيه جديد',         body: record?.body_ar || 'لديك تحديث جديد في لوحة التحكم.' },
      en: { title: record?.title_en || '🔔 New Notification',   body: record?.body_en || 'You have a new update.' },
    },
    activity_feed: {
      ar: { title: '🔔 تحديث على مشروعك', body: record?.action_ar || 'تم إجراء تحديث على مشروعك.' },
      en: { title: '🔔 Project Update',   body: record?.action_en || 'An update was made to your project.' },
    },
    call_signals: {
      ar: {
        title: record?.call_type === 'video' ? '📹 مكالمة فيديو واردة' : '📞 مكالمة صوتية واردة',
        body:  `${senderName || 'فريق ربحان'} يتصل بك. اقبل للانضمام.`,
      },
      en: {
        title: record?.call_type === 'video' ? '📹 Incoming Video Call' : '📞 Incoming Voice Call',
        body:  `${senderName || 'Team'} is calling you. Tap to join.`,
      },
    },
    tasks: {
      ar: { title: '📋 مهمة جديدة', body: `تمت إضافة مهمة: ${record?.title || ''}` },
      en: { title: '📋 New Task',    body: `A new task was added: ${record?.title || ''}` },
    },
    approvals: {
      ar: { title: '✅ طلب موافقة جديد', body: `يحتاج موافقتك: ${record?.title || ''}` },
      en: { title: '✅ New Approval Request', body: `Needs your approval: ${record?.title || ''}` },
    },
    meetings: {
      ar: { title: '📅 اجتماع جديد', body: `تم جدولة: ${record?.title || ''}` },
      en: { title: '📅 Meeting Scheduled', body: `Scheduled: ${record?.title || ''}` },
    },
    reports: {
      ar: { title: '📄 تقرير جديد',     body: `تقرير: ${record?.title || ''}` },
      en: { title: '📄 New Report',      body: `Report: ${record?.title || ''}` },
    },
    invoices: {
      ar: { title: '💰 فاتورة جديدة', body: `مبلغ ${record?.amount || ''} ${record?.currency || 'AED'}` },
      en: { title: '💰 New Invoice',   body: `Amount: ${record?.amount || ''} ${record?.currency || 'AED'}` },
    },
    support_tickets: {
      ar: { title: '🎫 تذكرة دعم', body: `${record?.title || ''}` },
      en: { title: '🎫 Support Ticket', body: `${record?.title || ''}` },
    },
  }

  return (t[table] || t.notifications)[lang]
}

// ── Send to ONE OneSignal app ─────────────────────────────────────────────────
async function sendToOneSignal(
  appId: string,
  apiKey: string,
  targeting: Record<string, any>,
  payload: Record<string, any>,
): Promise<{ appId: string; success: boolean; result: any }> {
  try {
    const resp = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${apiKey}`,
      },
      body: JSON.stringify({ app_id: appId, ...targeting, ...payload }),
    })
    const result = await resp.json()
    const success = !result.errors && (result.recipients > 0 || result.id)
    console.log(`[send-notification] OneSignal ${appId.substring(0, 8)}… → recipients:${result.recipients ?? '?'} errors:${JSON.stringify(result.errors ?? null)}`)
    return { appId, success, result }
  } catch (err) {
    console.error(`[send-notification] OneSignal ${appId.substring(0, 8)}… fetch error:`, err)
    return { appId, success: false, result: { error: String(err) } }
  }
}

// ── Main handler ──────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const body = await req.json()
    const { table, record } = body
    const targetId: string | null = body.target_user_id ?? body.client_id ?? null
    const senderName: string | undefined = body.sender_name

    if (!targetId) {
      return new Response(JSON.stringify({ error: 'No target user ID provided' }), { status: 400 })
    }

    // Fetch user profile
    const { data: userData, error: profileError } = await supabase
      .from('profiles')
      .select('full_name, preferred_language, onesignal_player_id')
      .eq('id', targetId)
      .maybeSingle()

    if (profileError) {
      console.error('[send-notification] Profile fetch error:', profileError.message)
    }

    if (!userData) {
      console.warn(`[send-notification] No profile for user ${targetId} — skipping push`)
      return new Response(JSON.stringify({ skipped: true, reason: 'no_profile' }), { headers: corsHeaders })
    }

    const lang: 'ar' | 'en' = userData.preferred_language === 'en' ? 'en' : 'ar'
    const firstName = userData.full_name?.split(' ')[0] || (lang === 'ar' ? 'عزيزي' : 'there')
    const isCall = table === 'call_signals'

    const { title, body: pushBody } = buildTemplate(table, record, lang, firstName, senderName)

    // ── Shared notification payload (no app_id or targeting yet) ──
    const sharedPayload: Record<string, any> = {
      headings: { ar: title, en: title },
      contents: { ar: pushBody, en: pushBody },
      data: {
        table,
        id: record?.id,
        type: isCall ? 'call' : table,
        call_type: record?.call_type,
        caller_name: record?.caller_name,
        link_path: record?.link_path,
        channel_id: record?.channel_id,
      },
    }

    if (isCall) {
      sharedPayload.priority = 10
      sharedPayload.ttl = 30
      sharedPayload.android_channel_id = 'moharek_calls'
      sharedPayload.ios_interruption_level = 'time-sensitive'
      sharedPayload.ios_relevance_score = 1.0
      sharedPayload.content_available = true
    } else {
      sharedPayload.priority = 7
      sharedPayload.android_channel_id = 'moharek_general'
    }

    console.log(`[send-notification] → ${table} → ${targetId} | player_id: ${userData.onesignal_player_id ?? 'none'} | ${title}`)

    const results: any[] = []

    // ── Strategy A: Target by stored Player ID (most reliable) ─────────────
    // When we have a stored player ID, we send directly to that specific device
    // subscription. Player IDs are unique to a OneSignal app, so we must also
    // send to the matching app_id.
    // Since we don't store which flavor registered the player, we try BOTH apps.
    if (userData.onesignal_player_id) {
      const playerTargeting = { include_player_ids: [userData.onesignal_player_id] }

      const sends = []
      if (MOHAREK_ONESIGNAL_APP_ID && MOHAREK_ONESIGNAL_API_KEY) {
        sends.push(sendToOneSignal(MOHAREK_ONESIGNAL_APP_ID, MOHAREK_ONESIGNAL_API_KEY, playerTargeting, sharedPayload))
      }
      if (RABHAN_ONESIGNAL_APP_ID && RABHAN_ONESIGNAL_API_KEY) {
        sends.push(sendToOneSignal(RABHAN_ONESIGNAL_APP_ID, RABHAN_ONESIGNAL_API_KEY, playerTargeting, sharedPayload))
      }

      const playerResults = await Promise.all(sends)
      results.push(...playerResults)
    }

    // ── Strategy B: Target by External User ID (fallback) ──────────────────
    // external_user_id = the Supabase user UUID set via OneSignal.login()
    // This works even if player_id is not stored yet (e.g. first login)
    const externalTargeting = {
      include_external_user_ids: [targetId],
      channel_for_external_user_ids: 'push',
    }

    const extSends = []
    if (MOHAREK_ONESIGNAL_APP_ID && MOHAREK_ONESIGNAL_API_KEY) {
      extSends.push(sendToOneSignal(MOHAREK_ONESIGNAL_APP_ID, MOHAREK_ONESIGNAL_API_KEY, externalTargeting, sharedPayload))
    }
    if (RABHAN_ONESIGNAL_APP_ID && RABHAN_ONESIGNAL_API_KEY) {
      extSends.push(sendToOneSignal(RABHAN_ONESIGNAL_APP_ID, RABHAN_ONESIGNAL_API_KEY, externalTargeting, sharedPayload))
    }

    const extResults = await Promise.all(extSends)
    results.push(...extResults)

    const anySuccess = results.some(r => r.success)
    return new Response(
      JSON.stringify({ sent: anySuccess, results }),
      { headers: corsHeaders, status: 200 },
    )

  } catch (error) {
    console.error('[send-notification] Unhandled error:', error)
    return new Response(JSON.stringify({ error: (error as Error).message }), { status: 500 })
  }
})
