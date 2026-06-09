import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:moharek_app/firebase_options.dart' as moharek_firebase;
import 'package:moharek_app/rabhan_firebase_options.dart' as rabhan_firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moharek_app/core/router/app_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/theme/rabhan_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/core/config/moharek_config.dart';

import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/services/notification_service.dart';
import 'package:moharek_app/core/providers/locale_provider.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart' if (dart.library.html) 'package:moharek_app/core/stubs/callkeep_stub.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/features/calls/widgets/call_signal_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class SafeLocalStorage extends LocalStorage {
  final _inMemoryStore = <String, String>{};
  final SharedPreferences? _prefs;
  static const _key = 'supabase.auth.token';

  SafeLocalStorage(this._prefs);

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    if (_prefs == null) return _inMemoryStore[_key];
    try {
      return _prefs.getString(_key);
    } catch (e) {
      return _inMemoryStore[_key];
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (_prefs == null) return _inMemoryStore.containsKey(_key);
    try {
      return _prefs.containsKey(_key);
    } catch (e) {
      return _inMemoryStore.containsKey(_key);
    }
  }

  @override
  Future<void> persistSession(String session) async {
    _inMemoryStore[_key] = session;
    if (_prefs == null) return;
    try {
      await _prefs.setString(_key, session);
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<void> removePersistedSession() async {
    _inMemoryStore.remove(_key);
    if (_prefs == null) return;
    try {
      await _prefs.remove(_key);
    } catch (e) {
      // ignore
    }
  }
}

void main() async {
  // If no instance has been set (e.g. running raw main.dart), default to MoharekConfig
  try {
    AppConfig.instance;
  } catch (_) {
    AppConfig.setInstance(const MoharekConfig());
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Register Arabic and English locales for timeago to prevent system-wide layout crashes
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  timeago.setLocaleMessages('en', timeago.EnMessages());

  // Initialize CallKeep for background call handling
  if (!kIsWeb) {
    try {
      // Dynamic compliance with Apple Guideline 5 (Legal - CallKit in China)
      // CallKit is prohibited on iOS in China.
      bool isChinaIOS = false;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final country = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
          if (country == 'CN') {
            isChinaIOS = true;
            debugPrint('China locale detected on iOS. CallKit configuration bypassed.');
          }
        } catch (_) {}
      }

      if (!isChinaIOS) {
        CallKeep.instance.configure(CallKeepConfig(
          appName: AppConfig.appName,
          android: CallKeepAndroidConfig(
            logo: "ic_launcher", // Standard launcher icon
            incomingCallNotificationChannelName: '${AppConfig.appName} Calls',
            missedCallNotificationChannelName: 'Missed Calls',
          ),
          ios: CallKeepIosConfig(
            iconName: 'ic_launcher',
            handleType: CallKitHandleType.generic,
            isVideoSupported: true,
          ),
        ));
      }
    } catch (e) {
      debugPrint('CallKeep Configuration Error: $e');
    }
  }

  // Pre-initialize SharedPreferences for SafeLocalStorage
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences initialization error: $e');
  }

  // Load saved locale before running the app
  final container = ProviderContainer(
    observers: [AppProviderObserver()],
  );
  await container.read(localeProvider.notifier).loadSaved();

  // Firebase & OneSignal are mobile-only — skip on web
  if (!kIsWeb) {
    try {
      final options = AppConfig.flavorName == 'rabhan'
          ? rabhan_firebase.DefaultFirebaseOptions.currentPlatform
          : moharek_firebase.DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);
      // Initialize notifications asynchronously so it doesn't block the main thread
      NotificationService.init();
    } catch (e) {
      debugPrint('Notification Service Initialization Error: $e');
    }
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SafeLocalStorage(prefs),
    ),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const MoharekApp()),
  );
}

class MoharekApp extends ConsumerWidget {
  const MoharekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Link User ID with OneSignal for targeted notifications (mobile only)
    if (!kIsWeb) {
      ref.listen(profileProvider, (previous, next) {
        next.whenData((profile) {
          if (profile != null) {
            NotificationService.setExternalUserId(profile.id);
          } else {
            NotificationService.logout();
          }
        });
      });
    }

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppConfig.flavorName == 'rabhan' ? RabhanThemeData.darkTheme : AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: CallSignalListener(child: child!),
        );
      },
    );
  }
}

class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is AsyncError) {
      debugPrint('======================================================');
      debugPrint('🚨 RIVERPOD PROVIDER ERROR: ${provider.name ?? provider.runtimeType}');
      debugPrint('Error: ${newValue.error}');
      debugPrint('Stacktrace: ${newValue.stackTrace}');
      debugPrint('======================================================');
    }
  }
}
