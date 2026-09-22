import Foundation

public struct SimilarPhotoGroup: Identifiable, Hashable {
    public let id: UUID
    public var assets: [MediaAsset]
    public var bestAssetId: String
    public var selectedIds: Set<String>
    public var similarityScore: Double
    
    public init(id: UUID = UUID(), assets: [MediaAsset], bestAssetId: String, selectedIds: Set<String>? = nil, similarityScore: Double = 0.9) {
        self.id = id
        self.assets = assets
        self.bestAssetId = bestAssetId
        if let selectedIds = selectedIds {
            self.selectedIds = selectedIds
        } else {
            // Default: select all except the best asset
            self.selectedIds = Set(assets.map(\.id).filter { $0 != bestAssetId })
        }
        self.similarityScore = similarityScore
    }
    
    public var bestAsset: MediaAsset? {
        assets.first { $0.id == bestAssetId }
    }
    
    public var totalSize: Int64 {
        assets.reduce(0) { $0 + $1.fileSize }
    }
    
    public var potentialSavings: Int64 {
        assets.filter { selectedIds.contains($0.id) }.reduce(0) { $0 + $1.fileSize }
    }
    
    public var formattedPotentialSavings: String {
        ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file)
    }
    
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    public mutating func toggleSelection(for assetId: String) {
        if selectedIds.contains(assetId) {
            selectedIds.remove(assetId)
        } else {
            // If selecting the best asset, change best asset to another one
            if assetId == bestAssetId {
                if let alternative = assets.first(where: { $0.id != assetId }) {
                    bestAssetId = alternative.id
                }
            }
            selectedIds.insert(assetId)
        }
    }
    
    public mutating func markAsBest(assetId: String) {
        bestAssetId = assetId
        selectedIds.remove(assetId)
        // Ensure other assets are selected
        for asset in assets where asset.id != assetId {
            selectedIds.insert(asset.id)
        }
    }
    
    public mutating func selectAllDuplicates() {
        selectedIds = Set(assets.map(\.id).filter { $0 != bestAssetId })
    }
    
    public mutating func deselectAll() {
        selectedIds.removeAll()
    }
}
