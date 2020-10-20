//
//  MediaFile.swift
//  file_picker
//
//  Created by Kasem Mohamed on 6/29/19.
//

import Foundation
import Photos

struct MediaFile : Codable {
    var id: String
    var dateAdded: Int? // seconds since 1970
    var path: String?
    var thumbnailPath: String?
    var orientation: Int
    var duration: Double // duration in seconds
    var mimeType: String?
    var type: MediaType
    var isLivePhoto: Bool
    
    init(id: String, dateAdded: Int?, path: String?, thumbnailPath: String?, orientation: Int, duration: Double, mimeType: String?, type: MediaType, isLivePhoto: Bool) {
        self.id = id
        self.dateAdded = dateAdded
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.orientation = orientation
        self.duration = duration
        self.mimeType = mimeType
        self.type = type
        self.isLivePhoto = isLivePhoto
    }
    
    init(asset: PHAsset, path: String, thumbnailPath: String?) throws {
        switch asset.mediaType {
        case .video:
            self.type = .video
            self.isLivePhoto = false
        case .image:
            self.type = .image
            
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes.contains(.photoLive) {
                    self.isLivePhoto = true
                } else {
                    self.isLivePhoto = false
                }
            } else {
                self.isLivePhoto = false
            }
        default:
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])
        }
        
        var dateAdded: Int?
        if let creationDate = asset.creationDate {
            dateAdded = Int(creationDate.timeIntervalSince1970)
        }
        
        self.id = asset.localIdentifier
        self.dateAdded = dateAdded
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.orientation = MediaAsset.getOrientation(asset: asset)
        self.duration = asset.duration
    }
}

enum MediaType: Int, Codable {
    case image
    case video
}
