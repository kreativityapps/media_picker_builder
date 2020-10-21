import Flutter
import UIKit
import Photos

public class SwiftMediaPickerBuilderPlugin: NSObject, FlutterPlugin {
    private var progressChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "media_picker_builder", binaryMessenger: registrar.messenger())
        
        let instance = SwiftMediaPickerBuilderPlugin()
        
        let _progressChannel = FlutterEventChannel(name: "com.mediapickerbuilder.getMediaFile.progress",
                                                   binaryMessenger: registrar.messenger(),
                                                   codec: FlutterJSONMethodCodec.sharedInstance())
        _progressChannel.setStreamHandler(instance)
        
        instance.progressChannel = _progressChannel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        
        switch call.method {
        case "v2/getMediaAssets":
            guard let typeValues = arguments["types"] as? [Int] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "withImages must not be null", details: nil))
                return
            }
            guard let startDateValue = arguments["startDate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "startDate must not be null", details: nil))
                return
            }
            guard let endDateValue = arguments["endDate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "endDate must not be null", details: nil))
                return
            }
            
            let startDate = Date(timeIntervalSince1970: startDateValue)
            let endDate = Date(timeIntervalSince1970: endDateValue)
            
            var types: Set<PHAssetMediaType> = Set()
            
            typeValues.forEach { (value) in
                guard let type = MediaType(rawValue: value) else {
                    return
                }
                
                switch type {
                case .video:
                    types.insert(PHAssetMediaType.video)
                case .image:
                    types.insert(PHAssetMediaType.image)
                }
            }
            
            let assets = MediaFetcher.getAssetsWithDateRange(start: startDate, end: endDate, types: Array(types))
            
            let mediaFiles = assets.compactMap { (asset) -> MediaAsset? in
                return try? MediaAsset(asset: asset)
            }
            
            do {
                let data = try JSONEncoder().encode(mediaFiles)
                let json = String(data: data, encoding: .utf8)!
                
                result(json)
            } catch {
                result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
            }
            
        case "v2/getMediaFile":
            guard let fileId = arguments["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            
            guard let asset = MediaFetcher.getAsset(with: fileId) else {
                result(FlutterError(code: "NOT_FOUND", message: "Unable to get the file", details: nil))
                return
            }
            
            MediaFetcher.getMediaFile(for: asset) { (progress) in
                try? self.sendEvent(event: GetMediaFileEvent(fileId: fileId, progress: progress))
            } completion: { (file) in
                let encoder = JSONEncoder()
                do {
                    let data = try encoder.encode(file)
                    let json = String(data: data, encoding: .utf8)!
                    
                    result(json)
                } catch {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the file", details: nil))
                }
            }
            
        case "getAlbums":
            guard let withImages = arguments["withImages"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "withImages must not be null", details: nil))
                return
            }
            guard let withVideos = arguments["withVideos"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "withVideos must not be null", details: nil))
                return
            }
            guard let loadPaths = arguments["loadIOSPaths"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "loadIOSPaths must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getAlbums").async {
                let albums = FileFetcher.getAlbums(withImages: withImages, withVideos: withVideos, loadPaths: loadPaths)
                let encodedData = try? JSONEncoder().encode(albums)
                let json = String(data: encodedData!, encoding: .utf8)!
                result(json)
            }
        case "getThumbnail":
            guard let fileId = arguments["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            guard let type = arguments["type"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "type must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getThumbnail").async {
                let thumbnail = FileFetcher.getThumbnail(for: fileId, type: MediaType.init(rawValue: type)!)
                if (thumbnail != nil) {
                    result(thumbnail)
                } else {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the thumbnail", details: nil))
                }
            }
        case "getMediaFile":
            guard let fileId = arguments["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            guard let loadPath = arguments["loadIOSPath"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "loadIOSPath must not be null", details: nil))
                return
            }
            guard let loadThumbnail = arguments["loadThumbnail"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "loadIOSPath must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getMediaFile").async {
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [fileId], options: .none).firstObject
                if asset == nil {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the file", details: nil))
                    return
                }
                let mediaFile = FileFetcher.getMediaFile(for: asset!, loadPath: loadPath, generateThumbnailIfNotFound: loadThumbnail)
                if (mediaFile != nil) {
                    let encodedData = try? JSONEncoder().encode(mediaFile)
                    let json = String(data: encodedData!, encoding: .utf8)!
                    result(json)
                } else {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the file", details: nil))
                }
            }
        case "getVideosAndLivePhotos":
            var dateInMs = Date()
            if let milliseconds = arguments["dateInMs"] as? Int64 {
                dateInMs = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
            }
            
            var durationInSeconds = 1
            if let seconds = arguments["durationInSeconds"] as? Int {
                durationInSeconds = seconds
            }
            
            DispatchQueue(label: "getVideosAndLivePhotos").async {
                if #available(iOS 9.1, *) {
                    let mediaFiles = FileFetcher.getVideosAndLivePhotos(dateInMs, duration: durationInSeconds)
                    
                    let encodedData = try? JSONEncoder().encode(mediaFiles)
                    let json = String(data: encodedData!, encoding: .utf8)!
                    result(json)
                } else {
                    // Fallback on earlier versions
                    result(nil)
                }
            }
            break
        case "getLivePhotoPath":
            guard let fileId = arguments["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getLivePhotoPath").async {
                if #available(iOS 9.1, *) {
                    guard let fullPath = FileFetcher.getLivePhotoPath(for: fileId) else {
                        return result(FlutterError(code: "NOT_FOUND", message: "Unable to get file path", details: nil))
                    }
                    
                    return result(fullPath)
                } else {
                    // Fallback on earlier versions
                    return result(FlutterError(code: "NOT_FOUND", message: "Unable to get file path", details: nil))
                }
            }
        case "getVideoPath":
            guard let fileId = arguments["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getVideoPath").async {
                guard let fullPath = FileFetcher.getVideoPath(for: fileId) else {
                    return result(FlutterError(code: "NOT_FOUND", message: "Unable to get video path", details: nil))
                }
                return result(fullPath)
            }
        default:
            result(FlutterError.init(
                code: "NOT_IMPLEMENTED",
                message: "Unknown method:  \(call.method)",
                details: nil))
        }
        
    }
}

struct GetMediaFileEvent: Encodable {
    let fileId: String
    let progress: Double?
}

extension SwiftMediaPickerBuilderPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        
        return nil
    }
    
    func sendEvent(event: GetMediaFileEvent) throws {
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(event)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(json)
        }
    }
}
