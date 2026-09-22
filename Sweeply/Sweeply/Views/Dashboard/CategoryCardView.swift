import SwiftUI

public struct CategoryCardView: View {
    public let icon: String
    public let iconColor: Color
    public let title: String
    public let subtitle: String
    public let badgeText: String?
    public let countText: String?
    public let isProcessing: Bool
    
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
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            // Texts
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Count / Badge & Chevron
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let count = countText {
                            Text(count)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        if let badge = badgeText {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(iconColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(iconColor.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .liquidGlass(cornerRadius: 20, padding: 16)
    }
}
