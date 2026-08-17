import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotosPermission() async {
    if (await Permission.photos.request().isGranted) return true;
    return Permission.storage.request().isGranted;
  }

  Future<bool> hasCameraPermission() async {
    return Permission.camera.isGranted;
  }

  Future<bool> hasPhotosPermission() async {
    if (await Permission.photos.isGranted) return true;
    return Permission.storage.isGranted;
  }

  Future<void> openSettings() => openAppSettings();
}
