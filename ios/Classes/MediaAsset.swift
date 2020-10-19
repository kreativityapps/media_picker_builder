//
//  MediaAsset.swift
//  media_picker_builder
//
//  Created by Juan Alvarez on 10/19/20.
//

import Foundation
import Photos

struct MediaAsset: Codable {
    let id: String
    let dateAdded: Int // seconds since 1970
    let orientation: Int
    let duration: Double
    let type: MediaType
    
    init(asset: PHAsset) throws {
        let dateAdded: Int
        if let since1970 = asset.creationDate?.timeIntervalSince1970 {
            dateAdded = Int(since1970)
        } else {
            dateAdded = 0
        }
        
        self.id = asset.localIdentifier
        self.dateAdded = dateAdded
        self.orientation = MediaAsset.getOrientation(asset: asset)
        self.duration = asset.duration
    
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
