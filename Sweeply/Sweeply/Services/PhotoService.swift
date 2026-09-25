import Foundation
import Photos
import UIKit

public final class PhotoService {
    public static let shared = PhotoService()
    public let imageManager = PHCachingImageManager()
    
    private var sizeCache: [String: Int64] = [:]
    private let cacheQueue = DispatchQueue(label: "com.sweeply.sizecache", attributes: .concurrent)
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    private init() {
        thumbnailCache.countLimit = 400
        thumbnailCache.totalCostLimit = 64 * 1024 * 1024
    }
    
    public func getCachedThumbnail(for identifier: String) -> UIImage? {
        thumbnailCache.object(forKey: identifier as NSString)
    }
    
    public func fetchAllImages(limit: Int? = nil) -> [MediaAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let limit = limit {
            options.fetchLimit = limit
        }
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [MediaAsset] = []
        result.enumerateObjects { asset, _, _ in
            let size = self.calculateAccurateSize(for: asset)
            assets.append(MediaAsset(phAsset: asset, fileSize: size))
        }
        return assets
    }
    
    public func fetchScreenshots() -> [MediaAsset] {
        var assets: [MediaAsset] = []
        
        // 1. Apple's native Smart Album for Screenshots
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
        if let screenshotsAlbum = collections.firstObject {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let result = PHAsset.fetchAssets(in: screenshotsAlbum, options: options)
            result.enumerateObjects { asset, _, _ in
                let size = self.calculateAccurateSize(for: asset)
                assets.append(MediaAsset(phAsset: asset, fileSize: size))
            }
        }
        
        // 2. Fallback: Filter all image assets in Swift for screenshot aspect ratios or subtype
        if assets.isEmpty {
            let allOptions = PHFetchOptions()
            allOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let all = PHAsset.fetchAssets(with: .image, options: allOptions)
            all.enumerateObjects { asset, _, _ in
                let maxDim = max(asset.pixelWidth, asset.pixelHeight)
                let minDim = min(asset.pixelWidth, asset.pixelHeight)
                let ratio = Double(maxDim) / Double(max(minDim, 1))
                if asset.mediaSubtypes.contains(.photoScreenshot) || (ratio >= 1.95 && ratio <= 2.25) {
                    let size = self.calculateAccurateSize(for: asset)
                    assets.append(MediaAsset(phAsset: asset, fileSize: size))
                }
            }
        }
        
        return assets
    }
    
    public func fetchVideos() -> [MediaAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .video, options: options)
        var assets: [MediaAsset] = []
        result.enumerateObjects { asset, _, _ in
            let size = self.calculateAccurateSize(for: asset)
            assets.append(MediaAsset(phAsset: asset, fileSize: size))
        }
        // Sort largest to smallest
        assets.sort { $0.fileSize > $1.fileSize }
        return assets
    }
    
    public func requestThumbnail(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let identifier = asset.localIdentifier
        if let cached = thumbnailCache.object(forKey: identifier as NSString) {
            completion(cached)
            return 0
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        return imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, info in
            if let image = image {
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    self?.thumbnailCache.setObject(image, forKey: identifier as NSString)
                }
            }
            completion(image)
        }
    }
    
    public func requestFullImage(for asset: PHAsset) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true
            
            var resultImage: UIImage? = nil
            self.imageManager.requestImage(for: asset, targetSize: CGSize(width: 800, height: 800), contentMode: .aspectFit, options: options) { image, _ in
                resultImage = image
            }
            return resultImage
        }.value
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
    
    public func createDemoMedia() async {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1170, height: 2532))
        let img1 = renderer.image { ctx in
            UIColor.systemIndigo.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1170, height: 2532))
        }
        let img2 = renderer.image { ctx in
            UIColor.systemIndigo.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1170, height: 2532))
        }
        let img3 = renderer.image { ctx in
            UIColor.systemPurple.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1170, height: 2532))
        }
        
        try? await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: img1)
            PHAssetChangeRequest.creationRequestForAsset(from: img2)
            PHAssetChangeRequest.creationRequestForAsset(from: img3)
        }
    }
}
