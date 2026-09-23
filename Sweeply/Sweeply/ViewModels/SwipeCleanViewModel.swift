import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class SwipeCleanViewModel: ObservableObject {
    @Published public var deck: [MediaAsset] = []
    @Published public var keptAssets: [MediaAsset] = []
    @Published public var trashedAssets: [MediaAsset] = []
    @Published public var isLoading: Bool = false
    @Published public var stagedBatch: CleanBatch? = nil
    
    private let photoService = PhotoService.shared
    
    public init() {}
    
    public var currentAsset: MediaAsset? {
        deck.first
    }
    
    public var totalTrashedBytes: Int64 {
        trashedAssets.reduce(0) { $0 + $1.fileSize }
    }
    
    public var formattedTrashedBytes: String {
        ByteCountFormatter.string(fromByteCount: totalTrashedBytes, countStyle: .file)
    }
    
    public func loadDeck(limit: Int = 60) {
        isLoading = true
        Task.detached(priority: .userInitiated) { [weak self] in
            let assets = PhotoService.shared.fetchAllImages(limit: limit)
            await MainActor.run {
                guard let self = self else { return }
                self.deck = assets
                self.isLoading = false
            }
        }
    }
    
    public func loadDeckAsync(limit: Int = 60) async {
        isLoading = true
        let assets = await Task.detached(priority: .userInitiated) {
            PhotoService.shared.fetchAllImages(limit: limit)
        }.value
        self.deck = assets
        self.isLoading = false
    }
    
    public func swipeLeft() {
        guard !deck.isEmpty else { return }
        let asset = deck.removeFirst()
        trashedAssets.append(asset)
    }
    
    public func swipeRight() {
        guard !deck.isEmpty else { return }
        let asset = deck.removeFirst()
        keptAssets.append(asset)
    }
    
    public func undo() {
        if let lastTrashed = trashedAssets.popLast() {
            deck.insert(lastTrashed, at: 0)
        } else if let lastKept = keptAssets.popLast() {
            deck.insert(lastKept, at: 0)
        }
    }
    
    public func prepareCleanBatch() -> CleanBatch? {
        guard !trashedAssets.isEmpty else { return nil }
        return CleanBatch(
            title: "Swipe Clean Items",
            category: .custom,
            assets: trashedAssets
        )
    }
}
