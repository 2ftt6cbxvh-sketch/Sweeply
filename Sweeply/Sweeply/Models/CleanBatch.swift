import Foundation

public enum CleanCategoryType: String, CaseIterable, Identifiable {
    case similarPhotos = "Similar Photos"
    case screenshots = "Screenshots"
    case largeVideos = "Large Videos"
    case blurryPhotos = "Blurry Photos"
    case duplicateContacts = "Duplicate Contacts"
    case custom = "Selected Items"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .similarPhotos: return "photo.on.rectangle.angled"
        case .screenshots: return "iphone"
        case .largeVideos: return "video.fill"
        case .blurryPhotos: return "camera.metering.matrix"
        case .duplicateContacts: return "person.2.fill"
        case .custom: return "trash.fill"
        }
    }
}

public struct CleanBatch: Identifiable {
    public let id: UUID
    public var title: String
    public var category: CleanCategoryType
    public var assets: [MediaAsset]
    public var contactGroups: [ContactDuplicateGroup]
    
    public init(id: UUID = UUID(), title: String, category: CleanCategoryType, assets: [MediaAsset] = [], contactGroups: [ContactDuplicateGroup] = []) {
        self.id = id
        self.title = title
        self.category = category
        self.assets = assets
        self.contactGroups = contactGroups
    }
    
    public var totalItemsCount: Int {
        assets.count + contactGroups.reduce(0) { $0 + $1.selectedIds.count }
    }
    
    public var totalBytesToFree: Int64 {
        assets.reduce(0) { $0 + $1.fileSize }
    }
    
    public var formattedSizeToFree: String {
        ByteCountFormatter.string(fromByteCount: totalBytesToFree, countStyle: .file)
    }
}
