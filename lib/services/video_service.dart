import 'package:photo_manager/photo_manager.dart';
import 'permission_service.dart';

class VideoFetchResult {
  final List<AssetEntity> videos;
  final PermissionState permissionState;
  final String? errorMessage;
  VideoFetchResult({
    required this.videos,
    required this.permissionState,
    this.errorMessage,
  });
}

class VideoService {
  static Future<VideoFetchResult> fetchAllVideos() async {
    try {
      final PermissionState ps =
          await PermissionService.requestVideoPermission();

      // Verify permissions are actually working
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        final permissionsWorking =
            await PermissionService.checkIfPermissionsAreActuallyWorking();
        if (!permissionsWorking) {
          return VideoFetchResult(
            videos: [],
            permissionState: PermissionState.denied,
            errorMessage:
                'Permissions granted but media access failed. Please check app permissions in settings.',
          );
        }
      }

      List<AssetEntity> videos = [];
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.video,
          filterOption: FilterOptionGroup(
            videoOption: const FilterOption(needTitle: true),
            orders: [
              const OrderOption(type: OrderOptionType.createDate, asc: false),
            ],
          ),
        );

        for (final album in albums) {
          final List<AssetEntity> albumVideos = await album.getAssetListPaged(
            page: 0,
            size: 1000,
          );
          videos.addAll(albumVideos);
        }
      }

      return VideoFetchResult(videos: videos, permissionState: ps);
    } catch (e) {
      print('Error fetching videos: $e');
      return VideoFetchResult(
        videos: [],
        permissionState: PermissionState.denied,
        errorMessage: 'Failed to load videos: $e',
      );
    }
  }
}
