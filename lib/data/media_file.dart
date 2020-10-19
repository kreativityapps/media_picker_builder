class MediaFile {
  /// Unique identifier for the file
  String id;

  /// Date added in seconds (unix timestamp)
  int dateAdded;

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

  /// Orientation in degrees
  /// 0 - landscape right
  /// 90 - portrait
  /// 180 - landscape left
  /// 270 - portrait upside down
  /// Exception iOS photos orientation value indicate a shift from vertical axis
  int orientation;

  /// Video duration in milliseconds
  double duration;

  /// Supported on Android only
  String mimeType;
  MediaType type;

  OrientationType get orientationType {
    if (orientation == 0 || orientation == 180) {
      return OrientationType.landscape;
    }

    return OrientationType.portrait;
  }

  int get durationInSeconds {
    return duration ~/ 1000;
  }

  MediaFile({this.id, this.dateAdded, this.path, this.thumbnailPath, this.orientation, this.type});

  MediaFile.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        dateAdded = json['dateAdded'],
        path = json['path'],
        thumbnailPath = json['thumbnailPath'],
        orientation = json['orientation'],
        duration = (json['duration'] as num)?.toDouble(),
        mimeType = json['mimeType'],
        type = MediaType.values[json['type']];

  @override
  bool operator ==(Object other) => identical(this, other) || other is MediaFile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum MediaType { IMAGE, VIDEO }
enum OrientationType { portrait, landscape }
