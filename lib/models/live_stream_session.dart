import 'package:equatable/equatable.dart';
import 'rtmp_stream_config.dart';

class LiveStreamSession extends Equatable {
  final String id;
  final String agoraChannelName;
  final int agoraUid;
  final String hostName;
  final String title;
  final DateTime startTime;
  final bool isHost;
  final List<RTMPStreamConfig> rtmpConfigs;

  const LiveStreamSession({
    required this.id,
    required this.agoraChannelName,
    required this.agoraUid,
    required this.hostName,
    required this.title,
    required this.startTime,
    required this.isHost,
    this.rtmpConfigs = const [],
  });

  Duration get duration => DateTime.now().difference(startTime);

  LiveStreamSession copyWith({
    String? id,
    String? agoraChannelName,
    int? agoraUid,
    String? hostName,
    String? title,
    DateTime? startTime,
    bool? isHost,
    List<RTMPStreamConfig>? rtmpConfigs,
  }) {
    return LiveStreamSession(
      id: id ?? this.id,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
      agoraUid: agoraUid ?? this.agoraUid,
      hostName: hostName ?? this.hostName,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      isHost: isHost ?? this.isHost,
      rtmpConfigs: rtmpConfigs ?? this.rtmpConfigs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        agoraChannelName,
        agoraUid,
        hostName,
        title,
        startTime,
        isHost,
        rtmpConfigs,
      ];
}
