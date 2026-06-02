import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../repositories/index.dart';
import '../services/index.dart';

class LiveStreamViewModel extends ChangeNotifier {
  final StreamRepository _repository;

  StreamStatus _streamStatus = StreamStatus(
    type: StreamStatusType.idle,
    message: 'Ready to start streaming',
  );

  LiveStreamSession? _currentSession;
  bool _isInitializing = false;
  String? _hostName;
  String? _streamTitle;
  StreamError? _lastError;

  // Remote user callbacks for audience
  Function(int)? onRemoteUserJoined;
  Function(int)? onRemoteUserLeft;

  LiveStreamViewModel({required StreamRepository repository})
    : _repository = repository {
    _repository.requestAllPermissions();
    _setupRemoteUserCallbacks();
  }

  void _setupRemoteUserCallbacks() {
    _repository.setRemoteUserCallbacks(
      onUserJoined: (uid) {
        print('✅ ViewModel: remote user joined $uid');
        onRemoteUserJoined?.call(uid);
        notifyListeners();
      },
      onUserLeft: (uid) {
        print('❌ ViewModel: remote user left $uid');
        onRemoteUserLeft?.call(uid);
        notifyListeners();
      },
    );
  }

  // Getters
  StreamStatus get streamStatus => _streamStatus;
  LiveStreamSession? get currentSession => _currentSession;
  bool get isInitializing => _isInitializing;
  bool get isLive => _streamStatus.type == StreamStatusType.live;
  StreamError? get lastError => _lastError;
  bool get isAgoraInitialized => _repository.isAgoraInitialized;
  List<int> get remoteUsers => _repository.remoteUsers;

  void setHostName(String name) {
    _hostName = name;
    notifyListeners();
  }

  void setStreamTitle(String title) {
    _streamTitle = title;
    notifyListeners();
  }

  Future<void> initialize() async {
    await _repository.initialize();
  }

  // In live_stream_viewmodel.dart
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
      final hasPermissions = await _repository.hasAllPermissions();
      if (!hasPermissions) {
        await _repository.requestAllPermissions();
      }

      final channelName = _hostName!.toLowerCase().trim().replaceAll(' ', '_');

      print('🎥 Starting live stream on channel: $channelName');

      await _repository.createLiveSession(
        hostName: _hostName!,
        title: _streamTitle ?? 'Live Stream',
        isHost: isBroadcaster,
        agoraChannelName: channelName,
      );

      await _repository.startBroadcasting(
        channelName: channelName,
        isBroadcaster: isBroadcaster,
      );

      _currentSession = _repository.currentSession;
      _setStatus(StreamStatusType.live, 'Live stream started');

      if (isBroadcaster && _repository.getRtmpConfigs().isNotEmpty) {
        await _startRtmpStreams();
      }
    } catch (e) {
      print('🔴 Error starting live stream: $e');
      _setError(
        StreamError(
          type: StreamErrorType.agoraConnectionFailed,
          message: 'Failed to start live stream',
          details: e.toString(),
        ),
      );
      _setStatus(StreamStatusType.error, 'Failed to start: ${e.toString()}');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> joinAsAudience(String channelName) async {
    _setStatus(StreamStatusType.initializing, 'Joining stream...');
    notifyListeners();

    try {
      print('👥 Joining as audience on channel: $channelName');

      await _repository.startBroadcasting(
        channelName: channelName,
        isBroadcaster: false,
      );

      await _repository.createLiveSession(
        hostName: 'Host',
        title: channelName,
        isHost: false,
        agoraChannelName: channelName,
      );

      _currentSession = _repository.currentSession;
      _setStatus(StreamStatusType.live, 'Connected to stream');
      print('✅ Audience successfully joined channel: $channelName');
    } catch (e) {
      print('🔴 Error joining as audience: $e');
      _setError(
        StreamError(
          type: StreamErrorType.agoraConnectionFailed,
          message: 'Failed to join stream',
          details: e.toString(),
        ),
      );
      _setStatus(StreamStatusType.error, 'Failed to join: ${e.toString()}');
    }
    notifyListeners();
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
        'Failed to connect: ${e.toString()}',
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

  // // ✅ Fixed: creates session so currentSession is never null after joining
  // Future<void> joinAsAudience(String channelName) async {
  //   _setStatus(StreamStatusType.initializing, 'Joining stream...');
  //   notifyListeners();

  //   try {
  //     await _repository.startBroadcasting(
  //       channelName: channelName,
  //       isBroadcaster: false,
  //     );

  //     // ✅ Create a session so AudienceLiveScreen doesn't show empty state
  //     await _repository.createLiveSession(
  //       hostName: 'Host',
  //       title: channelName,
  //       isHost: false,
  //       agoraChannelName: channelName,
  //     );

  //     _currentSession = _repository.currentSession;
  //     _setStatus(StreamStatusType.live, 'Connected to stream');
  //   } catch (e) {
  //     _setError(
  //       StreamError(
  //         type: StreamErrorType.agoraConnectionFailed,
  //         message: 'Failed to join stream',
  //         details: e.toString(),
  //       ),
  //     );
  //     _setStatus(StreamStatusType.error, 'Failed to join: ${e.toString()}');
  //   }
  //   notifyListeners();
  // }

  Future<void> leaveAudience() async {
    await _repository.stopBroadcasting();
    _currentSession = null; // ✅ clear session on leave
    _setStatus(StreamStatusType.idle, 'Left the stream');
    notifyListeners();
  }

  Future<void> setupRemoteVideo(int uid) async {
    await _repository.setupRemoteVideo(uid);
  }

  RtcEngine getRtcEngine() {
    return _repository.getRtcEngine();
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
