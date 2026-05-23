// Stub file for web platform — OneSignal has no web support.
// All methods are no-ops to satisfy the compiler on web.

// ignore_for_file: avoid_classes_with_only_static_members, camel_case_types

enum OSLogLevel { verbose, debug, info, warn, error, fatal, none }

class OneSignalDebug {
  void setLogLevel(OSLogLevel level) {}
}

class OneSignalNotifications {
  Future<bool> requestPermission(bool fallbackToSettings) async => false;
  void addForegroundWillDisplayListener(void Function(dynamic event) listener) {}
  void addClickListener(void Function(dynamic event) listener) {}
  void addPermissionObserver(void Function(dynamic event) listener) {}
}

class OSPushSubscription {
  String? get id => null;
  void addObserver(dynamic observer) {}
  void removeObserver(dynamic observer) {}
}

class OneSignalUser {
  final pushSubscription = OSPushSubscription();
}

class OneSignal {
  // ignore: non_constant_identifier_names
  static final OneSignalDebug Debug = OneSignalDebug();
  // ignore: non_constant_identifier_names
  static final OneSignalNotifications Notifications = OneSignalNotifications();
  // ignore: non_constant_identifier_names
  static final OneSignalUser User = OneSignalUser();

  static void initialize(String appId) {}
  static Future<void> login(String externalId) async {}
  static Future<void> logout() async {}
}
