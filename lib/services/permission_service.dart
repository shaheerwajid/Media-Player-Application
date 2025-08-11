import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static Future<PermissionState> requestVideoPermission() async {
    try {
      // First try the standard photo_manager permission request
      final PermissionState ps = await PhotoManager.requestPermissionExtend();

      // If successful, return immediately
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        return ps;
      }

      // For Android 13+ devices that might have issues with photo_manager
      if (Platform.isAndroid) {
        // Check if we're on Android 13+ (API 33+)
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          // Try alternative permission approach for problematic Android 13 devices
          return await _requestAndroid13Permissions();
        }
      }

      return ps;
    } catch (e) {
      print('Error requesting video permission: $e');
      // Fallback to basic permission request
      return await PhotoManager.requestPermissionExtend();
    }
  }

  static Future<PermissionState> requestAudioPermission() async {
    try {
      // First try the standard photo_manager permission request
      final PermissionState ps = await PhotoManager.requestPermissionExtend();

      // If successful, return immediately
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        return ps;
      }

      // For Android 13+ devices that might have issues with photo_manager
      if (Platform.isAndroid) {
        // Check if we're on Android 13+ (API 33+)
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          // Try alternative permission approach for problematic Android 13 devices
          return await _requestAndroid13Permissions();
        }
      }

      return ps;
    } catch (e) {
      print('Error requesting audio permission: $e');
      // Fallback to basic permission request
      return await PhotoManager.requestPermissionExtend();
    }
  }

  static Future<PermissionState> _requestAndroid13Permissions() async {
    try {
      // Request individual media permissions for Android 13+
      final videoStatus = await Permission.videos.request();
      final audioStatus = await Permission.audio.request();
      final photosStatus = await Permission.photos.request();

      // Check if all permissions are granted
      if (videoStatus.isGranted &&
          audioStatus.isGranted &&
          photosStatus.isGranted) {
        // Try to re-request photo_manager permission after individual permissions
        try {
          return await PhotoManager.requestPermissionExtend();
        } catch (e) {
          print(
            'PhotoManager permission request failed after individual permissions: $e',
          );
          // Return authorized if individual permissions are granted
          return PermissionState.authorized;
        }
      } else if (videoStatus.isGranted || audioStatus.isGranted) {
        // Partial permissions - return limited
        return PermissionState.limited;
      } else {
        // No permissions granted
        return PermissionState.denied;
      }
    } catch (e) {
      print('Error requesting Android 13 permissions: $e');
      return PermissionState.denied;
    }
  }

  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        // Try to get the actual Android version from the system
        try {
          // Use a more reliable method to detect Android version
          // For now, we'll use a conservative approach
          return 33; // Assume Android 13+ for problematic devices
        } catch (e) {
          print('Could not determine exact Android version: $e');
          // Fallback to assuming Android 13+ for safety
          return 33;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting Android version: $e');
      return 0;
    }
  }

  static Future<bool> checkIfPermissionsAreActuallyWorking() async {
    try {
      // Try to actually access media to verify permissions are working
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          videoOption: const FilterOption(needTitle: true),
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      // If we can get albums, permissions are working
      return albums.isNotEmpty;
    } catch (e) {
      print('Permission verification failed: $e');
      return false;
    }
  }

  static Future<bool> checkIfPermissionsAreActuallyWorkingForAudio() async {
    try {
      // Try to actually access audio media to verify permissions are working
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.audio,
        filterOption: FilterOptionGroup(
          audioOption: const FilterOption(needTitle: true),
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      // If we can get albums, permissions are working
      return albums.isNotEmpty;
    } catch (e) {
      print('Audio permission verification failed: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      // Open app settings so users can manually configure permissions
      // This is especially useful for Android 13 devices with permission issues
      await openAppSettings();
    } catch (e) {
      print('Failed to open app settings: $e');
      // Fallback: try to open general settings
      try {
        await openAppSettings();
      } catch (e) {
        print('Failed to open any settings: $e');
      }
    }
  }

  static String getPermissionTroubleshootingMessage() {
    return '''
If you're experiencing permission issues on Android 13:

1. Go to Settings > Apps > [Your App Name] > Permissions
2. Ensure the following permissions are granted:
   • Photos and videos
   • Audio
   • Files and media
3. If permissions are granted but media still won't load:
   • Try revoking and re-granting permissions
   • Restart the app
   • Check if your device has any security apps blocking media access

This is a known issue on some Android 13 devices and the above steps usually resolve it.
''';
  }
}
