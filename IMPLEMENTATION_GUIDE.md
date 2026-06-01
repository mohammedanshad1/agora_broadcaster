# Agora Live Broadcaster - MVVM Architecture Implementation

## Overview

This Flutter application implements a live streaming solution using **Agora SDK** with **RTMP/CDN push** for cross-platform broadcasting. The architecture follows **MVVM (Model-View-ViewModel)** pattern with clear separation of concerns.

## Architecture Layers

### 1. **Models** (`lib/models/`)
Data classes representing the domain entities:

- **StreamStatus**: Enum and model tracking stream state and messages
  - States: idle, initializing, live, rtmpConnecting, rtmpConnected, rtmpFailed, ending, error

- **RTMPStreamConfig**: Configuration for RTMP streaming to external platforms
  - Platforms: YouTube, Facebook, Instagram, Twitch, Custom
  - Properties: RTMP URL, stream key, enabled/disabled

- **LiveStreamSession**: Active stream session data
  - Host name, title, channel name
  - Session duration tracking
  - Associated RTMP configurations

- **StreamError**: Error handling with detailed information
  - Error types: invalidRtmpUrl, invalidStreamKey, agoraConnectionFailed, rtmpPushFailed, etc.

### 2. **Services** (`lib/services/`)
Business logic layer managing external integrations:

- **AgoraService**: Agora SDK integration
  - Initialize and manage Agora engine
  - Handle user join/leave events
  - Start/stop broadcasting
  - Manage RTMP transcoding

- **RTMPService**: RTMP streaming management
  - Validate RTMP URLs and stream keys
  - Manage stream connection states
  - Track individual platform statuses

- **PermissionService**: Runtime permissions handling
  - Request camera and microphone permissions
  - Check permission status

### 3. **Repository** (`lib/repositories/`)
Facade pattern coordinating all services:

- **StreamRepository**: Single source of truth
  - Coordinates between Agora, RTMP, and Permission services
  - Manages session lifecycle
  - Handles RTMP configuration storage
  - Aggregates data from multiple services

### 4. **ViewModels** (`lib/viewmodels/`)
UI logic and state management using Provider:

- **LiveStreamViewModel**: Live streaming state and actions
  - Input: host name, stream title
  - Actions: start/stop broadcasting, manage RTMP streams
  - Outputs: stream status, errors, session data
  - Notifies UI of state changes

- **RTMPConfigViewModel**: RTMP configuration management
  - Add/remove/update RTMP configurations
  - Validate configurations
  - Manage stream states per platform
  - Toggle platform streaming on/off

### 5. **Views** (`lib/views/`)
Flutter UI screens:

- **HomeScreen**: Role selection (Host/Audience)
- **HostLiveScreen**: Host interface with stream controls and platform management
- **AudienceLiveScreen**: Audience view showing active stream info
- **Widgets**: Reusable UI components (LiveStreamStatusWidget)

## Data Flow

```
User Interaction
      ↓
  View (UI)
      ↓
ViewModel (Logic & State)
      ↓
Repository (Orchestration)
      ↓
Services (Implementation)
      ↓
External APIs (Agora, RTMP)
```

## Key Features

### 1. Live Streaming
```dart
// Host starts live
viewModel.startLiveStream(isBroadcaster: true)
  ├─ Check permissions
  ├─ Create Agora session
  ├─ Start broadcasting
  └─ Return to Live screen

// Audience joins
viewModel.startLiveStream(isBroadcaster: false)
  └─ Join Agora channel in audience mode
```

### 2. RTMP Cross-Platform Streaming
```dart
// Add platform configuration
rtmpVM.addConfig(
  platform: StreamPlatform.youtube,
  rtmpUrl: 'rtmp://a.rtmp.youtube.com/live2',
  streamKey: 'your-stream-key',
)

// Start all configured streams when host goes live
repository.startAllRtmpStreams()
  ├─ Validate each configuration
  ├─ Start RTMP connection per platform
  └─ Track individual platform statuses
```

### 3. Error Handling
```dart
// Comprehensive error tracking
StreamError(
  type: StreamErrorType.rtmpPushFailed,
  message: 'Failed to connect to YouTube',
  details: 'Invalid stream key format',
)
```

