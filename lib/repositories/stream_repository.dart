import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../models/index.dart';
import '../services/index.dart';

class StreamRepository {
  final AgoraService _agoraService;
  final RTMPService _rtmpService;
  final PermissionService _permissionService;
  // Add this to StreamRepository class
  bool get isAgoraInitialized {
    return _agoraService.isInitialized;
  }

  LiveStreamSession? _currentSession;
  final List<RTMPStreamConfig> _rtmpConfigs = [];

  StreamRepository({
    required AgoraService agoraService,
    required RTMPService rtmpService,
    required PermissionService permissionService,
  }) : _agoraService = agoraService,
       _rtmpService = rtmpService,
       _permissionService = permissionService;

  // Add initialization method
  Future<void> initialize() async {
    await _agoraService.initialize();
  }

  // Permissions
  Future<bool> requestAllPermissions() =>
      _permissionService.requestAllPermissions();

  Future<bool> hasAllPermissions() => _permissionService.hasAllPermissions();

  // Live Stream Session Management
  LiveStreamSession? get currentSession => _currentSession;

  Future<void> createLiveSession({
    required String hostName,
    required String title,
    required bool isHost,
    required String agoraChannelName,
  }) async {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${hostName.hashCode}';

    _currentSession = LiveStreamSession(
      id: id,
      agoraChannelName: agoraChannelName,
      agoraUid: _agoraService.localUid,
      hostName: hostName,
      title: title,
      startTime: now,
      isHost: isHost,
      rtmpConfigs: _rtmpConfigs,
    );
  }

  Future<void> endLiveSession() async {
    await stopAllRtmpStreams();
    _currentSession = null;
    _rtmpConfigs.clear();
  }

  // RTMP Configuration
  void addRtmpConfig(RTMPStreamConfig config) {
    _rtmpConfigs.add(config);
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(rtmpConfigs: _rtmpConfigs);
    }
  }

  void removeRtmpConfig(String configId) {
    _rtmpConfigs.removeWhere((config) => config.id == configId);
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(rtmpConfigs: _rtmpConfigs);
    }
  }

  void updateRtmpConfig(RTMPStreamConfig updatedConfig) {
    final index = _rtmpConfigs.indexWhere(
      (config) => config.id == updatedConfig.id,
    );
    if (index != -1) {
      _rtmpConfigs[index] = updatedConfig;
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(rtmpConfigs: _rtmpConfigs);
      }
    }
  }

  List<RTMPStreamConfig> getRtmpConfigs() => _rtmpConfigs;

  // Broadcasting
  Future<void> startBroadcasting({
    required String channelName,
    required bool isBroadcaster,
  }) async {
    await _agoraService.startBroadcasting(
      channelName: channelName,
      isBroadcaster: isBroadcaster,
    );
  }

  Future<void> stopBroadcasting() async {
    await _agoraService.stopBroadcasting();
  }

  // RTMP Streaming
  Future<bool> validateRtmpConfig(RTMPStreamConfig config) =>
      _rtmpService.validateRtmpConfig(config);

  Future<void> startRtmpStream(RTMPStreamConfig config) async {
    final isValid = await validateRtmpConfig(config);
    if (!isValid) {
      throw StreamError(
        type: StreamErrorType.invalidRtmpUrl,
        message: 'Invalid RTMP URL or stream key',
      );
    }

    await _rtmpService.startStream(config);
    await _agoraService.startRtmpStream(config.fullStreamUrl);
  }

  Future<void> stopRtmpStream(String configId) async {
    final state = _rtmpService.getStreamState(configId);
    if (state != null) {
      await _rtmpService.stopStream(configId);
      await _agoraService.stopRtmpStream(state.config.fullStreamUrl);
    }
  }

  Future<void> startAllRtmpStreams() async {
    for (final config in _rtmpConfigs.where((c) => c.enabled)) {
      try {
        await startRtmpStream(config);
      } catch (e) {
        // Continue with other streams even if one fails
      }
    }
  }

  Future<void> stopAllRtmpStreams() async {
    for (final config in _rtmpConfigs) {
      try {
        await stopRtmpStream(config.id);
      } catch (e) {
        // Continue with other streams even if one fails
      }
    }
  }

  // Stream State
  List<RTMPStreamState> getAllRtmpStreamStates() =>
      _rtmpService.getAllStreamStates();

  RTMPStreamState? getRtmpStreamState(String configId) =>
      _rtmpService.getStreamState(configId);

  RtcEngine getRtcEngine() {
    return _agoraService.getRtcEngine();
  }

  void dispose() {
    _rtmpService.clear();
    _agoraService.dispose();
  }
}
