import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
    ];

    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> hasCameraPermission() async {
    return (await Permission.camera.status).isGranted;
  }

  Future<bool> hasMicrophonePermission() async {
    return (await Permission.microphone.status).isGranted;
  }

  Future<bool> hasAllPermissions() async {
    return (await hasCameraPermission()) && (await hasMicrophonePermission());
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
