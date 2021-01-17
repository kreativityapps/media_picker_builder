package com.kasem.media_picker_builder.providers

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.media.ThumbnailUtils
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import com.kasem.media_picker_builder.model.Album
import com.kasem.media_picker_builder.model.MediaFile
import java.io.File
import java.io.FileOutputStream

object ThumbnailImageProvider {

    fun fetchThumbnails(
            context: Context,
            albumHashMap: MutableMap<Long, Album>,
            withImages: Boolean,
            withVideos: Boolean
    ) {
        if (withImages) {
            context.contentResolver.query(
                    MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI,
                    arrayOf(
                            MediaStore.Images.Thumbnails.IMAGE_ID,
                            MediaStore.Images.Thumbnails.DATA
                    ),
                    null,
                    null,
                    null)
                    ?.use { cursor ->
                        while (cursor.moveToNext()) {
                            val fileId = cursor.getLong(0)
                            var thumbnail = cursor.getString(1)

                            // Set the thumbnail to null if it doesn't exist
                            if (!File(thumbnail).exists())
                                thumbnail = null

                            if (thumbnail != null)
                                for (album in albumHashMap.values) {
                                    val file = album.files.firstOrNull { it.id == fileId }
                                    if (file != null) {
                                        file.thumbnailPath = thumbnail
                                        break
                                    }
                                }
                        }
                        cursor.close()
                    }
        }

        if (withVideos) {
            context.contentResolver.query(
                    MediaStore.Video.Thumbnails.EXTERNAL_CONTENT_URI,
                    arrayOf(
                            MediaStore.Video.Thumbnails.VIDEO_ID,
                            MediaStore.Video.Thumbnails.DATA
                    ),
                    null,
                    null,
                    null)
                    ?.use { cursor ->

                        val fileIdColumn = cursor.getColumnIndex(MediaStore.Video.Thumbnails.VIDEO_ID)
                        val thumbnailPathColumn = cursor.getColumnIndex(MediaStore.Video.Thumbnails.DATA)
                        while (cursor.moveToNext()) {
                            val fileId = cursor.getLong(fileIdColumn)
                            var thumbnail = cursor.getString(thumbnailPathColumn)

                            // Set the thumbnail to null if it doesn't exist
                            if (!File(thumbnail).exists())
                                thumbnail = null

                            if (thumbnail != null)
                                for (album in albumHashMap.values) {
                                    val file = album.files.firstOrNull { it.id == fileId }
                                    if (file != null) {
                                        file.thumbnailPath = thumbnail
                                        break
                                    }
                                }
                        }
                    }
        }
    }

    fun getThumbnail(context: Context, fileId: Long, type: MediaFile.MediaType): String? {
        val dir = File(context.externalCacheDir, ".thumbnails")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        val outputFile = File(dir, "$fileId.jpg")
        return if (outputFile.exists()) {
            outputFile.path
        } else {
            generateThumbnail(context, fileId, type, outputFile)
        }
    }

    private fun generateThumbnail(
            context: Context,
            fileId: Long,
            type: MediaFile.MediaType,
            outputFile: File
    ): String? {
        val bitmap: Bitmap
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            bitmap = when (type) {
                MediaFile.MediaType.IMAGE -> {
                    val uri = Uri.parse("${MediaStore.Images.Media.EXTERNAL_CONTENT_URI}/$fileId")
                    context.contentResolver.loadThumbnail(uri, Size(90, 90), null)
                }
                MediaFile.MediaType.VIDEO -> {
                    val uri = Uri.parse("${MediaStore.Video.Media.EXTERNAL_CONTENT_URI}/$fileId")
                    context.contentResolver.loadThumbnail(uri, Size(270, 270), null)
                }
            }
        } else {
            bitmap = when (type) {
                MediaFile.MediaType.IMAGE -> {
                    MediaStore.Images.Thumbnails.getThumbnail(
                            context.contentResolver,
                            fileId,
                            MediaStore.Images.Thumbnails.MINI_KIND,
                            null
                    )
                }
                MediaFile.MediaType.VIDEO -> {
                    MediaStore.Video.Thumbnails.getThumbnail(
                            context.contentResolver,
                            fileId,
                            MediaStore.Video.Thumbnails.MINI_KIND,
                            null)

                }
            } ?: throw Exception("Unable to generate thumbnail")
        }

        FileOutputStream(outputFile).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out)
        }

        bitmap.recycle()

        updateThumbnailMediaStore(context, fileId, type, outputFile)

        return outputFile.path
    }

    private fun updateThumbnailMediaStore(
            context: Context,
            fileId: Long,
            type: MediaFile.MediaType,
            outputFile: File
    ) {
        when (type) {
            MediaFile.MediaType.IMAGE -> {
                val values = ContentValues()
                values.put(MediaStore.Images.Thumbnails.DATA, outputFile.path)
                try {
                    values.put(MediaStore.Images.Thumbnails.IMAGE_ID, fileId)
                    values.put(MediaStore.Images.Thumbnails.KIND, MediaStore.Images.Thumbnails.MINI_KIND)
                    context.contentResolver.insert(MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI, values)
                } catch (e: Exception) {
                    context.contentResolver.update(MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI, values,
                            "${MediaStore.Images.Thumbnails.IMAGE_ID} = $fileId AND " +
                                    "${MediaStore.Images.Thumbnails.KIND} = ${MediaStore.Images.Thumbnails.MINI_KIND}",
                            null)
                }
            }
            MediaFile.MediaType.VIDEO -> {
                val values = ContentValues()
                values.put(MediaStore.Video.Thumbnails.DATA, outputFile.path)
                try {
                    values.put(MediaStore.Video.Thumbnails.VIDEO_ID, fileId)
                    values.put(MediaStore.Video.Thumbnails.KIND, MediaStore.Video.Thumbnails.MINI_KIND)
                    context.contentResolver.insert(MediaStore.Video.Thumbnails.EXTERNAL_CONTENT_URI, values)
                } catch (e: Exception) {
                    context.contentResolver.update(MediaStore.Video.Thumbnails.EXTERNAL_CONTENT_URI, values,
                            "${MediaStore.Video.Thumbnails.VIDEO_ID} = $fileId AND " +
                                    "${MediaStore.Video.Thumbnails.KIND} = ${MediaStore.Video.Thumbnails.MINI_KIND}",
                            null
                    )
                }
            }
        }
    }
}