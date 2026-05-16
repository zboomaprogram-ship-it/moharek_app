// Stub for Jitsi Meet on web — the real SDK only works on mobile.
// All classes and methods are no-ops.

class JitsiMeetConferenceOptions {
  final String room;
  final String? serverURL;
  final Map<String, Object>? configOverrides;
  final Map<String, Object>? featureFlags;
  final JitsiMeetUserInfo? userInfo;

  JitsiMeetConferenceOptions({
    required this.room,
    this.serverURL,
    this.configOverrides,
    this.featureFlags,
    this.userInfo,
  });
}

class JitsiMeetUserInfo {
  final String? displayName;
  final String? email;
  final String? avatar;

  JitsiMeetUserInfo({this.displayName, this.email, this.avatar});
}

class JitsiMeet {
  Future<void> join(JitsiMeetConferenceOptions options) async {}
  Future<void> hangUp() async {}
}
