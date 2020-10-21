package com.kasem.media_picker_builder.providers

import android.content.Context
import com.kasem.media_picker_builder.model.Album
import com.kasem.media_picker_builder.model.MediaFile


object FileFetcher {

    fun getAlbums(
            context: Context,
            withImages: Boolean,
            withVideos: Boolean,
            startDate: Long? = null,
            endDate: Long? = null
    ): MutableMap<Long, Album> {
        val albumHashMap: MutableMap<Long, Album> = LinkedHashMap()

        if (withImages) {
            ImageFileProvider.fetchImages(context, albumHashMap, startDate, endDate)
        }

        if (withVideos) {
            VideoFileProvider.fetchVideos(context, albumHashMap, startDate, endDate)
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