import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_picker_builder/data/album.dart';
import 'package:media_picker_builder/data/media_asset.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:meta/meta.dart';

import 'data/media_file.dart';

class MediaPickerBuilder {
  static const MethodChannel _channel = const MethodChannel('media_picker_builder');

  static Future<List<MediaAsset>> getMediaAssets({
    @required DateTime start,
    @required DateTime end,
    bool withImages = true,
    bool withVideos = true,
  }) async {
    assert(start != null);
    assert(end != null);

    final String json = await _channel.invokeMethod(
      "v2/getMediaAssets",
      {
        "startDate": start.millisecondsSinceEpoch / 1000,
        "endDate": end.millisecondsSinceEpoch / 1000,
        "withImages": withImages,
        "withVideos": withVideos,
      },
    );

    return await compute(_jsonToMediaAssets, json);
  }

  static Future<MediaFile> retrieveMediaFile(MediaFile file) async {
    assert(file != null);

    final String json = await _channel.invokeMethod("v2/getMediaFile", {"fileId": file.id});

    return await compute(_jsonToMediaFile, json);
  }

  /// Gets list of albums and its content based on the required flags.
  /// This method will also return the thumbnails IF it was already generated.
  /// If thumbnails returned are null you will have to call [getThumbnail]
  /// to generate one and return its path.
  /// [loadIOSPaths] For iOS only, to optimize the speed of querying the files you can set this to false,
  /// but if you do that you will have to get the path & video duration after selection is done
  static Future<List<Album>> getAlbums({
    @required bool withImages,
    @required bool withVideos,
    bool loadIOSPaths = true,
  }) async {
    final String json = await _channel.invokeMethod(
      "getAlbums",
      {
        "withImages": withImages,
        "withVideos": withVideos,
        "loadIOSPaths": loadIOSPaths,
      },
    );

    return await compute(_jsonToAlbums, json);
  }

  /// Returns the thumbnail path of the media file returned in method [getAlbums].
  /// If there is no cached thumbnail for the file, it will generate one and return it.
  /// Android thumbnails will need to be rotated based on the file orientation.
  /// iOS thumbnails have the correct orientation
  /// i.e. RotatedBox(
  ///                  quarterTurns: Platform.isIOS
  ///                      ? 0
  ///                      : orientationToQuarterTurns(mediaFile.orientation),
  ///                  child: Image.file(
  ///                    File(mediaFile.thumbnailPath),
  ///                    fit: BoxFit.cover,
  ///                    )
  static Future<String> getThumbnail({
    @required String fileId,
    @required MediaType type,
  }) async {
    final String path = await _channel.invokeMethod(
      'getThumbnail',
      {
        "fileId": fileId,
        "type": type.index,
      },
    );
    return path;
  }

  /// Returns the [MediaFile] of a file by the unique identifier
  /// [loadIOSPath] Whether or not to try and fetch path & video duration for iOS.
  /// Android always returns the path & duration
  /// [loadThumbnail] Whether or not to generate a thumbnail
  static Future<MediaFile> getMediaFile({
    @required String fileId,
    @required MediaType type,
    bool loadIOSPath = true,
    bool loadThumbnail = false,
  }) async {
    final String json = await _channel.invokeMethod(
      'getMediaFile',
      {
        "fileId": fileId,
        "type": type.index,
        "loadIOSPath": loadIOSPath,
        "loadThumbnail": loadThumbnail,
      },
    );
    final encoded = jsonDecode(json);
    return MediaFile.fromJson(encoded);
  }

  /// Gets list of videos and live photos with corresponding thumbnails
  static Future<List<MediaFile>> getVideosAndLivePhotos({
    int dateInMs,
    int durationInSeconds,
  }) async {
    final String json = await _channel.invokeMethod(
      "getVideosAndLivePhotos",
      {
        "dateInMs": dateInMs,
        "durationInSeconds": durationInSeconds,
      },
    );
    final decoded = jsonDecode(json) as List;
    return decoded.map((i) => MediaFile.fromJson(i as Map<String, dynamic>)).toList();
  }

  /// Get path of a live photo (iOS only)
  static Future<String> getLivePhotoPath(String fileId) async {
    return await _channel.invokeMethod('getLivePhotoPath', {'fileId': fileId});
  }

  /// Get path of a video
  static Future<String> getVideoPath(String fileId) async {
    return await _channel.invokeMethod('getVideoPath', {'fileId': fileId});
  }
}

MediaFile _jsonToMediaFile(dynamic json) {
  final decoded = jsonDecode(json) as Map;
  final Map<String, dynamic> map = Map.castFrom(decoded);

  return MediaFile.fromJson(map);
}

List<MediaAsset> _jsonToMediaAssets(dynamic json) {
  final decoded = jsonDecode(json) as List;
  final List<Map<String, dynamic>> list = List.castFrom(decoded);

  return list.map<MediaAsset>((e) => MediaAsset.fromJson(e)).toList();
}

List<Album> _jsonToAlbums(dynamic json) {
  final decoded = jsonDecode(json) as List;
  final List<Map<String, dynamic>> list = List.castFrom(decoded);

  return list.map<Album>((album) => Album.fromJson(album)).toList();
}
