import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'
import admin from 'npm:firebase-admin@12.1.0'

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
  firstName: string,
  senderName?: string,
): Record<'ar' | 'en', { title: string; body: string }> {
  const senderAr = senderName || 'فريقك'
  const senderEn = senderName || 'Your team'

  const t: Record<string, Record<'ar' | 'en', { title: string; body: string }>> = {
    messages: {
      ar: { title: '💬 رسالة جديدة', body: `${senderAr}: ${record?.content ? String(record.content).substring(0, 80) : 'راجع المحادثة'}` },
      en: { title: '💬 New Message',  body: `${senderEn}: ${record?.content ? String(record.content).substring(0, 80) : 'Check the chat'}` },
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
        body:  `${record?.caller_name ?? senderName ?? 'فريق ربحان'} يتصل بك. اقبل للانضمام.`,
      },
      en: {
        title: record?.call_type === 'video' ? '📹 Incoming Video Call' : '📞 Incoming Voice Call',
        body:  `${record?.caller_name ?? senderName ?? 'Team'} is calling you. Tap to join.`,
      },
    },
    call_signals_missed: {
      ar: {
        title: record?.call_type === 'video' ? '📹 مكالمة فيديو فائتة' : '📞 مكالمة صوتية فائتة',
        body:  `لديك مكالمة فائتة من ${record?.caller_name ?? senderName ?? 'فريق ربحان'}.`,
      },
      en: {
        title: record?.call_type === 'video' ? '📹 Missed Video Call' : '📞 Missed Voice Call',
        body:  `You have a missed call from ${record?.caller_name ?? senderName ?? 'Team'}.`,
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
      ar: { title: '💰 فاتورة جديدة', body: `مبلغ ${record?.amount || ''} ${record?.currency || 'SAR'}` },
      en: { title: '💰 New Invoice',   body: `Amount: ${record?.amount || ''} ${record?.currency || 'SAR'}` },
    },
    support_tickets: {
      ar: { title: '🎫 تذكرة دعم', body: `${record?.title || ''}` },
      en: { title: '🎫 Support Ticket', body: `${record?.title || ''}` },
    },
  }

  return t[table] || t.notifications
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
    console.log(`[send-notification] OneSignal ${appId.substring(0, 8)}… → response: ${JSON.stringify(result)}`)
    return { appId, success, result }
  } catch (err) {
    console.error(`[send-notification] OneSignal ${appId.substring(0, 8)}… fetch error:`, err)
    return { appId, success: false, result: { error: String(err) } }
  }
}

// ── Send to Apple APNs (PushKit) ──────────────────────────────────────────────
async function sendToAPNs(
  deviceToken: string,
  payload: Record<string, any>,
  bundleId: string
): Promise<{ success: boolean; result: any }> {
  try {
    const p8Key = Deno.env.get('APPLE_VOIP_KEY')?.trim()
    const teamId = Deno.env.get('APPLE_TEAM_ID')?.trim()
    const keyId = Deno.env.get('APPLE_KEY_ID')?.trim()

    if (!p8Key || !teamId || !keyId) {
      console.warn(`[send-notification] Missing Apple APNs credentials. Ensure APPLE_VOIP_KEY, APPLE_TEAM_ID, and APPLE_KEY_ID are set in Secrets.`)
      return { success: false, result: { error: 'Missing credentials' } }
    }

    // Parse the private key
    const privateKey = await jose.importPKCS8(p8Key, 'ES256')

    // Create the JWT
    const jwt = await new jose.SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: keyId })
      .setIssuer(teamId)
      .setIssuedAt()
      .sign(privateKey)

    // Send HTTP/2 request to Apple Push Notification service (Production)
    // Deno fetch supports HTTP/2 automatically
    const apnsUrl = `https://api.push.apple.com/3/device/${deviceToken}`
    
    const response = await fetch(apnsUrl, {
      method: 'POST',
      headers: {
        'authorization': `bearer ${jwt}`,
        'apns-topic': `${bundleId}.voip`, // VoIP topic is bundle ID + .voip
        'apns-push-type': 'voip',
        'apns-priority': '10',
      },
      body: JSON.stringify({ aps: payload, ...payload }),
    })

    if (response.ok) {
      console.log(`[send-notification] APNs VoIP push sent successfully to ${deviceToken.substring(0, 8)}...`)
      return { success: true, result: await response.text() }
    } else {
      const errorText = await response.text()
      console.error(`[send-notification] APNs error: ${response.status} ${errorText}`)
      return { success: false, result: { error: errorText } }
    }
  } catch (err) {
    console.error(`[send-notification] APNs exception:`, err)
    return { success: false, result: { error: String(err) } }
  }
}

