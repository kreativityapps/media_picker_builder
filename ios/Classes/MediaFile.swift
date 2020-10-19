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
    var duration: Double?
    var mimeType: String?
    var type: MediaType
    
    init(id: String, dateAdded: Int?, path: String?, thumbnailPath: String?, orientation: Int, duration: Double?, mimeType: String?, type: MediaType) {
        self.id = id
        self.dateAdded = dateAdded
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.orientation = orientation
        self.duration = duration
        self.mimeType = mimeType
        self.type = type
    }
    
    init(asset: PHAsset, path: String?, thumbnailPath: String?) throws {
        switch asset.mediaType {
        case .video:
            self.type = .video
        case .image:
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes.contains(.photoLive) {
                    self.type = .livePhoto
                } else {
                    self.type = .image
                }
            } else {
                self.type = .image
            }
        default:
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])
        }
        
        var dateAdded: Int?
        if let creationDate = asset.creationDate {
            dateAdded = Int(creationDate.timeIntervalSince1970)
        }
        
        let duration: Double
        if asset.duration != 0 {
            duration = asset.duration * 1000
        } else {
            duration = 0
        }
        
        self.id = asset.localIdentifier
        self.dateAdded = dateAdded
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.orientation = MediaFile.getOrientation(asset: asset)
        self.duration = duration
    }
    
    static func getOrientation(asset: PHAsset) -> Int {
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        
        if width < height {
            return 90
        }
        
        return 0
    }
}

enum MediaType: Int, Codable {
    case image
    case video
    case livePhoto
}


