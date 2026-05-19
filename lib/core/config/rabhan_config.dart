import 'app_config.dart';

class RabhanConfig extends AppConfig {
  const RabhanConfig()
      : super(
          supabaseUrlVal: const String.fromEnvironment(
            'RABHAN_SUPABASE_URL',
            defaultValue: 'https://placeholder.supabase.co',
          ),
          supabaseAnonKeyVal: const String.fromEnvironment(
            'RABHAN_SUPABASE_ANON_KEY',
            defaultValue: 'placeholder-anon-key',
          ),
          wordpressMediaUrlVal: const String.fromEnvironment(
            'RABHAN_WP_MEDIA_URL',
            defaultValue: 'https://placeholder.com/media-api.php',
          ),
          oneSignalAppIdVal: const String.fromEnvironment(
            'RABHAN_ONESIGNAL_APP_ID',
            defaultValue: 'placeholder-onesignal-id',
          ),
          notificationsEnabledVal: true,
          livekitEnabledVal: true,
          appNameVal: 'ربحان',
          flavorNameVal: 'rabhan',
        );

  // New Rabhan Feature Flags
  bool get enableGrowthSystem => true;
  bool get enableEcomMetrics => true;
  bool get enablePackageTiers => true;
  bool get enableAdCampaigns => true;
}
