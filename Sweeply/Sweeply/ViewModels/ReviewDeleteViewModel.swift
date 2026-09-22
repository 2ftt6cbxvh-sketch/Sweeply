import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public final class ReviewDeleteViewModel: ObservableObject {
    @Published public var batch: CleanBatch
    @Published public var isDeleting: Bool = false
    @Published public var deletionError: String? = nil
    @Published public var hasCompleted: Bool = false
    @Published public var actuallyFreedBytes: Int64 = 0
    
    private let photoService = PhotoService.shared
    private let contactService = ContactService.shared
    
    public init(batch: CleanBatch) {
        self.batch = batch
    }
    
    public func removeItem(assetId: String) {
        batch.assets.removeAll { $0.id == assetId }
    }
    
    public func removeContactGroup(groupId: UUID) {
        batch.contactGroups.removeAll { $0.id == groupId }
    }
    
    public func executeClean() async -> Bool {
        guard batch.totalItemsCount > 0 else { return false }
        isDeleting = true
        deletionError = nil
        
        var freedBytes = batch.totalBytesToFree
        
        do {
            // 1. Delete Photo / Video assets
            if !batch.assets.isEmpty {
                let phAssets = batch.assets.map(\.phAsset)
                try await photoService.deleteAssets(assets: phAssets)
            }
            
            // 2. Delete contacts if present
            for group in batch.contactGroups {
                let ids = group.selectedIds
                if !ids.isEmpty {
                    try await contactService.deleteContacts(ids: ids)
                }
            }
            
            self.actuallyFreedBytes = freedBytes
            self.hasCompleted = true
            self.isDeleting = false
            return true
        } catch {
            self.deletionError = error.localizedDescription
            self.isDeleting = false
            return false
        }
    }
}
