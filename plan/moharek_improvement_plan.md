# Moharek App — Improvement Plan v2.1

**Goal: Make every client feel like they have a front-row seat to their own business growth.**
**Date: May 2026 | Based on version 1.6.0**

---

## Table of Contents

1. [In-App Calls — Replace Browser Jitsi](#1-in-app-calls)
2. [Unforgettable Onboarding Experience](#2-unforgettable-onboarding)
3. [Living Dashboard — Make Data Feel Alive](#3-living-dashboard)
4. [Growth Milestones & Celebrations](#4-milestones--celebrations)
5. [The Journey Screen — Reborn](#5-journey-screen-reborn)
6. [Smart Notifications with Personality](#6-smart-notifications)
7. [Monthly Growth Story Report](#7-growth-story-report)
8. [Client Health Score](#8-client-health-score)
9. [In-App Survey & NPS](#9-nps--satisfaction)
10. [UX Polish & Micro-interactions](#10-ux-polish)
11. [Full Arabic Support — Default Language](#11-arabic-support)
12. [Voice Messages in Chat](#12-voice-messages)
13. [Implementation Phases](#13-phases)
14. [Updated Tech Stack & Cost](#14-cost)

---

## 1. In-App Calls

**Problem:** Jitsi opens Chrome. Client leaves the app. Experience breaks.\*\*
**Fix:** Replace entirely with LiveKit — fully native, zero monthly cost up to 10,000 minutes/month.

### Why LiveKit over Jitsi

| Feature          | Jitsi (current)       | LiveKit (new)                         |
| ---------------- | --------------------- | ------------------------------------- |
| Stays in app     | ❌ Opens browser      | ✅ 100% native Flutter                |
| Free tier        | ✅ Unlimited (server) | ✅ 10,000 min/month                   |
| Flutter SDK      | ❌ WebView wrapper    | ✅ Native `livekit_client`            |
| Call UI control  | ❌ None               | ✅ Full custom UI                     |
| Background calls | ❌ Breaks             | ✅ Native CallKit + ConnectionService |
| Screen share     | ❌ Limited            | ✅ Built-in                           |
| Recording        | ❌ No                 | ✅ Optional (paid)                    |

### Packages to add

```yaml
dependencies:
  livekit_client: ^2.2.0 # Core WebRTC engine
  flutter_webrtc: ^0.10.0 # Required by livekit_client
  callkeep: ^4.0.0 # Native iOS CallKit + Android ConnectionService
  flutter_local_notifications: ^17.0.0
```

### Backend — LiveKit Server (Free)

**Option A — LiveKit Cloud (recommended for start):**

- Sign up at `livekit.io` → free tier: 10,000 participant-minutes/month
- No server to manage
- Get `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`

**Option B — Self-host on a $6/mo VPS (when scaling):**

```bash
# One command on any Linux VPS
docker run --rm -e LIVEKIT_KEYS="devkey: secret" \
  -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  livekit/livekit-server --dev
```

### Supabase Edge Function — Token Generator

Create `supabase/functions/livekit-token/index.ts`:

```typescript
import { AccessToken } from "livekit-server-sdk";

Deno.serve(async (req) => {
  const { room_name, participant_name, participant_identity } =
    await req.json();

  const at = new AccessToken(
    Deno.env.get("LIVEKIT_API_KEY")!,
    Deno.env.get("LIVEKIT_API_SECRET")!,
    { identity: participant_identity, name: participant_name },
  );
  at.addGrant({
    roomJoin: true,
    room: room_name,
    canPublish: true,
    canSubscribe: true,
  });

  return Response.json({
    token: await at.toJwt(),
    url: Deno.env.get("LIVEKIT_URL"),
  });
});
```

### meetings table — add new columns

```sql
alter table meetings add column livekit_room_name text;
alter table meetings add column call_type text default 'video'; -- 'video' or 'voice'
alter table meetings add column initiated_by uuid references profiles(id);
```

### Flutter — Call Service

Create `lib/features/calls/services/call_service.dart`:

```dart
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallService {
  final _supabase = Supabase.instance.client;
  Room? _room;
  Room? get currentRoom => _room;

  // Step 1: Initiate a call (caller side)
  Future<Room> startCall({
    required String projectId,
    required String callType, // 'video' or 'voice'
    required String callerName,
    required String callerId,
  }) async {
    final roomName = 'moharek-$projectId-${DateTime.now().millisecondsSinceEpoch}';

    // Get token from Supabase Edge Function
    final res = await _supabase.functions.invoke('livekit-token', body: {
      'room_name': roomName,
      'participant_name': callerName,
      'participant_identity': callerId,
    });
    final token = res.data['token'] as String;
    final url = res.data['url'] as String;

    // Save meeting row so recipient can join
    await _supabase.from('meetings').insert({
      'project_id': projectId,
      'livekit_room_name': roomName,
      'call_type': callType,
      'initiated_by': callerId,
      'status': 'ongoing',
      'title': '$callType call',
    });

    // Connect to LiveKit room
    _room = Room();
    await _room!.connect(url, token,
      roomOptions: RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: true,
          videoEncoding: VideoEncoding(maxBitrate: 1500000, maxFramerate: 30),
        ),
      ),
    );

    // Enable camera + mic
    await _room!.localParticipant?.setCameraEnabled(callType == 'video');
    await _room!.localParticipant?.setMicrophoneEnabled(true);

    return _room!;
  }

  // Step 2: Join an existing call (recipient side)
  Future<Room> joinCall({
    required String roomName,
    required String participantName,
    required String participantIdentity,
    required String callType,
  }) async {
    final res = await _supabase.functions.invoke('livekit-token', body: {
      'room_name': roomName,
      'participant_name': participantName,
      'participant_identity': participantIdentity,
    });
    final token = res.data['token'] as String;
    final url = res.data['url'] as String;

    _room = Room();
    await _room!.connect(url, token);
    await _room!.localParticipant?.setCameraEnabled(callType == 'video');
    await _room!.localParticipant?.setMicrophoneEnabled(true);
    return _room!;
  }

  Future<void> endCall(String meetingId) async {
    await _room?.disconnect();
    _room = null;
    await _supabase.from('meetings')
        .update({'status': 'completed'})
        .eq('id', meetingId);
  }

  void toggleCamera() => _room?.localParticipant?.setCameraEnabled(
    !(_room?.localParticipant?.isCameraEnabled() ?? false));

  void toggleMic() => _room?.localParticipant?.setMicrophoneEnabled(
    !(_room?.localParticipant?.isMicrophoneEnabled() ?? false));
}
```

### Flutter — In-App Call Screen UI

Create `lib/features/calls/screens/active_call_screen.dart`:

```dart
class ActiveCallScreen extends StatefulWidget {
  final Room room;
  final String callType; // 'video' or 'voice'
  final String remoteName;
  final String meetingId;
  // ...
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Remote video (full screen)
          _buildRemoteVideo(),

          // Local video (picture-in-picture, top right)
          Positioned(top: 60, right: 16,
            child: _buildLocalVideo()),

          // Top bar: caller name + duration timer
          Positioned(top: 0, left: 0, right: 0,
            child: _buildTopBar()),

          // Bottom controls
          Positioned(bottom: 0, left: 0, right: 0,
            child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute mic
          _CallButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onTap: () { setState(() => _isMuted = !_isMuted); _callService.toggleMic(); },
          ),
          // End call (red, center, larger)
          _CallButton(
            icon: Icons.call_end,
            label: 'End',
            color: Colors.red,
            size: 72,
            onTap: () async {
              await _callService.endCall(widget.meetingId);
              context.pop();
            },
          ),
          // Camera toggle (only for video calls)
          if (widget.callType == 'video')
            _CallButton(
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _isCameraOff ? 'Show cam' : 'Hide cam',
              onTap: () { setState(() => _isCameraOff = !_isCameraOff); _callService.toggleCamera(); },
            ),
          // Speaker
          _CallButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: 'Speaker',
            onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
          ),
        ],
      ),
    );
  }
}
```

### Native Incoming Call UI (while app is background/closed)

**iOS — CallKit via `callkeep` package:**

```dart
// In main.dart, before runApp():
FlutterCallkeep().setup({
  'ios': {
    'appName': 'Moharek',
    'imageName': 'moharek_logo',
    'supportsVideo': true,
  },
  'android': {
    'alertTitle': 'Permissions required',
    'alertDescription': 'Allow Moharek to manage calls',
    'cancelButton': 'Cancel',
    'okButton': 'Allow',
    'foregroundService': {
      'channelId': 'com.moharek.calls',
      'channelName': 'Moharek Calls',
      'notificationTitle': 'Call in progress',
    },
  },
});
```

**FCM Incoming Call Payload (from Supabase Edge Function → FCM):**

```json
{
  "priority": "high",
  "data": {
    "type": "incoming_call",
    "room_name": "moharek-abc123-1234567890",
    "call_type": "video",
    "caller_name": "Ahmed — Moharek Team",
    "caller_id": "uuid-here",
    "meeting_id": "uuid-here"
  },
  "apns": {
    "payload": { "aps": { "content-available": 1 } },
    "headers": { "apns-priority": "10", "apns-push-type": "voip" }
  }
}
```

**On FCM receive (background isolate):**

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['type'] == 'incoming_call') {
    FlutterCallkeep().displayIncomingCall(
      message.data['meeting_id'],
      message.data['caller_name'],
      handleType: 'generic',
      hasVideo: message.data['call_type'] == 'video',
    );
  }
}
```

---

## 2. Unforgettable Onboarding

**First impression determines if a client feels like a premium partner or just another account.**

### New client first-login flow (5 screens, one-time only)

**Screen 1 — Welcome Moment**

- Full dark screen, Moharek logo animates in from center
- Text fades in: _"Welcome, [Name]. Your growth journey starts now."_
- Subtle particle animation in background (use `particles_flutter` package)
- Single CTA button: "Let's begin →"

**Screen 2 — Meet Your Team**

- "These are the people working for you every day"
- Horizontal scroll of team member cards: avatar + name + role
- Each card has a short voice note or text intro (upload from admin)
- Feels personal — not a generic "your account is ready" screen

**Screen 3 — Your 90-Day Roadmap**

- Animated timeline revealing the first 90 days
- Each milestone pops in with a subtle bounce: Day 1, Day 7, Day 30, Day 60, Day 90
- Labels: "Audit Complete", "Strategy Delivered", "First Keywords Improved", etc.

**Screen 4 — What to Expect**

- 3 swipeable cards explaining:
  - 📊 "Track your results here — updated weekly"
  - ✅ "Approve content before it goes live"
  - 💬 "Talk to your growth manager anytime"

**Screen 5 — First Task (immediate value)**

- "Before we start, tell us one thing:"
- Single question: "What's your #1 goal this year?" (3-4 option buttons)
- Answer saves to `projects.client_goal` column
- This personalizes the dashboard greeting going forward

**Implementation:**

```dart
// Check if onboarding is done
final profile = await supabase.from('profiles')
    .select('onboarding_completed')
    .eq('id', userId)
    .single();

if (!profile['onboarding_completed']) {
  context.go('/onboarding');
}

// Mark complete on last screen
await supabase.from('profiles')
    .update({'onboarding_completed': true, 'client_goal': selectedGoal})
    .eq('id', userId);
```

**New columns needed:**

```sql
alter table profiles add column onboarding_completed boolean default false;
alter table profiles add column client_goal text;
```

---

## 3. Living Dashboard

**Data should feel like it's breathing, not sitting dead on a screen.**

### Improvements to the Home Screen

**A — Personalized greeting (changes by time of day + goal)**

```dart
String getGreeting(String name, String goal) {
  final hour = DateTime.now().hour;
  final timeGreet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  return '$timeGreet, $name 👋\nStill focused on: $goal';
}
```

**B — Animated metric counters**
When the dashboard loads, numbers count up from 0 to their real value over 800ms.

```dart
class AnimatedCounter extends StatefulWidget {
  final double end;
  final String suffix; // %, K, etc.
  // ...
  // Use Tween<double> + CurvedAnimation(curve: Curves.easeOut)
}
```

**C — "What's new since your last visit" banner**
Show a highlighted card at the top if there is new activity since the user's last session:

- "3 tasks were completed since you last checked"
- "Your traffic increased 18% this week"
- "1 item needs your approval"

```sql
-- Track last seen timestamp
alter table profiles add column last_seen_at timestamptz;
```

**D — Heartbeat indicator on live data**
A small pulsing green dot next to "Last Updated" timestamp to signal real-time connection is active.

**E — Weekly comparison chip on each metric card**
Every metric card shows a small `↑ 12% vs last week` or `↓ 3%` chip in the corner, color-coded green/red.

---

## 4. Milestones & Celebrations

**Clients should feel wins, not just read about them.**

### Milestone Events (auto-detected by Supabase triggers)

| Event                   | Trigger Condition                                     | Celebration                                  |
| ----------------------- | ----------------------------------------------------- | -------------------------------------------- |
| First keyword on Page 1 | `results.metric_value <= 10` where type=`seo_ranking` | Full-screen confetti burst + trophy card     |
| Traffic doubled         | current value ≥ 2× the value 30 days ago              | Animated chart with "2×" badge               |
| 100 leads reached       | `sum(leads) >= 100`                                   | "Century" milestone card unlocked            |
| First invoice paid      | `invoices.status = 'paid'`                            | "Partner" badge on profile                   |
| Project stage completed | `journey_stages.is_completed = true`                  | Stage completion animation in Journey screen |
| 90 days together        | `projects.start_date + 90 days = today`               | Special "90-day partner" notification        |

### Confetti Implementation

```yaml
dependencies:
  confetti: ^0.7.0
```

```dart
class MilestoneOverlay extends StatefulWidget {
  final String title;   // "You reached Page 1! 🎉"
  final String subtitle; // "Your keyword 'best dental clinic Cairo' is now #7"
  // ...
}

// Show from anywhere in the app:
showGeneralDialog(
  context: context,
  pageBuilder: (_, __, ___) => MilestoneOverlay(
    title: "You hit Page 1! 🎉",
    subtitle: "\"$keyword\" is now ranked #$position on Google",
  ),
);
```

### Milestones table (new)

```sql
create table milestones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  milestone_type text, -- page1_keyword, traffic_doubled, 100_leads, etc.
  title text,
  description text,
  achieved_at timestamptz default now(),
  seen_by_client boolean default false
);
```

**Supabase function that checks for milestones (run daily via pg_cron):**

```sql
-- Enable pg_cron in Supabase dashboard → Extensions
select cron.schedule('check-milestones', '0 9 * * *', $$
  -- Check for Page 1 keywords
  insert into milestones (project_id, milestone_type, title, description)
  select distinct r.project_id,
    'page1_keyword',
    'Keyword reached Page 1!',
    r.metric_label || ' is now ranked #' || r.metric_value::int
  from results r
  where r.result_type = 'seo_ranking'
    and r.metric_value <= 10
    and r.recorded_at = current_date
    and not exists (
      select 1 from milestones m
      where m.project_id = r.project_id
        and m.milestone_type = 'page1_keyword'
        and m.description = r.metric_label || ' is now ranked #' || r.metric_value::int
    );
$$);
```

---

## 5. Journey Screen Reborn

**The Journey screen should feel like a story, not a checklist.**

### Current problem

It's a list of stages. It doesn't tell a story. It doesn't celebrate progress. It doesn't show what's coming next.

### New design: "Your Growth Story"

**Visual treatment:**

- Vertical timeline with a glowing animated line connecting stages
- Completed stages: solid teal with checkmark + completion date
- Current stage: pulsing blue border, "In Progress" badge, progress sub-bar showing % of tasks done within this stage
- Future stages: muted/dimmed with lock icon
- Each stage taps open to reveal: tasks, files, team member photos, and a short "what we're doing" paragraph written by the account manager

**New column: stage description (from admin)**

```sql
alter table journey_stages add column stage_description text;
-- Admin writes: "This week we're building your keyword map and analyzing 3 competitors..."
```

**Key widget — animated timeline connector:**

```dart
// The glowing line between stages
Container(
  width: 2,
  height: 60,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isCompleted
        ? [const Color(0xFF4CAF50), const Color(0xFF4CAF50)]
        : [const Color(0xFF4CAF50), const Color(0xFF1E293B)],
    ),
  ),
)
```

**"What happens next" section at the bottom:**
After the current stage, show a preview card of the next stage with: title + 2-line description + estimated start date. Makes the client feel momentum, not waiting.

---

## 6. Smart Notifications

**Notifications should sound like a person, not a system.**

### Notification copy — before vs after

| Event            | ❌ Before (generic)            | ✅ After (personal)                                                              |
| ---------------- | ------------------------------ | -------------------------------------------------------------------------------- |
| New report       | "Your monthly report is ready" | "Ahmed, your April report is ready. Big wins inside 📈"                          |
| Keyword improves | "Keyword ranking updated"      | "🚀 'best dental clinic Cairo' jumped from #18 to #7 — you're almost on Page 1!" |
| Task waiting     | "Task needs your approval"     | "Quick one, Ahmed — we need 5 min of your time to approve next month's content"  |
| Invoice due      | "Invoice #4 is due"            | "Friendly reminder: Invoice #4 (May retainer) is due in 3 days"                  |
| Milestone        | "Milestone achieved"           | "🎉 You just hit 100 leads! That's a huge deal — tap to celebrate"               |
| Call incoming    | "Incoming call"                | "📞 Sarah from Moharek is calling — your growth manager"                         |

### Smart notification builder (Supabase Edge Function)

`supabase/functions/send-smart-notification/index.ts`:

```typescript
const templates = {
  new_report: (data: any) => ({
    title: `${data.client_name}, your ${data.month} report is ready`,
    body: `${data.highlight} — tap to read the full breakdown 📈`,
  }),
  keyword_improved: (data: any) => ({
    title: `🚀 "${data.keyword}" jumped to #${data.new_position}!`,
    body:
      data.new_position <= 10
        ? `You're on Page 1 of Google! Tap to celebrate 🎉`
        : `Up from #${data.old_position} — ${10 - data.new_position} spots to Page 1`,
  }),
  approval_needed: (data: any) => ({
    title: `Quick approval needed, ${data.client_name}`,
    body: `Your team is waiting on: ${data.approval_title}`,
  }),
  milestone: (data: any) => ({
    title: `🏆 ${data.title}`,
    body: data.description,
  }),
};
```

### Notification preferences (client controls)

Add to Settings screen — toggle switches per category:

- 📊 Results & rankings updates
- ✅ Tasks & approvals
- 📄 New reports
- 💰 Invoice reminders
- 🎉 Milestones & celebrations
- 📞 Calls & meetings

```sql
alter table profiles add column notification_preferences jsonb default '{
  "results": true,
  "tasks": true,
  "reports": true,
  "invoices": true,
  "milestones": true,
  "calls": true
}';
```

---

## 7. Growth Story Report

**Replace the flat PDF with an in-app narrative monthly report.**

### Concept

Instead of a PDF the client downloads and probably never reads — create a rich, swipeable in-app "Growth Story" that tells the month's narrative with visuals.

### Structure (swipeable pages)

1. **Cover page** — Month name, project name, animated headline stat ("Your best month yet")
2. **The Numbers** — Key metrics in large, beautiful cards with trend arrows
3. **Keywords Story** — Before/after ranking table, top 5 movers highlighted
4. **What we built** — Completed tasks this month as a visual list
5. **What's coming** — Top 3 priorities for next month
6. **A note from your manager** — Short personal text written by the account manager (new `manager_note` field in `reports` table)

**New columns:**

```sql
alter table reports add column manager_note text;
alter table reports add column highlight_stat text;       -- "Traffic grew 47%"
alter table reports add column highlight_context text;    -- "Your best month since we started"
alter table reports add column next_month_priorities text[];
```

**Widget:** Use `PageView.builder` with `PageController` for the swipeable pages, `Hero` animations between the report card and the full report screen.

---

## 8. Client Health Score

**Give the team and client a single number that tells the full story.**

### Formula

```dart
double calculateHealthScore({
  required int tasksCompletedThisMonth,
  required int totalTasksThisMonth,
  required double trafficChange,    // percentage change
  required int pendingApprovals,
  required int invoicesOverdue,
  required double rankingImprovement, // average position improvement
}) {
  double score = 0;

  // Task completion rate (30 points max)
  if (totalTasksThisMonth > 0) {
    score += (tasksCompletedThisMonth / totalTasksThisMonth) * 30;
  }

  // Traffic growth (25 points max)
  score += (trafficChange.clamp(-25, 25));

  // Ranking improvement (25 points max)
  score += (rankingImprovement.clamp(0, 25));

  // Pending approvals penalty (-5 per pending, up to -15)
  score -= (pendingApprovals * 5).clamp(0, 15);

  // Overdue invoice penalty (-10 per overdue)
  score -= (invoicesOverdue * 10).clamp(0, 20);

  return score.clamp(0, 100);
}
```

### Score tiers

| Score  | Label           | Color           | Emoji |
| ------ | --------------- | --------------- | ----- |
| 80–100 | Thriving        | Green `#4CAF50` | 🚀    |
| 60–79  | Growing         | Blue `#2196F3`  | 📈    |
| 40–59  | Steady          | Amber `#FFC107` | ⚡    |
| 0–39   | Needs attention | Red `#F44336`   | 🔍    |

### Where it appears

- **Client home screen:** Large circular gauge widget, prominent above the fold
- **Admin client list:** Column showing each client's health score — sortable, color-coded
- **Weekly internal alert:** If any client's score drops below 50, send an internal Slack/email alert to the account manager

```sql
-- Materialized view refreshed daily
create materialized view client_health_scores as
select
  p.project_id,
  -- calculate score components from related tables
  ...
with data;

create index on client_health_scores(project_id);
```

---

## 9. NPS & Satisfaction

**Ask at the right moment, not randomly.**

### When to ask

- After a stage is completed (e.g., audit done → "How was your audit experience?")
- After the first month (30-day check-in)
- After an approval is actioned
- Never more than once per 30 days

### In-app survey widget

A small bottom sheet that slides up:

```
How are you feeling about your growth progress?

😞  😐  🙂  😊  🚀
 1   2   3   4   5

[Optional: Tell us more...  text field]

[Submit]  [Maybe later]
```

**New table:**

```sql
create table satisfaction_surveys (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  trigger_event text,   -- stage_completed, 30_day, post_approval
  score int check (score between 1 and 5),
  comment text,
  created_at timestamptz default now()
);
```

**Admin sees:** Average satisfaction score per client + trend chart in the admin panel.

---

## 10. UX Polish

### A. Empty states with personality

Every empty list needs a proper empty state (not just blank space):

| Screen    | Empty state message                                           |
| --------- | ------------------------------------------------------------- |
| Tasks     | "Your team is prepping the first tasks — check back soon"     |
| Reports   | "Your first report will be ready at the end of this month"    |
| Results   | "Data starts rolling in after the first 2 weeks of execution" |
| Approvals | "Nothing waiting for your approval — enjoy the peace ☕"      |
| Chat      | "Say hi to your growth manager 👋"                            |

### B. Skeleton screens

Every screen that loads data must show a `Shimmer` skeleton while loading — never a blank screen or a spinner alone.

```yaml
dependencies:
  shimmer: ^3.0.0
```

### C. Haptic feedback map

| Action                     | Haptic type                     |
| -------------------------- | ------------------------------- |
| Approve item               | `HapticFeedback.mediumImpact()` |
| Send message               | `HapticFeedback.lightImpact()`  |
| Milestone celebration      | `HapticFeedback.heavyImpact()`  |
| End call                   | `HapticFeedback.heavyImpact()`  |
| Pull to refresh (complete) | `HapticFeedback.lightImpact()`  |

### D. Offline banner

```dart
// Use connectivity_plus
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: const Text('You\'re offline — showing last saved data'),
      backgroundColor: Colors.orange.shade800,
      actions: [TextButton(onPressed: () {}, child: const Text('Dismiss'))],
    ),
  );
}
```

### E. Arabic RTL support

```dart
// In MaterialApp:
supportedLocales: const [Locale('en'), Locale('ar')],
localizationsDelegates: const [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
// RTL is automatic for Arabic locale
// For custom layout direction overrides:
Directionality(textDirection: TextDirection.rtl, child: widget)
```

---

## 11. Full Arabic Support — Default Language

**Arabic is the default. English is the optional switch. Not the other way around.**

### Core principle

Every string, layout direction, number, date, and font must feel native to an Arabic speaker — not a translated English app. The app opens in Arabic on first launch. The language switch is available in Settings but never forced.

---

### A. Packages

```yaml
dependencies:
  flutter_localizations: sdk: flutter   # built-in, no extra package
  intl: ^0.19.0                         # date + number formatting
  google_fonts: ^6.2.0                  # Cairo font (best Arabic UI font)
  flutter_arabicvalidation: ^1.0.0      # Arabic input validation helpers
```

---

### B. Project structure for translations

```
lib/
  l10n/
    app_ar.arb    ← default (Arabic)
    app_en.arb    ← secondary (English)
  core/
    l10n_setup.dart
```

**`pubspec.yaml` — enable code generation:**

```yaml
flutter:
  generate: true

flutter_intl:
  enabled: true
  arb_dir: lib/l10n
  output_dir: lib/generated/l10n
```

**`l10n.yaml` (create at project root):**

```yaml
arb-dir: lib/l10n
template-arb-file: app_ar.arb
output-localization-file: app_localizations.dart
preferred-supported-locales: [ar, en]
```

---

### C. Arabic ARB file — `lib/l10n/app_ar.arb`

Full strings map. Add every UI string here — never hardcode Arabic text in widgets.

```json
{
  "@@locale": "ar",
  "@@last_modified": "2026-05-11",

  "appName": "محرك",
  "welcomeMessage": "مرحباً، {name}",
  "@welcomeMessage": { "placeholders": { "name": { "type": "String" } } },

  "goodMorning": "صباح الخير",
  "goodAfternoon": "مساء الخير",
  "goodEvening": "مساء النور",

  "goalLabel": "هدفك: {goal}",
  "@goalLabel": { "placeholders": { "goal": { "type": "String" } } },

  "growthProgress": "تقدم النمو",
  "tasksCompleted": "مهام منجزة",
  "inProgress": "جاري التنفيذ",
  "waitingApproval": "بانتظار موافقتك",
  "completed": "مكتمل",
  "delayed": "متأخر",
  "todo": "لم يبدأ",
  "inReview": "قيد المراجعة",

  "homeTab": "الرئيسية",
  "tasksTab": "المهام",
  "resultsTab": "النتائج",
  "reportsTab": "التقارير",
  "chatTab": "المحادثة",

  "journeyTitle": "رحلة النمو",
  "auditStage": "التحليل",
  "strategyStage": "الاستراتيجية",
  "setupStage": "الإعداد",
  "executionStage": "التنفيذ",
  "optimizationStage": "التحسين",
  "resultsStage": "النتائج",

  "seoResults": "نتائج SEO",
  "adsResults": "نتائج الإعلانات",
  "aiVisibility": "الظهور في AI",
  "trustEngine": "محرك الثقة",

  "keywords": "الكلمات المفتاحية",
  "organicTraffic": "الزيارات العضوية",
  "leads": "العملاء المحتملون",
  "roas": "العائد على الإعلان",
  "costPerLead": "تكلفة العميل",
  "conversionRate": "معدل التحويل",

  "pendingApprovals": "موافقات معلقة",
  "approve": "موافقة",
  "requestChanges": "طلب تعديلات",
  "approved": "تمت الموافقة",
  "changesRequested": "تم طلب تعديلات",

  "newReport": "تقرير جديد",
  "weeklyReport": "التقرير الأسبوعي",
  "monthlyReport": "التقرير الشهري",
  "downloadPdf": "تحميل PDF",
  "viewReport": "عرض التقرير",
  "reportReady": "التقرير جاهز",

  "startVideoCall": "بدء مكالمة فيديو",
  "startVoiceCall": "بدء مكالمة صوتية",
  "endCall": "إنهاء المكالمة",
  "mute": "كتم الصوت",
  "unmute": "إلغاء الكتم",
  "hideCamera": "إخفاء الكاميرا",
  "showCamera": "إظهار الكاميرا",
  "incomingCall": "مكالمة واردة",
  "accept": "قبول",
  "decline": "رفض",
  "callEnded": "انتهت المكالمة",
  "callDuration": "مدة المكالمة: {duration}",
  "@callDuration": { "placeholders": { "duration": { "type": "String" } } },

  "holdToRecord": "اضغط مطولاً للتسجيل",
  "releaseToSend": "ارفع إصبعك للإرسال",
  "swipeToCancel": "اسحب للإلغاء",
  "voiceMessage": "رسالة صوتية",
  "recording": "جاري التسجيل...",
  "recordingCancelled": "تم إلغاء التسجيل",

  "typeMessage": "اكتب رسالة...",
  "send": "إرسال",
  "today": "اليوم",
  "yesterday": "أمس",

  "requestMeeting": "طلب اجتماع",
  "upcomingMeetings": "الاجتماعات القادمة",
  "joinMeeting": "الانضمام للاجتماع",
  "meetingSummary": "ملخص الاجتماع",
  "actionItems": "بنود العمل",

  "contracts": "العقود",
  "signed": "موقّع",
  "pendingSignature": "بانتظار التوقيع",
  "expired": "منتهي",

  "invoices": "الفواتير",
  "payNow": "ادفع الآن",
  "paid": "مدفوع",
  "overdue": "متأخر السداد",
  "dueDate": "تاريخ الاستحقاق: {date}",
  "@dueDate": { "placeholders": { "date": { "type": "String" } } },
  "paymentSuccessful": "تمت عملية الدفع بنجاح ✅",

  "files": "الملفات",
  "brandGuidelines": "دليل الهوية",
  "contentPlan": "خطة المحتوى",
  "campaignAssets": "مواد الحملة",

  "settings": "الإعدادات",
  "language": "اللغة",
  "arabic": "العربية",
  "english": "English",
  "notifications": "الإشعارات",
  "logout": "تسجيل الخروج",
  "profile": "الملف الشخصي",

  "healthScore": "مؤشر الصحة",
  "thriving": "ممتاز",
  "growing": "في نمو",
  "steady": "مستقر",
  "needsAttention": "يحتاج اهتمام",

  "milestoneReached": "إنجاز جديد! 🎉",
  "keywordPage1": "كلمتك المفتاحية وصلت للصفحة الأولى!",
  "trafficDoubled": "تضاعفت زياراتك! 🚀",
  "leads100": "وصلت لـ 100 عميل محتمل 🏆",

  "howAreYouFeeling": "كيف تشعر تجاه تقدم نموك؟",
  "submitFeedback": "إرسال",
  "maybeLater": "لاحقاً",
  "thankYouFeedback": "شكراً! رأيك يهمنا 🙏",

  "emptyTasks": "فريقك يجهّز المهام الأولى — تابع قريباً",
  "emptyReports": "تقريرك الأول سيكون جاهزاً نهاية الشهر",
  "emptyResults": "البيانات تبدأ بعد أسبوعين من التنفيذ",
  "emptyApprovals": "لا يوجد شيء ينتظر موافقتك ☕",
  "emptyChat": "قل مرحباً لمدير نموك 👋",

  "newSinceLastVisit": "جديد منذ آخر زيارة",
  "tasksCompletedSince": "تم إنجاز {count} مهام منذ آخر زيارة",
  "@tasksCompletedSince": { "placeholders": { "count": { "type": "int" } } },
  "trafficIncrease": "زياراتك زادت {percent}% هذا الأسبوع",
  "@trafficIncrease": { "placeholders": { "percent": { "type": "int" } } },
  "itemNeedsApproval": "يوجد {count} عنصر يحتاج موافقتك",
  "@itemNeedsApproval": { "placeholders": { "count": { "type": "int" } } },

  "onboardingWelcomeTitle": "مرحباً بك في محرك",
  "onboardingWelcomeSubtitle": "رحلة نموك تبدأ الآن",
  "onboardingBegin": "لنبدأ ←",
  "onboardingTeamTitle": "هؤلاء يعملون لأجل نموك",
  "onboardingRoadmapTitle": "خطتك للـ 90 يوم القادمة",
  "onboardingGoalTitle": "ما هو هدفك الأول لهذا العام؟",
  "goalMoreLeads": "زيادة العملاء المحتملين",
  "goalBrandAwareness": "تقوية الحضور الرقمي",
  "goalMoreSales": "زيادة المبيعات",
  "goalImproveRanking": "تحسين ترتيب الموقع"
}
```

---

### D. English ARB file — `lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "appName": "Moharek",
  "welcomeMessage": "Welcome, {name}",
  "goodMorning": "Good morning",
  "goodAfternoon": "Good afternoon",
  "goodEvening": "Good evening",
  "goalLabel": "Your goal: {goal}",
  "growthProgress": "Growth Progress",
  "tasksCompleted": "Tasks Completed",
  "inProgress": "In Progress",
  "waitingApproval": "Waiting Your Approval",
  "completed": "Completed",
  "delayed": "Delayed",
  "todo": "To Do",
  "inReview": "In Review",
  "homeTab": "Home",
  "tasksTab": "Tasks",
  "resultsTab": "Results",
  "reportsTab": "Reports",
  "chatTab": "Chat",
  "journeyTitle": "Growth Journey",
  "auditStage": "Audit",
  "strategyStage": "Strategy",
  "setupStage": "Setup",
  "executionStage": "Execution",
  "optimizationStage": "Optimization",
  "resultsStage": "Results",
  "holdToRecord": "Hold to record",
  "releaseToSend": "Release to send",
  "swipeToCancel": "Slide to cancel",
  "voiceMessage": "Voice message",
  "recording": "Recording...",
  "recordingCancelled": "Recording cancelled",
  "startVideoCall": "Start Video Call",
  "startVoiceCall": "Start Voice Call",
  "endCall": "End Call",
  "mute": "Mute",
  "unmute": "Unmute",
  "approve": "Approve",
  "requestChanges": "Request Changes",
  "payNow": "Pay Now",
  "healthScore": "Health Score",
  "thriving": "Thriving",
  "growing": "Growing",
  "steady": "Steady",
  "needsAttention": "Needs Attention",
  "emptyTasks": "Your team is prepping the first tasks — check back soon",
  "emptyReports": "Your first report will be ready at end of month",
  "emptyResults": "Data starts rolling in after 2 weeks of execution",
  "emptyApprovals": "Nothing waiting for your approval — enjoy the peace ☕",
  "emptyChat": "Say hi to your growth manager 👋",
  "onboardingWelcomeTitle": "Welcome to Moharek",
  "onboardingWelcomeSubtitle": "Your growth journey starts now",
  "onboardingBegin": "Let's begin →",
  "goalMoreLeads": "More qualified leads",
  "goalBrandAwareness": "Stronger digital presence",
  "goalMoreSales": "Increase sales",
  "goalImproveRanking": "Improve search rankings"
}
```

---

### E. App setup — Arabic as default

**`lib/main.dart`:**

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const ProviderScope(child: MoharekApp()));
}

class MoharekApp extends ConsumerWidget {
  const MoharekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider); // 'ar' by default

    return MaterialApp.router(
      title: 'محرك',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,

      // Arabic is the default locale
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Force RTL for Arabic
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },

      theme: AppTheme.dark,
    );
  }
}
```

**`lib/core/providers/locale_provider.dart`:**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar'); // Arabic is the default

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
    state = Locale(languageCode);
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale') ?? 'ar'; // fall back to Arabic
    state = Locale(saved);
  }
}
```

Call `ref.read(localeProvider.notifier).loadSaved()` inside `main()` before `runApp()`.

---

### F. Typography — Cairo font (best Arabic UI font)

Cairo is designed specifically for Arabic UI — clean, readable, modern. It covers both Arabic and Latin scripts so it handles bilingual content gracefully with one font.

**`lib/core/theme/app_theme.dart`:**

```dart
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get dark {
    // Cairo covers Arabic + Latin — single font for both scripts
    final cairoTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      primaryColor: const Color(0xFF4CAF50),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4CAF50),
        secondary: Color(0xFF2196F3),
        surface: Color(0xFF1E293B),
        background: Color(0xFF0F172A),
      ),
      textTheme: cairoTextTheme.copyWith(
        // Headlines: Cairo Bold
        headlineLarge: cairoTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: cairoTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        // Body: Cairo Regular — higher line height for Arabic readability
        bodyLarge: cairoTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.8, // Arabic needs more line spacing than Latin
        ),
        bodyMedium: cairoTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFCBD5E1),
          height: 1.8,
        ),
        // Labels
        labelLarge: cairoTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0, // Arabic doesn't use letter-spacing
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
```

**Why Cairo over other Arabic fonts:**

| Font              | Pros                                                     | Cons                                  |
| ----------------- | -------------------------------------------------------- | ------------------------------------- |
| **Cairo** ✅      | Clean UI, covers Arabic + Latin, Google Fonts, 6 weights | —                                     |
| Tajawal           | Similar to Cairo, good                                   | Less weight variety                   |
| Noto Naskh Arabic | Traditional look                                         | Too formal for a modern app           |
| IBM Plex Arabic   | Professional                                             | Latin pairing harder                  |
| Almarai           | Rounded, friendly                                        | Can feel childish in business context |

---

### G. RTL layout rules — common mistakes to avoid

**❌ Wrong — hardcoded left/right padding:**

```dart
Padding(padding: EdgeInsets.only(left: 16)) // breaks in RTL
```

**✅ Correct — directional padding:**

```dart
Padding(padding: EdgeInsetsDirectional.only(start: 16)) // start = right in RTL
```

**❌ Wrong — hardcoded icon direction:**

```dart
Icon(Icons.arrow_forward) // points wrong way in RTL
```

**✅ Correct — mirror-aware icon:**

```dart
Icon(Icons.arrow_forward, textDirection: Directionality.of(context))
// Or use the auto-mirroring Icons:
Icon(Icons.arrow_forward_ios) // Flutter auto-mirrors this in RTL
```

**❌ Wrong — Row with fixed left/right logic:**

```dart
Row(children: [Icon(Icons.person), Text('Name')]) // icon always on left
```

**✅ Correct — Directionality-aware:**

```dart
// In RTL, Row already reverses automatically. Just don't override it.
// If you must control order explicitly:
Row(
  textDirection: Directionality.of(context),
  children: [Icon(Icons.person), Text(l10n.profile)],
)
```

**✅ Always use these instead of their non-directional counterparts:**

| ❌ Avoid                                                   | ✅ Use instead                            |
| ---------------------------------------------------------- | ----------------------------------------- |
| `EdgeInsets.only(left:)`                                   | `EdgeInsetsDirectional.only(start:)`      |
| `EdgeInsets.only(right:)`                                  | `EdgeInsetsDirectional.only(end:)`        |
| `BorderRadius.only(topLeft:)`                              | `BorderRadiusDirectional.only(topStart:)` |
| `Alignment.centerLeft`                                     | `AlignmentDirectional.centerStart`        |
| `MainAxisAlignment.start` (fine, it's already directional) | ✅ already RTL-aware                      |
| `CrossAxisAlignment.start`                                 | ✅ already RTL-aware                      |
| `TextAlign.left`                                           | `TextAlign.start`                         |

---

### H. Arabic number formatting

By default Flutter shows English digits (1, 2, 3...). Arabic uses Eastern Arabic numerals (١، ٢، ٣...). Control this explicitly.

```dart
// lib/core/utils/number_formatter.dart

import 'package:intl/intl.dart';

class ArabicFormatter {
  // Format numbers — use Arabic digits when locale is Arabic
  static String number(num value, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return NumberFormat('#,##0', 'ar').format(value);
      // Output: ١٬٢٣٠ instead of 1,230
    }
    return NumberFormat('#,##0').format(value);
  }

  // Format percentages
  static String percent(double value, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.percentPattern(locale == 'ar' ? 'ar' : 'en').format(value / 100);
  }

  // Format currency
  static String currency(num value, String currencyCode, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.currency(
      locale: locale == 'ar' ? 'ar' : 'en',
      symbol: currencyCode == 'EGP' ? 'ج.م' : currencyCode,
    ).format(value);
  }
}
```

**Usage in a widget:**

```dart
Text(ArabicFormatter.number(2450, context)) // shows ٢،٤٥٠ in Arabic mode
```

---

### I. Arabic date formatting

```dart
// lib/core/utils/date_formatter.dart

import 'package:intl/intl.dart';

class ArabicDateFormatter {
  static String relative(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return l10n.today;
    if (diff.inDays == 1) return l10n.yesterday;
    return full(date, context);
  }

  static String full(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      // Arabic: الثلاثاء، ١٢ مايو ٢٠٢٦
      return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
    }
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  static String short(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat(locale == 'ar' ? 'd MMM' : 'MMM d', locale).format(date);
  }

  static String time(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    // Arabic uses AM/PM as ص/م
    return DateFormat.jm(locale == 'ar' ? 'ar' : 'en').format(date);
  }
}
```

---

### J. Language switcher in Settings screen

```dart
// In SettingsScreen — language section
Consumer(builder: (context, ref, _) {
  final locale = ref.watch(localeProvider);
  final l10n = AppLocalizations.of(context)!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.language, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 12),
      Row(
        children: [
          _LanguageChip(
            label: 'العربية',
            isSelected: locale.languageCode == 'ar',
            onTap: () => ref.read(localeProvider.notifier).setLocale('ar'),
          ),
          const SizedBox(width: 12),
          _LanguageChip(
            label: 'English',
            isSelected: locale.languageCode == 'en',
            onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
          ),
        ],
      ),
    ],
  );
}),
```

---

### K. Admin panel — Arabic content fields

The admin team writes Arabic content for clients. Add Arabic text fields in the admin panel for:

- `stage_description` — Arabic description of what we're doing this stage
- `manager_note` in monthly reports — Arabic note from account manager
- Task titles and descriptions — support Arabic input
- Approval titles and team notes

**Admin panel Arabic input widget:**

```dart
TextFormField(
  textDirection: TextDirection.rtl, // Always RTL for Arabic content
  textAlign: TextAlign.right,
  decoration: InputDecoration(
    labelText: 'وصف المرحلة (عربي)',
    alignLabelWithHint: true,
    hintTextDirection: TextDirection.rtl,
  ),
  maxLines: 4,
)
```

---

### L. Notification content in Arabic

Update the notification template system (from Section 6) to send Arabic text:

```typescript
// supabase/functions/send-smart-notification/index.ts
const templates = {
  new_report: (data: any) => ({
    ar: {
      title: `${data.client_name}، تقرير ${data.month} جاهز 📊`,
      body: `${data.highlight} — اضغط لقراءة التفاصيل`,
    },
    en: {
      title: `${data.client_name}, your ${data.month} report is ready`,
      body: `${data.highlight} — tap to read the full breakdown`,
    },
  }),
  keyword_improved: (data: any) => ({
    ar: {
      title: `🚀 "${data.keyword}" وصل للمركز #${data.new_position}!`,
      body:
        data.new_position <= 10
          ? `أنت في الصفحة الأولى على جوجل! 🎉`
          : `ارتفع من #${data.old_position} — ${10 - data.new_position} مراكز للصفحة الأولى`,
    },
    en: {
      title: `🚀 "${data.keyword}" jumped to #${data.new_position}!`,
      body:
        data.new_position <= 10
          ? `You're on Page 1! 🎉`
          : `Up from #${data.old_position}`,
    },
  }),
  approval_needed: (data: any) => ({
    ar: {
      title: `موافقة سريعة مطلوبة، ${data.client_name}`,
      body: `فريقك ينتظرك على: ${data.approval_title}`,
    },
    en: {
      title: `Quick approval needed, ${data.client_name}`,
      body: `Your team is waiting on: ${data.approval_title}`,
    },
  }),
  milestone: (data: any) => ({
    ar: { title: `🏆 ${data.title_ar}`, body: data.description_ar },
    en: { title: `🏆 ${data.title_en}`, body: data.description_en },
  }),
};

