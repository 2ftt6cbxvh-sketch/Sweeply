import Foundation
import Photos
import Contacts
import Combine
import SwiftUI

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var storage: StorageBreakdown = StorageBreakdown()
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var activeBatchForReview: CleanBatch? = nil
    @Published public var showSuccessScreen: Bool = false
    @Published public var lastCleanedBytes: Int64 = 0
    @Published public var lastScanDate: Date? = nil
    
    private let storageService = StorageService.shared
    private let photoService = PhotoService.shared
    private let contactService = ContactService.shared
    private let similarityService = SimilarityService.shared
    private let blurryService = BlurryService.shared
    
    public init() {
        refreshStorage()
    }
    
    public func refreshStorage() {
        let (total, free, used) = storageService.fetchDeviceStorage()
        storage.totalDiskBytes = total
        storage.freeDiskBytes = free
        storage.usedDiskBytes = used
    }
    
    public func runQuickScan() async {
        isScanning = true
        scanProgress = 0.0
        refreshStorage()
        
        // 1. Fetch Screenshots
        let screenshots = photoService.fetchScreenshots()
        var screenshotSize: Int64 = 0
        for s in screenshots {
            screenshotSize += s.fileSize
        }
        storage.screenshotsCount = screenshots.count
        storage.screenshotsBytes = screenshotSize
        scanProgress = 0.25
        
        // 2. Fetch Large Videos
        let videos = photoService.fetchVideos()
        var videoSize: Int64 = 0
        for v in videos {
            videoSize += v.fileSize
        }
        storage.largeVideosCount = videos.count
        storage.largeVideosBytes = videoSize
        scanProgress = 0.50
        
        // 3. Duplicate Contacts
        if PermissionService.shared.hasContactsAccess {
            if let contacts = try? await contactService.fetchAllContacts() {
                let duplicateGroups = contactService.findDuplicateGroups(from: contacts)
                storage.duplicateContactsSets = duplicateGroups.count
                storage.duplicateContactsCount = duplicateGroups.reduce(0) { $0 + $1.contacts.count }
            }
        }
        scanProgress = 0.75
        
        // 4. Quick Sample for Similar Photos
        let allImages = photoService.fetchAllImages(limit: 300)
        let similarGroups = await similarityService.detectSimilarPhotos(assets: allImages)
        var similarSavings: Int64 = 0
        var similarCount: Int = 0
        for g in similarGroups {
            similarSavings += g.potentialSavings
            similarCount += g.assets.count
        }
        storage.similarPhotosCount = similarCount
        storage.similarPhotosBytes = similarSavings
        
        scanProgress = 1.0
        lastScanDate = Date()
        isScanning = false
    }
    
    public func onCleaningFinished(freedBytes: Int64) {
        lastCleanedBytes = freedBytes
        refreshStorage()
        // Reduce reclaimable counts dynamically
        storage.similarPhotosBytes = max(0, storage.similarPhotosBytes - freedBytes)
        showSuccessScreen = true
    }
}
