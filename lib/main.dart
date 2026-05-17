import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moharek_app/core/router/app_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/services/notification_service.dart';
import 'package:moharek_app/core/providers/locale_provider.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart' if (dart.library.html) 'package:moharek_app/core/stubs/callkeep_stub.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/features/calls/widgets/call_signal_listener.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WordPress Media API secret key in secure storage
  const secureStorage = FlutterSecureStorage();
  try {
    final hasKey = await secureStorage.containsKey(key: 'wp_media_api_secret');
    if (!hasKey) {
      await secureStorage.write(key: 'wp_media_api_secret', value: 'omarmahmoud23112002');
    }
  } catch (e) {
    debugPrint('Secure storage init error: $e');
  }

  // Initialize CallKeep for background call handling
  if (!kIsWeb) {
    CallKeep.instance.configure(CallKeepConfig(
      appName: 'Moharek',
      android: CallKeepAndroidConfig(
        logo: "ic_launcher", // Standard launcher icon
        incomingCallNotificationChannelName: 'Moharek Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      ios: CallKeepIosConfig(
        iconName: 'ic_launcher',
        handleType: CallKitHandleType.generic,
        isVideoSupported: true,
      ),
    ));
  }

  // Load saved locale before running the app
  final container = ProviderContainer();
  await container.read(localeProvider.notifier).loadSaved();

  // Firebase & OneSignal are mobile-only — skip on web
  if (!kIsWeb) {
    await NotificationService.init();
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
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
      title: 'محرك',
      theme: AppTheme.darkTheme,
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
