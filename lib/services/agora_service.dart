import 'package:agora_broadcaster/config/agora_config.dart';
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
  List<int> _remoteUsers = [];
  String? _currentChannelId; // ✅ track current channel

  // Callbacks
  Function(int)? onUserJoined;
  Function(int)? onUserOffline;
  Function(String)? onConnectionStateChanged;
  Function(StreamError)? onError;
  Function(int)? onRemoteUserJoined;
  Function(int)? onRemoteUserLeft;

  AgoraService({required this.agoraAppId});

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  int get localUid => _localUid;
  List<int> get remoteUsers => List.unmodifiable(_remoteUsers);
  String? get currentChannelId => _currentChannelId;

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

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _localUid = connection.localUid ?? 0;
            _currentChannelId = connection.channelId;
            print(
              '✅ Joined channel: ${connection.channelId} as uid: $_localUid',
            );
            onConnectionStateChanged?.call('Joined channel');
            notifyListeners();
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            print(
              '✅ Remote user $remoteUid joined channel ${connection.channelId}',
            );
            if (!_remoteUsers.contains(remoteUid)) {
              _remoteUsers.add(remoteUid);
            }
            onRemoteUserJoined?.call(remoteUid);
            onUserJoined?.call(remoteUid);
            notifyListeners();
          },
          onUserOffline: (connection, remoteUid, reason) {
            print('❌ Remote user $remoteUid left: $reason');
            _remoteUsers.remove(remoteUid);
            onRemoteUserLeft?.call(remoteUid);
            onUserOffline?.call(remoteUid);
            notifyListeners();
          },
          onRemoteVideoStateChanged: (
            connection,
            remoteUid,
            state,
            reason,
            elapsed,
          ) {
            // ✅ fires when host video starts/stops — useful for debugging
            print(
              '📹 Remote video state changed: uid=$remoteUid state=$state reason=$reason',
            );
          },
          onConnectionStateChanged: (connection, state, reason) {
            print('🔗 Connection state: $state reason: $reason');
          },
          onError: (err, msg) {
            print('🔴 Agora error: $err — $msg');
            onError?.call(
              StreamError(
                type: StreamErrorType.agoraConnectionFailed,
                message: 'Agora Error: $err',
                details: msg,
              ),
            );
          },
          onCameraReady: () {
            print('📷 Camera is ready');
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
      print('🔴 Agora init failed: $e');
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
  // In AgoraService.startBroadcasting method, update the audience section:

  Future<void> startBroadcasting({
    required String channelName,
    required bool isBroadcaster,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _engine!.setClientRole(
        role:
            isBroadcaster
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
      );

      // Always enable video for both broadcaster and audience
      await _engine!.enableVideo();

      if (isBroadcaster) {
        await _enableCameraAndMicrophone();
      } else {
        // For audience, just enable video but not camera
        await _engine!.enableLocalVideo(false);
        await _engine!.enableLocalAudio(false);
      }

      print('🔑 Using token for channel: $channelName');
      print('🔗 Joining as ${isBroadcaster ? "Broadcaster" : "Audience"}');

      // Use the temporary token from config
      await _engine!.joinChannel(
        token: AgoraConfig.tempToken, // 👈 Using your generated token
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: isBroadcaster,
          publishMicrophoneTrack: isBroadcaster,
          clientRoleType:
              isBroadcaster
                  ? ClientRoleType.clientRoleBroadcaster
                  : ClientRoleType.clientRoleAudience,
        ),
      );

      print('✅ Successfully joined channel: $channelName');
      onConnectionStateChanged?.call('Broadcasting started');
      notifyListeners();
    } catch (e) {
      print('🔴 startBroadcasting error: $e');
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
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.enableLocalAudio(true);

      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 720, height: 1280),
          frameRate: 30,
          bitrate: 1200,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      await _engine!.setupLocalVideo(
        const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden),
      );

      await _engine!.startPreview();
      _isCameraEnabled = true;

      onConnectionStateChanged?.call('Camera and microphone enabled');
      notifyListeners();
    } catch (e) {
      print('🔴 Error enabling camera: $e');
      rethrow;
    }
  }

  Future<void> setupRemoteVideo(int uid) async {
    if (_engine == null) return;

    try {
      // ✅ Use renderModeFit so video fills the view correctly
      await _engine!.setupRemoteVideo(
        VideoCanvas(uid: uid, renderMode: RenderModeType.renderModeFit),
      );
      print('✅ Remote video setup for uid: $uid');
    } catch (e) {
      print('🔴 Error setting up remote video: $e');
    }
  }

  Future<void> muteRemoteAudio(int uid, bool muted) async {
    if (_engine == null) return;
    try {
      await _engine!.muteRemoteAudioStream(uid: uid, mute: muted);
    } catch (e) {
      print('Error muting remote audio: $e');
    }
  }

  Future<void> addTranscodingUser({required int uid}) async {
    try {
      await _engine!.startRtmpStreamWithTranscoding(
        url: '',
        transcoding: LiveTranscoding(
          videoCodecProfile: VideoCodecProfileType.videoCodecProfileMain,
          width: 360,
          height: 640,
          videoBitrate: 1000,
          videoFramerate: 30,
          audioChannels: 2,
          audioBitrate: 48,
          audioSampleRate: AudioSampleRateType.audioSampleRate48000,
          transcodingUsers: [
            TranscodingUser(uid: uid, x: 0, y: 0, width: 360, height: 640),
          ],
        ),
      );
    } catch (e) {
      onError?.call(
        StreamError(
          type: StreamErrorType.rtmpPushFailed,
          message: 'Failed to add transcoding user',
          details: e.toString(),
        ),
      );
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
      _remoteUsers.clear();
      _currentChannelId = null;
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
      _remoteUsers.clear();
      _currentChannelId = null;
      _engine = null;
    } catch (e) {
      // Ignore errors during dispose
    }
  }
}
