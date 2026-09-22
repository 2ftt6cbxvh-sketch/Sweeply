import Foundation
import Photos
import UIKit

public struct MediaAsset: Identifiable, Hashable {
    public let id: String
    public let phAsset: PHAsset
    public let creationDate: Date?
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let duration: TimeInterval
    public let mediaType: PHAssetMediaType
    public let isFavorite: Bool
    public let isScreenshot: Bool
    public var fileSize: Int64
    
    public init(phAsset: PHAsset, fileSize: Int64 = 0) {
        self.id = phAsset.localIdentifier
        self.phAsset = phAsset
        self.creationDate = phAsset.creationDate
        self.pixelWidth = phAsset.pixelWidth
        self.pixelHeight = phAsset.pixelHeight
        self.duration = phAsset.duration
        self.mediaType = phAsset.mediaType
        self.isFavorite = phAsset.isFavorite
        self.isScreenshot = phAsset.mediaSubtypes.contains(.photoScreenshot)
        self.fileSize = fileSize > 0 ? fileSize : MediaAsset.estimateSize(asset: phAsset)
    }
    
    public static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    public var formattedDuration: String {
        guard duration > 0 else { return "" }
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var formattedDate: String {
        guard let date = creationDate else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public static func estimateSize(asset: PHAsset) -> Int64 {
        if asset.mediaType == .video {
            // Rough estimation for video: ~2.5 MB per second for 1080p
            let sec = max(asset.duration, 1.0)
            return Int64(sec * 2_500_000)
        } else {
            // Rough estimation for photos: ~2.8 bytes per pixel (HEIC/JPEG)
            let pixels = Double(asset.pixelWidth * asset.pixelHeight)
            let estimated = Int64(pixels * 0.4) // ~2-4MB for standard 12MP shot
            return max(estimated, 250_000)
        }
    }
}
