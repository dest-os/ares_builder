import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  Future<bool> micGranted() => ph.Permission.microphone.isGranted;

  Future<bool> notificationGranted() => ph.Permission.notification.isGranted;

  Future<bool> requestMicrophone() async {
    final status = await ph.Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestNotification() async {
    final status = await ph.Permission.notification.request();
    return status.isGranted;
  }

  Future<void> openSettings() async {
    await ph.openAppSettings();
  }
}
