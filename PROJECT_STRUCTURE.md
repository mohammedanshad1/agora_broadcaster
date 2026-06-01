# Project Structure - MVVM Architecture

```
agora_broadcaster/
│
├── lib/
│   ├── main.dart                          # App entry point with Provider setup
│   │
│   ├── config/
│   │   ├── agora_config.dart              # Agora SDK and RTMP platform config
│   │   └── index.dart                     # Config exports
│   │
│   ├── models/                            # Data models and domain entities
│   │   ├── stream_status.dart             # Stream status types and model
│   │   ├── rtmp_stream_config.dart        # RTMP configuration model
│   │   ├── live_stream_session.dart       # Active stream session model
│   │   ├── stream_error.dart              # Error types and model
│   │   └── index.dart                     # Model exports
│   │
│   ├── services/                          # Business logic layer
│   │   ├── agora_service.dart             # Agora SDK wrapper
│   │   │   ├─ initialize()                # Initialize Agora engine
│   │   │   ├─ startBroadcasting()         # Start live streaming
│   │   │   ├─ stopBroadcasting()          # Stop live streaming
│   │   │   ├─ startRtmpStream()           # Start RTMP push
│   │   │   └─ stopRtmpStream()            # Stop RTMP push
│   │   │
│   │   ├── rtmp_service.dart              # RTMP streaming management
│   │   │   ├─ validateRtmpConfig()        # Validate RTMP URL/key
│   │   │   ├─ startStream()               # Start RTMP stream
│   │   │   ├─ stopStream()                # Stop RTMP stream
│   │   │   ├─ getStreamState()            # Get platform status
│   │   │   └─ getAllStreamStates()        # Get all platforms status
│   │   │
│   │   ├── permission_service.dart        # Permission handling
│   │   │   ├─ requestAllPermissions()     # Request camera/mic
│   │   │   ├─ hasAllPermissions()         # Check permissions
│   │   │   └─ openAppSettings()           # Open permission settings
│   │   │
│   │   └── index.dart                     # Service exports
│   │
│   ├── repositories/                      # Facade pattern - coordinates services
│   │   ├── stream_repository.dart         # Main business orchestration
│   │   │   ├─ Session Management          # Create/end live sessions
│   │   │   ├─ RTMP Configuration          # Add/remove/update configs
│   │   │   ├─ Broadcasting Control        # Start/stop streaming
│   │   │   ├─ RTMP Streaming              # Start/stop RTMP streams
│   │   │   └─ Stream State Tracking       # Monitor platform status
│   │   │
│   │   └── index.dart                     # Repository exports
│   │
│   ├── viewmodels/                        # UI logic with state management
│   │   ├── live_stream_view_model.dart    # Main streaming ViewModel
│   │   │   ├─ startLiveStream()           # Start broadcasting
│   │   │   ├─ stopLiveStream()            # Stop broadcasting
│   │   │   ├─ setHostName()               # Set host name
│   │   │   ├─ setStreamTitle()            # Set stream title
│   │   │   ├─ streamStatus (observable)   # Current stream status
│   │   │   ├─ currentSession (observable) # Active session data
│   │   │   ├─ isLive (observable)         # Is currently live
│   │   │   └─ lastError (observable)      # Last error occurred
│   │   │
│   │   ├── rtmp_config_view_model.dart    # RTMP config ViewModel
│   │   │   ├─ addConfig()                 # Add platform
│   │   │   ├─ removeConfig()              # Remove platform
│   │   │   ├─ updateConfig()              # Update platform
│   │   │   ├─ toggleConfig()              # Enable/disable platform
│   │   │   ├─ startStream()               # Start platform stream
│   │   │   ├─ stopStream()                # Stop platform stream
│   │   │   ├─ configs (observable)        # List of configurations
│   │   │   ├─ streamStates (observable)   # Platform statuses
│   │   │   └─ lastError (observable)      # Last config error
│   │   │
│   │   └── index.dart                     # ViewModel exports
│   │
│   ├── views/                             # Flutter UI layer
│   │   ├── home_screen.dart               # Role selection (Host/Audience)
│   │   ├── host_live_screen.dart          # Host interface
│   │   │   └─ Layout
│   │   │      ├─ Pre-live: Configure stream and RTMP
│   │   │      └─ Live: Monitor stream and platforms
│   │   │
│   │   ├── audience_live_screen.dart      # Audience view
│   │   │
│   │   ├── widgets/
│   │   │   ├── live_stream_status_widget.dart # Display stream info
│   │   │   └── index.dart
│   │   │
│   │   └── index.dart                     # View exports
│   │
│   ├── utils/                             # Utility functions
│   │   ├── constants.dart                 # App-wide constants
│   │   ├── helpers.dart                   # Validation, formatting, logging
│   │   └── index.dart                     # Utility exports
│   │
│   └── config/
│       └── index.dart                     # Config exports
│
├── android/                               # Android native code
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   │       └── main/AndroidManifest.xml   # Add permissions here
│   │
│   └── gradle.properties
│
├── ios/                                   # iOS native code
│   ├── Runner/
│   │   ├── Info.plist                     # Add permission descriptions
│   │   └── GeneratedPluginRegistrant.h/m
│   │
│   └── Podfile
│
├── pubspec.yaml                           # Flutter dependencies
├── analysis_options.yaml                  # Linting rules
├── project.md                             # Project requirements
├── IMPLEMENTATION_GUIDE.md                # This architecture guide
└── README.md                              # Project readme
```

## Layer Responsibilities