// Send in the client's preferred language
const clientLocale = data.client_locale ?? "ar";
const content = template[clientLocale];
```

**Add `preferred_locale` column to profiles:**

```sql
alter table profiles add column preferred_locale text default 'ar';
```

---

### M. RTL testing checklist

Before each release, test all screens with Arabic locale enabled:

- [ ] Bottom navigation labels are Arabic, tabs respond to RTL tap order
- [ ] All icons that indicate direction are mirrored (arrows, back buttons)
- [ ] Chat bubbles: client messages on the right (correct in RTL), team on the left
- [ ] All `EdgeInsets.only(left/right)` replaced with `EdgeInsetsDirectional.only(start/end)`
- [ ] `TextAlign.left` replaced with `TextAlign.start` everywhere
- [ ] Numbers display Eastern Arabic digits (١، ٢، ٣) in Arabic mode
- [ ] Dates show Arabic month names (يناير، فبراير...)
- [ ] Currency displays ج.م for Egyptian Pound
- [ ] Milestone and notification copy is in Arabic
- [ ] Progress bars fill from right to left in RTL
- [ ] Sliders (call duration, voice message playback) are RTL-aware
- [ ] Swipe-to-cancel voice message gesture direction is reversed in RTL
- [ ] Charts have Arabic axis labels and Arabic tooltips
- [ ] Skeleton loading placeholder shapes match RTL layout
- [ ] Onboarding screen copy, button labels are in Arabic
- [ ] Error and empty state messages are in Arabic

---

## 12. Voice Messages in Chat

**Hold to record. Slide to cancel. Release to send. A full WhatsApp-quality voice message experience.**

### What we're building

- Hold microphone button → records audio
- Slide left (RTL: slide right) → cancels recording with feedback
- Release → sends voice message
- Playback with animated waveform + duration
- Works in background (app minimized while listening)
- Uploads to Supabase Storage

---

### A. Packages

```yaml
dependencies:
  record: ^5.1.0 # High-quality audio recording (replaces flutter_sound for recording)
  just_audio: ^0.9.36 # Playback (lightweight, background-safe)
  audio_waveforms: ^1.0.5 # Waveform visualization during record + playback
  path_provider: ^2.1.0 # Local temp file path
  permission_handler: ^11.3.0 # Microphone permission
