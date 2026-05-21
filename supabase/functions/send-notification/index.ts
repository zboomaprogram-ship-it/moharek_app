import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')?.trim()
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')?.trim()
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

// ─── Arabic/English push notification templates ───────────────────────────────
function buildTemplate(table: string, record: any, lang: 'ar' | 'en', firstName: string, senderName?: string) {
  const sender = senderName || (lang === 'ar' ? 'فريقك' : 'Your team')

  const t: Record<string, Record<'ar' | 'en', { title: string; body: string }>> = {
    messages: {
      ar: { title: '💬 رسالة جديدة', body: `${sender}: ${record?.content ? String(record.content).substring(0, 80) : 'راجع المحادثة'}` },
      en: { title: '💬 New Message', body: `${sender}: ${record?.content ? String(record.content).substring(0, 80) : 'Check the chat'}` },
    },
    notifications: {
      ar: { title: record?.title_ar || '🔔 تنبيه جديد', body: record?.body_ar || 'لديك تحديث جديد في لوحة التحكم.' },
      en: { title: record?.title_en || '🔔 New Notification', body: record?.body_en || 'You have a new update.' },
    },
    activity_feed: {
      ar: { title: '🔔 تحديث على مشروعك', body: record?.action_ar || 'تم إجراء تحديث على مشروعك.' },
      en: { title: '🔔 Project Update', body: record?.action_en || 'An update was made to your project.' },
    },
    call_signals: {
      ar: {
        title: record?.call_type === 'video' ? '📹 مكالمة فيديو واردة' : '📞 مكالمة صوتية واردة',
        body: `${senderName || 'فريق ربحان'} يتصل بك. اقبل للانضمام.`,
      },
      en: {
        title: record?.call_type === 'video' ? '📹 Incoming Video Call' : '📞 Incoming Voice Call',
        body: `${senderName || 'Rabhan Team'} is calling you. Tap to join.`,
      },
    },
    tasks: {
      ar: { title: '📋 مهمة جديدة', body: `تمت إضافة مهمة: ${record?.title || ''}` },
      en: { title: '📋 New Task', body: `A new task was added: ${record?.title || ''}` },
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
      ar: { title: '📄 تقرير جديد', body: `تقرير: ${record?.title || ''}` },
      en: { title: '📄 New Report', body: `Report: ${record?.title || ''}` },
    },
    invoices: {
      ar: { title: '💰 فاتورة جديدة', body: `مبلغ ${record?.amount || ''} ${record?.currency || 'AED'}` },
      en: { title: '💰 New Invoice', body: `Amount: ${record?.amount || ''} ${record?.currency || 'AED'}` },
    },
    support_tickets: {
      ar: { title: '🎫 تذكرة دعم', body: `${record?.title || ''}` },
      en: { title: '🎫 Support Ticket', body: `${record?.title || ''}` },
    },
  }

  const template = t[table] || t.notifications
  return template[lang]
}

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

    // Fetch user profile — use maybeSingle to avoid crash if no profile row
    const { data: userData } = await supabase
      .from('profiles')
      .select('full_name, preferred_language, onesignal_player_id')
      .eq('id', targetId)
      .maybeSingle()

    if (!userData) {
      console.warn(`[send-notification] No profile for user ${targetId} — skipping push`)
      return new Response(JSON.stringify({ skipped: true, reason: 'no_profile' }), { headers: corsHeaders, status: 200 })
    }

    const lang: 'ar' | 'en' = userData.preferred_language === 'en' ? 'en' : 'ar'
    const firstName = userData.full_name?.split(' ')[0] || (lang === 'ar' ? 'عزيزي' : 'there')

    const { title, body: pushBody } = buildTemplate(table, record, lang, firstName, senderName)
    const isCall = table === 'call_signals'

    // Build OneSignal payload — target by external_user_id (primary) OR player_id (fallback)
    const targeting: Record<string, any> = userData.onesignal_player_id
      ? { include_player_ids: [userData.onesignal_player_id] }
      : { include_external_user_ids: [targetId], channel_for_external_user_ids: 'push' }

    const osPayload: Record<string, any> = {
      app_id: ONESIGNAL_APP_ID,
      headings: { ar: title, en: title },
      contents: { ar: pushBody, en: pushBody },
      ...targeting,
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
      osPayload.priority = 10
      osPayload.ttl = 30
      osPayload.android_channel_id = 'moharek_calls'
      osPayload.ios_interruption_level = 'time-sensitive'
      osPayload.ios_relevance_score = 1.0
      osPayload.content_available = true
    } else {
      osPayload.priority = 7
      osPayload.android_channel_id = 'moharek_general'
    }

    console.log(`[send-notification] → ${table} → ${targetId} (player: ${userData.onesignal_player_id || 'none'}) | ${title}`)

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      console.error('[send-notification] Missing ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY secret!')
      return new Response(JSON.stringify({ error: 'OneSignal secrets not configured' }), { status: 500 })
    }

    const osResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(osPayload),
    })

    const osResult = await osResponse.json()
    console.log('[send-notification] OneSignal result:', JSON.stringify(osResult))

    return new Response(JSON.stringify(osResult), { headers: corsHeaders, status: 200 })

  } catch (error) {
    console.error('[send-notification] Error:', error)
    return new Response(JSON.stringify({ error: (error as Error).message }), { status: 500 })
  }
})
