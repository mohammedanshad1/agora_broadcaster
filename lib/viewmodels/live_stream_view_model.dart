import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../repositories/index.dart';
import '../services/index.dart';

class LiveStreamViewModel extends ChangeNotifier {
  final StreamRepository _repository;

  StreamStatus _streamStatus = StreamStatus(
    type: StreamStatusType.idle,
    message: 'Ready to start streaming',
  );

  // Add this to LiveStreamViewModel class
  bool get isAgoraInitialized {
    return _repository.isAgoraInitialized;
  }

  // Add this method to LiveStreamViewModel class
  RtcEngine getRtcEngine() {
    return _repository.getRtcEngine();
  }

  // Add this method to LiveStreamViewModel class
  Future<void> initialize() async {
    await _repository.initialize();
  }

  LiveStreamSession? _currentSession;
  bool _isInitializing = false;
  String? _hostName;
  String? _streamTitle;

  StreamError? _lastError;

  LiveStreamViewModel({required StreamRepository repository})
    : _repository = repository {
    _repository.requestAllPermissions();
  }

  // Getters
  StreamStatus get streamStatus => _streamStatus;
  LiveStreamSession? get currentSession => _currentSession;
  bool get isInitializing => _isInitializing;
  bool get isLive => _streamStatus.type == StreamStatusType.live;
  StreamError? get lastError => _lastError;

  // Setters for input
  void setHostName(String name) {
    _hostName = name;
    notifyListeners();
  }

  void setStreamTitle(String title) {
    _streamTitle = title;
    notifyListeners();
  }

  Future<void> startLiveStream({required bool isBroadcaster}) async {
    if (_hostName == null || _hostName!.isEmpty) {
      _setError(
        StreamError(
          type: StreamErrorType.unknownError,
          message: 'Host name is required',
        ),
      );
      return;
    }

    _isInitializing = true;
    _setStatus(StreamStatusType.initializing, 'Initializing stream...');
    notifyListeners();

    try {
      // Check permissions
      final hasPermissions = await _repository.hasAllPermissions();
      if (!hasPermissions) {
        await _repository.requestAllPermissions();
      }

      // Create session
      final channelName = 'live_${DateTime.now().millisecondsSinceEpoch}';
      await _repository.createLiveSession(
        hostName: _hostName!,
        title: _streamTitle ?? 'Live Stream',
        isHost: isBroadcaster,
        agoraChannelName: channelName,
      );

      // Start broadcasting
      await _repository.startBroadcasting(
        channelName: channelName,
        isBroadcaster: isBroadcaster,
      );

      _currentSession = _repository.currentSession;
      _setStatus(StreamStatusType.live, 'Live stream started');

      // Start RTMP streams if any are configured
      if (isBroadcaster && _repository.getRtmpConfigs().isNotEmpty) {
        await _startRtmpStreams();
      }
    } catch (e) {
      _setError(
        StreamError(
          type: StreamErrorType.agoraConnectionFailed,
          message: 'Failed to start live stream',
          details: e.toString(),
        ),
      );
      _setStatus(
        StreamStatusType.error,
        'Failed to start live stream: ${e.toString()}',
      );
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _startRtmpStreams() async {
    _setStatus(StreamStatusType.rtmpConnecting, 'Connecting to platforms...');
    notifyListeners();

    try {
      await _repository.startAllRtmpStreams();
      _setStatus(StreamStatusType.rtmpConnected, 'Connected to all platforms');
    } catch (e) {
      _setError(
        StreamError(
          type: StreamErrorType.rtmpPushFailed,
          message: 'Failed to connect to RTMP platforms',
          details: e.toString(),
        ),
      );
      _setStatus(
        StreamStatusType.rtmpFailed,
        'Failed to connect to platforms: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  Future<void> stopLiveStream() async {
    _setStatus(StreamStatusType.ending, 'Ending live stream...');
    notifyListeners();

    try {
      await _repository.stopAllRtmpStreams();
      await _repository.stopBroadcasting();
      await _repository.endLiveSession();

      _currentSession = null;
      _setStatus(StreamStatusType.idle, 'Live stream ended');
      _hostName = null;
      _streamTitle = null;
    } catch (e) {
      _setError(
        StreamError(
          type: StreamErrorType.unknownError,
          message: 'Failed to stop live stream',
          details: e.toString(),
        ),
      );
      _setStatus(
        StreamStatusType.error,
        'Error stopping stream: ${e.toString()}',
      );
    } finally {
      notifyListeners();
    }
  }

  void _setStatus(StreamStatusType type, String message) {
    _streamStatus = StreamStatus(type: type, message: message);
    _lastError = null;
  }

  void _setError(StreamError error) {
    _lastError = error;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
