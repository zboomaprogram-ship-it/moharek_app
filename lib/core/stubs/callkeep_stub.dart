class CallKeep {
  static final instance = CallKeep();
  void configure(dynamic config) {}
}

class CallKeepConfig {
  CallKeepConfig({required String appName, dynamic android, dynamic ios});
}

class CallKeepAndroidConfig {
  CallKeepAndroidConfig({required String logo, required String incomingCallNotificationChannelName, required String missedCallNotificationChannelName});
}

class CallKeepIosConfig {
  CallKeepIosConfig({required String iconName, required dynamic handleType, required bool isVideoSupported});
}

enum CallKitHandleType { generic }
