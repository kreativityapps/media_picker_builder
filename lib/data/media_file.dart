import 'dart:io';

import 'package:media_picker_builder/data/media_asset.dart';

enum MediaType { image, video }
enum OrientationType { portrait, landscape }

class MediaFile extends MediaAsset {
  /// Original file path
  String? path;

  /// Thumbnails from android (NOT iOS) need to have their orientation fixed
  /// based on the returned [orientation]
  /// usage: RotatedBox(
  ///                  quarterTurns: Platform.isIOS
  ///                      ? 0
  ///                      : orientationToQuarterTurns(mediaFile.orientation),
  ///                  child: Image.file(
  ///                    File(mediaFile.thumbnailPath),
  ///                    fit: BoxFit.cover,
  ///                    )
  /// Note: If thumbnail returned is null you will have to call [MediaPickerBuilder.getThumbnail]
  String? thumbnailPath;

  /// Supported on Android only
  String? mimeType;

  /// A convenient function that converts image orientation to quarter turns for widget [RotatedBox]
  /// i.e. RotatedBox(
  ///           quarterTurns: orientationToQuarterTurns(mediaFile.orientation),
  ///           child: Image.file(
  ///           File(mediaFile.thumbnailPath),
  ///               fit: BoxFit.cover,
  ///       )
  int get orientationToQuarterTurns {
    if (Platform.isIOS || type == MediaType.video) {
      return 0;
    }

    switch (orientation) {
      case 90:
        return 1;
      case 180:
        return 2;
      case 270:
        return 3;
      default:
        return 0;
    }
  }

  MediaFile({
    required String? id,
    required int? dateAdded,
    required double? duration,
    required int? orientation,
    required MediaType type,
    required bool? isLivePhoto,
    required this.path,
    required this.thumbnailPath,
    required this.mimeType,
  }) : super(dateAdded: dateAdded, duration: duration, id: id, orientation: orientation, type: type, isLivePhoto: isLivePhoto);

  factory MediaFile.fromJson(Map<String, dynamic> json) => MediaFile(
        id: json['id'],
        dateAdded: json['dateAdded'],
        path: json['path'],
        thumbnailPath: json['thumbnailPath'],
        orientation: json['orientation'],
        duration: (json['duration'] as num?)?.toDouble(),
        mimeType: json['mimeType'],
        type: MediaType.values[json['type']],
        isLivePhoto: json['isLivePhoto'],
      );

  @override
  bool operator ==(Object other) => identical(this, other) || other is MediaFile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
