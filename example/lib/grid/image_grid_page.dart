import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:media_picker_builder/media_picker_builder.dart';
import 'package:media_picker_builder_example/grid/image_item.dart';
import 'package:transparent_image/transparent_image.dart';

class ImageGridPage extends StatefulWidget {
  ImageGridPage({@required this.range, Key key}) : super(key: key);

  final DateTimeRange range;

  @override
  _ImageGridPageState createState() => _ImageGridPageState();
}

class _ImageGridPageState extends State<ImageGridPage> {
  List<MediaItem> _items = [];
  Map<String, String> thumbnailsCache = {};

  static const _imageSize = Size(90, 122);

  final _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    childAspectRatio: _imageSize.aspectRatio,
    mainAxisSpacing: 13,
    crossAxisSpacing: 13,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
  }

  Future<void> refresh() async {
    final start = widget.range.start;
    final end = widget.range.end;

    final files = await MediaPickerBuilder.getMediaAssets(
      start: start,
      end: end,
      types: [MediaType.video, MediaType.image],
    );

    // Show only videos and Live Photos
    // Live photos require the MediaType.image so we need to filter the non live photos out
    final items = files.where((e) => e.type == MediaType.video || e.isLivePhoto).map((e) => MediaItem(e)).toList();

    setState(() {
      _items = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final captionStyle = textTheme.caption.copyWith(color: Colors.white);

    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
      ),
      body: Builder(
        builder: (context) {
          if (_items == null) {
            return Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(18.0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _items[index];
                        return ValueListenableBuilder<String>(
                          valueListenable: item,
                          builder: (context, value, child) {
                            if (value == null) {
                              item.getThumbnail();

                              return Container(
                                color: Colors.black,
                                height: _imageSize.height,
                                width: _imageSize.width,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final mediaFile = item.asset;

                            IconData icon;

                            switch (mediaFile.type) {
                              case MediaType.image:
                                if (mediaFile.isLivePhoto) {
                                  icon = Icons.motion_photos_on;
                                } else {
                                  icon = Icons.photo;
                                }
                                break;
                              case MediaType.video:
                                icon = Icons.videocam;
                                break;
                            }

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                FadeInImage(
                                  placeholder: MemoryImage(kTransparentImage),
                                  image: FileImage(File(value)),
                                  fit: BoxFit.cover,
                                  width: _imageSize.width,
                                  height: _imageSize.height,
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(icon, color: Colors.white),
                                  ),
                                ),
                                if (mediaFile.type == MediaType.video)
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (mediaFile.orientationType == OrientationType.landscape)
                                            Text('Landscape', style: captionStyle)
                                          else
                                            Text('Portrait', style: captionStyle),
                                          Text('${mediaFile.duration.round()}', style: captionStyle),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                      childCount: _items.length,
                    ),
                    gridDelegate: _gridDelegate,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
