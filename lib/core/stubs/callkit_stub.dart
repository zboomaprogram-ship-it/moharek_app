class FlutterCallkitIncoming {
  static Future<void> showCallkitIncoming(dynamic params) async {}
  static Future<void> showMissCallNotification(dynamic params) async {}
  static Future<void> endCall(String uuid) async {}
  static Future<void> endAllCalls() async {}
  static Stream<CallEvent> get onEvent => const Stream.empty();
  static Future<String?> getDevicePushTokenVoIP() async => null;
  static Future<List<CallKitParams>> activeCalls() async => [];
}

class CallKitParams {
  final String id;
  final String? nameCaller;
  final String? appName;
  final String? avatar;
  final String? handle;
  final int? type;
  final int? duration;
  final String? textAccept;
  final String? textDecline;
  final NotificationParams? missedCallNotification;
  final NotificationParams? callingNotification;
  final Map<String, dynamic>? extra;
  final Map<String, dynamic>? headers;
  final AndroidParams? android;
  final IOSParams? ios;

  const CallKitParams({
    this.id = '',
    this.nameCaller,
    this.appName,
    this.avatar,
    this.handle,
    this.type,
    this.duration,
    this.textAccept,
    this.textDecline,
    this.missedCallNotification,
    this.callingNotification,
    this.extra,
    this.headers,
    this.android,
    this.ios,
  });
}

class NotificationParams {
  final bool? showNotification;
  final int? count;
  final String? subtitle;
  final String? callbackText;
  final bool? isShowLogo;
  final bool? isShowCallback;

  const NotificationParams({
    this.showNotification,
    this.count,
    this.subtitle,
    this.callbackText,
    this.isShowLogo,
    this.isShowCallback,
  });
}

class AndroidParams {
  final bool? isCustomNotification;
  final bool? isShowLogo;
  final String? ringtonePath;
  final String? backgroundColor;
  final String? actionColor;
  final String? textColor;
  final String? incomingCallNotificationChannelName;
  final String? missedCallNotificationChannelName;
  final bool? isShowFullLockedScreen;
  final bool? isFullScreen;
  final bool? isImportant;
  final String? textAccept;
  final String? textDecline;

  const AndroidParams({
    this.isCustomNotification,
    this.isShowLogo,
    this.ringtonePath,
    this.backgroundColor,
    this.actionColor,
    this.textColor,
    this.incomingCallNotificationChannelName,
    this.missedCallNotificationChannelName,
    this.isShowFullLockedScreen,
    this.isFullScreen,
    this.isImportant,
    this.textAccept,
    this.textDecline,
  });
}

class IOSParams {
  final String? iconName;
  final String? handleType;
  final bool? supportsVideo;
  final int? maximumCallGroups;
  final int? maximumCallsPerCallGroup;
  final String? audioSessionMode;
  final bool? audioSessionActive;
  final bool? supportsDTMF;
  final bool? supportsHolding;
  final String? ringtonePath;

  const IOSParams({
    this.iconName,
    this.handleType,
    this.supportsVideo,
    this.maximumCallGroups,
    this.maximumCallsPerCallGroup,
    this.audioSessionMode,
    this.audioSessionActive,
    this.supportsDTMF,
    this.supportsHolding,
    this.ringtonePath,
  });
}

abstract class CallEvent {
  const CallEvent();
  String get eventName;
}

class CallEventActionCallAccept extends CallEvent {
  final String id;
  const CallEventActionCallAccept(this.id);
  @override
  String get eventName => '';
}

class CallEventActionCallDecline extends CallEvent {
  final String id;
  const CallEventActionCallDecline(this.id);
  @override
  String get eventName => '';
}

class CallEventActionCallEnded extends CallEvent {
  final String id;
  const CallEventActionCallEnded(this.id);
  @override
  String get eventName => '';
}

class CallEventActionCallTimeout extends CallEvent {
  final String id;
  const CallEventActionCallTimeout(this.id);
  @override
  String get eventName => '';
}

