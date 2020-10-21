//
//  MediaFetcher.swift
//  media_picker_builder
//
//  Created by Juan Alvarez on 10/15/20.
//

import Foundation
import Photos
import UIKit

typealias ProgressBlock = (Double) -> Void
typealias MediaFileCompletionBlock = (MediaFile?) -> Void

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
        
        if typePredicates.count > 0 {
            let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)
            predicates.append(predicate)
        }
        
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
    
    static func getMediaFile(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping MediaFileCompletionBlock) {
        switch asset.mediaType {
        case .video:
            getVideoURL(for: asset, progressBlock: progressBlock, completion: completion)
        case .image:
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes.contains(.photoLive) {
                    getLivePhotoUrl(for: asset, progressBlock: progressBlock, completion: completion)
                } else {
                    getImageUrl(for: asset, progressBlock: progressBlock, completion: completion)
                }
            } else {
                getImageUrl(for: asset, progressBlock: progressBlock, completion: completion)
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
}

private extension MediaFetcher {
    static func getVideoURL(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping MediaFileCompletionBlock) {
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
            
            let result = try? MediaFile(asset: asset, path: urlAsset.url.path, thumbnailPath: nil)
            
            completion(result)
        }
    }
    
    static func getImageUrl(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping MediaFileCompletionBlock) {
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
            
            result = try? MediaFile(asset: asset, path: url.path, thumbnailPath: nil)
        }
    }
    
    @available(iOS 9.1, *)
    static func getLivePhotoUrl(for asset: PHAsset, progressBlock: ProgressBlock?, completion: @escaping MediaFileCompletionBlock) {
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        options.progressHandler = { progress, error, stop, info in
            if let block = progressBlock {
                block(progress)
            }
        }
        
        let manager = PHCachingImageManager.default()
        manager.requestLivePhoto(for: asset, targetSize: CGSize.zero, contentMode: .default, options: options) { (photo, info) in
            guard let photo = photo else {
                completion(nil)
                return
            }
            
            let resources = PHAssetResource.assetResources(for: photo)
            
            guard let videoResource = resources.first(where: ({ $0.type == PHAssetResourceType.pairedVideo })) else {
                completion(nil)
                return
            }
            
            var photoUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            photoUrl.appendPathComponent(UUID().uuidString)
            
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { progress in
                if let block = progressBlock {
                    block(progress)
                }
            }
            
            let resourceManager = PHAssetResourceManager.default()
            resourceManager.writeData(for: videoResource, toFile: photoUrl, options: options) { (error) in
                guard error == nil else {
                    completion(nil)
                    return
                }
                
                let file = try? MediaFile(asset: asset, path: photoUrl.path, thumbnailPath: nil)
                
                completion(file)
            }
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
