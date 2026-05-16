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

// ─── Professional Arabic notification templates ───────────────────────────────
function buildTemplate(table: string, record: any, lang: 'ar' | 'en', firstName: string) {
  const t = {
    // Chat message
    messages: {
      ar: { title: '💬 رسالة جديدة من فريقك', body: `${firstName}، وصلتك رسالة جديدة. افتح التطبيق للرد.` },
      en: { title: '💬 New Message', body: `${firstName}, you have a new message. Tap to reply.` },
    },
    // In-app notifications (forwarded from notifications table)
    notifications: {
      ar: { title: record?.title_ar || '🔔 تنبيه جديد', body: record?.body_ar || 'لديك تحديث جديد في لوحة التحكم.' },
      en: { title: record?.title_en || '🔔 New Notification', body: record?.body_en || 'You have a new update.' },
    },
    // Activity feed
    activity_feed: {
      ar: { title: '🔔 تحديث على مشروعك', body: record?.action_ar || 'تم إجراء تحديث على مشروعك. راجع التفاصيل.' },
      en: { title: '🔔 Project Update', body: record?.action_en || 'An update was made to your project.' },
    },
    // Call signal — high priority
    call_signals: {
      ar: {
        title: record?.call_type === 'video' ? '📹 مكالمة فيديو واردة' : '📞 مكالمة صوتية واردة',
        body: `${record?.caller_name || 'فريق محرك'} يتصل بك. اقبل للانضمام.`,
      },
      en: {
        title: record?.call_type === 'video' ? '📹 Incoming Video Call' : '📞 Incoming Voice Call',
        body: `${record?.caller_name || 'Moharek Team'} is calling you. Tap to join.`,
      },
    },
    // Tasks
    tasks: {
      ar: { title: '📋 مهمة جديدة بانتظارك', body: `تمت إضافة مهمة جديدة: ${record?.title || ''}. راجعها في التطبيق.` },
      en: { title: '📋 New Task Assigned', body: `A new task was added: ${record?.title || ''}. Check it now.` },
    },
    // Approvals
    approvals: {
      ar: { title: '✅ طلب موافقة جديد', body: `يوجد عنصر جديد يحتاج موافقتك: ${record?.title || ''}` },
      en: { title: '✅ New Approval Request', body: `A new item requires your approval: ${record?.title || ''}` },
    },
    // Meetings
    meetings: {
      ar: { title: '📅 اجتماع جديد مجدول', body: `تم جدولة اجتماع: ${record?.title || ''}. تحقق من التوقيت.` },
      en: { title: '📅 Meeting Scheduled', body: `A meeting has been scheduled: ${record?.title || ''}. Check the time.` },
    },
    // Reports
    reports: {
      ar: { title: '📄 تقرير جديد متاح', body: `تم رفع تقرير بعنوان: ${record?.title || ''}. يمكنك تحميله الآن.` },
      en: { title: '📄 New Report Available', body: `A new report is ready: ${record?.title || ''}. Download it now.` },
    },
    // Invoices
    invoices: {
      ar: { title: '💰 فاتورة جديدة', body: `تم إصدار فاتورة بمبلغ ${record?.amount || ''} ${record?.currency || 'AED'}. يرجى المراجعة.` },
      en: { title: '💰 New Invoice', body: `An invoice for ${record?.amount || ''} ${record?.currency || 'AED'} has been issued.` },
    },
    // Support tickets
    support_tickets: {
      ar: { title: '🎫 تذكرة دعم فني', body: `تم إنشاء تذكرة دعم: ${record?.title || ''}. سيتواصل معك الفريق قريباً.` },
      en: { title: '🎫 Support Ticket', body: `A support ticket was created: ${record?.title || ''}. We'll get back to you soon.` },
    },
  }

  const template = t[table as keyof typeof t] || t.activity_feed
  return template[lang]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const body = await req.json()
    const { table, record } = body
    const targetId: string | null = body.target_user_id ?? body.client_id ?? null

    if (!targetId) {
      return new Response(JSON.stringify({ error: 'No target user ID provided' }), { status: 400 })
    }

    // Fetch user profile
    const { data: userData } = await supabase
      .from('profiles')
      .select('full_name, preferred_language')
      .eq('id', targetId)
      .maybeSingle()

    if (!userData) {
      return new Response(JSON.stringify({ error: 'User not found' }), { status: 404 })
    }

    const lang: 'ar' | 'en' = userData.preferred_language === 'en' ? 'en' : 'ar'
    const firstName = userData.full_name?.split(' ')[0] || 'عزيزي'

    const { title, body: pushBody } = buildTemplate(table, record, lang, firstName)
    const isCall = table === 'call_signals'

    // Build OneSignal payload
    const osPayload: Record<string, any> = {
      app_id: ONESIGNAL_APP_ID,
      headings: { ar: title, en: title },
      contents: { ar: pushBody, en: pushBody },
      include_external_user_ids: [targetId],
      // Deep link data — app uses this to route to the right screen
      data: {
        table,
        id: record?.id,
        type: isCall ? 'call' : table,
        call_type: record?.call_type,
        caller_name: record?.caller_name,
        link_path: record?.link_path,
      },
    }

    // Call notifications need special high-priority handling
    if (isCall) {
      osPayload.priority = 10           // Max priority for calls
      osPayload.ttl = 30               // Expire after 30s (matches call timeout)
      osPayload.android_channel_id = 'moharek_calls'
      osPayload.ios_interruption_level = 'time-sensitive'
      osPayload.ios_relevance_score = 1.0
      // Content-available = 1 wakes the app even when in background (required for CallKeep)
      osPayload.content_available = true
    } else {
      osPayload.priority = 7
      osPayload.android_channel_id = 'moharek_general'
    }

    console.log(`[send-notification] → ${table} → ${targetId} | ${title}`)

    const osResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(osPayload),
    })

    const osResult = await osResponse.json()
    console.log('[send-notification] Result:', JSON.stringify(osResult))

    return new Response(JSON.stringify(osResult), { headers: corsHeaders, status: 200 })

  } catch (error) {
    console.error('[send-notification] Error:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
