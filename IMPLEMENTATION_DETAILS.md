# Moharek App — The Complete Engineering & Product Manual

This document is an exhaustive guide to the Moharek application ecosystem. It contains the granular technical details, logic formulas, database definitions, and functional workflows for both the Client and Admin systems.

---

## 1. Core Architecture & Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter SDK (Stable)
- **State Management**: **Riverpod 2.x**. Uses `AsyncNotifier` for chat and `FutureProvider` for data fetching.
- **Dependency Injection**: Riverpod's `ref` system is used to inject the `SupabaseClient` across the app.
- **Routing**: **GoRouter**. Implements `StatefulShellRoute` to maintain the state of each tab in the bottom navigation bar.
- **Charts**: `fl_chart` for rendering SEO and Ads metrics.
- **PDF Rendering**: `syncfusion_flutter_pdfviewer` for viewing reports and contracts.

### UI/UX Design System
- **Theme**: Premium Dark Mode.
- **Colors**: 
    - `Primary Green`: #4CAF50 (Used for success and actions)
    - `Primary Blue`: #2196F3 (Used for info and links)
    - `Background`: #0F172A (Deep midnight blue)
    - `Card Color`: #1E293B (Lighter blue-gray for containers)
- **Typography**: Inter (Modern sans-serif for high readability).
- **Feedback**: `HapticFeedback.lightImpact()` on all primary action buttons.
- **Loading States**: Custom `Shimmer` placeholders for lists and profile headers.

---

## 2. Database Deep-Dive (Granular Table Definitions)

### A. Core Management Tables
1. **`profiles`**
    - `id`: UUID (Primary Key, matches Auth UID)
    - `full_name`: Text (Client name)
    - `company_name`: Text (Business name)
    - `role`: Text (Enum: 'admin', 'client', 'account_manager', etc.)
    - `avatar_url`: Text (Link to Storage)
2. **`projects`**
    - `id`: UUID (Primary Key)
    - `client_id`: UUID (Foreign Key to profiles)
    - `name`: Text (Project title)
    - `status`: Text (Enum: 'active', 'paused', 'completed')
    - `current_stage`: Text (e.g., 'audit')
3. **`journey_stages`**
    - `project_id`: UUID (Foreign Key to projects)
    - `stage_name`: Text (Audit, Strategy, Execution, Results)
    - `order_index`: Integer (0-3)
    - `is_completed`: Boolean (Default: false)

### B. Project Operations Tables
4. **`tasks`**
    - `project_id`: UUID
    - `title`: Text
    - `description`: Text
    - `category`: Text (Free-text, e.g., 'On-Page SEO', 'Technical')
    - `priority`: Text (Free-text, e.g., 'Urgent', 'Low')
    - `status`: Text (Enum: 'todo', 'in_progress', 'waiting_client', 'completed')
5. **`results`**
    - `project_id`: UUID
    - `metric_label`: Text (e.g., 'Organic Traffic')
    - `metric_value`: Numeric (The number for the chart)
    - `result_type`: Text (seo, ads, trust_engine)
    - `recorded_at`: Timestamp (Used for X-axis on charts)
6. **`approvals`**
    - `id`: UUID
    - `project_id`: UUID
    - `title`: Text
    - `status`: Text (pending, approved, rejected)
    - `client_notes`: Text

---

## 3. Advanced Feature Logic

### A. Growth Progress Calculation (Mobile)
The progress % shown on the home screen is not hardcoded. It is calculated using the following logic:
```dart
double calculateProgress(List<JourneyStage> stages) {
  if (stages.isEmpty) return 0;
  final completed = stages.where((s) => s.isCompleted).length;
  return (completed / stages.length) * 100;
}
```

### B. Chart Rendering (SEO/Ads)
Metrics from the `results` table are mapped to `fl_chart` data points. The app uses `LineChart` with custom `LineChartBarData` to display trends over time, automatically scaling the Y-axis based on the `metric_value`.

### C. The Super Chat (Jitsi Integration)
- **Room Logic**: The room ID is generated as `moharek-[project_id]-[timestamp]`.
- **Link Posting**: When a call starts, the system automatically posts a message: `📹 Video call started — Join: https://meet.jit.si/[room_id]`.
- **UI Bubbles**: The chat uses a `ListView.builder` that maps each `Message` to a specific bubble widget:
    - `text`: Standard message bubble.
    - `image`: Bubble with a `CachedNetworkImage` and full-screen viewer.
    - `call`: Interactive card with a "Join Call" button that uses `url_launcher`.

### D. Dashboard Metric Cards
The home screen displays three key metrics:
1. **SEO Traffic**: Latest value from `results` where `result_type == 'seo'`.
2. **Ads Performance**: Latest value from `results` where `result_type == 'ads'`.
3. **AI Visibility**: Latest value from `results` where `result_type == 'ai_visibility'`.

---

## 4. Administrative Management (Web Console)

### A. Manage Client Interface
A centralized hub for admins to control all client data. It features a 5-tab system:
1. **Tasks**: Create tasks with free-text category/priority. Features status filters (All, In Progress, etc.).
2. **Results**: Log metrics for charts. Admins can select the `result_type` (SEO/Ads) and set the `recorded_at` date.
3. **Approvals**: Create approval requests. Clients see these as pending alerts on their dashboard.
4. **Reports**: Upload monthly PDF reports. Integrates with Supabase Storage for secure hosting.
5. **Files**: Manage all project documents and brand assets.

### B. State Management Patterns
After any administrative update (e.g., adding a task or logging a result), the app uses Riverpod to ensure real-time consistency:
```dart
ref.invalidate(tasksProvider);
ref.invalidate(currentProjectProvider);
```
This forces the app to re-fetch the latest data from Supabase, keeping the UI perfectly in sync.

---

## 5. Automation & Notifications

### A. Activity Feed Triggers
Events that automatically generate an entry in the `activity_feed` table:
- **Task Completed**: When a task moves to `completed`.
- **New Report**: When a PDF is uploaded to the `reports` table.
- **Approval Responded**: When a client approves or rejects a request.
- **Invoice Paid**: When an invoice status changes to `paid`.

### B. Push Notifications
Integrated with **Firebase Cloud Messaging (FCM)**:
- **New Message**: Triggered when a message is inserted into the `messages` table.
- **Call Started**: High-priority notification with a sound alert.
- **Task Waiting**: Notifies the client when a task is moved to `waiting_client`.

---

## 6. Security & Deployment Checklist

### Row-Level Security (RLS)
- **Client Access**: `(auth.uid() = client_id)` or `project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())`.
- **Admin Access**: `EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')`.

### Media & Storage
- **Bucket RLS**: Policies ensure that users can only upload to the `chats/` directory and only read files belonging to their project.
- **PDF Viewer**: Integrated using `syncfusion_flutter_pdfviewer` to provide a premium document viewing experience on both web and mobile.

---

## 7. How to Use the Admin Panel (Step-by-Step)
1. **Adding a New Client**: 
    - Go to "Clients" -> "Add Client".
    - Fill in details. This creates their Auth, Profile, Project, and Chat.
2. **Logging Results**:
    - Go to "Manage Client" -> "Results".
    - Add a metric (e.g., SEO Traffic: 2500). This updates their charts in real-time.
3. **Managing Invoices**:
    - Go to "Financials".
    - Use the "Installment" feature to split big deals into monthly payments.

---
**Last Updated**: May 2026 | **Version**: 1.6.0
**Author**: Antigravity AI
