package com.kasem.media_picker_builder.model

import org.json.JSONObject

data class MediaAsset(
        val id: Long,
        val dateAdded: Long,
        val orientation: Int,
        val duration: Double?,
        val type: MediaFile.MediaType,
        val isLivePhoto: Boolean
) {

    fun toJSONObject(): JSONObject {
        return JSONObject()
                .put("id", id.toString())
                .put("dateAdded", dateAdded)
                .put("orientation", orientation)
                .put("duration", duration)
                .put("type", type.ordinal)
                .put("isLivePhoto", isLivePhoto)
    }
}