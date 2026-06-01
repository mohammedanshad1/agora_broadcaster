/// Agora Configuration Constants
/// 
/// Replace YOUR_AGORA_APP_ID with your actual Agora App ID from:
/// https://console.agora.io/
class AgoraConfig {
  // Your Agora App ID - Get it from https://console.agora.io/
  static const String appId = 'YOUR_AGORA_APP_ID';

  // Optional: Token for secure access
  // Set to empty string for testing
  static const String token = '';

  // Video configuration
  static const int videoWidth = 360;
  static const int videoHeight = 640;
  static const int videoFrameRate = 30;
  static const int videoBitrate = 1000;

  // Audio configuration
  static const int audioChannels = 2;
  static const int audioBitrate = 48;
  static const int audioSampleRate = 48000;

  // RTMP Configuration
  static const Duration rtmpConnectionTimeout = Duration(seconds: 10);
  static const Duration rtmpRetryDelay = Duration(seconds: 2);
  static const int rtmpMaxRetries = 3;
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
