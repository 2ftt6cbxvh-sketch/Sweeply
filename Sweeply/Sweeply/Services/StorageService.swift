import Foundation

public final class StorageService {
    public static let shared = StorageService()
    
    private init() {}
    
    public func fetchDeviceStorage() -> (total: Int64, free: Int64, used: Int64) {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            let used = max(0, total - free)
            return (total, free, used)
        } catch {
            // Fallback via fileSystemAttributes
            if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
                let total = (attrs[.systemSize] as? NSNumber)?.int64Value ?? 0
                let free = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
                let used = max(0, total - free)
                return (total, free, used)
            }
            return (0, 0, 0)
        }
    }
}
