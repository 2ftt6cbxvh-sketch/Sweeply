import SwiftUI

public struct StorageRingView: View {
    public let breakdown: StorageBreakdown
    @Environment(\.colorScheme) private var colorScheme
    
    public init(breakdown: StorageBreakdown) {
        self.breakdown = breakdown
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Main Radial Progress Gauge
            ZStack {
                // Background Track
                Circle()
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.05),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 185, height: 185)
                
                // Active Glowing Storage Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(breakdown.usedPercentage, 0.02), 1.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.6, blue: 1.0),
                                Color(red: 0.3, green: 0.4, blue: 1.0),
                                Color(red: 0.6, green: 0.3, blue: 0.95),
                                Color(red: 0.1, green: 0.8, blue: 0.95),
                                Color(red: 0.1, green: 0.6, blue: 1.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 185, height: 185)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.blue.opacity(colorScheme == .dark ? 0.6 : 0.35), radius: 12, x: 0, y: 4)
                    .animation(.spring(response: 0.9, dampingFraction: 0.75), value: breakdown.usedPercentage)
                
                // Center Glass Pod with Stats
                VStack(spacing: 4) {
                    Text("\(Int(breakdown.usedPercentage * 100))%")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white, Color(uiColor: .systemGray4)]
                                    : [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.2, green: 0.3, blue: 0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active Disk")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 10)
            
            // Storage Stats Bar (Glass Pill Container)
            HStack(spacing: 0) {
                // Used Stat
                statColumn(
                    title: "Used",
                    value: breakdown.formattedUsedDisk,
                    color: Color(red: 0.2, green: 0.5, blue: 1.0),
                    symbol: "circle.fill"
                )
                
                Divider()
                    .frame(height: 32)
                    .opacity(0.3)
                
                // Free Stat
                statColumn(
                    title: "Free",
                    value: breakdown.formattedFreeDisk,
                    color: colorScheme == .dark ? Color.white.opacity(0.6) : Color.gray,
                    symbol: "circle"
                )
                
                Divider()
                    .frame(height: 32)
                    .opacity(0.3)
                
                // Cleanable Stat
                statColumn(
                    title: "Cleanable",
                    value: breakdown.formattedReclaimable,
                    color: Color(red: 0.95, green: 0.55, blue: 0.1),
                    symbol: "sparkles"
                )
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5), lineWidth: 1)
                    )
            )
        }
        .liquidGlass(cornerRadius: 28, padding: 22)
    }
    
    private func statColumn(title: String, value: String, color: Color, symbol: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
