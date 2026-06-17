import 'app_config.dart';

class RabhanConfig extends AppConfig {
  const RabhanConfig()
    : super(
        supabaseUrlVal: const String.fromEnvironment(
          'RABHAN_SUPABASE_URL',
          defaultValue: 'https://pyzheqwypoaazpmpgiuq.supabase.co',
        ),
        supabaseAnonKeyVal: const String.fromEnvironment(
          'RABHAN_SUPABASE_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5emhlcXd5cG9hYXpwbXBnaXVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODUwMzEsImV4cCI6MjA5NDc2MTAzMX0.ZRM1H-5ZR01UwL5KXG0O9vFomc6ZOiMg8r-yNLvvMiw',
        ),
        wordpressMediaUrlVal: const String.fromEnvironment(
          'RABHAN_WP_MEDIA_URL',
          defaultValue: 'https://rabhanagency.com/media-api.php',
        ),
        oneSignalAppIdVal: const String.fromEnvironment(
          'RABHAN_ONESIGNAL_APP_ID',
          defaultValue: '063a237d-bbf9-4aac-8791-ef5e57752801',
        ),
        notificationsEnabledVal: true,
        livekitEnabledVal: true,
        appNameVal: 'ربحان',
        flavorNameVal: 'rabhan',
        logoAssetVal: 'assets/rabhan_logo.png',
        enableSEOVal: false,
        enableAIVisibilityVal: false,
        enableTrustEngineVal: false,
        enableContentMarketingVal: false,
        complaintsWhatsappVal: '966597387374',
      );

  // New Rabhan Feature Flags
  bool get enableGrowthSystem => true;
  bool get enableEcomMetrics => true;
  bool get enablePackageTiers => true;
  bool get enableAdCampaigns => true;
}
