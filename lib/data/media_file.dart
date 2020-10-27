import 'dart:io';

import 'package:media_picker_builder/data/media_asset.dart';
import 'package:meta/meta.dart';

enum MediaType { image, video }
enum OrientationType { portrait, landscape }

class MediaFile extends MediaAsset {
  /// Original file path
  String path;

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
  String thumbnailPath;

  /// Supported on Android only
  String mimeType;

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
    @required String id,
    @required int dateAdded,
    @required double duration,
    @required int orientation,
    @required MediaType type,
    @required bool isLivePhoto,
    @required this.path,
    @required this.thumbnailPath,
    @required this.mimeType,
  }) : super(dateAdded: dateAdded, duration: duration, id: id, orientation: orientation, type: type, isLivePhoto: isLivePhoto);

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    if (json == null) return null;

    final livePhoto = json['isLivePhoto'] as bool ?? false;

    var duration = (json['duration'] as num)?.toDouble();
    if (livePhoto) {
      duration = 3.0;
    }

    final file = MediaFile(
      id: json['id'],
      dateAdded: json['dateAdded'],
      path: json['path'],
      thumbnailPath: json['thumbnailPath'],
      orientation: json['orientation'],
      duration: duration,
      mimeType: json['mimeType'],
      type: MediaType.values[json['type']],
      isLivePhoto: livePhoto,
    );

    return file;
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is MediaFile &&
        o.id == id &&
        o.dateAdded == dateAdded &&
        o.orientation == orientation &&
        o.duration == duration &&
        o.type == type &&
        o.isLivePhoto == isLivePhoto &&
        o.path == path &&
        o.thumbnailPath == thumbnailPath &&
        o.mimeType == mimeType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        dateAdded.hashCode ^
        orientation.hashCode ^
        duration.hashCode ^
        type.hashCode ^
        isLivePhoto.hashCode ^
        path.hashCode ^
        thumbnailPath.hashCode ^
        mimeType.hashCode;
  }
}
