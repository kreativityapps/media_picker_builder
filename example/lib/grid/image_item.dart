import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/media_asset.dart';
import 'package:media_picker_builder/media_picker_builder.dart';

class MediaItem extends ValueNotifier<String> {
  final MediaAsset asset;

  MediaItem(this.asset) : super(null);

  Future<void> getThumbnail() async {
    if (value != null) return;

    final filePath = await MediaPickerBuilder.getThumbnail(
      fileId: asset.id,
      type: asset.type,
    );

    value = filePath;

    notifyListeners();
  }
}