### Presentation Layer (Views)
- **Responsibility**: Render UI and handle user interactions
- **Awareness**: Only knows about ViewModels
- **Tools**: Flutter widgets, Provider consumers
- **Examples**:
  - HomeScreen: Render role selection buttons
  - HostLiveScreen: Render stream controls and platform list
  - AudienceLiveScreen: Display stream information

### Logic Layer (ViewModels)
- **Responsibility**: Handle business logic and state management
- **Awareness**: Services and Repositories via dependency injection
- **Tools**: ChangeNotifier, Provider state management
- **Examples**:
  - LiveStreamViewModel: Orchestrate start/stop stream
  - RTMPConfigViewModel: Manage RTMP configurations

### Domain Layer (Services)
- **Responsibility**: Implement specific features
- **Awareness**: External APIs (Agora, RTMP)
- **Tools**: SDK wrappers, HTTP clients
- **Examples**:
  - AgoraService: Direct Agora SDK calls
  - RTMPService: RTMP validation and state tracking
  - PermissionService: Permission requests

### Coordination Layer (Repository)
- **Responsibility**: Coordinate services and expose unified API
- **Awareness**: All services
- **Tools**: Service instances
- **Examples**:
  - Orchestrate Agora + RTMP for simultaneous streaming
  - Aggregate session data from multiple sources

### Data Layer (Models)
- **Responsibility**: Represent domain entities
- **Awareness**: No dependencies on other layers
- **Tools**: Equatable for equality, copyWith for immutability
- **Examples**:
  - StreamStatus: Status state and message
  - RTMPStreamConfig: Platform configuration

## Data Flow Examples

### Starting a Live Stream
```
User taps "Start Live" button (HostLiveScreen)
    ↓
LiveStreamViewModel.startLiveStream()
    ↓
StreamRepository.createLiveSession()
StreamRepository.startBroadcasting()
StreamRepository.startAllRtmpStreams()
    ↓
AgoraService.startBroadcasting()
RTMPService.startStream() ← for each config
    ↓
StreamStatus updates
    ↓
HostLiveScreen rebuilds with new status
```

### Adding RTMP Configuration
```
User enters platform details and taps "Add" (HostLiveScreen)
    ↓
RTMPConfigViewModel.addConfig()
    ↓
RTMPService.validateRtmpConfig()
StreamRepository.addRtmpConfig()
    ↓
RTMPConfigViewModel notifies listeners
    ↓
Widget rebuilds showing new platform in list
```

### Monitoring Stream Status
```
RTMP Platform connection changes
    ↓
RTMPService.startStream() updates stream state
    ↓
RTMPConfigViewModel.streamStates observable
    ↓
Platform status widget rebuilds
    ↓
User sees "Connected to YouTube" or error message
```

## Dependency Injection

Provider enables constructor injection:

```dart
// In main.dart
MultiProvider(
  providers: [
    // Create services first
    Provider(create: (_) => AgoraService(...)),
    Provider(create: (_) => RTMPService()),
    
    // Create repository with services
    ProxyProvider3<AgoraService, RTMPService, PermissionService, StreamRepository>(
      create: (context) => StreamRepository(
        agoraService: context.read<AgoraService>(),
        rtmpService: context.read<RTMPService>(),
        permissionService: context.read<PermissionService>(),
      ),
    ),
    
    // Create viewmodels with repository
    ChangeNotifierProxyProvider<StreamRepository, LiveStreamViewModel>(
      create: (context) => LiveStreamViewModel(
        repository: context.read<StreamRepository>()
      ),
    ),
  ],
)
```

Benefits:
- Easy to test (inject mocks)
- Loose coupling between layers
- Centralized configuration
- Automatic cleanup with Provider

## Testing Strategy

### Unit Tests (Services)
```dart
test('AgoraService initialization', () async {
  final service = AgoraService(agoraAppId: 'test-id');
  await service.initialize();
  expect(service.isInitialized, true);
});
```

### ViewModel Tests
```dart
test('LiveStreamViewModel starts stream', () async {
  final repo = MockStreamRepository();
  final vm = LiveStreamViewModel(repository: repo);
  
  await vm.startLiveStream(isBroadcaster: true);
  
  expect(vm.isLive, true);
  expect(vm.streamStatus.type, StreamStatusType.live);
});
```

### Widget Tests
```dart
testWidgets('HomeScreen shows role buttons', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  expect(find.text('Go Live as Host'), findsOneWidget);
  expect(find.text('Join as Audience'), findsOneWidget);
});
```

## Performance Considerations

1. **State Management**: Provider only rebuilds affected widgets
2. **Service Initialization**: Lazy load Agora on first use
3. **RTMP Connections**: Parallel stream connections with timeout
4. **Memory**: Dispose viewmodels to release Agora resources
5. **UI Updates**: Use Consumer for fine-grained subscriptions

## Error Recovery

1. **Agora Failures**: Retry connection with exponential backoff
2. **RTMP Failures**: Continue with other platforms if one fails
3. **Permission Errors**: Redirect to app settings
4. **Network Errors**: Show retry UI and queue operations

## Future Enhancements

1. **Persistence**: Store RTMP configs to local storage
2. **Analytics**: Track stream metrics (duration, viewers, bitrate)
3. **Scheduling**: Schedule live streams in advance
4. **Recording**: Record streams locally or to cloud
5. **Filters**: Add beauty filters and effects
6. **Chat**: Real-time chat during streams
7. **Monetization**: Donations and tips system
8. **Multi-host**: Multiple hosts in single stream
