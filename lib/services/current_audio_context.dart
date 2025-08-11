import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class CurrentAudioSelection {
  final List<AssetEntity> audios;
  final int index;
  const CurrentAudioSelection({required this.audios, required this.index});
}

class CurrentAudioContext {
  static final ValueNotifier<CurrentAudioSelection?> selectionNotifier =
      ValueNotifier<CurrentAudioSelection?>(null);

  static void setSelection(List<AssetEntity> audios, int index) {
    if (index < 0 || index >= audios.length) return;
    selectionNotifier.value = CurrentAudioSelection(
      audios: List.unmodifiable(audios),
      index: index,
    );
  }

  static CurrentAudioSelection? get selection => selectionNotifier.value;
}
