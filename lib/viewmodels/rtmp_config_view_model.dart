import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../repositories/index.dart';
import '../services/rtmp_service.dart';

class RTMPConfigViewModel extends ChangeNotifier {
  final StreamRepository _repository;

  final List<RTMPStreamConfig> _configs = [];
  StreamError? _lastError;

  RTMPConfigViewModel({required StreamRepository repository})
      : _repository = repository {
    _loadConfigs();
  }

  List<RTMPStreamConfig> get configs => _configs;
  List<RTMPStreamState> get streamStates =>
      _repository.getAllRtmpStreamStates();
  StreamError? get lastError => _lastError;

  void _loadConfigs() {
    _configs.clear();
    _configs.addAll(_repository.getRtmpConfigs());
    notifyListeners();
  }

  Future<void> addConfig({
    required StreamPlatform platform,
    required String platformName,
    required String rtmpUrl,
    required String streamKey,
  }) async {
    final config = RTMPStreamConfig(
      id: const Uuid().v4(),
      platform: platform,
      platformName: platformName,
      rtmpUrl: rtmpUrl,
      streamKey: streamKey,
    );

    // Validate before adding
    final isValid = await _repository.validateRtmpConfig(config);
    if (!isValid) {
      _lastError = StreamError(
        type: StreamErrorType.invalidRtmpUrl,
        message: 'Invalid RTMP URL or stream key format',
      );
      notifyListeners();
      return;
    }

    _repository.addRtmpConfig(config);
    _loadConfigs();
    _lastError = null;
  }

  void removeConfig(String configId) {
    _repository.removeRtmpConfig(configId);
    _loadConfigs();
  }

  Future<void> updateConfig(RTMPStreamConfig updatedConfig) async {
    final isValid = await _repository.validateRtmpConfig(updatedConfig);
    if (!isValid) {
      _lastError = StreamError(
        type: StreamErrorType.invalidRtmpUrl,
        message: 'Invalid RTMP URL or stream key format',
      );
      notifyListeners();
      return;
    }

    _repository.updateRtmpConfig(updatedConfig);
    _loadConfigs();
    _lastError = null;
  }

  RTMPStreamState? getStreamState(String configId) =>
      _repository.getRtmpStreamState(configId);

  Future<void> startStream(String configId) async {
    final config = _configs.firstWhere(
      (c) => c.id == configId,
      orElse: () => throw Exception('Config not found'),
    );

    try {
      await _repository.startRtmpStream(config);
      notifyListeners();
    } catch (e) {
      _lastError = StreamError(
        type: StreamErrorType.rtmpPushFailed,
        message: 'Failed to start RTMP stream',
        details: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> stopStream(String configId) async {
    try {
      await _repository.stopRtmpStream(configId);
      notifyListeners();
    } catch (e) {
      _lastError = StreamError(
        type: StreamErrorType.unknownError,
        message: 'Failed to stop RTMP stream',
        details: e.toString(),
      );
      notifyListeners();
    }
  }

  void toggleConfig(String configId) {
    final index = _configs.indexWhere((c) => c.id == configId);
    if (index != -1) {
      _configs[index] = _configs[index].copyWith(
        enabled: !_configs[index].enabled,
      );
      _repository.updateRtmpConfig(_configs[index]);
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
