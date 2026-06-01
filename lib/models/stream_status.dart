enum StreamStatusType {
  idle,
  initializing,
  live,
  rtmpConnecting,
  rtmpConnected,
  rtmpFailed,
  ending,
  error,
}

class StreamStatus {
  final StreamStatusType type;
  final String message;
  final DateTime timestamp;

  StreamStatus({
    required this.type,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  StreamStatus copyWith({
    StreamStatusType? type,
    String? message,
  }) {
    return StreamStatus(
      type: type ?? this.type,
      message: message ?? this.message,
    );
  }

  @override
  String toString() => 'StreamStatus($type: $message)';
}