```

---

### B. Database — messages table update

```sql
-- Already exists, just ensure these columns are present:
alter table messages add column if not exists duration_seconds int;
alter table messages add column if not exists waveform_data jsonb;
-- waveform_data stores amplitude samples: [0.1, 0.8, 0.3, 0.95, ...]
-- Used to render the waveform without re-processing the audio file
```

**Supabase Storage bucket:**

```sql
-- Create a private bucket for voice messages
insert into storage.buckets (id, name, public) values ('voice-messages', 'voice-messages', false);

-- RLS: only participants of the same project can read
create policy "Project members can read voice messages"
on storage.objects for select
using (
  bucket_id = 'voice-messages' and
  (storage.foldername(name))[1] in (
    select project_id::text from chat_channels
    where id::text = (storage.foldername(name))[2]
  )
);

-- RLS: authenticated users can upload
create policy "Authenticated users can upload voice messages"
on storage.objects for insert
with check (bucket_id = 'voice-messages' and auth.role() = 'authenticated');
```

---

### C. Voice recording service

`lib/features/chat/services/voice_recorder_service.dart`:

```dart
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final RecorderController waveformController = RecorderController()
    ..androidEncoder = AndroidEncoder.aac
    ..androidOutputFormat = AndroidOutputFormat.mpeg4
    ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
    ..sampleRate = 44100;

  String? _filePath;
  DateTime? _startTime;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _startTime = DateTime.now();

    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: _filePath!,
    );

    // Start waveform controller for live visualization
    waveformController.record(path: _filePath);
  }

  Future<VoiceRecordingResult?> stopRecording() async {
    final path = await _recorder.stop();
    waveformController.stop();

    if (path == null || _startTime == null) return null;

    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration < 1) {
      // Too short — discard
      final file = File(path);
      if (await file.exists()) await file.delete();
      return null;
    }

    // Extract waveform amplitude data for storage
    final waveformData = waveformController.waveData;

    return VoiceRecordingResult(
      filePath: path,
      durationSeconds: duration,
      waveformData: waveformData,
    );
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    waveformController.stop();
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) await file.delete();
    }
    _filePath = null;
    _startTime = null;
  }

  void dispose() {
    _recorder.dispose();
    waveformController.dispose();
  }
}

