import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_billing_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_channels_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_chat_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_logs_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_support_screen.dart';
import 'package:moharek_app/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:moharek_app/features/dashboard/presentation/screens/growth_story_screen.dart';
import 'package:moharek_app/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:moharek_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:moharek_app/features/profile/presentation/screens/team_management_screen.dart';
import 'package:moharek_app/features/support/presentation/screens/support_ticket_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/auth/presentation/screens/web_login_screen.dart';
import 'package:moharek_app/features/auth/presentation/screens/login_screen.dart';
import 'package:moharek_app/features/auth/presentation/screens/web_only_screen.dart';
import 'package:moharek_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:moharek_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:moharek_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:moharek_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:moharek_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:moharek_app/features/dashboard/presentation/screens/main_shell.dart';
import 'package:moharek_app/features/journey/presentation/screens/journey_screen.dart';
import 'package:moharek_app/features/strategy/presentation/screens/strategy_screen.dart';
import 'package:moharek_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:moharek_app/features/results/presentation/screens/results_screen.dart';
import 'package:moharek_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:moharek_app/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:moharek_app/features/files/presentation/screens/files_screen.dart';
import 'package:moharek_app/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:moharek_app/features/contracts/presentation/screens/contracts_screen.dart';
import 'package:moharek_app/features/financials/presentation/screens/billing_screen.dart';
import 'package:moharek_app/features/campaigns/presentation/screens/campaigns_screen.dart';
import 'package:moharek_app/features/support/presentation/screens/support_screen.dart';
import 'package:moharek_app/features/campaigns/presentation/screens/campaign_detail_screen.dart';
import 'package:moharek_app/features/chat/presentation/screens/channels_screen.dart';
import 'package:moharek_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:moharek_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:moharek_app/features/profile/presentation/screens/company_profile_screen.dart';

// Admin Dashboard Imports
import 'package:moharek_app/features/admin/presentation/screens/admin_shell.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_team_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_am_detail_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_clients_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_notifications_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_packages_screen.dart';

// AM Dashboard Imports
import 'package:moharek_app/features/am/presentation/screens/am_shell.dart';
import 'package:moharek_app/features/am/presentation/screens/am_clients_screen.dart';
import 'package:moharek_app/features/am/presentation/screens/am_tasks_screen.dart';
import 'package:moharek_app/features/am/presentation/screens/am_approvals_screen.dart';
import 'package:moharek_app/features/am/presentation/screens/am_reports_screen.dart';
import 'package:moharek_app/features/am/presentation/screens/am_chat_screen.dart';
import 'package:moharek_app/features/am/presentation/screens/am_calendar_screen.dart';
import 'package:moharek_app/features/am/presentation/screens/am_profile_screen.dart';
import 'package:moharek_app/features/rabhan/screens/growth_pro_screen.dart';
import 'package:moharek_app/features/rabhan/screens/growth_system_screen.dart';
import 'package:moharek_app/features/rabhan/screens/rabhan_analytics_screen.dart';
import 'package:moharek_app/features/rabhan/screens/rabhan_strategy_screen.dart';

// Shared Imports
import 'package:moharek_app/features/shared/presentation/screens/shared_client_hub_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

late final _authListenable = SupabaseAuthListenable();

class SupabaseAuthListenable extends ChangeNotifier {
  bool _initialized = false;
  Timer? _debounceTimer;

  bool get isInitialized => _initialized;

