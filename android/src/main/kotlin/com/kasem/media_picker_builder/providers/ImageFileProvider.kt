package com.kasem.media_picker_builder.providers

import android.content.Context
import android.database.Cursor
import android.provider.MediaStore
import com.kasem.media_picker_builder.model.Album
import com.kasem.media_picker_builder.model.MediaFile

object ImageFileProvider {

    private val IMAGE_MEDIA_COLUMNS = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.Media.ORIENTATION,
            MediaStore.Images.Media.MIME_TYPE)
    
    fun getImageMediaFile(
            context: Context, 
            fileId: Long
    ): MediaFile? {
        context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                IMAGE_MEDIA_COLUMNS,
                "${MediaStore.Images.Media._ID} = $fileId",
                null,
                null)?.use { cursor ->

            if (cursor.moveToFirst()) {
                return cursorToMediaFile(cursor)
            }
        }
        
        return null
    }

    fun fetchImages(context: Context, albumHashMap: MutableMap<Long, Album>) {
        context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                IMAGE_MEDIA_COLUMNS, null,
                null,
                "${MediaStore.Images.Media._ID} DESC")?.use { cursor ->

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

    private fun cursorToMediaFile(
            cursor: Cursor
    ): MediaFile {
        val fileId = cursor.getLong(0)          //MediaStore.Images.Media._ID
        val fileDateAdded = cursor.getLong(1)   //MediaStore.Images.Media.DATE_ADDED
        val filePath = cursor.getString(2)      //MediaStore.Images.Media.DATA
        val albumName = cursor.getString(3)     //MediaStore.Images.Media.BUCKET_DISPLAY_NAME
        val albumId = cursor.getLong(4)         //MediaStore.Images.Media.BUCKET_ID
        val orientation = cursor.getInt(5)      //MediaStore.Images.Media.ORIENTATION
        val mimeType = cursor.getString(6)      //MediaStore.Images.Media.MIME_TYPE

        return MediaFile(
                id = fileId,
                albumId = albumId,
                albumName = "", //Passing empty string, because real `albumName` was problematic under certain circumstances
                dateAdded = fileDateAdded,
                path = filePath,
                thumbnailPath = null,
                orientation = orientation,
                mimeType = mimeType,
                duration = null,
                type = MediaFile.MediaType.IMAGE)
    }
}