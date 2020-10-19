//
//  MediaFetcher.swift
//  media_picker_builder
//
//  Created by Juan Alvarez on 10/15/20.
//

import Foundation
import Photos
import UIKit

class MediaFetcher {
    static func getAsset(with fileId: String) -> PHAsset? {
        var asset: PHAsset?
        
        let assetFetch = PHAsset.fetchAssets(withLocalIdentifiers: [fileId], options: nil)
        assetFetch.enumerateObjects { (_asset, _, _) in
            asset = _asset
        }
        
        return asset
    }
    
    static func getAssetsWithDateRange(start: Date?, end: Date?, types: [PHAssetMediaType]) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        
        var predicates: [NSPredicate] = []
        if let startDate = start {
            predicates.append(NSPredicate(format: "creationDate > %@", startDate as CVarArg))
        }
        if let endDate = end {
            predicates.append(NSPredicate(format: "creationDate < %@", endDate as CVarArg))
        }
        
        var typePredicates: [NSPredicate] = []
        for type in types {
            typePredicates.append(NSPredicate(format: "mediaType == %i", type.rawValue))
        }
        
        let typePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)
        
        predicates.append(typePredicate)
        
        fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let results = PHAsset.fetchAssets(with: fetchOptions)
        
        guard results.count > 0 else {
            return []
        }
        
        var assets: [PHAsset] = []
        
        results.enumerateObjects { (asset, index, stop) in
            assets.append(asset)
        }
        
        return assets
    }
    
    static func getMediaAsset(for asset: PHAsset) -> MediaAsset? {
        switch asset.mediaType {
        case .video:
            return getMediaAssetForVideo(asset: asset)
        case .image:
            return getMediaAssetForImage(asset: asset)
        default:
            return nil
        }
    }
    
    static func getMediaFile(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping (MediaFile?) -> Void) {
        switch asset.mediaType {
        case .video:
            getVideoURL(for: asset, progressBlock: progressBlock) { (url) in
                
            }
        case .image:
            getImageUrl(for: asset, progressBlock: progressBlock) { (file) in
                
            }
            
        default:
            completion(nil)
        }
    }
    
    static func getThumbnailFor(file: MediaFile, imageSize: CGSize, completion: @escaping (Data?) -> Void) {
        guard let asset = getAsset(with: file.id) else {
            completion(nil)
            return
        }
        
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        
        let manager = PHCachingImageManager.default()
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { (image, info) in
            if let imageData = image?.jpegData(compressionQuality: 0.7) {
                completion(imageData)
            } else {
                completion(nil)
            }
        }
    }
    
    typealias ProgressBlock = (Double) -> Void
    
    static func getVideoURL(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping (MediaFile?) -> Void) {
        let requestOptions = PHVideoRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.progressHandler = { progress, error, stop, info in
            if let block = progressBlock {
                block(progress)
            }
        }
        
        let manager = PHCachingImageManager.default()
        manager.requestAVAsset(forVideo: asset, options: requestOptions) { (avAsset, mix, info) in
            guard let urlAsset = avAsset as? AVURLAsset else {
                completion(nil)
                return
            }
            
            let duration: Double
            if asset.duration != 0 {
                duration = asset.duration * 1000
            } else {
                duration = 0
            }
            
            var dateAdded: Int?
            if let creationDate = asset.creationDate {
                dateAdded = Int(creationDate.timeIntervalSince1970)
            }
            
            let result = MediaFile(
                id: asset.localIdentifier,
                dateAdded: dateAdded,
                path: urlAsset.url.path,
                thumbnailPath: nil,
                orientation: getOrientation(asset: asset),
                duration: duration,
                mimeType: nil,
                type: .VIDEO
            )
            
            completion(result)
        }
    }
    
    static func getImageUrl(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping (MediaFile?) -> Void) {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, error in
            if let block = progressBlock {
                block(progress)
            }
        }
        
        asset.requestContentEditingInput(with: options) { (input, info) in
            let result: MediaFile?
            
            defer {
                completion(result)
            }
            
            guard let input = input else {
                result = nil
                return
            }
            
            guard let url = input.fullSizeImageURL else {
                result = nil
                return
            }
            
            var dateAdded: Int?
            if let creationDate = asset.creationDate {
                dateAdded = Int(creationDate.timeIntervalSince1970)
            }
            
            result = MediaFile(
                id: asset.localIdentifier,
                dateAdded: dateAdded,
                path: url.path,
                thumbnailPath: nil,
                orientation: getOrientation(asset: asset),
                duration: nil,
                mimeType: nil,
                type: .IMAGE
            )
        }
    }
}

private extension MediaFetcher {
    static func getOrientation(asset: PHAsset) -> Int {
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        
        if width < height {
            return 90
        }
        
        return 0
    }
    
    static func getVideoOrientation(avAsset: AVAsset) -> Int {
        if let t = avAsset.tracks(withMediaType: AVMediaType.video).first?.preferredTransform {
            // Portrait
            if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
                return 90
            }
            // PortraitUpsideDown
            if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
                return 270
            }
            // LandscapeRight
            if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
                return 0
            }
            // LandscapeLeft
            if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
                return 180
            }
        }
        
        return 0
    }
    
    static func getMediaAssetForVideo(asset: PHAsset) -> MediaAsset {
        let assetId = asset.localIdentifier
        
        var dateAdded: Int?
        if let since1970 = asset.creationDate?.timeIntervalSince1970 {
            dateAdded = Int(since1970)
        }
        
        let duration: Double
        if asset.duration != 0 {
            duration = asset.duration * 1000
        } else {
            duration = 0
        }
        
        let mediaAsset = MediaAsset(
            id: assetId,
            dateAdded: dateAdded ?? 0,
            orientation: getOrientation(asset: asset),
            duration: duration,
            type: .VIDEO)
        
        return mediaAsset
    }
    
    static func getMediaAssetForImage(asset: PHAsset) -> MediaAsset {
        let assetId = asset.localIdentifier
        
        var dateAdded: Int?
        if let creationDate = asset.creationDate {
            dateAdded = Int(creationDate.timeIntervalSince1970)
        }
        
        let mediaAsset = MediaAsset(
            id: assetId,
            dateAdded: dateAdded ?? 0,
            orientation: getOrientation(asset: asset),
            duration: nil,
            type: .IMAGE)
        
        return mediaAsset
    }
}
