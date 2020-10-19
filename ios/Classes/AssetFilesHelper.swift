//
//  FilesHelper.swift
//  media_picker_builder
//
//  Created by Stevan Medic on 10/5/20.
//

import Foundation
import Photos
import MobileCoreServices

class AssetFilesHelper {
    
    static func saveAssetResource(resource: PHAssetResource, inDirectory: NSURL, buffer: NSMutableData?, error: Error?, creationDate: Date?,
                                  completion: @escaping (URL?) -> ()) {
        guard error == nil else {
            print("Could not request data for resource: \(resource), error: \(String(describing: error))")
            completion(nil)
            return
        }
        
        let optionalExt = UTTypeCopyPreferredTagWithClass(
            resource.uniformTypeIdentifier as CFString,
            kUTTagClassFilenameExtension
        )?.takeRetainedValue()
        
        guard let ext = optionalExt else {
            completion(nil)
            return
        }
        guard var fileUrl = inDirectory.appendingPathComponent(NSUUID().uuidString) else {
            completion(nil)
            return
        }
        
        fileUrl = fileUrl.appendingPathExtension(ext as String)
        
        if let buffer = buffer, buffer.write(to: fileUrl, atomically: true) {
            print("Saved resource form buffer \(resource) to filepath \(String(describing: fileUrl))")
            completion(fileUrl)
        } else {
            PHAssetResourceManager.default().writeData(for: resource, toFile: fileUrl, options: nil) { (error) in
                if let _ = error {
                    completion(nil)
                }
                DispatchQueue.main.async {
                    completion(fileUrl)
                }
            }
        }
    }
    
    static func generateFolderForLivePhotoResources() -> NSURL? {
        let photoDir = NSURL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).appendingPathComponent(NSUUID().uuidString)
        
        let fileManager = FileManager()
        let success: ()? = try? fileManager.createDirectory(
            at: photoDir!,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return success != nil ? photoDir! as NSURL : nil
    }
    
}
