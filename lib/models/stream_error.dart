enum StreamErrorType {
  invalidRtmpUrl,
  invalidStreamKey,
  agoraConnectionFailed,
  rtmpPushFailed,
  permissionDenied,
  networkError,
  unknownError,
}

class StreamError {
  final StreamErrorType type;
  final String message;
  final String? details;

  StreamError({
    required this.type,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'StreamError($type: $message${details != null ? ' - $details' : ''})';
}
