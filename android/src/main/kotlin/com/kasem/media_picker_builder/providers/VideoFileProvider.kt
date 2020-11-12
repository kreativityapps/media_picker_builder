package com.kasem.media_picker_builder.providers

import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.provider.MediaStore
import com.kasem.media_picker_builder.model.Album
import com.kasem.media_picker_builder.model.MediaFile

object VideoFileProvider {

    private val VIDEO_MEDIA_COLUMNS = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.MIME_TYPE
    )

    fun getVideoMediaFile(
            context: Context,
            fileId: Long
    ): MediaFile? {
        val cursor = context.contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                VIDEO_MEDIA_COLUMNS,
                "${MediaStore.Video.Media._ID} = $fileId",
                null,
                null)

        val mediaMetadataRetriever = MediaMetadataRetriever()
        if (cursor != null && cursor.moveToFirst()) {
            return cursorToMediaFile(mediaMetadataRetriever, cursor)
        }
        mediaMetadataRetriever.release()

        return null
    }

    fun fetchVideos(
            context: Context,
            albumHashMap: MutableMap<Long, Album>,
            startDate: Long? = null,
            endDate: Long? = null
    ) {
        var selectionClause: String? = null
        var selectionArgs: Array<String>? = null

        if (startDate != null && endDate != null) {
            selectionClause = "${MediaStore.Video.Media.DATE_ADDED} BETWEEN ? AND ?"
            selectionArgs = arrayOf(startDate.toString(), endDate.toString())
        }

        val cursor = context.contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                VIDEO_MEDIA_COLUMNS,
                selectionClause,
                selectionArgs,
                "${MediaStore.Video.Media._ID} DESC")

        val mediaMetadataRetriever = MediaMetadataRetriever()
        while (cursor?.moveToNext() == true) {
            val mediaFile = cursorToMediaFile(mediaMetadataRetriever, cursor)

            if (mediaFile != null) {
                val album = albumHashMap[mediaFile.albumId]
                if (album == null) {
                    albumHashMap[mediaFile.albumId] = Album(
                            mediaFile.albumId,
                            mediaFile.albumName,
                            mutableListOf(mediaFile)
                    )
                } else {
                    album.files.add(mediaFile)
                }
            }
        }
        mediaMetadataRetriever.release()
    }


    private fun cursorToMediaFile(
            mediaMetadataRetriever: MediaMetadataRetriever,
            cursor: Cursor
    ): MediaFile? {
        val fileId = cursor.getLong(0)
        val fileDateAdded = cursor.getLong(1)
        val filePath = cursor.getString(2)
        val mimeType = cursor.getString(3)

        var duration: Float? = null
        var orientation: Int = -1
        try {
            mediaMetadataRetriever.setDataSource(filePath)
            duration = mediaMetadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION).toFloat() / 1000
            orientation = mediaMetadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION).toInt()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return MediaFile(
                fileId,
                0,
                "", //Passing empty string, because real `albumName` was problematic under certain circumstances
                fileDateAdded,
                filePath,
                null,
                orientation,
                mimeType,
                duration?.toDouble(),
                MediaFile.MediaType.VIDEO
        )
    }
}