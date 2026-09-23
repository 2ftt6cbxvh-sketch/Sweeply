import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class ScreenshotsViewModel: ObservableObject {
    @Published public var screenshots: [MediaAsset] = []
    @Published public var selectedIds: Set<String> = []
    @Published public var sortOrder: MediaSortOrder = .newest
    @Published public var isLoading: Bool = false
    @Published public var stagedBatch: CleanBatch? = nil
    
    public var sortedScreenshots: [MediaAsset] {
        screenshots.sorted(by: sortOrder)
    }
    
    private let photoService = PhotoService.shared
    
    public init() {}
    
    public var totalCount: Int { screenshots.count }
    
    public var selectedCount: Int { selectedIds.count }
    
    public var totalSize: Int64 {
        screenshots.reduce(0) { $0 + $1.fileSize }
    }
    
    public var selectedSavingsBytes: Int64 {
        screenshots.filter { selectedIds.contains($0.id) }.reduce(0) { $0 + $1.fileSize }
    }
    
    public var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: selectedSavingsBytes, countStyle: .file)
    }
    
    public func load() {
        isLoading = true
        let fetched = photoService.fetchScreenshots()
        self.screenshots = fetched
        // Default: select all screenshots for fast one-tap cleanup
        self.selectedIds = Set(fetched.map(\.id))
        self.isLoading = false
    }
    
    public func toggleSelection(for assetId: String) {
        if selectedIds.contains(assetId) {
            selectedIds.remove(assetId)
        } else {
            selectedIds.insert(assetId)
        }
    }
    
    public func selectAll() {
        selectedIds = Set(screenshots.map(\.id))
    }
    
    public func deselectAll() {
        selectedIds.removeAll()
    }
    
    public func prepareCleanBatch() -> CleanBatch? {
        let assetsToDelete = screenshots.filter { selectedIds.contains($0.id) }
        guard !assetsToDelete.isEmpty else { return nil }
        
        return CleanBatch(
            title: "Clean Screenshots",
            category: .screenshots,
            assets: assetsToDelete
        )
    }
    
    public func removeDeletedAssets(deletedIds: Set<String>) {
        screenshots.removeAll { deletedIds.contains($0.id) }
        selectedIds.subtract(deletedIds)
    }
}
