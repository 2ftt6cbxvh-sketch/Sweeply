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
        // Stills typically take ~30% of Live Photo file size
        self.estimatedStillSize = Int64(Double(totalSize) * 0.32)
    }
}

public final class LivePhotoService {
    public static let shared = LivePhotoService()
    
    private init() {}
    
    public func fetchLivePhotos() async -> [LivePhotoItem] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        var items: [LivePhotoItem] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            let totalBytes = resources.compactMap { $0.value(forKey: "fileSize") as? Int64 }.reduce(0, +)
            // If resource size is zero, fallback to estimated 6.5 MB per Live Photo
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
            
            imageManager.requestImageDataAndOrientation(for: item.phAsset, options: options) { data, uti, orientation, _ in
                guard let data = data, let image = UIImage(data: data) else {
                    continuation.resume(throwing: NSError(domain: "com.sweeply.livephoto", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read still image data"]))
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    // 1. Create still photo
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    creationRequest.creationDate = item.phAsset.creationDate
                    creationRequest.location = item.phAsset.location
                    
                    // 2. Delete original Live Photo
                    PHAssetChangeRequest.deleteAssets([item.phAsset] as NSArray)
                }) { success, error in
                    if success {
                        continuation.resume(returning: item.reclaimableBytes)
                    } else {
                        continuation.resume(throwing: error ?? NSError(domain: "com.sweeply.livephoto", code: -2, userInfo: [NSLocalizedDescriptionKey: "PhotoKit conversion failed"]))
                    }
                }
            }
        }
    }
}
