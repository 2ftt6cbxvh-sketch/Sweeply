import Foundation
import Photos
import UIKit

public final class PhotoService {
    public static let shared = PhotoService()
    public let imageManager = PHCachingImageManager()
    
    private var sizeCache: [String: Int64] = [:]
    private let cacheQueue = DispatchQueue(label: "com.sweeply.sizecache", attributes: .concurrent)
    
    private init() {}
    
    public func fetchAllImages(limit: Int? = nil) -> [MediaAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let limit = limit {
            options.fetchLimit = limit
        }
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [MediaAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(MediaAsset(phAsset: asset))
        }
        return assets
    }
    
    public func fetchScreenshots() -> [MediaAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d AND (mediaSubtype & %d) != 0",
                                      PHAssetMediaType.image.rawValue,
                                      PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        var assets: [MediaAsset] = []
        result.enumerateObjects { asset, _, _ in
            let cachedSize = self.getCachedSize(for: asset.localIdentifier)
            assets.append(MediaAsset(phAsset: asset, fileSize: cachedSize ?? 0))
        }
        return assets
    }
    
    public func fetchVideos() -> [MediaAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .video, options: options)
        var assets: [MediaAsset] = []
        result.enumerateObjects { asset, _, _ in
            let cachedSize = self.getCachedSize(for: asset.localIdentifier)
            assets.append(MediaAsset(phAsset: asset, fileSize: cachedSize ?? 0))
        }
        // Sort largest to smallest
        assets.sort { $0.fileSize > $1.fileSize }
        return assets
    }
    
    public func requestThumbnail(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        return imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
    
    public func requestFullImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 800, height: 800), contentMode: .aspectFit, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    public func calculateAccurateSize(for asset: PHAsset) -> Int64 {
        if let cached = getCachedSize(for: asset.localIdentifier) {
            return cached
        }
        let resources = PHAssetResource.assetResources(for: asset)
        var totalSize: Int64 = 0
        for resource in resources {
            if let sizeNum = resource.value(forKey: "fileSize") as? NSNumber {
                totalSize += sizeNum.int64Value
            }
        }
        if totalSize <= 0 {
            totalSize = MediaAsset.estimateSize(asset: asset)
        }
        setCachedSize(totalSize, for: asset.localIdentifier)
        return totalSize
    }
    
    private func getCachedSize(for identifier: String) -> Int64? {
        cacheQueue.sync { sizeCache[identifier] }
    }
    
    private func setCachedSize(_ size: Int64, for identifier: String) {
        cacheQueue.async(flags: .barrier) {
            self.sizeCache[identifier] = size
        }
    }
    
    public func deleteAssets(assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }
}
