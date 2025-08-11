import 'package:photo_manager/photo_manager.dart';
import 'permission_service.dart';

class AudioFetchResult {
  final List<AssetEntity> audios;
  final PermissionState permissionState;
  final bool hasMore;
  final int totalCount;
  final String? errorMessage;

  AudioFetchResult({
    required this.audios,
    required this.permissionState,
    this.hasMore = false,
    this.totalCount = 0,
    this.errorMessage,
  });
}

class AudioService {
  static const int _defaultPageSize = 50;

  // Maintain backward compatibility
  static Future<AudioFetchResult> fetchAllAudios() async {
    return fetchAudiosPaginated(page: 0, pageSize: 1000);
  }

  static Future<AudioFetchResult> fetchAudiosPaginated({
    int page = 0,
    int pageSize = _defaultPageSize,
    String? searchQuery,
  }) async {
    try {
      final PermissionState ps =
          await PermissionService.requestAudioPermission();

      // Verify permissions are actually working
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        final permissionsWorking =
            await PermissionService.checkIfPermissionsAreActuallyWorkingForAudio();
        if (!permissionsWorking) {
          return AudioFetchResult(
            audios: [],
            permissionState: PermissionState.denied,
            hasMore: false,
            totalCount: 0,
            errorMessage:
                'Permissions granted but media access failed. Please check app permissions in settings.',
          );
        }
      }

      List<AssetEntity> audios = [];
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.audio,
          filterOption: FilterOptionGroup(
            audioOption: const FilterOption(needTitle: true),
            orders: [
              const OrderOption(type: OrderOptionType.createDate, asc: false),
            ],
          ),
        );

        for (final album in albums) {
          final List<AssetEntity> albumAudios = await album.getAssetListPaged(
            page: page,
            size: pageSize,
          );
          audios.addAll(albumAudios);
        }

        // Check if there are more items available
        bool hasMore = false;
        if (pageSize == _defaultPageSize) {
          // Try to fetch one more item to check if there are more
          try {
            final nextPageAudios = await albums.first.getAssetListPaged(
              page: page + 1,
              size: 1,
            );
            hasMore = nextPageAudios.isNotEmpty;
          } catch (e) {
            hasMore = audios.length == pageSize;
          }
        }

        return AudioFetchResult(
          audios: audios,
          permissionState: ps,
          hasMore: hasMore,
          totalCount: audios.length,
        );
      }

      return AudioFetchResult(
        audios: audios,
        permissionState: ps,
        hasMore: false,
        totalCount: 0,
      );
    } catch (e) {
      print('Error fetching audios: $e');
      return AudioFetchResult(
        audios: [],
        permissionState: PermissionState.denied,
        hasMore: false,
        totalCount: 0,
        errorMessage: 'Failed to load audios: $e',
      );
    }
  }
}