class VoiceRecordingResult {
  final String filePath;
  final int durationSeconds;
  final List<double> waveformData;

  const VoiceRecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.waveformData,
  });
}
```

---

### D. Upload voice message to Supabase

`lib/features/chat/services/voice_upload_service.dart`:

```dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceUploadService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadAndSend({
    required String channelId,
    required String projectId,
    required String senderId,
    required VoiceRecordingResult recording,
  }) async {
    // 1. Upload file to Supabase Storage
    final fileName = '$projectId/$channelId/${DateTime.now().millisecondsSinceEpoch}.m4a';
    final file = File(recording.filePath);

    await _supabase.storage.from('voice-messages').upload(
      fileName,
      file,
      fileOptions: const FileOptions(contentType: 'audio/m4a', upsert: false),
    );

    // 2. Get signed URL (valid 7 days — refresh on view)
    final signedUrl = await _supabase.storage
        .from('voice-messages')
        .createSignedUrl(fileName, 60 * 60 * 24 * 7);

    // 3. Insert message row
    await _supabase.from('messages').insert({
      'channel_id': channelId,
      'sender_id': senderId,
      'message_type': 'voice',
      'file_url': signedUrl,
      'duration_seconds': recording.durationSeconds,
      'waveform_data': recording.waveformData,
      'content': '🎤 رسالة صوتية', // Fallback text for notifications
    });

    // 4. Clean up local temp file
    await file.delete();

    return signedUrl;
  }
}
```

---

### E. Hold-to-record button widget

`lib/features/chat/widgets/voice_record_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceRecordButton extends StatefulWidget {
  final VoiceRecorderService recorderService;
  final Function(VoiceRecordingResult) onRecordingComplete;
  final bool isRtl; // from Directionality

  const VoiceRecordButton({
    super.key,
    required this.recorderService,
    required this.onRecordingComplete,
    required this.isRtl,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isCancelling = false;
  double _dragOffset = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Cancel threshold — 100px drag left (LTR) or right (RTL)
  static const double _cancelThreshold = 100;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startRecording() async {
    try {
      await widget.recorderService.startRecording();
      HapticFeedback.mediumImpact();
      setState(() { _isRecording = true; _isCancelling = false; _dragOffset = 0; });
    } catch (e) {
      _showPermissionError();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    setState(() => _isRecording = false);
    _pulseController.stop();
    _pulseController.reset();

    if (_isCancelling) {
      await widget.recorderService.cancelRecording();
      HapticFeedback.lightImpact();
    } else {
      final result = await widget.recorderService.stopRecording();
      if (result != null) {
        HapticFeedback.lightImpact();
        widget.onRecordingComplete(result);
      }
    }
    setState(() { _isCancelling = false; _dragOffset = 0; });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;
    setState(() {
      // RTL: cancel by dragging RIGHT; LTR: cancel by dragging LEFT
      final delta = widget.isRtl ? details.delta.dx : -details.delta.dx;
      _dragOffset = (_dragOffset + delta).clamp(0, double.infinity);
      _isCancelling = _dragOffset > _cancelThreshold;
    });
    if (_isCancelling) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressMoveUpdate: (details) => _onDragUpdate(
        DragUpdateDetails(
          globalPosition: details.globalPosition,
          delta: details.offsetFromOrigin,
          localPosition: details.localPosition,
        ),
      ),
      child: _isRecording
          ? _buildRecordingState(l10n)
          : _buildIdleButton(l10n),
    );
  }

  Widget _buildIdleButton(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52, height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mic, color: Color(0xFF4CAF50), size: 26),
        ),
        const SizedBox(height: 4),
        Text(l10n.holdToRecord,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildRecordingState(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slide-to-cancel hint
        if (!_isCancelling)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8),
            child: Row(children: [
              Icon(
                widget.isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                size: 12, color: const Color(0xFF64748B),
              ),
              Text(l10n.swipeToCancel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ]),
          ),

        // Cancel indicator
        if (_isCancelling)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8),
            child: Text(l10n.recordingCancelled,
              style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),

        // Pulse mic button
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _isCancelling ? Colors.red : const Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('يرجى السماح بالوصول للميكروفون في الإعدادات')),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
```

---

### F. Recording indicator bar (while recording)

Replaces the text input bar when recording is active. Shown above the keyboard.

```dart
class RecordingBar extends StatefulWidget {
  final VoiceRecorderService recorderService;
  final VoidCallback onCancel;
  // ...
}

class _RecordingBarState extends State<RecordingBar> {
  int _seconds = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  String get _durationLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Red pulsing dot
          _PulsingDot(),
          const SizedBox(width: 8),
          // Live waveform
          Expanded(
            child: AudioWaveforms(
              recorderController: widget.recorderService.waveformController,
              size: const Size(double.infinity, 32),
              waveStyle: WaveStyle(
                waveColor: const Color(0xFF4CAF50),
                showDurationLabel: false,
                spacing: 4,
                waveThickness: 2,
                extendWaveform: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timer
          Text(
            _durationLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          // Cancel X
          GestureDetector(
            onTap: widget.onCancel,
            child: const Icon(Icons.close, color: Colors.red, size: 22),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }
}
```

---

### G. Voice message playback bubble

`lib/features/chat/widgets/voice_message_bubble.dart`:

```dart
import 'package:just_audio/just_audio.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final List<double> waveformData;
  final bool isFromMe;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.waveformData,
    required this.isFromMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late AudioPlayer _player;
  late PlayerController _waveformController;
  bool _isPlaying = false;
  double _progress = 0;
  int _currentSeconds = 0;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationSeconds;
    _player = AudioPlayer();
    _waveformController = PlayerController()
      ..preparePlayer(path: widget.audioUrl, shouldExtractWaveform: false)
      ..updateFrequency = UpdateFrequency.high;

    // Preload waveform from stored data (no re-processing needed)
    _waveformController.setWaveformData(widget.waveformData);

    _player.positionStream.listen((position) {
      if (!mounted) return;
      final duration = _player.duration?.inSeconds ?? _totalSeconds;
      setState(() {
        _progress = duration > 0 ? position.inMilliseconds / (duration * 1000) : 0;
        _currentSeconds = position.inSeconds;
      });
    });

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _waveformController.seekTo(0);
        setState(() { _isPlaying = false; _progress = 0; _currentSeconds = 0; });
      }
    });
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      await _player.pause();
      _waveformController.pausePlayer();
    } else {
      await _player.setUrl(widget.audioUrl);
      await _player.play();
      await _waveformController.startPlayer();
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isFromMe
        ? const Color(0xFF4CAF50).withOpacity(0.2)
        : const Color(0xFF1E293B);
    final waveColor = widget.isFromMe
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2196F3);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(16),
          topEnd: const Radius.circular(16),
          bottomStart: widget.isFromMe ? const Radius.circular(16) : const Radius.circular(4),
          bottomEnd: widget.isFromMe ? const Radius.circular(4) : const Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: waveColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: waveColor, size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Waveform + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Playback waveform
                AudioFileWaveforms(
                  playerController: _waveformController,
                  size: const Size(double.infinity, 30),
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: Colors.white24,
                    liveWaveColor: waveColor,
                    seekLineColor: waveColor,
                    waveThickness: 2,
                    spacing: 4,
                  ),
                ),
                const SizedBox(height: 2),
                // Duration
                Text(
                  _isPlaying
                    ? '${_formatDuration(_currentSeconds)} / ${_formatDuration(_totalSeconds)}'
                    : _formatDuration(_totalSeconds),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _waveformController.dispose();
    super.dispose();
  }
}
```

---

### H. Chat screen integration — updated input bar

The chat input bar has three states: **idle** (text + mic), **typing** (text active, mic hidden), **recording** (bar replaced by `RecordingBar`).

```dart
class ChatInputBar extends ConsumerStatefulWidget { ... }

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _textController = TextEditingController();
  final _recorderService = VoiceRecorderService();
  bool _isRecording = false;
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // State 1: Recording mode
    if (_isRecording) {
      return RecordingBar(
        recorderService: _recorderService,
        onCancel: () async {
          await _recorderService.cancelRecording();
          setState(() => _isRecording = false);
        },
      );
    }

    // State 2: Normal input bar
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          // Send button or mic button (right side in RTL, left in LTR)
          if (!_isTyping)
            VoiceRecordButton(
              recorderService: _recorderService,
              isRtl: isRtl,
              onRecordingComplete: (result) async {
                setState(() => _isRecording = false);
                await VoiceUploadService().uploadAndSend(
                  channelId: widget.channelId,
                  projectId: widget.projectId,
                  senderId: ref.read(currentUserProvider)!.id,
                  recording: result,
                );
              },
            ),

          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              onChanged: (v) => setState(() => _isTyping = v.isNotEmpty),
              decoration: InputDecoration(
                hintText: l10n.typeMessage,
                hintTextDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16, vertical: 10),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send text button (only visible while typing)
          if (_isTyping)
            GestureDetector(
              onTap: _sendTextMessage,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), shape: BoxShape.circle),
                child: Icon(
                  isRtl ? Icons.send : Icons.send,
                  color: Colors.white, size: 20,
                  // Flutter mirrors this icon in RTL automatically
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### I. Voice message in the messages stream

Update the message list builder to render voice bubbles:

```dart
Widget _buildMessage(Message message) {
  final isFromMe = message.senderId == currentUserId;

  switch (message.messageType) {
    case 'text':
      return TextBubble(text: message.content, isFromMe: isFromMe);

    case 'image':
      return ImageBubble(imageUrl: message.fileUrl!, isFromMe: isFromMe);

    case 'voice':
      return VoiceMessageBubble(
        audioUrl: message.fileUrl!,
        durationSeconds: message.durationSeconds ?? 0,
        waveformData: List<double>.from(message.waveformData ?? []),
        isFromMe: isFromMe,
      );

    case 'call':
      return CallCard(
        roomName: message.content,
        callType: message.callType ?? 'video',
        isFromMe: isFromMe,
      );

    default:
      return TextBubble(text: message.content, isFromMe: isFromMe);
  }
}
```

---

### J. iOS & Android permissions

**iOS — `ios/Runner/Info.plist`:**

```xml
<key>NSMicrophoneUsageDescription</key>
<string>محرك يحتاج الميكروفون لإرسال الرسائل الصوتية والمكالمات</string>
<key>NSMicrophoneUsageDescriptionArabic</key>
<string>محرك يحتاج الميكروفون لإرسال الرسائل الصوتية والمكالمات</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Android — `android/app/src/main/AndroidManifest.xml`:**

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

---

### K. Voice message UX rules

- **Minimum duration:** 1 second. Shorter recordings are silently discarded.
- **Maximum duration:** 5 minutes. Auto-stop and send at the limit.
- **File format:** `.m4a` (AAC). Smaller than MP3, supported on all platforms.
- **Max file size:** ~2.4MB for 5 minutes at 64kbps — well within Supabase free storage.
- **Playback speed:** Add 1× / 1.5× / 2× speed toggle (long-press the playback button). Use `_player.setSpeed(1.5)`.
- **Slide direction by locale:**
  - Arabic (RTL): slide RIGHT to cancel
  - English (LTR): slide LEFT to cancel
- **Signed URL expiry:** 7 days. On expiry, re-fetch a new signed URL from Supabase before playback attempt.

---

### L. Voice message notification

When a voice message is received, the FCM notification shows:

```typescript
// Arabic:
title: `رسالة صوتية من ${senderName}`,
body: `🎤 ${durationFormatted} — اضغط للاستماع`

// English:
title: `Voice message from ${senderName}`,
body: `🎤 ${durationFormatted} — tap to listen`
```

---

## 13. Implementation Phases

### Phase 1 — In-app calls (Week 1–2)

- [ ] Add `livekit_client`, `callkeep` packages
- [ ] Create `livekit-token` Edge Function
- [ ] Build `CallService` class
- [ ] Build `ActiveCallScreen` with video tiles
- [ ] Integrate `callkeep` for background/closed app call UI (iOS CallKit + Android ConnectionService)
- [ ] Update FCM handler to parse `incoming_call` type
- [ ] Add "Start Video Call" and "Start Voice Call" buttons in Chat screen
- [ ] Test on physical iOS and Android devices (simulators don't support camera)

### Phase 2 — Arabic support (Week 2–3) ← do this early, affects everything

- [ ] Add `intl`, `google_fonts`, `shared_preferences` packages
- [ ] Create `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb` with all strings
- [ ] Configure `l10n.yaml` and enable code generation (`flutter gen-l10n`)
- [ ] Set up `LocaleNotifier` with Arabic as default
- [ ] Apply Cairo font across the entire app theme
- [ ] Replace all hardcoded Arabic/English strings with `l10n.key` references
- [ ] Replace all `EdgeInsets.only(left/right)` with `EdgeInsetsDirectional` equivalents
- [ ] Replace all `TextAlign.left` with `TextAlign.start`
- [ ] Replace all directional icons with auto-mirroring equivalents
- [ ] Add `ArabicFormatter` utility for numbers, dates, currency
- [ ] Add language switcher to Settings screen
- [ ] Update notification Edge Function to send Arabic copy by default
- [ ] Add `preferred_locale` column to `profiles`
- [ ] Run full RTL testing checklist on both iOS and Android

### Phase 3 — Voice messages (Week 3–4)

- [ ] Add `record`, `just_audio`, `audio_waveforms`, `path_provider` packages
- [ ] Add iOS `NSMicrophoneUsageDescription` to `Info.plist`
- [ ] Add Android `RECORD_AUDIO` permission to `AndroidManifest.xml`
- [ ] Create `voice-messages` Supabase Storage bucket with RLS policies
- [ ] Add `duration_seconds` and `waveform_data` columns to `messages`
- [ ] Build `VoiceRecorderService`
- [ ] Build `VoiceUploadService`
- [ ] Build `VoiceRecordButton` (hold to record, slide to cancel)
- [ ] Build `RecordingBar` (live waveform + timer)
- [ ] Build `VoiceMessageBubble` (playback waveform + play/pause)
- [ ] Integrate all into `ChatInputBar`
- [ ] Update message list builder to handle `message_type = 'voice'`
- [ ] Test RTL slide-to-cancel direction (right for Arabic, left for English)
- [ ] Update FCM notification for voice messages

### Phase 4 — Onboarding & First Login (Week 5)

- [ ] Build 5-screen onboarding flow (all copy in Arabic)
- [ ] Add `onboarding_completed` + `client_goal` columns to `profiles`
- [ ] Create `TeamMember` cards component
- [ ] Build animated 90-day timeline widget
- [ ] Connect goal selection to dashboard greeting

### Phase 5 — Living Dashboard (Week 6)

- [ ] Animated metric counters (Arabic numerals in Arabic mode)
- [ ] "What's new since last visit" banner logic + `last_seen_at` column
- [ ] Weekly comparison chips on metric cards
- [ ] Personalized greeting by time of day + goal (Arabic copy)
- [ ] Health Score calculation + gauge widget

### Phase 6 — Milestones & Celebrations (Week 7)

- [ ] Create `milestones` table
- [ ] Add `confetti` package
- [ ] Build `MilestoneOverlay` full-screen celebration widget (Arabic text)
- [ ] Set up `pg_cron` daily check for milestone conditions
- [ ] Build Milestones feed in home screen

### Phase 7 — Journey Screen Reborn (Week 8)

- [ ] Redesign as animated vertical timeline
- [ ] Add `stage_description` column (admin writes Arabic, client reads)
- [ ] Build "What happens next" preview card
- [ ] Add task count progress within each stage

### Phase 8 — Growth Story Report (Week 9)

- [ ] Add new columns to `reports` table (including Arabic `manager_note`)
- [ ] Build swipeable `PageView` report viewer
- [ ] Add Arabic `manager_note` field in admin report upload form

### Phase 9 — Smart Notifications & NPS (Week 10)

- [ ] Rewrite `send-notification` Edge Function with bilingual template system
- [ ] Add `notification_preferences` column + Settings UI (Arabic labels)
- [ ] Create `satisfaction_surveys` table
- [ ] Build bottom sheet survey widget with Arabic copy and timing logic

### Phase 10 — UX Polish (Week 11)

- [ ] Skeleton screens for all data-loading screens
- [ ] Empty states with Arabic personality copy for all lists
- [ ] Haptic feedback map implementation
- [ ] Offline banner in Arabic
- [ ] Final RTL testing pass across all screens

---

## 14. Updated Tech Stack & Cost

### New packages (additions to v1.6.0)

```yaml
# Calls
livekit_client: ^2.2.0
flutter_webrtc: ^0.10.0
callkeep: ^4.0.0

# Arabic / localization
google_fonts: ^6.2.0 # Cairo font
shared_preferences: ^2.2.0 # Persist locale choice
flutter_arabicvalidation: ^1.0.0

# Voice messages
record: ^5.1.0
just_audio: ^0.9.36
audio_waveforms: ^1.0.5
path_provider: ^2.1.0

# UX
confetti: ^0.7.0
particles_flutter: ^0.1.0
shimmer: ^3.0.0
connectivity_plus: ^6.0.0
permission_handler: ^11.3.0
```

### Cost breakdown

| Service              | Monthly cost | Notes                                  |
| -------------------- | ------------ | -------------------------------------- |
| Supabase             | **$0**       | Free: 500MB DB, 1GB storage, 50K MAU   |
| LiveKit Cloud        | **$0**       | Free: 10,000 participant-minutes/month |
| Firebase FCM         | **$0**       | Unlimited                              |
| Vercel (admin web)   | **$0**       | Free                                   |
| Stripe               | **$0/month** | 2.9% + $0.30 per transaction only      |
| **Total fixed cost** | **$0/month** | —                                      |

### When to upgrade

| Trigger                     | Action                             | Cost                    |
| --------------------------- | ---------------------------------- | ----------------------- |
| > 10,000 call minutes/month | Upgrade LiveKit Cloud or self-host | $0.02/min or ~$6/mo VPS |
| > 50,000 MAU or > 500MB DB  | Upgrade Supabase Pro               | $25/month               |
| > 1GB file storage          | Upgrade Supabase storage           | Included in Pro         |

### Self-hosting LiveKit (when ready)

```bash
# On any $6/mo VPS (DigitalOcean, Hetzner, etc.)
# Handles ~200 concurrent call participants
docker run -d --name livekit \
  -e LIVEKIT_KEYS="moharek_key: your_secret_here" \
  -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  --restart always \
  livekit/livekit-server
```

---

_Moharek Improvement Plan v2.0 — Built for AI agent implementation_
_Every section is self-contained and can be handed to an agent independently._
