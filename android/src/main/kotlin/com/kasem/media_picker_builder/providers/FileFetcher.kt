package com.kasem.media_picker_builder.providers

import android.content.Context
import com.kasem.media_picker_builder.model.Album
import com.kasem.media_picker_builder.model.MediaFile
import org.json.JSONArray


object FileFetcher {

    fun getAlbums(context: Context, withImages: Boolean, withVideos: Boolean): MutableMap<Long, Album> {
        val albumHashMap: MutableMap<Long, Album> = LinkedHashMap()

        if (withImages) {
            ImageFileProvider.fetchImages(context, albumHashMap)
        }

        if (withVideos) {
            VideoFileProvider.fetchVideos(context, albumHashMap)
        }

        ThumbnailImageProvider.fetchThumbnails(context, albumHashMap, withImages, withVideos)

        albumHashMap.values.forEach { album ->
            album.files.sortByDescending { file ->
                file.dateAdded
            }
        }
        return albumHashMap
    }

    @Throws(Exception::class)
    fun getMediaFile(
            context: Context,
            fileId: Long,
            type: MediaFile.MediaType,
            loadThumbnail: Boolean
    ): MediaFile? {
        val mediaFile = when (type) {
            MediaFile.MediaType.IMAGE -> {
                ImageFileProvider.getImageMediaFile(context, fileId)
            }
            MediaFile.MediaType.VIDEO -> {
                VideoFileProvider.getVideoMediaFile(context, fileId)
            }
        }

        if (mediaFile != null && loadThumbnail) {
            mediaFile.thumbnailPath = ThumbnailImageProvider.getThumbnail(context, fileId, type)
        }

        return mediaFile
    }
}