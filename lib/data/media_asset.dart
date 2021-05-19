import 'package:media_picker_builder/data/media_file.dart';
import 'package:meta/meta.dart';

class MediaAsset {
  /// Unique identifier for the file
  String? id;

  /// Date added in seconds (unix timestamp)
  int? dateAdded;

  /// Orientation in degrees
  /// 0 - landscape right
  /// 90 - portrait
  /// 180 - landscape left
  /// 270 - portrait upside down
  /// Exception iOS photos orientation value indicate a shift from vertical axis
  int? orientation;

  /// Video duration in seconds
  double? duration;

  MediaType type;

  bool? isLivePhoto;

  MediaAsset({
    required this.id,
    required this.dateAdded,
    required this.orientation,
    required this.duration,
    required this.type,
    required this.isLivePhoto,
  });

  OrientationType get orientationType {
    if (orientation == 0 || orientation == 180) {
      return OrientationType.landscape;
    }

    return OrientationType.portrait;
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    if (json == null) return null;

    return MediaAsset(
      id: json['id'],
      dateAdded: json['dateAdded'],
      orientation: json['orientation'],
      duration: (json['duration'] as num?)?.toDouble(),
      type: MediaType.values[json['type']],
      isLivePhoto: json['isLivePhoto'],
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is MediaAsset &&
        o.id == id &&
        o.dateAdded == dateAdded &&
        o.orientation == orientation &&
        o.duration == duration &&
        o.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ dateAdded.hashCode ^ orientation.hashCode ^ duration.hashCode ^ type.hashCode;
  }
}
