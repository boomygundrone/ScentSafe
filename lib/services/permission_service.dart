import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }

  PermissionService._();

  /// Get platform-specific permissions list
  List<Permission> _getPlatformSpecificPermissions() {
    if (kIsWeb) {
      // On web, only check supported permissions
      return [
        Permission.camera,
      ];
    } else {
      // On mobile platforms, check required permissions
      return [
        Permission.camera,
        Permission.microphone, // For audio alerts
        Permission.storage, // For file operations
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];
    }
  }

  /// Request all required permissions
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = _getPlatformSpecificPermissions();

    final statuses = await permissions.request();
    debugPrint('Permission statuses: $statuses');
    return statuses;
  }

  /// Check if all permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final permissions = _getPlatformSpecificPermissions();

    for (final permission in permissions) {
      try {
        final status = await permission.status;
        if (!status.isGranted) {
          debugPrint('Permission not granted: $permission');
          return false;
        }
      } catch (e) {
        // On web, some permissions might not be supported
        if (kIsWeb) {
          debugPrint('Skipping unsupported permission on web: $permission');
          continue;
        } else {
          rethrow;
        }
      }
    }
    return true;
  }

  /// Check specific permission
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings(); // Call the global function from permission_handler
  }

  /// Get Android SDK version for conditional permissions
  Future<int> getAndroidSdkVersion() async {
    if (!kIsWeb) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  /// Request permissions with explanation
  Future<bool> requestPermissionsWithExplanation() async {
    // Check if permissions are already granted
    if (await areAllPermissionsGranted()) {
      return true;
    }

    // For web, only request supported permissions
    if (kIsWeb) {
      final webPermissions = _getPlatformSpecificPermissions();
      final statuses = await webPermissions.request();
      return statuses.values.every((status) => status.isGranted);
    }

    // For Android 12+, need to handle Bluetooth permissions differently
    final sdkVersion = await getAndroidSdkVersion();
    if (sdkVersion >= 31) {
      // Android 12+ specific handling
      return await _requestAndroid12PlusPermissions();
    }

    // Standard permission request for mobile
    final statuses = await requestAllPermissions();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> _requestAndroid12PlusPermissions() async {
    // Handle Android 12+ Bluetooth permissions
    final bluetoothStatuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final otherStatuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    return [...bluetoothStatuses.values, ...otherStatuses.values]
        .every((status) => status.isGranted);
  }

  /// Check if we're running on web platform
  bool get isWeb => kIsWeb;

  /// Get supported permissions for current platform
  List<Permission> get supportedPermissions =>
      _getPlatformSpecificPermissions();
}