### 4. State Management
- **Provider**: Reactive state management with ChangeNotifier
- **Separation**: Each ViewModel manages specific domain (streaming vs RTMP config)
- **Notifications**: Automatic UI rebuild on state changes

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Agora
1. Get your Agora App ID from [Agora Console](https://console.agora.io/)
2. Update `lib/main.dart`:
```dart
const String agoraAppId = 'YOUR_AGORA_APP_ID';
```

### 3. Android Configuration
Add to `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        targetSdkVersion 34
    }
}
```

### 4. iOS Configuration
Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

### 5. Add Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to broadcast live</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to broadcast live</string>
```

## Usage Example

### Starting a Live Stream as Host
```dart
// In HostLiveScreen
Consumer<LiveStreamViewModel>(
  builder: (context, viewModel, _) {
    return ElevatedButton(
      onPressed: () {
        viewModel.setHostName('John Doe');
        viewModel.setStreamTitle('My Live Stream');
        viewModel.startLiveStream(isBroadcaster: true);
      },
      child: Text('Start Live'),
    );
  },
)
```

### Adding RTMP Configuration
```dart
// In HostLiveScreen
Consumer<RTMPConfigViewModel>(
  builder: (context, rtmpVM, _) {
    return ElevatedButton(
      onPressed: () async {
        await rtmpVM.addConfig(
          platform: StreamPlatform.youtube,
          platformName: 'YouTube',
          rtmpUrl: 'rtmp://a.rtmp.youtube.com/live2',
          streamKey: userInputStreamKey,
        );
      },
      child: Text('Add YouTube'),
    );
  },
)
```

### Monitoring Stream Status
```dart
Consumer<LiveStreamViewModel>(
  builder: (context, viewModel, _) {
    return Text(viewModel.streamStatus.message);
  },
)

Consumer<RTMPConfigViewModel>(
  builder: (context, rtmpVM, _) {
    final states = rtmpVM.streamStates;
    return ListView.builder(
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        return ListTile(
          title: Text(state.config.platformName),
          subtitle: Text(state.statusText),
        );
      },
    );
  },
)
```

## Error Handling

The application handles multiple error types:

```dart
enum StreamErrorType {
  invalidRtmpUrl,        // Invalid RTMP URL format
  invalidStreamKey,      // Empty or invalid stream key
  agoraConnectionFailed, // Agora SDK connection error
  rtmpPushFailed,        // RTMP platform connection failed
  permissionDenied,      // Camera/microphone permission denied
  networkError,          // Network connectivity issue
  unknownError,          // Unexpected error
}
```

Access errors:
```dart
if (viewModel.lastError != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(text: viewModel.lastError!.message),
  );
  viewModel.clearError();
}
```

## Configuration

### Agora Settings (`lib/config/agora_config.dart`)
- Video resolution: 360x640
- Frame rate: 30 fps
- Bitrate: 1000 kbps
- Audio: 2 channels, 48 kHz

### RTMP Platform URLs
```dart
YouTube: rtmp://a.rtmp.youtube.com/live2
Facebook: rtmps://live-api-s.facebook.com:443/rtmp/
Instagram: rtmps://live-api-s.instagram.com:443/rtmp/
Twitch: rtmp://live.twitch.tv/app
```

## Testing

### Test Host Broadcasting
1. Select "Go Live as Host"
2. Enter name and title
3. Add YouTube RTMP configuration
4. Click "Start Live"
5. Verify Agora status and RTMP connection

### Test Audience Join
1. Run app on another device/emulator
2. Select "Join as Audience"
3. Verify live stream visibility

### Test RTMP Validation
1. Try adding invalid RTMP URL
2. Verify error message appears
3. Try empty stream key
4. Verify rejection

## Extension Points

### Add New Platform
```dart
// 1. Add to StreamPlatform enum
enum StreamPlatform {
  youtube,
  facebook,
  instagram,
  twitch,
  customPlatform, // NEW
}

// 2. Update configuration
static const Map<String, String> rtmpServers = {
  'YouTube': '...',
  'Custom Platform': 'rtmp://custom.platform/live',
};

// 3. UI automatically supports it
```

### Custom Stream Processing
```dart
// Extend RTMPService
class CustomRTMPService extends RTMPService {
  @override
  Future<void> startStream(RTMPStreamConfig config) async {
    // Custom logic here
    await super.startStream(config);
  }
}
```

## Best Practices

1. **Always dispose ViewModels**: They clean up Agora resources
2. **Validate RTMP URLs**: Before starting streams
3. **Handle permissions gracefully**: Request at startup
4. **Monitor stream status**: Show real-time feedback
5. **Graceful error recovery**: Allow retry mechanisms
6. **Clean session end**: Stop all RTMP streams before ending

## Troubleshooting

**Agora Connection Failed**
- Check App ID is correct
- Verify network connectivity
- Check firewall/NAT settings

**RTMP Push Failed**
- Verify RTMP URL format (rtmp:// or rtmps://)
- Check stream key validity
- Confirm platform credentials
- Check upload bandwidth

**Permission Denied**
- User rejected permission request
- Check app has runtime permission
- Request permissions at startup

**Empty Stream States**
- Ensure RTMP configs added before start
- Check configuration validity
- Monitor platform status UI

## References

- [Agora Flutter SDK](https://pub.dev/packages/agora_rtc_engine)
- [Provider Package](https://pub.dev/packages/provider)
- [Flutter Architecture](https://flutter.dev/docs/development/architecture)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
