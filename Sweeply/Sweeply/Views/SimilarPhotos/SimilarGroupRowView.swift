import SwiftUI
import Photos

public struct SimilarGroupRowView: View {
    public let group: SimilarPhotoGroup
    public let onToggleSelection: (String) -> Void
    public let onMarkAsBest: (String) -> Void
    
    public init(
        group: SimilarPhotoGroup,
        onToggleSelection: @escaping (String) -> Void,
        onMarkAsBest: @escaping (String) -> Void
    ) {
        self.group = group
        self.onToggleSelection = onToggleSelection
        self.onMarkAsBest = onMarkAsBest
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "photo.stack")
                        .foregroundStyle(.blue)
                    Text("\(group.assets.count) Similar Photos")
                        .font(.subheadline.weight(.semibold))
                }
                
                Spacer()
                
                Text("Potential saving: \(group.formattedPotentialSavings)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Assets Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.assets) { asset in
                        let isBest = asset.id == group.bestAssetId
                        let isSelected = group.selectedIds.contains(asset.id)
                        
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 240, height: 240))
                                    .frame(width: 120, height: 150)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isBest ? Color.yellow : (isSelected ? Color.blue : Color.clear), lineWidth: 3)
                                    )
                                
                                // Selection Checkmark or Star Badge
                                if isBest {
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9))
                                        Text("BEST")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow)
                                    .cornerRadius(6)
                                    .padding(6)
                                } else {
                                    Button {
                                        onToggleSelection(asset.id)
                                    } label: {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(isSelected ? .blue : .white)
                                            .background(Circle().fill(Color.black.opacity(0.3)))
                                    }
                                    .padding(6)
                                }
                            }
                            
                            // Info line
                            HStack {
                                Text(asset.formattedSize)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if !isBest {
                                    Button("Keep") {
                                        onMarkAsBest(asset.id)
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.blue)
                                }
                            }
                            .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .liquidGlass(cornerRadius: 18, padding: 14)
    }
}