// ── Main handler ──────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const body = await req.json()
    console.log('[send-notification] Received webhook payload:', JSON.stringify(body))

    const { table, record } = body

    // ── Target User Resolution ──────────────────────────────────────────────
    // Resolve targetId from various possible formats:
    // 1. Direct body keys (manual trigger)
    // 2. Webhook record keys (e.g. from notifications table insert)
    // 3. Webhook on other tables
    let targetId: string | null = 
      body.target_user_id ?? 
      body.client_id ?? 
      record?.user_id ?? 
      record?.client_id ?? 
      null

    // If targetId is not provided but we have a project_id, resolve it using the project ID
    if (!targetId && record?.project_id) {
      const { data: project, error: projError } = await supabase
        .from('projects')
        .select('client_id, account_manager_id')
        .eq('id', record.project_id)
        .single();
      
      if (project && !projError) {
        if (table === 'call_signals' || table === 'call_signals_missed') {
          if (record.caller_id === project.client_id) {
            targetId = project.account_manager_id;
          } else {
            targetId = project.client_id;
          }
        } else if (table === 'tasks' && record.assigned_to) {
          targetId = record.assigned_to;
        } else {
          // General fallback: notify the other party if we know who did the action
          const actorId = 
            body.sender_id ?? 
            body.actor_id ?? 
            record.sender_id ?? 
            record.actor_id ?? 
            record.uploaded_by ?? 
            null;
          
          if (actorId) {
            if (actorId === project.client_id) {
              targetId = project.account_manager_id;
            } else {
              targetId = project.client_id;
            }
          } else {
            // Default to client for client-facing updates, or AM
            if (['approvals', 'invoices', 'reports', 'meetings'].includes(table)) {
              targetId = project.client_id;
            } else {
              targetId = project.client_id || project.account_manager_id;
            }
          }
        }
      }
    }

    const senderName: string | undefined = body.sender_name ?? record?.data?.sender_name

    if (!targetId) {
      console.error('[send-notification] Error: No target user ID found in payload')
      return new Response(JSON.stringify({ error: 'No target user ID provided' }), { status: 400 })
    }

    // ── Self-Notification Prevention ──────────────────────────────────────────
    // Do not notify a user about their own actions.
    const actorId = 
      body.sender_id ?? 
      body.actor_id ?? 
      record?.sender_id ?? 
      record?.actor_id ?? 
      record?.uploaded_by ??
      record?.metadata?.sender_id ??
      record?.data?.sender_id ??
      null;

    if (actorId && targetId === actorId) {
      console.log(`[send-notification] Skipping push notification: target user ${targetId} is the actor ${actorId}`);
      return new Response(
        JSON.stringify({ skipped: true, reason: 'self_notification' }),
        { headers: corsHeaders, status: 200 }
      );
    }

    // Fetch base user profile (this should always succeed)
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

    // Attempt to fetch new token columns (may fail if SQL migration hasn't been run)
    const { data: extraData } = await supabase
      .from('profiles')
      .select('fcm_token, apns_voip_token')
      .eq('id', targetId)
      .maybeSingle()
      
    if (extraData) {
      Object.assign(userData, extraData)
    }

    const lang: 'ar' | 'en' = userData.preferred_language === 'en' ? 'en' : 'ar'
    const firstName = userData.full_name?.split(' ')[0] || (lang === 'ar' ? 'عزيزي' : 'there')
    
    // Determine the source table
    // For in-app notification records, we always use the notifications template
    // which extracts title_ar/body_ar/title_en/body_en from the notification row.
    const sourceTable = table === 'notifications' ? 'notifications' : table
    const isCall = sourceTable === 'call_signals'

    // Get bilingual templates
    const template = buildTemplate(sourceTable, record, firstName, senderName)
    
    // Ensure we always have non-empty strings for both languages to satisfy OneSignal validation
    const titleAr = template.ar.title || '🔔 تنبيه جديد'
    const bodyAr = template.ar.body || 'لديك تحديث جديد في لوحة التحكم.'

    // ── Shared notification payload (no app_id or targeting yet) ──
    const sharedPayload: Record<string, any> = {
      headings: { ar: titleAr, en: titleAr }, // Always Arabic
      contents: { ar: bodyAr, en: bodyAr },   // Always Arabic
      data: {
        table: sourceTable,
        id: record?.id,
        type: isCall ? 'call' : sourceTable,
        call_type: record?.call_type ?? record?.data?.call_type,
        caller_name: record?.caller_name ?? record?.data?.caller_name,
        link_path: record?.link_path ?? record?.data?.link_path,
        channel_id: record?.channel_id ?? record?.data?.channel_id,
      },
    }

    if (isCall) {
      sharedPayload.priority = 10
      sharedPayload.ttl = 30
      sharedPayload.content_available = true
      
      // Remove headings and contents to make it a silent background push for CallKit
      delete sharedPayload.headings;
      delete sharedPayload.contents;
      
    } else {
      sharedPayload.priority = 7
    }

    console.log(`[send-notification] → ${sourceTable} → ${targetId} | player_id: ${userData.onesignal_player_id ?? 'none'} | ${titleAr}`)

    const results: any[] = []

    // ── OneSignal Credentials Resolution ─────────────────────────────────────────
    // Identify if this request originates from Rabhan vs Moharek to prevent duplicate pushes.
    const getOneSignalCredentials = () => {
      const isRabhan = SUPABASE_URL.includes('pyzheqwypoaazpmpgiuq') || 
                       Deno.env.get('APP_FLAVOR')?.trim().toLowerCase() === 'rabhan';
      
      if (isRabhan) {
        const appId = RABHAN_ONESIGNAL_APP_ID || Deno.env.get('ONESIGNAL_APP_ID')?.trim();
        const apiKey = RABHAN_ONESIGNAL_API_KEY || Deno.env.get('ONESIGNAL_REST_API_KEY')?.trim();
        if (appId && apiKey) return { appId, apiKey };
      } else {
        const appId = MOHAREK_ONESIGNAL_APP_ID || Deno.env.get('ONESIGNAL_APP_ID')?.trim();
        const apiKey = MOHAREK_ONESIGNAL_API_KEY || Deno.env.get('ONESIGNAL_REST_API_KEY')?.trim();
        if (appId && apiKey) return { appId, apiKey };
      }

      // Final fallback to whatever default env vars are present
      const appId = Deno.env.get('ONESIGNAL_APP_ID')?.trim();
      const apiKey = Deno.env.get('ONESIGNAL_REST_API_KEY')?.trim();
      if (appId && apiKey) return { appId, apiKey };

      return null;
    };

    const creds = getOneSignalCredentials();
    if (!creds) {
      console.error('[send-notification] Error: No OneSignal credentials found');
      return new Response(JSON.stringify({ error: 'OneSignal credentials not found' }), { status: 500 });
    }

    // ── Strategy A: Target by stored Player ID (most reliable) ─────────────
    if (userData.onesignal_player_id) {
      const playerTargeting = { 
        include_subscription_ids: [userData.onesignal_player_id]
      }
      const res = await sendToOneSignal(creds.appId, creds.apiKey, playerTargeting, sharedPayload);
      results.push(res);
    } else {
      // ── Strategy B: Target by External User ID (fallback) ──────────────────
      const externalTargeting = {
        include_external_user_ids: [targetId],
        channel_for_external_user_ids: 'push',
      }
      const res = await sendToOneSignal(creds.appId, creds.apiKey, externalTargeting, sharedPayload);
      results.push(res);
    }

    // ── Strategy C: Silent VoIP Push (Apple PushKit / Android FCM) ─────────
    if (isCall) {
      console.log(`[send-notification] Attempting silent background push for VoIP...`);
      
      // 1. Android FCM (Native Background Wakeup for CallKit)
      if (userData.fcm_token) {
        console.log(`[send-notification] FCM token found for ${targetId}. Sending direct Firebase data push...`);
        try {
          const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')?.trim()
          if (!serviceAccountStr) {
            console.warn('[send-notification] WARNING: FIREBASE_SERVICE_ACCOUNT secret is missing! Cannot send FCM push.');
          } else {
            // Initialize Firebase Admin if not already initialized
            if (!admin.apps.length) {
              const serviceAccount = JSON.parse(serviceAccountStr)
              admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
              })
            }
            
            // Send data-only payload to FCM. This bypasses OneSignal and directly 
            // wakes up the Flutter FirebaseMessaging.onBackgroundMessage isolate!
            const fcmPayload = {
              token: userData.fcm_token,
              data: {
                id: String(sharedPayload.data.id || ''),
                type: 'call',
                call_type: String(sharedPayload.data.call_type || 'voice'),
                caller_name: String(sharedPayload.data.caller_name || 'Admin'),
                room_name: String(record?.room_name || ''),
              },
              android: {
                priority: 'high' as const,
              }
            };
            
            const fcmRes = await admin.messaging().send(fcmPayload)
            console.log(`[send-notification] FCM data push success: ${fcmRes}`)
            results.push({ success: true, result: fcmRes })
          }
        } catch (fcmErr) {
          console.error(`[send-notification] FCM push failed:`, fcmErr)
          results.push({ success: false, result: { error: String(fcmErr) } })
        }
      }

      // 2. Apple APNs (PushKit)
      if (userData.apns_voip_token) {
        // We assume the bundle ID is com.zbooma.moharek (adjust if flavor is Rabhan)
        const bundleId = SUPABASE_URL.includes('pyzheqwypoaazpmpgiuq') || Deno.env.get('APP_FLAVOR')?.trim().toLowerCase() === 'rabhan'
          ? 'com.zbooma.rabhan' 
          : 'com.zbooma.moharek';
          
        const apnsRes = await sendToAPNs(userData.apns_voip_token, sharedPayload, bundleId);
        results.push(apnsRes);
      }
    }

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
