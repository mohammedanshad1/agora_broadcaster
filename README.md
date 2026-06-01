# Agora Live Broadcaster

A professional Flutter application for live streaming using **Agora SDK** with **RTMP cross-platform restreaming** support. Built with **MVVM architecture** for clean, maintainable, and scalable code.

## Features

🎥 **Live Streaming**
- Host broadcasting with Agora
- Real-time audience viewing
- Video and audio streaming
- Stream session management

📡 **Multi-Platform RTMP Support**
- YouTube Live
- Facebook Live
- Instagram Live
- Twitch
- Custom RTMP servers

🛡️ **Robust Error Handling**
- Comprehensive error types
- User-friendly messages
- Connection validation
- Graceful failure recovery

📊 **Professional UI/UX**
- Role-based interfaces (Host/Audience)
- Real-time status monitoring
- Platform connection tracking
- Stream information display

🏗️ **Clean Architecture**
- MVVM pattern with separation of concerns
- Provider-based state management
- Dependency injection
- Testable components

## Quick Start

### Prerequisites
- Flutter 3.7.0+
- Dart 3.7.0+
- Agora Account (free)

### Setup
1. Clone repository
2. Run `flutter pub get`
3. Get [Agora App ID](https://console.agora.io/)
4. Update `lib/main.dart` with your App ID
5. Run `flutter run`

**Detailed instructions**: See [QUICKSTART.md](QUICKSTART.md)

## Project Structure

```
lib/
├── main.dart           # App entry point with Provider setup
├── models/             # Data models (StreamStatus, RTMPStreamConfig, etc.)
├── services/           # Business logic (Agora, RTMP, Permissions)
├── repositories/       # Service coordination
├── viewmodels/         # State management (LiveStream, RTMPConfig)
├── views/              # UI screens and widgets
├── config/             # Configuration constants
└── utils/              # Helpers and utilities
```

**Full details**: See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

## Architecture

### MVVM Pattern
```
View (UI) ↔ ViewModel (Logic) ↔ Repository ↔ Services ↔ External APIs
```

### Key Components

**Models**: Domain entities
- `StreamStatus` - Stream state tracking
- `RTMPStreamConfig` - Platform configuration
- `LiveStreamSession` - Active session data
- `StreamError` - Error information

**Services**: Business logic
- `AgoraService` - Agora SDK wrapper
- `RTMPService` - RTMP management
- `PermissionService` - Permission handling

**ViewModels**: State management
- `LiveStreamViewModel` - Broadcasting logic
- `RTMPConfigViewModel` - Platform management

**Views**: User interface
- `HomeScreen` - Role selection
- `HostLiveScreen` - Host interface
- `AudienceLiveScreen` - Audience view

**See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for detailed documentation**

## Usage Examples

### Start Live Stream
```dart
Consumer<LiveStreamViewModel>(
  builder: (context, viewModel, _) {
    return ElevatedButton(
      onPressed: () {
        viewModel.setHostName('John Doe');
        viewModel.setStreamTitle('My Stream');
        viewModel.startLiveStream(isBroadcaster: true);
      },
      child: Text('Start Live'),
    );
  },
)
```

### Add RTMP Platform
```dart
Consumer<RTMPConfigViewModel>(
  builder: (context, rtmpVM, _) {
    return ElevatedButton(
      onPressed: () {
        rtmpVM.addConfig(
          platform: StreamPlatform.youtube,
          platformName: 'YouTube',
          rtmpUrl: 'rtmp://a.rtmp.youtube.com/live2',
          streamKey: 'your-stream-key',
        );
      },
      child: Text('Add YouTube'),
    );
  },
)
```

### Monitor Stream Status
```dart
Consumer<RTMPConfigViewModel>(
  builder: (context, rtmpVM, _) {
    return ListView(
      children: rtmpVM.streamStates.map((state) {
        return ListTile(
          title: Text(state.config.platformName),
          subtitle: Text(state.statusText),
        );
      }).toList(),
    );
  },
)
```

## State Management

The app uses **Provider** for reactive state management:

```dart
MultiProvider(
  providers: [
    Provider(create: (_) => AgoraService(agoraAppId: agoraAppId)),
    Provider(create: (_) => RTMPService()),
    Provider(create: (_) => PermissionService()),
    ProxyProvider3<AgoraService, RTMPService, PermissionService, StreamRepository>(
      create: (context) => StreamRepository(...),
    ),
    ChangeNotifierProxyProvider<StreamRepository, LiveStreamViewModel>(...),
    ChangeNotifierProxyProvider<StreamRepository, RTMPConfigViewModel>(...),
  ],
)
```

## Error Handling

Comprehensive error types:
- `invalidRtmpUrl` - Invalid RTMP URL format
- `invalidStreamKey` - Invalid stream key
- `agoraConnectionFailed` - Agora connection error
- `rtmpPushFailed` - RTMP platform connection failed
- `permissionDenied` - Permission not granted
- `networkError` - Network connectivity issue
- `unknownError` - Unexpected error

Access errors:
```dart
if (viewModel.lastError != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(viewModel.lastError!.message)),
  );
}
```

## Configuration

### Agora Settings
File: `lib/config/agora_config.dart`
- App ID: Set in `main.dart`
- Video: 360x640 @ 30fps @ 1000kbps
- Audio: 2 channels @ 48kHz

### Platforms
```dart
YouTube: rtmp://a.rtmp.youtube.com/live2
Facebook: rtmps://live-api-s.facebook.com:443/rtmp/
Instagram: rtmps://live-api-s.instagram.com:443/rtmp/
Twitch: rtmp://live.twitch.tv/app
```

## Permissions

### Android
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access</string>
```

## Dependencies

```yaml
dependencies:
  agora_rtc_engine: ^6.2.0    # Agora SDK
  permission_handler: ^11.4.4 # Permissions
  provider: ^6.0.0            # State management
  uuid: ^4.0.0                # ID generation
  equatable: ^2.0.5           # Value equality
  dio: ^5.4.0                 # HTTP client
```

## Testing

The architecture supports comprehensive testing:

**Unit Tests**
```dart
test('AgoraService initialization', () async {
  final service = AgoraService(agoraAppId: 'test-id');
  await service.initialize();
  expect(service.isInitialized, true);
});
```

**Widget Tests**
```dart
testWidgets('HomeScreen shows role buttons', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Go Live as Host'), findsOneWidget);
});
```

**Integration Tests** - Complete user flows

## Troubleshooting

### App ID Error
- Get free App ID from [Agora Console](https://console.agora.io/)
- Update `lib/main.dart` with your ID

### Permission Denied
- **Android**: Settings > App > Permissions > Enable Camera/Microphone
- **iOS**: Settings > Agora Broadcaster > Enable Camera/Microphone

### RTMP Failed
- Verify RTMP URL format (rtmp:// or rtmps://)
- Check stream key is correct
- Confirm platform account is active

### Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

See [QUICKSTART.md](QUICKSTART.md) for more troubleshooting.

## Performance

- **Optimized rebuilds**: Provider only rebuilds affected widgets
- **Lazy loading**: Services initialized on demand
- **Concurrent streams**: Multiple platform uploads simultaneously
- **Memory efficient**: Proper resource cleanup

## Best Practices

1. Always set Agora App ID before running
2. Request permissions on startup
3. Validate RTMP configs before streaming
4. Monitor stream status during broadcast
5. Gracefully handle connection failures
6. Clean up resources when ending stream

## Architecture Patterns

- **MVVM**: Model-View-ViewModel pattern
- **Repository**: Facade for service coordination
- **Dependency Injection**: Provider for service management
- **Observable State**: ChangeNotifier for reactive updates
- **Error Handling**: Result types with comprehensive errors

## Future Enhancements

- 📱 Mobile-specific optimizations
- 💬 Real-time chat during streams
- 🎨 Beauty filters and effects
- 💾 Stream recording
- 📊 Analytics dashboard
- 🎯 Scheduled streams
- 👥 Multi-host support

## Documentation

- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Detailed architecture
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - File organization
- [QUICKSTART.md](QUICKSTART.md) - Setup guide
- [SUMMARY.md](SUMMARY.md) - Implementation summary

## Support

- [Agora Docs](https://docs.agora.io/)
- [Flutter Docs](https://flutter.dev/docs)
- [Provider Docs](https://pub.dev/packages/provider)

## License

This project is provided as-is for educational and commercial use.

## Author

Flutter Developer - Agora Live Broadcasting Implementation

---

## Getting Help

1. **Check logs** - Look for error messages in console
2. **Review docs** - See documentation files in project
3. **Verify setup** - Ensure App ID and permissions are configured
4. **Test step-by-step** - Isolate issues by testing individual components

---

**Ready to stream?** Follow [QUICKSTART.md](QUICKSTART.md) to get started! 🎬