  SupabaseAuthListenable() {
    // If a session already exists synchronously (e.g. on hot restart), mark initialized
    if (Supabase.instance.client.auth.currentSession != null) {
      _initialized = true;
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _initialized = true;

      // On explicit sign-out, clear cache and notify immediately for instant security
      if (data.event == AuthChangeEvent.signedOut) {
        _cachedRole = null;
        _cachedIsActive = null;
        _cachedUserId = null;
        _debounceTimer?.cancel();
        notifyListeners();
        return;
      }

      // Ignore initialSession if session is null to prevent premature redirects
      if (data.event == AuthChangeEvent.initialSession && data.session == null) {
        return;
      }

      // For other events (e.g. token refresh, login), debounce to avoid rapid rebuilds/flicker
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Cache for user role to avoid redundant DB calls on every redirect
String? _cachedRole;
bool? _cachedIsActive;
String? _cachedUserId;

String? _processRedirect(
  String path,
  String role,
  bool isActive,
  bool isLoginPage,
  bool isRoot,
) {
  // Status Gate: Check if user is active
  if (!isActive) {
    // Do not aggressively call signOut() here as it can cause a redirect loop. 
    // Just route them to a suspended page.
    return '/suspended';
  }

  final bool isAdmin = role == 'admin';
  final bool isAM = role == 'account_manager';

  // Mobile Web-Only Gate: Redirect admin/AM to dedicated web-only warning on native platforms
  if (!kIsWeb && (isAdmin || isAM)) {
    if (path == '/web-only') return null;
    return '/web-only';
  }

  // Prevent clients from manually visiting /web-only on mobile
  if (path == '/web-only' && (kIsWeb || (!isAdmin && !isAM))) {
    return '/dashboard';
  }

  // Entry Gate: Redirect from Login/Root to appropriate Dashboard
  if (isLoginPage || isRoot) {
    if (isAdmin) return '/admin/overview';
    if (isAM) return '/am/clients';
    return '/dashboard';
  }

  // Security Gate: Protect Web Dashboards
  if (path.startsWith('/admin') && !isAdmin) {
    return isAM ? '/am/clients' : '/dashboard';
  }

  // Prevent admin from accidentally on AM routes (redirect back)
  if (path.startsWith('/am') && !isAM && !isAdmin) {
    return '/dashboard';
  }

  return null;
}

late final appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: rootNavigatorKey,
  refreshListenable: _authListenable,
  redirect: (context, state) async {
    // If the auth listenable hasn't finished restoring the initial session yet,
    // immediately return null to stay on the current path (avoiding premature /login redirect)
    if (!_authListenable.isInitialized) {
      return null;
    }

    final client = Supabase.instance.client;
    Session? session = client.auth.currentSession;
    
    // Fallback for transient null session on Web after login
    if (session == null && kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 50));
      session = client.auth.currentSession;
    }

    final path = state.matchedLocation;
    final isLoginPage = path == '/login';
    final isRoot = path == '/';
    final isForgotPass = path == '/forgot-password';

    // 1. Unauthenticated users (even after retry)
    if (session == null) {
      // Only clear cache on confirmed sign-out, not transient null
      if (_cachedUserId != null) {
        _cachedRole = null;
        _cachedIsActive = null;
        _cachedUserId = null;
      }
      if (isRoot || isForgotPass || isLoginPage) return null;
      return '/login';
    }

    // 2. Use cache if available and userId matches (avoids repeated DB calls)
    if (_cachedUserId == session.user.id && _cachedRole != null) {
      return _processRedirect(
        path,
        _cachedRole!,
        _cachedIsActive ?? true,
        isLoginPage,
        isRoot,
      );
    }

    // 3. Fetch profile for security verification
    try {
      final profile = await client
          .from('profiles')
          .select('role, is_active')
          .eq('id', session.user.id)
          .maybeSingle();

      if (profile == null) {
        if (path.startsWith('/admin') || path.startsWith('/am')) return '/dashboard';
        return null;
      }

      bool active = true;
      if (profile['is_active'] != null) {
        if (profile['is_active'] is bool) {
          active = profile['is_active'];
        } else if (profile['is_active'] is int) {
          active = profile['is_active'] == 1;
        } else if (profile['is_active'] is String) {
          active = profile['is_active'] == 'true' || profile['is_active'] == '1';
        }
      }

      // Update cache
      _cachedUserId = session.user.id;
      _cachedRole = (profile['role'] as String? ?? 'client').toLowerCase();
      _cachedIsActive = active;

      return _processRedirect(
        path,
        _cachedRole!,
        _cachedIsActive!,
        isLoginPage,
        isRoot,
      );
    } catch (e) {
      debugPrint('Security Gate Error: $e');
      // On error, don't redirect — let the user stay on their current page
      return null;
    }
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/suspended',
      builder: (context, state) => const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, color: Colors.redAccent, size: 64),
              SizedBox(height: 16),
              Text(
                'الحساب معلق',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'عذراً، هذا الحساب غير نشط حالياً. يرجى التواصل مع الدعم.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => kIsWeb ? const WebLoginScreen() : const LoginScreen(),
    ),
    GoRoute(
      path: '/web-only',
      builder: (context, state) => const WebOnlyScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // ── Client/Mobile Shell ───────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'approvals',
                  builder: (c, s) => const ApprovalsScreen(),
                ),
                GoRoute(path: 'files', builder: (c, s) => const FilesScreen()),
                GoRoute(
                  path: 'meetings',
                  builder: (c, s) => const MeetingsScreen(),
                ),
                GoRoute(
                  path: 'contracts',
                  builder: (c, s) => const ContractsScreen(),
                ),
                GoRoute(
                  path: 'billing',
                  builder: (c, s) => const BillingScreen(),
                ),
                GoRoute(
                  path: 'campaigns',
                  builder: (c, s) => const CampaignsScreen(),
                ),
                GoRoute(
                  path: 'campaigns/:id',
                  builder: (c, s) =>
                      CampaignDetailScreen(campaignId: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'ai-assistant',
                  builder: (c, s) => const AiAssistantScreen(),
                ),
                GoRoute(
                  path: 'growth-story',
                  builder: (c, s) => const GrowthStoryScreen(),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (c, s) => const NotificationCenterScreen(),
                ),
                GoRoute(
                  path: 'package',
                  builder: (c, s) => const GrowthProScreen(),
                ),
                GoRoute(
                  path: 'growth-system',
                  builder: (c, s) => const GrowthSystemScreen(),
                ),
                GoRoute(
                  path: 'analytics',
                  builder: (c, s) => const RabhanAnalyticsScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/tasks', builder: (c, s) => const TasksScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (c, s) => const ChannelsScreen(),
              routes: [
                GoRoute(
                  path: ':channelId',
                  builder: (c, s) => ChatScreen(
                    channelId: s.pathParameters['channelId']!,
                    channelName: s.uri.queryParameters['name'] ?? 'Chat',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/results',
              builder: (c, s) => AppConfig.flavorName == 'rabhan' ? const NotificationCenterScreen() : const ResultsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (c, s) => AppConfig.flavorName == 'rabhan' ? const ProfileScreen() : const ReportsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Admin Dashboard (Web) ──────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin', redirect: (_, __) => '/admin/overview'),
        GoRoute(
          path: '/admin/overview',
          builder: (_, __) => const AdminOverviewScreen(),
        ),
        GoRoute(
          path: '/admin/packages',
          builder: (_, __) => const AdminPackagesScreen(),
        ),
        GoRoute(
          path: '/admin/team',
          builder: (_, __) => const AdminTeamScreen(),
        ),
        GoRoute(
          path: '/admin/team/:amId',
          builder: (_, s) =>
              AdminAmDetailScreen(amId: s.pathParameters['amId']!),
        ),
        GoRoute(
          path: '/admin/clients',
          builder: (_, __) => const AdminClientsScreen(),
        ),
        GoRoute(
          path: '/admin/clients/:projectId',
          builder: (_, s) => SharedClientHubScreen(
            projectId: s.pathParameters['projectId']!,
            isAdmin: true,
          ),
          routes: [
            GoRoute(
              path: 'channels',
              builder: (_, s) => AdminChannelsScreen(
                projectId: s.pathParameters['projectId']!,
                clientName: s.uri.queryParameters['clientName'] ?? 'Client',
              ),
            ),
          ],
        ),
        // Direct chat routes
        GoRoute(
          path: '/admin/chat/:projectId',
          builder: (_, s) => AdminChannelsScreen(
            projectId: s.pathParameters['projectId']!,
            clientName: s.uri.queryParameters['name'] ?? 'Client',
          ),
        ),
        GoRoute(
          path: '/admin/chat/:projectId/:channelId',
          builder: (_, s) => AdminChatScreen(
            projectId: s.pathParameters['projectId']!,
            channelId: s.pathParameters['channelId']!,
            clientName: s.uri.queryParameters['clientName'] ?? 'Client',
            channelName: s.uri.queryParameters['channelName'] ?? 'Chat',
          ),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (_, __) => const AdminReportsScreen(),
        ),
        GoRoute(
          path: '/admin/billing',
          builder: (_, __) => const AdminBillingScreen(),
        ),
        GoRoute(
          path: '/admin/logs',
          builder: (_, __) => const AdminLogsScreen(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (_, __) => const AdminSettingsScreen(),
        ),
        GoRoute(
          path: '/admin/support',
          builder: (_, __) => const AdminSupportScreen(),
        ),
        GoRoute(
          path: '/admin/support/:ticketId',
          builder: (_, s) => SupportTicketDetailScreen(
            ticketId: s.pathParameters['ticketId']!,
          ),
        ),
        GoRoute(
          path: '/admin/notifications',
          builder: (_, __) => const AdminNotificationsScreen(),
        ),
      ],
    ),

    // ── Account Manager Dashboard (Web) ────────────────────────
    ShellRoute(
      builder: (context, state, child) => AmShell(child: child),
      routes: [
        GoRoute(path: '/am', redirect: (_, __) => '/am/clients'),
        GoRoute(
          path: '/am/clients',
          builder: (_, __) => const AmClientsScreen(),
        ),
        GoRoute(
          path: '/am/clients/:projectId',
          builder: (_, s) => SharedClientHubScreen(
            projectId: s.pathParameters['projectId']!,
            isAdmin: false,
          ),
        ),
        GoRoute(path: '/am/tasks', builder: (_, __) => const AmTasksScreen()),
        GoRoute(
          path: '/am/approvals',
          builder: (_, __) => const AmApprovalsScreen(),
        ),
        GoRoute(
          path: '/am/reports',
          builder: (_, __) => const AmReportsScreen(),
        ),
        GoRoute(path: '/am/chat', builder: (_, __) => const AmChatScreen()),
        GoRoute(
          path: '/am/calendar',
          builder: (_, __) => const AmCalendarScreen(),
        ),
        GoRoute(
          path: '/am/profile',
          builder: (_, __) => const AmProfileScreen(),
        ),
      ],
    ),
    // ── Global/Extra Routes ───────────────────────────────────
    GoRoute(path: '/journey', builder: (c, s) => const JourneyScreen()),
    GoRoute(
      path: '/strategy',
      redirect: (context, state) => AppConfig.flavorName == 'rabhan' ? '/dashboard/growth-system' : null,
      builder: (c, s) => const StrategyScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (c, s) => const ProfileScreen(),
      routes: [
        GoRoute(path: 'edit', builder: (c, s) => const EditProfileScreen()),
        GoRoute(
          path: 'company',
          builder: (c, s) => const CompanyProfileScreen(),
        ),
        GoRoute(
          path: 'support',
          builder: (c, s) => const SupportScreen(),
          routes: [
            GoRoute(
              path: ':ticketId',
              builder: (c, s) => SupportTicketDetailScreen(
                ticketId: s.pathParameters['ticketId']!,
              ),
            ),
          ],
        ),
        GoRoute(path: 'team', builder: (c, s) => const TeamManagementScreen()),
        GoRoute(path: 'settings', builder: (c, s) => const SettingsScreen()),
      ],
    ),
  ],
);
