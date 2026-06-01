import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/index.dart';

class AgoraService {
  late RtcEngine _engine;
  final String agoraAppId;
  
  int _localUid = 0;
  bool _isInitialized = false;

  // Callbacks
  Function(int)? onUserJoined;
  Function(int)? onUserOffline;
  Function(String)? onConnectionStateChanged;
  Function(StreamError)? onError;

  AgoraService({required this.agoraAppId});

  bool get isInitialized => _isInitialized;
  int get localUid => _localUid;

  Future<void> initialize() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.liveBroadcasting,
      ));

      // Setup event listeners
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _localUid = connection.localUid;
            onConnectionStateChanged?.call('Joined channel');
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            onUserOffline?.call(remoteUid);
          },
          onError: (err, msg) {
            onError?.call(StreamError(
              type: StreamErrorType.agoraConnectionFailed,
              message: 'Agora Error',
              details: msg,
            ));
          },
        ),
      );

      _isInitialized = true;
    } catch (e) {
      onError?.call(StreamError(
        type: StreamErrorType.unknownError,
        message: 'Failed to initialize Agora',
        details: e.toString(),
      ));
    }
  }

  Future<void> startBroadcasting({
    required String channelName,
    required bool isBroadcaster,
  }) async {
    try {
      await _engine.setClientRole(
        role: isBroadcaster
            ? ClientRoleType.broadcaster
            : ClientRoleType.audience,
      );

      await _engine.enableVideo();
      await _engine.startPreview();

      await _engine.joinChannel(
        token: '',
        channelName: channelName,
        uid: 0,
        options: const RtcChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: isBroadcaster,
          publishMicrophoneTrack: isBroadcaster,
        ),
      );

      onConnectionStateChanged?.call('Broadcasting started');
    } catch (e) {
      onError?.call(StreamError(
        type: StreamErrorType.agoraConnectionFailed,
        message: 'Failed to start broadcasting',
        details: e.toString(),
      ));
    }
  }

  Future<void> addTranscodingUser({
    required int uid,
  }) async {
    try {
      await _engine.startRtmpStreamWithTranscoding(
        url: '', // Will be set by RTMP service
        transcoding: LiveTranscoding(
          videoCodecProfile: VideoCodecProfileType.main,
          width: 360,
          height: 640,
          bitrate: 1000,
          frameRate: 30,
          audioChannels: 2,
          audioBitrate: 48,
          audioSampleRate: AudioSampleRateType.asr48000,
          users: [
            TranscodingUser(
              uid: uid,
              x: 0,
              y: 0,
              width: 360,
              height: 640,
            ),
          ],
        ),
      );
    } catch (e) {
      onError?.call(StreamError(
        type: StreamErrorType.rtmpPushFailed,
        message: 'Failed to add transcoding user',
        details: e.toString(),
      ));
    }
  }

  Future<void> stopBroadcasting() async {
    try {
      await _engine.leaveChannel();
      await _engine.stopPreview();
    } catch (e) {
      onError?.call(StreamError(
        type: StreamErrorType.unknownError,
        message: 'Failed to stop broadcasting',
        details: e.toString(),
      ));
    }
  }

  Future<void> startRtmpStream(String rtmpUrl) async {
    try {
      await _engine.startRtmpStreamWithoutTranscoding(rtmpUrl);
    } catch (e) {
      onError?.call(StreamError(
        type: StreamErrorType.rtmpPushFailed,
        message: 'Failed to start RTMP stream',
        details: e.toString(),
      ));
    }
  }

  Future<void> stopRtmpStream(String rtmpUrl) async {
    try {
      await _engine.stopRtmpStream(rtmpUrl);
    } catch (e) {
      onError?.call(StreamError(
        type: StreamErrorType.unknownError,
        message: 'Failed to stop RTMP stream',
        details: e.toString(),
      ));
    }
  }

  Future<void> dispose() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
      _isInitialized = false;
    } catch (e) {
      // Ignore errors during dispose
    }
  }
}
