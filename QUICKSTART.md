# Quick Start Guide

## Prerequisites
- Flutter SDK 3.7.0 or higher
- Dart 3.7.0 or higher
- Agora Developer Account (free at https://console.agora.io/)

## Step 1: Get Your Agora App ID

1. Visit [Agora Console](https://console.agora.io/)
2. Sign up or log in
3. Create a new project
4. Copy your **App ID**
5. Save it for the next step

## Step 2: Configure the App

### Update Agora App ID
Edit `lib/main.dart` and replace:
```dart
const String agoraAppId = 'YOUR_AGORA_APP_ID';
```
with your actual Agora App ID.

### Configure Android Permissions
Edit `android/app/src/main/AndroidManifest.xml` and ensure these permissions exist:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Configure iOS Permissions
Edit `ios/Runner/Info.plist` and add:
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to broadcast live streams</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to broadcast live streams</string>
```

## Step 3: Install Dependencies

```bash
flutter pub get
```

## Step 4: Build and Run

### Run on Android Device/Emulator
```bash
flutter run
```

### Run on iOS Device
```bash
flutter run -d ios
```

### Run on Specific Device
```bash
flutter devices                    # List available devices
flutter run -d <device_id>        # Run on specific device
```

## Step 5: Test the App

### As Host (Broadcaster)
1. **Select Role**: Tap "Go Live as Host"
2. **Enter Details**:
   - Name: Your name/username
   - Title: Stream title
3. **Add RTMP Platform** (Optional):
   - Platform: Select (YouTube, Facebook, etc.)
   - RTMP URL: Platform's RTMP endpoint
   - Stream Key: Your platform's stream key
4. **Start Live**: Tap "Start Live" button
5. **Monitor**: Watch stream and platform connection status
6. **End**: Tap "End Live" when done

### As Audience (Viewer)
1. **Select Role**: Tap "Join as Audience"
2. **Watch**: View active live stream information
3. **Exit**: Tap back to return to home

## Troubleshooting

### "Invalid App ID" Error
- Verify you copied the App ID correctly
- Check for extra spaces or special characters
- Confirm the App ID is active in Agora Console

### Camera Permission Denied
- **Android**: Go to Settings > App > Permissions > Camera > Allow
- **iOS**: Go to Settings > Agora Broadcaster > Camera > Allow

### Microphone Permission Denied
- **Android**: Go to Settings > App > Permissions > Microphone > Allow
- **iOS**: Go to Settings > Agora Broadcaster > Microphone > Allow

### RTMP Connection Failed
- Check RTMP URL format (should start with `rtmp://` or `rtmps://`)
- Verify stream key is correct
- Check your platform account is active
- Ensure network allows outbound RTMP (port 1935)

### App Crashes on Start
1. Clean build files:
   ```bash
   flutter clean
   flutter pub get
   ```
2. Rebuild:
   ```bash
   flutter run -d <device_id>
   ```

### Permissions Not Requested
- Run on actual device (permissions work better on hardware)
- Reinstall app: `flutter clean && flutter run`
- Check AndroidManifest.xml and Info.plist are updated

## Getting RTMP Details for Platforms

### YouTube Live
1. Go to YouTube Studio
2. Click "Create" > "Go Live"
3. Choose "Stream" tab
4. Copy **Stream URL** (RTMP URL)
5. Copy **Stream Key**
6. Format: `rtmp://a.rtmp.youtube.com/live2` + stream key

### Facebook Live
1. Go to Facebook Pages
2. Click "Live" > "Go Live"
3. Navigate to dashboard
4. Copy **Server URL** (RTMP URL)
5. Copy **Stream Key**

### Twitch
1. Go to Twitch Creator Dashboard
2. Settings > Stream Key
3. Copy **Stream Key**
4. RTMP URL: `rtmp://live.twitch.tv/app`

## Architecture Overview

The app follows **MVVM (Model-View-ViewModel)** architecture:

```
Views (Screens) 
    ↓
ViewModels (Logic & State)
    ↓
Repository (Coordination)
    ↓
Services (Implementation)
    ↓
External APIs (Agora, RTMP)
```

Key files:
- `lib/main.dart` - App entry point and Provider setup
- `lib/views/` - UI screens and widgets
- `lib/viewmodels/` - Business logic and state management
- `lib/repositories/` - Service coordination
- `lib/services/` - Agora, RTMP, Permission implementations
- `lib/models/` - Data models

## Key Features

✅ **Agora Live Streaming**
- Host broadcasting
- Audience viewing
- Real-time video/audio

✅ **RTMP Multi-Platform Support**
- YouTube Live
- Facebook Live
- Instagram Live
- Twitch
- Custom RTMP servers

✅ **Stream Management**
- Start/stop streaming
- Configure platforms
- Monitor platform status

✅ **Error Handling**
- Graceful error messages
- Connection retry
- Validation feedback

## Development Tips

### Hot Reload
After code changes, use hot reload to see changes instantly:
```bash
# In terminal running flutter run
r  # Hot reload
R  # Hot restart
```

### Debug Logs
The app uses a Logger utility:
```dart
Logger.log('Info message');
Logger.logError('Error occurred', error, stackTrace);
Logger.logWarning('Warning message');
Logger.logDebug('Debug message');
```

Check console output in terminal or IDE.

### Testing Permissions
Revoke permissions to test permission flow:
```bash
# Android
adb shell pm revoke com.flyweis.agorabroadcaster android.permission.CAMERA
adb shell pm revoke com.flyweis.agorabroadcaster android.permission.RECORD_AUDIO

# Then reinstall and run
flutter run
```

## Next Steps

1. **Deploy**: Build release APK/IPA for distribution
2. **Customize**: Modify colors, fonts, UI layout
3. **Add Features**: Chat, filters, recordings
4. **Test**: Thoroughly test all platforms
5. **Monitor**: Use Agora Analytics for insights

## Resources

- [Agora Documentation](https://docs.agora.io/en/)
- [Flutter Guide](https://flutter.dev/docs)
- [Provider Documentation](https://pub.dev/packages/provider)
- [MVVM Architecture](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)

## Support

- **Agora Issues**: Visit [Agora Support](https://support.agora.io/)
- **Flutter Issues**: Check [Flutter Issues](https://github.com/flutter/flutter/issues)
- **App Issues**: Review logs and error messages in console

---

Happy streaming! 🎬
