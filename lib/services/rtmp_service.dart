import '../models/index.dart';

class RTMPService {
  final Map<String, RTMPStreamState> _streamStates = {};

  Future<bool> validateRtmpConfig(RTMPStreamConfig config) async {
    try {
      // Validate RTMP URL format
      if (!_isValidRtmpUrl(config.rtmpUrl)) {
        return false;
      }

      // Validate stream key format
      if (config.streamKey.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isValidRtmpUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'rtmp' || uri.scheme == 'rtmps';
    } catch (e) {
      return false;
    }
  }

  Future<void> startStream(RTMPStreamConfig config) async {
    if (!config.enabled) {
      return;
    }

    _streamStates[config.id] = RTMPStreamState(
      status: RTMPStreamStatus.connecting,
      config: config,
    );

    try {
      // Simulate stream connection
      await Future.delayed(const Duration(seconds: 2));
      
      _streamStates[config.id] = RTMPStreamState(
        status: RTMPStreamStatus.connected,
        config: config,
      );
    } catch (e) {
      _streamStates[config.id] = RTMPStreamState(
        status: RTMPStreamStatus.failed,
        config: config,
        error: e.toString(),
      );
    }
  }

  Future<void> stopStream(String configId) async {
    if (_streamStates.containsKey(configId)) {
      _streamStates[configId] = RTMPStreamState(
        status: RTMPStreamStatus.disconnected,
        config: _streamStates[configId]!.config,
      );
    }
  }

  Future<void> stopAllStreams() async {
    for (final configId in _streamStates.keys.toList()) {
      await stopStream(configId);
    }
  }

  RTMPStreamState? getStreamState(String configId) => _streamStates[configId];

  List<RTMPStreamState> getAllStreamStates() => _streamStates.values.toList();

  void clear() {
    _streamStates.clear();
  }
}

enum RTMPStreamStatus {
  idle,
  connecting,
  connected,
  disconnecting,
  disconnected,
  failed,
}

class RTMPStreamState {
  final RTMPStreamStatus status;
  final RTMPStreamConfig config;
  final String? error;
  final DateTime timestamp;

  RTMPStreamState({
    required this.status,
    required this.config,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get statusText {
    switch (status) {
      case RTMPStreamStatus.idle:
        return 'Idle';
      case RTMPStreamStatus.connecting:
        return 'Connecting to ${config.platformName}...';
      case RTMPStreamStatus.connected:
        return 'Connected to ${config.platformName}';
      case RTMPStreamStatus.disconnecting:
        return 'Disconnecting from ${config.platformName}...';
      case RTMPStreamStatus.disconnected:
        return 'Disconnected from ${config.platformName}';
      case RTMPStreamStatus.failed:
        return 'Failed to connect to ${config.platformName}';
    }
  }
}
