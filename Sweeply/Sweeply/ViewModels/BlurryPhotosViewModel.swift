import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class BlurryPhotosViewModel: ObservableObject {
    @Published public var blurryAssets: [MediaAsset] = []
    @Published public var selectedAssetIds: Set<String> = []
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var feedbackMessage: String? = nil
    
    private let blurryService = BlurryService.shared
    private let photoService = PhotoService.shared
    
    public init() {}
    
    public var selectedTotalBytes: Int64 {
        blurryAssets
            .filter { selectedAssetIds.contains($0.id) }
            .reduce(0) { $0 + $1.fileSize }
    }
    
    public var isAllSelected: Bool {
        !blurryAssets.isEmpty && selectedAssetIds.count == blurryAssets.count
    }
    
    public func scan() async {
        isScanning = true
        scanProgress = 0.0
        
        do {
            let allPhotos = photoService.fetchAllImages(limit: 150)
            let detected = await blurryService.detectBlurryPhotos(assets: allPhotos) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            self.blurryAssets = detected
            self.selectedAssetIds = Set(detected.map(\.id))
        } catch {
            self.feedbackMessage = "Scan error: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    public func toggleSelection(for assetId: String) {
        HapticService.shared.selection()
        if selectedAssetIds.contains(assetId) {
            selectedAssetIds.remove(assetId)
        } else {
            selectedAssetIds.insert(assetId)
        }
    }
    
    public func toggleSelectAll() {
        HapticService.shared.impact(.light)
        if isAllSelected {
            selectedAssetIds.removeAll()
        } else {
            selectedAssetIds = Set(blurryAssets.map(\.id))
        }
    }
    
    public func createCleanBatch() -> CleanBatch {
        let assetsToClean = blurryAssets.filter { selectedAssetIds.contains($0.id) }
        return CleanBatch(title: "Blurry Photos", category: .blurryPhotos, assets: assetsToClean)
    }
}
