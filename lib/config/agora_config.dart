/// Agora Configuration Constants
///
/// Replace YOUR_AGORA_APP_ID with your actual Agora App ID from:
/// https://console.agora.io/
/// Agora Configuration
class AgoraConfig {
  // Your Agora App ID
  static const String appId = 'dd522d50dc8945a38da60ba87d9da0e0';

  // Your generated temporary token
  static const String tempToken =
      '007eJxTYHDyDFv7zvGaqnHRxB/tbKKaDRP0PuzZKhOXt5rjuZSa3QwFhpQUUyOjFFODlGQLSxPTRGOLlEQzg6REC/MUy5REg1QD13dyWQ2BjAxKDWtZGBkgEMRnZyhJLS4xNDJmYAAAJYceVw==';

  // Video configuration
  static const int videoWidth = 720;
  static const int videoHeight = 1280;
  static const int videoFrameRate = 30;
  static const int videoBitrate = 1200;
}

/// Stream Platform Configuration
class StreamPlatformConfig {
  static const Map<String, String> rtmpServers = {
    'YouTube': 'rtmp://a.rtmp.youtube.com/live2',
    'Facebook': 'rtmps://live-api-s.facebook.com:443/rtmp/',
    'Instagram': 'rtmps://live-api-s.instagram.com:443/rtmp/',
    'Twitch': 'rtmp://live.twitch.tv/app',
  };

  static String? getServerUrl(String platformName) {
    return rtmpServers[platformName];
  }
}
