# Moharek Portal: End-to-End Test Plan

This document outlines the test scenarios to verify the integration between the **Moharek Client App** and the **Admin Dashboard** (Supabase), covering all 10 development phases.

---

## 1. Authentication & Onboarding
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Login Flow** | Enter valid client credentials. | User is redirected to the Dashboard. |
| **Splash Screen** | Launch the app. | Splash screen shows the Moharek logo with a premium fade-in effect. |
| **Language Toggle** | Go to Profile -> Settings -> Switch to English/Arabic. | UI text, alignment (RTL/LTR), and date formats update instantly. |

---

## 2. Smart Notifications & Profile
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Notification Prefs** | Toggle "Milestone Notifications" off in Settings. | Settings are saved to Supabase `profiles` table. |
| **Bilingual Push** | Trigger a notification from Admin (or DB). | User receives the notification in their `preferred_language`. |
| **NPS Survey Trigger** | Set `last_nps_date` to >30 days ago in DB and open Dashboard. | Premium NPS bottom sheet appears automatically. |
| **NPS Submission** | Select a score (1-10) and add a comment. | Data is saved to `satisfaction_surveys` table; sheet dismisses with a "Thank you". |

---

## 3. Dashboard & Real-time Metrics
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Skeleton Loading** | Launch app on slow internet. | Dashboard shows shimmering skeleton cards instead of a blank screen. |
| **Live Metrics** | Update a project metric (e.g., ROI) in Supabase. | Dashboard metric card updates in real-time or upon pull-to-refresh. |
| **Empty Metrics** | Create a new project with no metrics. | Dashboard shows the "Personality Empty State" (e.g., "بانتظار قصة نجاحك"). |

---

## 4. Journey & Milestone Celebrations
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Journey Timeline** | Navigate to the "Journey" tab. | Project stages are displayed in a premium vertical timeline. |
| **Milestone Unlock** | Change a milestone status to `completed` in Supabase. | App triggers a full-screen celebration (confetti + haptic feedback). |
| **Stage Progression** | Complete all milestones in a stage. | The "Next Stage" preview card updates to show the upcoming goals. |

---

## 5. Premium Chat & Communication
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Real-time Messaging** | Send a message from App; reply from Admin. | Messages appear instantly without refresh. |
| **Haptic Feedback** | Send a message. | User feels a subtle "tap" (HapticService.light) on successful send. |
| **Voice Messages** | Record and send a 5-second voice note. | Waveform is generated; audio plays back correctly for both parties. |
| **Meetings (Jitsi)** | Tap "Start Meeting" or join an active one. | Jitsi Meet overlay opens; audio/video works as expected. |

---

## 6. Tasks & Approvals
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Task Status** | Mark a task as "Done" in the app. | Status updates in the `tasks` table; UI reflects completion. |
| **Approval Request** | Create an `approval` record in DB with status `pending`. | "Approvals" screen shows the request card. |
| **Approve/Reject** | Tap "Approve" (with Haptic tap) or "Request Changes". | Status updates in DB; card moves to the corresponding history section. |

---

## 7. Growth Story Reports
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Swipeable Reports** | Open the Reports tab and tap "Growth Story". | Reports are displayed in a modern, swipeable full-screen viewer. |
| **PDF Viewing** | Tap "View PDF" on a report card. | Integrated PDF viewer opens with the report file. |
| **Empty Reports** | Clear the `project_reports` table. | Screen shows the personality empty state with Arabic copy. |

---

## 8. UX, Offline & Performance
| Scenario | Steps | Expected Result |
| :--- | :--- | :--- |
| **Offline Banner** | Disable Wi-Fi/Data while in the app. | Red Arabic banner appears: "لا يوجد اتصال بالإنترنت...". |
| **Connection Restore** | Re-enable Wi-Fi. | Banner slides up and disappears instantly. |
| **Tactile Navigation** | Tap through Bottom Navigation items. | Navigation is smooth with no layout shifts. |

---

## Developer Verification (Final Build)
- [ ] **Bundle ID**: Verify Android (com.zbooma.moharek) and iOS match.
- [ ] **Firebase**: Verify `google-services.json` contains the new package name.
- [ ] **Haptics**: Test on a physical device (Haptics do not trigger on Emulators).
- [ ] **Localization**: Verify RTL layout for Arabic is pixel-perfect.
