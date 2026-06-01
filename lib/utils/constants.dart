import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // String constants
  static const String appName = 'Agora Live Broadcaster';
  static const String appVersion = '1.0.0';

  // Duration constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration retryDelay = Duration(seconds: 2);

  // Size constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;

  // Video/Audio defaults
  static const int defaultVideoWidth = 1280;
  static const int defaultVideoHeight = 720;
  static const int defaultFrameRate = 30;

  // Error messages
  static const String errorUnknown = 'An unknown error occurred';
  static const String errorNetwork = 'Network connection error';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorInvalidInput = 'Invalid input';
}

/// UI Constants
class UIConstants {
  // Colors
  static const Color primaryColor = Colors.deepPurple;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );
}

/// Stream-related constants
class StreamConstants {
  // Stream parameters
  static const int maxConcurrentRtmpStreams = 10;
  static const Duration rtmpConnectionTimeout = Duration(seconds: 10);
  static const Duration agoraConnectionTimeout = Duration(seconds: 10);

  // Validation
  static const int minChannelNameLength = 1;
  static const int maxChannelNameLength = 64;
  static const int minStreamKeyLength = 1;
  static const int maxStreamKeyLength = 256;

  // Messages
  static const String msgStreamStarted = 'Stream started';
  static const String msgStreamEnded = 'Stream ended';
  static const String msgRtmpConnecting = 'Connecting to platform...';
  static const String msgRtmpConnected = 'Connected to platform';
  static const String msgRtmpFailed = 'Failed to connect to platform';
  static const String msgPermissionRequired = 'Camera and microphone permissions required';
}
