/// Validation utilities
class ValidationUtils {
  /// Validate Agora channel name
  static bool isValidChannelName(String? name) {
    if (name == null || name.isEmpty) return false;
    if (name.length > 64) return false;
    // Allow alphanumeric, hyphen, underscore
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name);
  }

  /// Validate RTMP URL
  static bool isValidRtmpUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'rtmp' || uri.scheme == 'rtmps';
    } catch (e) {
      return false;
    }
  }

  /// Validate stream key
  static bool isValidStreamKey(String? key) {
    if (key == null || key.isEmpty) return false;
    if (key.length > 256) return false;
    // Allow most characters except spaces
    return !key.contains(' ');
  }

  /// Validate host name
  static bool isValidHostName(String? name) {
    if (name == null || name.isEmpty) return false;
    return name.length <= 100;
  }

  /// Validate stream title
  static bool isValidStreamTitle(String? title) {
    if (title == null || title.isEmpty) return false;
    return title.length <= 200;
  }
}

/// String formatting utilities
class StringUtils {
  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format DateTime to readable string
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Truncate string to max length with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Mask sensitive data (e.g., stream key)
  static String maskSensitiveData(String data, {int visibleLength = 4}) {
    if (data.length <= visibleLength) return data;
    final masked = '*' * (data.length - visibleLength);
    return data.substring(0, visibleLength) + masked;
  }
}

/// Logger utility for debugging
class Logger {
  static const String _prefix = '[AgoraBroadcaster]';

  static void log(String message) {
    print('$_prefix INFO: $message');
  }

  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    print('$_prefix ERROR: $message');
    if (error != null) {
      print('  Exception: $error');
    }
    if (stackTrace != null) {
      print('  Stack trace: $stackTrace');
    }
  }

  static void logWarning(String message) {
    print('$_prefix WARNING: $message');
  }

  static void logDebug(String message) {
    print('$_prefix DEBUG: $message');
  }
}
