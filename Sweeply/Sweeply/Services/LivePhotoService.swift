import Foundation
import Photos
import UIKit

public struct LivePhotoItem: Identifiable {
    public let id: String
    public let phAsset: PHAsset
    public let totalSize: Int64
    public let estimatedStillSize: Int64
    public var reclaimableBytes: Int64 {
        max(0, totalSize - estimatedStillSize)
    }
    
    public init(phAsset: PHAsset, totalSize: Int64) {
        self.id = phAsset.localIdentifier
        self.phAsset = phAsset
        self.totalSize = totalSize
        // The still photo typically takes only ~28-32% of total combined Live Photo storage
        self.estimatedStillSize = Int64(Double(totalSize) * 0.30)
    }
}

public final class LivePhotoService {
    public static let shared = LivePhotoService()
    
    private init() {}
    
    public func fetchLivePhotos() async -> [LivePhotoItem] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch all image assets and filter strictly in Swift
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        var items: [LivePhotoItem] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            // Strict Check 1: Must have photoLive media subtype
            guard asset.mediaSubtypes.contains(.photoLive) else { return }
            
            // Strict Check 2: Must contain a genuine paired video resource (.mov)
            let resources = PHAssetResource.assetResources(for: asset)
            let hasPairedVideo = resources.contains { $0.type == .pairedVideo }
            guard hasPairedVideo else { return }
            
            let totalBytes = resources.compactMap { $0.value(forKey: "fileSize") as? Int64 }.reduce(0, +)
            let finalSize = totalBytes > 0 ? totalBytes : Int64(6.5 * 1024 * 1024)
            items.append(LivePhotoItem(phAsset: asset, totalSize: finalSize))
        }
        
        return items
    }
    
    public func convertToStill(item: LivePhotoItem) async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            var hasResumed = false
            let lock = NSLock()
            let safeResume: (Result<Int64, Error>) -> Void = { result in
                lock.lock()
                defer { lock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(with: result)
            }
            
            imageManager.requestImageDataAndOrientation(for: item.phAsset, options: options) { data, uti, orientation, _ in
                guard let data = data, let image = UIImage(data: data) else {
                    safeResume(.failure(NSError(domain: "com.sweeply.livephoto", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read still image data"])))
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    // 1. Create high-resolution still photo
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    creationRequest.creationDate = item.phAsset.creationDate
                    creationRequest.location = item.phAsset.location
                    
                    // 2. Delete original Live Photo
                    PHAssetChangeRequest.deleteAssets([item.phAsset] as NSArray)
                }) { success, error in
                    if success {
                        safeResume(.success(item.reclaimableBytes))
                    } else {
                        safeResume(.failure(error ?? NSError(domain: "com.sweeply.livephoto", code: -2, userInfo: [NSLocalizedDescriptionKey: "PhotoKit conversion failed"])))
                    }
                }
            }
        }
    }
}
