package com.kasem.media_picker_builder.providers

import android.content.Context
import android.database.Cursor
import android.provider.MediaStore
import com.kasem.media_picker_builder.model.Album
import com.kasem.media_picker_builder.model.MediaFile

object VideoFileProvider {

    private val VIDEO_MEDIA_COLUMNS = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Video.Media.BUCKET_ID,
            MediaStore.Video.Media.MIME_TYPE,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.ORIENTATION)

    fun getVideoMediaFile(
            context: Context,
            fileId: Long
    ): MediaFile? {
        context.contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                VIDEO_MEDIA_COLUMNS,
                "${MediaStore.Video.Media._ID} = $fileId",
                null,
                null)?.use { cursor ->

            if (cursor.moveToFirst()) {
                return cursorToMediaFile(cursor)
            }
        }

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
        
        context.contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                VIDEO_MEDIA_COLUMNS,
                selectionClause,
                selectionArgs,
                "${MediaStore.Video.Media._ID} DESC")?.use { cursor ->

            while (cursor.moveToNext()) {
                val mediaFile = cursorToMediaFile(cursor)

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
    }

    private fun cursorToMediaFile(cursor: Cursor): MediaFile {
        val fileId = cursor.getLong(0)          //MediaStore.Video.Media._ID
        val fileDateAdded = cursor.getLong(1)   //MediaStore.Video.Media.DATE_ADDED
        val filePath = cursor.getString(2)      //MediaStore.Video.Media.DATA
        val albumName = cursor.getString(3)     //MediaStore.Video.Media.BUCKET_DISPLAY_NAME
        val albumId = cursor.getLong(4)         //MediaStore.Video.Media.BUCKET_ID
        val mimeType = cursor.getString(5)      //MediaStore.Video.Media.MIME_TYPE
        val duration = cursor.getLong(6)        //MediaStore.Video.Media.DURATION
        val orientation = cursor.getInt(7)        //MediaStore.Video.Media.ORIENTATION

        return MediaFile(
                fileId,
                albumId,
                "", //Passing empty string, because real `albumName` was problematic under certain circumstances
                fileDateAdded,
                filePath,
                null,
                orientation,
                mimeType,
                duration,
                MediaFile.MediaType.VIDEO
        )
    }
}