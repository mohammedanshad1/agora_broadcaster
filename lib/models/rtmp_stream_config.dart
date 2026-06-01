import 'package:equatable/equatable.dart';

enum StreamPlatform {
  youtube,
  facebook,
  instagram,
  twitch,
  custom,
}

class RTMPStreamConfig extends Equatable {
  final String id;
  final StreamPlatform platform;
  final String platformName;
  final String rtmpUrl;
  final String streamKey;
  final bool enabled;

  const RTMPStreamConfig({
    required this.id,
    required this.platform,
    required this.platformName,
    required this.rtmpUrl,
    required this.streamKey,
    this.enabled = true,
  });

  String get fullStreamUrl => '$rtmpUrl/$streamKey';

  RTMPStreamConfig copyWith({
    String? id,
    StreamPlatform? platform,
    String? platformName,
    String? rtmpUrl,
    String? streamKey,
    bool? enabled,
  }) {
    return RTMPStreamConfig(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      platformName: platformName ?? this.platformName,
      rtmpUrl: rtmpUrl ?? this.rtmpUrl,
      streamKey: streamKey ?? this.streamKey,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props =>
      [id, platform, platformName, rtmpUrl, streamKey, enabled];
}
