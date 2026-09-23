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
    
    public init(
        id: String,
        phAsset: PHAsset = PHAsset(),
        creationDate: Date? = Date(),
        pixelWidth: Int = 1920,
        pixelHeight: Int = 1080,
        duration: TimeInterval = 0,
        mediaType: PHAssetMediaType = .image,
        isFavorite: Bool = false,
        isScreenshot: Bool = false,
        fileSize: Int64 = 1_000_000
    ) {
        self.id = id
        self.phAsset = phAsset
        self.creationDate = creationDate
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.duration = duration
        self.mediaType = mediaType
        self.isFavorite = isFavorite
        self.isScreenshot = isScreenshot
        self.fileSize = fileSize
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

public enum MediaSortOrder: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case sizeDescending = "Largest"
    case sizeAscending = "Smallest"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .sizeDescending: return "Largest Size"
        case .sizeAscending: return "Smallest Size"
        }
    }
    
    public var shortLabel: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .sizeDescending: return "Largest"
        case .sizeAscending: return "Smallest"
        }
    }
    
    public var icon: String {
        switch self {
        case .newest: return "calendar.badge.clock"
        case .oldest: return "calendar"
        case .sizeDescending: return "arrow.down.circle.fill"
        case .sizeAscending: return "arrow.up.circle.fill"
        }
    }
}

public extension Array where Element == MediaAsset {
    func sorted(by order: MediaSortOrder) -> [MediaAsset] {
        switch order {
        case .newest:
            return sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest:
            return sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        case .sizeDescending:
            return sorted { $0.fileSize > $1.fileSize }
        case .sizeAscending:
            return sorted { $0.fileSize < $1.fileSize }
        }
    }
}

public extension Array where Element == LivePhotoItem {
    func sorted(by order: MediaSortOrder) -> [LivePhotoItem] {
        switch order {
        case .newest:
            return sorted { ($0.phAsset.creationDate ?? .distantPast) > ($1.phAsset.creationDate ?? .distantPast) }
        case .oldest:
            return sorted { ($0.phAsset.creationDate ?? .distantPast) < ($1.phAsset.creationDate ?? .distantPast) }
        case .sizeDescending:
            return sorted { $0.totalSize > $1.totalSize }
        case .sizeAscending:
            return sorted { $0.totalSize < $1.totalSize }
        }
    }
}

public extension Array where Element == SimilarPhotoGroup {
    func sorted(by order: MediaSortOrder) -> [SimilarPhotoGroup] {
        switch order {
        case .newest:
            return sorted {
                let d0 = $0.assets.compactMap(\.creationDate).max() ?? .distantPast
                let d1 = $1.assets.compactMap(\.creationDate).max() ?? .distantPast
                return d0 > d1
            }
        case .oldest:
            return sorted {
                let d0 = $0.assets.compactMap(\.creationDate).min() ?? .distantPast
                let d1 = $1.assets.compactMap(\.creationDate).min() ?? .distantPast
                return d0 < d1
            }
        case .sizeDescending:
            return sorted { $0.potentialSavings > $1.potentialSavings }
        case .sizeAscending:
            return sorted { $0.potentialSavings < $1.potentialSavings }
        }
    }
}
