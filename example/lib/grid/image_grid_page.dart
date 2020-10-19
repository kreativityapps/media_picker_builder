import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:media_picker_builder/media_picker_builder.dart';
import 'package:media_picker_builder_example/grid/image_item.dart';
import 'package:transparent_image/transparent_image.dart';

class ImageGridPage extends StatefulWidget {
  ImageGridPage({Key key}) : super(key: key);

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

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month, 30);

    MediaPickerBuilder.getMediaAssets(
      start: start,
      end: end,
      withImages: true,
      withVideos: false,
    ).then((files) {
      final items = files.map((e) => MediaItem(e)).toList();

      setState(() {
        _items = items;
      });
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

          return CustomScrollView(
            slivers: [
              SliverGrid(
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
                            if (mediaFile.type == MediaType.video) ...[
                              Align(
                                child: Text('${mediaFile.durationInSeconds}', style: captionStyle),
                                alignment: Alignment.bottomRight,
                              ),
                              if (mediaFile.orientationType == OrientationType.landscape)
                                Align(
                                  child: Text('Landscape', style: captionStyle),
                                  alignment: Alignment.bottomLeft,
                                )
                              else
                                Align(
                                  child: Text('Portrait', style: captionStyle),
                                  alignment: Alignment.bottomLeft,
                                )
                            ]
                          ],
                        );
                      },
                    );
                  },
                  childCount: _items.length,
                ),
                gridDelegate: _gridDelegate,
              ),
            ],
          );
        },
      ),
    );
  }
}
