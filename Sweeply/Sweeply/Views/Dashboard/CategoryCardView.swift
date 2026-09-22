import SwiftUI

public struct CategoryCardView: View {
    public let icon: String
    public let iconColor: Color
    public let title: String
    public let subtitle: String
    public let badgeText: String?
    public let countText: String?
    public let isProcessing: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        badgeText: String? = nil,
        countText: String? = nil,
        isProcessing: Bool = false
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.countText = countText
        self.isProcessing = isProcessing
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Glowing Glass Icon Badge
            ZStack {
                // Colored ambient glow behind the icon
                Circle()
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.35 : 0.20))
                    .frame(width: 48, height: 48)
                    .blur(radius: 6)
                
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.25),
                                iconColor.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [iconColor.opacity(0.6), iconColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            // Texts
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Count / Badge & Glass Chevron
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    VStack(alignment: .trailing, spacing: 3) {
                        if let count = countText {
                            Text(count)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.primary)
                        }
                        if let badge = badgeText {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(iconColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(iconColor.opacity(colorScheme == .dark ? 0.20 : 0.12))
                                        .overlay(
                                            Capsule().stroke(iconColor.opacity(0.35), lineWidth: 0.8)
                                        )
                                )
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
        .liquidGlass(cornerRadius: 22, padding: 16)
    }
}
