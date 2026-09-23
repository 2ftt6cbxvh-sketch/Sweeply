import SwiftUI

public struct CategoryCardView: View {
    public let icon: String
    public let iconColor: Color
    public let title: String
    public let subtitle: String
    public let badgeText: String?
    public let countText: String?
    public let percentageText: String?
    public let isProcessing: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        badgeText: String? = nil,
        countText: String? = nil,
        percentageText: String? = nil,
        isProcessing: Bool = false
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.countText = countText
        self.percentageText = percentageText
        self.isProcessing = isProcessing
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // 3D Liquid Glass Icon Capsule
            ZStack {
                // Subtle optical caustic tint behind the icon
                Circle()
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.20 : 0.14))
                    .frame(width: 52, height: 52)
                    .blur(radius: 6)
                
                // Frosted Liquid Droplet Pod
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.white.opacity(0.75)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        iconColor.opacity(colorScheme == .dark ? 0.20 : 0.12),
                                        iconColor.opacity(colorScheme == .dark ? 0.05 : 0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        // Specular Light Glint
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.50), location: 0.0),
                                        .init(color: Color.white.opacity(0.10), location: 0.25),
                                        .init(color: Color.clear, location: 0.50)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.60 : 0.80), location: 0.0),
                                        .init(color: iconColor.opacity(0.40), location: 0.35),
                                        .init(color: Color.white.opacity(0.20), location: 0.70),
                                        .init(color: iconColor.opacity(0.25), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Texts & Storage Percentage
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let percentage = percentageText {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(iconColor)
                        Text(percentage)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(iconColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.08)
                                    : Color.white.opacity(0.70)
                            )
                            .overlay(
                                Capsule()
                                    .fill(iconColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.7), iconColor.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: iconColor.opacity(0.20), radius: 4, x: 0, y: 2)
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Count / Badge & Glass Chevron
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .tint(iconColor)
                        .scaleEffect(0.85)
                } else {
                    VStack(alignment: .trailing, spacing: 3) {
                        if let count = countText {
                            Text(count)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary)
                        }
                        
                        if let badge = badgeText {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(iconColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            colorScheme == .dark
                                                ? Color.white.opacity(0.08)
                                                : Color.white.opacity(0.70)
                                        )
                                        .overlay(
                                            Capsule()
                                                .fill(iconColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
                                        )
                                        .overlay(
                                            Capsule().stroke(iconColor.opacity(0.40), lineWidth: 0.8)
                                        )
                                )
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
        }
        .liquidGlass(cornerRadius: 24, padding: 16)
    }
}
