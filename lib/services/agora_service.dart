import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/index.dart';

class AgoraService extends ChangeNotifier {
  RtcEngine? _engine;
  final String agoraAppId;

  int _localUid = 0;
  bool _isInitialized = false;
  bool _isCameraEnabled = false;
  bool _isInitializing = false;

  // Callbacks
  Function(int)? onUserJoined;
  Function(int)? onUserOffline;
  Function(String)? onConnectionStateChanged;
  Function(StreamError)? onError;

  AgoraService({required this.agoraAppId});

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  int get localUid => _localUid;

  RtcEngine getRtcEngine() {
    if (_engine == null) {
      throw Exception('Agora engine not initialized. Call initialize() first.');
    }
    return _engine!;
  }

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Setup event listeners
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _localUid = connection.localUid ?? 0;
            onConnectionStateChanged?.call('Joined channel');
            notifyListeners();
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            onUserOffline?.call(remoteUid);
          },
          onError: (err, msg) {
            onError?.call(
              StreamError(
                type: StreamErrorType.agoraConnectionFailed,
                message: 'Agora Error: $err',
                details: msg,
              ),
            );
          },
          onCameraReady: () {
            print('Camera is ready');
            onConnectionStateChanged?.call('Camera ready');
            notifyListeners();
          },
        ),
      );

      _isInitialized = true;
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _isInitializing = false;
      onError?.call(
        StreamError(
          type: StreamErrorType.unknownError,
          message: 'Failed to initialize Agora',
          details: e.toString(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> startBroadcasting({
    required String channelName,
    required bool isBroadcaster,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Set client role first
      await _engine!.setClientRole(
        role:
            isBroadcaster
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
      );

      // Enable video for broadcaster
      if (isBroadcaster) {
        await _enableCameraAndMicrophone();
      }

      // Join channel with correct media options
      await _engine!.joinChannel(
        token: '', // For testing without token, leave empty
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: isBroadcaster,
          publishMicrophoneTrack: isBroadcaster,
        ),
      );

      onConnectionStateChanged?.call('Broadcasting started');
      notifyListeners();
    } catch (e) {
      onError?.call(
        StreamError(
          type: StreamErrorType.agoraConnectionFailed,
          message: 'Failed to start broadcasting',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _enableCameraAndMicrophone() async {
    try {
      // Enable video module
      await _engine!.enableVideo();

      // Enable local video
      await _engine!.enableLocalVideo(true);

      // Enable local audio
      await _engine!.enableLocalAudio(true);

      // Set video encoder configuration for better quality
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 720, height: 1280),
          frameRate: 30,
          bitrate: 1200,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      // Setup local video for preview
      await _engine!.setupLocalVideo(
        const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden),
      );

      // Start preview after enabling video
      await _engine!.startPreview();
      _isCameraEnabled = true;

      onConnectionStateChanged?.call('Camera and microphone enabled');
      notifyListeners();
    } catch (e) {
      print('Error enabling camera: $e');
      rethrow;
    }
  }

  Future<void> stopBroadcasting() async {
    try {
      if (_isCameraEnabled) {
        await _engine?.stopPreview();
        await _engine?.muteLocalVideoStream(true);
        await _engine?.muteLocalAudioStream(true);
        _isCameraEnabled = false;
      }

      await _engine?.leaveChannel();
      notifyListeners();
    } catch (e) {
      onError?.call(
        StreamError(
          type: StreamErrorType.unknownError,
          message: 'Failed to stop broadcasting',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> startRtmpStream(String rtmpUrl) async {
    try {
      await _engine!.startRtmpStreamWithoutTranscoding(rtmpUrl);
    } catch (e) {
      onError?.call(
        StreamError(
          type: StreamErrorType.rtmpPushFailed,
          message: 'Failed to start RTMP stream',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> stopRtmpStream(String rtmpUrl) async {
    try {
      await _engine!.stopRtmpStream(rtmpUrl);
    } catch (e) {
      onError?.call(
        StreamError(
          type: StreamErrorType.unknownError,
          message: 'Failed to stop RTMP stream',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> dispose() async {
    try {
      if (_isCameraEnabled) {
        await _engine?.stopPreview();
        await _engine?.muteLocalVideoStream(true);
        await _engine?.muteLocalAudioStream(true);
      }
      await _engine?.leaveChannel();
      await _engine?.release();
      _isInitialized = false;
      _isCameraEnabled = false;
      _engine = null;
    } catch (e) {
      // Ignore errors during dispose
    }
  }
}
