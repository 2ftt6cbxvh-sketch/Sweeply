import SwiftUI

public struct DashboardRecommendationsView: View {
    public let breakdown: StorageBreakdown
    public let onSelectRecommendation: (DashboardRoute) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    public init(breakdown: StorageBreakdown, onSelectRecommendation: @escaping (DashboardRoute) -> Void) {
        self.breakdown = breakdown
        self.onSelectRecommendation = onSelectRecommendation
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("RECOMMENDATIONS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            // Recommendation 1: Review Large Videos
            recommendationCard(
                icon: "play.square.stack.fill",
                iconColor: Color.blue,
                title: "Review Downloaded Media",
                subtitle: breakdown.largeVideosBytes > 0
                    ? "Free up \(ByteCountFormatter.string(fromByteCount: breakdown.largeVideosBytes, countStyle: .file)) of storage. Review downloaded videos and large files stored on your device and consider removing them."
                    : "Review large videos and clips taking up significant disk storage space.",
                actionLabel: nil,
                showChevron: true,
                onTap: { onSelectRecommendation(.largeVideos) }
            )
            
            // Recommendation 2: Clean Similar Photos & Bursts
            recommendationCard(
                icon: "photo.stack.fill",
                iconColor: Color.orange,
                title: "Clean Similar Photos & Bursts",
                subtitle: breakdown.similarPhotosBytes > 0
                    ? "Free up \(ByteCountFormatter.string(fromByteCount: breakdown.similarPhotosBytes, countStyle: .file)) of storage. Sweeply detected duplicate photos. Keep the best shot and clean duplicates."
                    : "Automatically organize duplicate burst shots and identical captures.",
                actionLabel: "Review",
                showChevron: false,
                onTap: { onSelectRecommendation(.similarPhotos) }
            )
            
            // Recommendation 3: Live Photo Optimizer
            recommendationCard(
                icon: "livephoto",
                iconColor: Color.cyan,
                title: "Optimize Live Photos",
                subtitle: "Convert stationary Live Photos to high-resolution stills. Your photos are preserved and you save up to 70% storage.",
                actionLabel: "Save 70%",
                showChevron: false,
                onTap: { onSelectRecommendation(.livePhotos) }
            )
            
            // Recommendation 4: Duplicate Contacts
            recommendationCard(
                icon: "person.2.fill",
                iconColor: Color.green,
                title: "Merge Duplicate Contacts",
                subtitle: breakdown.duplicateContactsCount > 0
                    ? "Found \(breakdown.duplicateContactsCount) contacts across \(breakdown.duplicateContactsSets) duplicate sets and incomplete cards."
                    : "Safely merge duplicate names, numbers, and emails with shake-to-undo recovery.",
                actionLabel: "Merge",
                showChevron: false,
                onTap: { onSelectRecommendation(.duplicateContacts) }
            )
        }
    }
    
    @ViewBuilder
    private func recommendationCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        actionLabel: String?,
        showChevron: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    // Apple-style rounded icon square
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconColor)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    if let action = actionLabel {
                        Text(action)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.blue)
                    } else if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(SmoothCardButtonStyle())
        .liquidGlass(cornerRadius: 18, padding: 16)
    }
}
