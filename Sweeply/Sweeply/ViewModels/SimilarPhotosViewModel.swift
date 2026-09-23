import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class SimilarPhotosViewModel: ObservableObject {
    @Published public var groups: [SimilarPhotoGroup] = []
    @Published public var sortOrder: MediaSortOrder = .newest
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var stagedBatch: CleanBatch? = nil
    
    public var sortedGroups: [SimilarPhotoGroup] {
        groups.sorted(by: sortOrder)
    }
    
    private let photoService = PhotoService.shared
    private let similarityService = SimilarityService.shared
    
    public init() {}
    
    public var totalDuplicatesFound: Int {
        groups.reduce(0) { $0 + max(0, $1.assets.count - 1) }
    }
    
    public var totalSelectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedIds.count }
    }
    
    public var totalSavingsBytes: Int64 {
        groups.reduce(0) { total, group in
            let groupSavings = group.assets
                .filter { group.selectedIds.contains($0.id) }
                .reduce(0) { $0 + $1.fileSize }
            return total + groupSavings
        }
    }
    
    public var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: totalSavingsBytes, countStyle: .file)
    }
    
    public func scan(limit: Int = 400) async {
        isScanning = true
        scanProgress = 0.0
        
        let assets = photoService.fetchAllImages(limit: limit)
        let detected = await similarityService.detectSimilarPhotos(assets: assets) { [weak self] progress in
            Task { @MainActor in
                self?.scanProgress = progress
            }
        }
        
        self.groups = detected
        self.isScanning = false
    }
    
    public func toggleSelection(groupIndex: Int, assetId: String) {
        guard groups.indices.contains(groupIndex) else { return }
        groups[groupIndex].toggleSelection(for: assetId)
    }
    
    public func toggleSelection(groupId: UUID, assetId: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].toggleSelection(for: assetId)
    }
    
    public func markAsBest(groupIndex: Int, assetId: String) {
        guard groups.indices.contains(groupIndex) else { return }
        groups[groupIndex].markAsBest(assetId: assetId)
    }
    
    public func markAsBest(groupId: UUID, assetId: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].markAsBest(assetId: assetId)
    }
    
    public func selectAllDuplicates() {
        for index in groups.indices {
            groups[index].selectAllDuplicates()
        }
    }
    
    public func deselectAll() {
        for index in groups.indices {
            groups[index].deselectAll()
        }
    }
    
    public func prepareCleanBatch() -> CleanBatch? {
        var assetsToDelete: [MediaAsset] = []
        for group in groups {
            for asset in group.assets where group.selectedIds.contains(asset.id) {
                assetsToDelete.append(asset)
            }
        }
        guard !assetsToDelete.isEmpty else { return nil }
        
        return CleanBatch(
            title: "Clean Similar Photos",
            category: .similarPhotos,
            assets: assetsToDelete
        )
    }
    
    public func removeDeletedAssets(deletedIds: Set<String>) {
        var updatedGroups: [SimilarPhotoGroup] = []
        for var group in groups {
            group.assets.removeAll { deletedIds.contains($0.id) }
            group.selectedIds.subtract(deletedIds)
            if group.assets.count > 1 {
                if !group.assets.contains(where: { $0.id == group.bestAssetId }) {
                    group.bestAssetId = group.assets.first?.id ?? ""
                }
                updatedGroups.append(group)
            }
        }
        self.groups = updatedGroups
    }
}
