import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class LargeVideosViewModel: ObservableObject {
    @Published public var videos: [MediaAsset] = []
    @Published public var selectedIds: Set<String> = []
    @Published public var isLoading: Bool = false
    @Published public var stagedBatch: CleanBatch? = nil
    
    // Video Compression state
    @Published public var selectedVideoForCompress: MediaAsset? = nil
    @Published public var isCompressing: Bool = false
    @Published public var compressionProgress: Double = 0.0
    @Published public var compressionSuccessMessage: String? = nil
    @Published public var compressionQuality: VideoCompressionQuality = .medium
    
    private let photoService = PhotoService.shared
    private let videoService = VideoService.shared
    
    public init() {}
    
    public var selectedSavingsBytes: Int64 {
        videos.filter { selectedIds.contains($0.id) }.reduce(0) { $0 + $1.fileSize }
    }
    
    public var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: selectedSavingsBytes, countStyle: .file)
    }
    
    public func load() {
        isLoading = true
        let fetched = photoService.fetchVideos()
        self.videos = fetched
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
        selectedIds = Set(videos.map(\.id))
    }
    
    public func deselectAll() {
        selectedIds.removeAll()
    }
    
    public func prepareCleanBatch() -> CleanBatch? {
        let assetsToDelete = videos.filter { selectedIds.contains($0.id) }
        guard !assetsToDelete.isEmpty else { return nil }
        
        return CleanBatch(
            title: "Clean Large Videos",
            category: .largeVideos,
            assets: assetsToDelete
        )
    }
    
    public func compressCurrentVideo() async {
        guard let video = selectedVideoForCompress else { return }
        isCompressing = true
        compressionProgress = 0.0
        compressionSuccessMessage = nil
        
        do {
            let outputURL = try await videoService.compressVideo(
                phAsset: video.phAsset,
                quality: compressionQuality
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.compressionProgress = progress
                }
            }
            
            _ = try await videoService.saveVideoToLibrary(url: outputURL)
            try? FileManager.default.removeItem(at: outputURL)
            
            let originalSize = video.fileSize
            let estimatedNewSize = Int64(Double(originalSize) * compressionQuality.estimatedCompressionRatio)
            let savedBytes = max(0, originalSize - estimatedNewSize)
            let savedString = ByteCountFormatter.string(fromByteCount: savedBytes, countStyle: .file)
            
            compressionSuccessMessage = "Video compressed! Saved approx. \(savedString)"
            isCompressing = false
            load()
        } catch {
            isCompressing = false
            compressionSuccessMessage = "Compression error: \(error.localizedDescription)"
        }
    }
    
    public func removeDeletedAssets(deletedIds: Set<String>) {
        videos.removeAll { deletedIds.contains($0.id) }
        selectedIds.subtract(deletedIds)
    }
}
