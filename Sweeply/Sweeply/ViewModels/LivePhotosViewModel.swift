import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class LivePhotosViewModel: ObservableObject {
    @Published public var livePhotos: [LivePhotoItem] = []
    @Published public var selectedIds: Set<String> = []
    @Published public var isLoading: Bool = false
    @Published public var isConverting: Bool = false
    @Published public var feedbackMessage: String? = nil
    
    private let livePhotoService = LivePhotoService.shared
    
    public init() {}
    
    public var selectedTotalReclaimable: Int64 {
        livePhotos
            .filter { selectedIds.contains($0.id) }
            .reduce(0) { $0 + $1.reclaimableBytes }
    }
    
    public var isAllSelected: Bool {
        !livePhotos.isEmpty && selectedIds.count == livePhotos.count
    }
    
    public func load() async {
        isLoading = true
        let items = await livePhotoService.fetchLivePhotos()
        self.livePhotos = items
        self.selectedIds = Set(items.map(\.id))
        isLoading = false
    }
    
    public func toggleSelection(for id: String) {
        HapticService.shared.selection()
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
    
    public func toggleSelectAll() {
        HapticService.shared.impact(.light)
        if isAllSelected {
            selectedIds.removeAll()
        } else {
            selectedIds = Set(livePhotos.map(\.id))
        }
    }
    
    public func convertSelected() async {
        isConverting = true
        var convertedCount = 0
        var totalFreed: Int64 = 0
        
        let toConvert = livePhotos.filter { selectedIds.contains($0.id) }
        
        for item in toConvert {
            do {
                let freed = try await livePhotoService.convertToStill(item: item)
                totalFreed += freed
                convertedCount += 1
            } catch {
                continue
            }
        }
        
        await load()
        let freedFormatted = ByteCountFormatter.string(fromByteCount: totalFreed, countStyle: .file)
        feedbackMessage = "Converted \(convertedCount) Live Photos! Reclaimed ~\(freedFormatted)."
        HapticService.shared.notification(.success)
        UndoService.shared.recordClean(title: "Converted Live Photos to Stills", count: convertedCount, bytes: totalFreed)
        isConverting = false
    }
}
