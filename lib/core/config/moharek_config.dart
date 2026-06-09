import 'app_config.dart';

class MoharekConfig extends AppConfig {
  const MoharekConfig()
    : super(
        supabaseUrlVal: 'https://typbaddqqhpeppzpbbhj.supabase.co',
        supabaseAnonKeyVal:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
        wordpressMediaUrlVal: 'https://mohrek.com/media-api.php',
        oneSignalAppIdVal: '234d893b-ca81-493d-9afd-6a287a69b27e',
        notificationsEnabledVal: true,
        livekitEnabledVal: true,
        appNameVal: 'محرك',
        flavorNameVal: 'moharek',
        complaintsWhatsappVal: '966500000000',
      );
}
