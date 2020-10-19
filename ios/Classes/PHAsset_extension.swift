//
//  PHAsset_extension.swift
//  media_picker_builder
//
//  Created by Stevan Medic on 10/5/20.
//

import Foundation
import Photos

extension PHAsset {
    @available(iOS 9.1, *)
    static func fetchVideosFor(date: Date = Date(), duration: Int = 1) -> [PHAsset] {
        let requestOptions = PHVideoRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        
        let fetchOptions = PHFetchOptions()
        let beginningOfDay = Calendar.current.startOfDay(for: date) as NSDate
        var components = DateComponents()
        components.day = 1
        components.second = -1
        guard let endOfDay = Calendar.current.date(byAdding: components, to: beginningOfDay as Date) as NSDate? else { return [] }
        
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@ AND creationDate < %@", beginningOfDay, endOfDay)
        
        var videoPHAssets = [PHAsset]()
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        fetchResult.enumerateObjects { asset, _, _ in
            if asset.mediaType == .video || (asset.mediaType == .image && asset.mediaSubtypes.contains(.photoLive)) {
                if asset.pixelHeight > asset.pixelWidth { // showing only portrait assets (for now)
                    videoPHAssets.append(asset)
                }
            }
        }
        
        return videoPHAssets;
    }
    
    func getCreationDateSince1970() -> Int? {
        let since1970 = creationDate?.timeIntervalSince1970
        return since1970 != nil ? Int(since1970!) : nil
    }
}
