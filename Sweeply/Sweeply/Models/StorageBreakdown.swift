import Foundation

public struct StorageBreakdown: Equatable {
    public var totalDiskBytes: Int64
    public var freeDiskBytes: Int64
    public var usedDiskBytes: Int64
    
    public var similarPhotosBytes: Int64
    public var similarPhotosCount: Int
    
    public var screenshotsBytes: Int64
    public var screenshotsCount: Int
    
    public var largeVideosBytes: Int64
    public var largeVideosCount: Int
    
    public var blurryPhotosBytes: Int64
    public var blurryPhotosCount: Int
    
    public var duplicateContactsSets: Int
    public var duplicateContactsCount: Int
    
    public init(
        totalDiskBytes: Int64 = 0,
        freeDiskBytes: Int64 = 0,
        usedDiskBytes: Int64 = 0,
        similarPhotosBytes: Int64 = 0,
        similarPhotosCount: Int = 0,
        screenshotsBytes: Int64 = 0,
        screenshotsCount: Int = 0,
        largeVideosBytes: Int64 = 0,
        largeVideosCount: Int = 0,
        blurryPhotosBytes: Int64 = 0,
        blurryPhotosCount: Int = 0,
        duplicateContactsSets: Int = 0,
        duplicateContactsCount: Int = 0
    ) {
        self.totalDiskBytes = totalDiskBytes
        self.freeDiskBytes = freeDiskBytes
        self.usedDiskBytes = usedDiskBytes
        self.similarPhotosBytes = similarPhotosBytes
        self.similarPhotosCount = similarPhotosCount
        self.screenshotsBytes = screenshotsBytes
        self.screenshotsCount = screenshotsCount
        self.largeVideosBytes = largeVideosBytes
        self.largeVideosCount = largeVideosCount
        self.blurryPhotosBytes = blurryPhotosBytes
        self.blurryPhotosCount = blurryPhotosCount
        self.duplicateContactsSets = duplicateContactsSets
        self.duplicateContactsCount = duplicateContactsCount
    }
    
    public var totalReclaimableBytes: Int64 {
        similarPhotosBytes + screenshotsBytes + largeVideosBytes + blurryPhotosBytes
    }
    
    public var formattedTotalDisk: String {
        ByteCountFormatter.string(fromByteCount: totalDiskBytes, countStyle: .file)
    }
    
    public var formattedFreeDisk: String {
        ByteCountFormatter.string(fromByteCount: freeDiskBytes, countStyle: .file)
    }
    
    public var formattedUsedDisk: String {
        ByteCountFormatter.string(fromByteCount: usedDiskBytes, countStyle: .file)
    }
    
    public var formattedReclaimable: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableBytes, countStyle: .file)
    }
    
    public var usedPercentage: Double {
        guard totalDiskBytes > 0 else { return 0.0 }
        return Double(usedDiskBytes) / Double(totalDiskBytes)
    }
    
    public var freePercentage: Double {
        guard totalDiskBytes > 0 else { return 1.0 }
        return Double(freeDiskBytes) / Double(totalDiskBytes)
    }
    
    /// Returns the percentage of filled/used storage occupied by the specified byte count
    public func percentageOfFilledStorage(bytes: Int64) -> Double {
        guard usedDiskBytes > 0 && bytes > 0 else { return 0.0 }
        return min(100.0, (Double(bytes) / Double(usedDiskBytes)) * 100.0)
    }
    
    /// Formats the percentage of filled storage for UI display (e.g. "2.4% of filled storage")
    public func formattedPercentageOfFilledStorage(bytes: Int64) -> String {
        let pct = percentageOfFilledStorage(bytes: bytes)
        if pct < 0.1 && pct > 0 {
            return "<0.1% of filled disk"
        } else if pct <= 0 {
            return "0% of filled disk"
        } else {
            return String(format: "%.1f%% of filled disk", pct)
        }
    }
}
