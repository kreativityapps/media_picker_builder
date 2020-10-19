import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:media_picker_builder/media_picker_builder.dart';

class MediaItem extends ValueNotifier<String> {
  final MediaFile file;

  MediaItem(this.file) : super(null);

  Future<void> getThumbnail() async {
    if (value != null) return;

    final filePath = await MediaPickerBuilder.getThumbnail(
      fileId: file.id,
      type: file.type,
    );

    value = filePath;

    notifyListeners();
  }
}
