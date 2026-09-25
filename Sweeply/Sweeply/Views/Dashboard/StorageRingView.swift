import SwiftUI

public struct StorageRingView: View {
    public let breakdown: StorageBreakdown
    @Environment(\.colorScheme) private var colorScheme
    
    public init(breakdown: StorageBreakdown) {
        self.breakdown = breakdown
    }
    
    public var body: some View {
        VStack(spacing: 22) {
            // Main Radial Progress Gauge
            ZStack {
                // Background Track (Glass Groove)
                Circle()
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color(red: 0.15, green: 0.25, blue: 0.50).opacity(0.08),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: 195, height: 195)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .frame(width: 217, height: 217)
                    )
                
                // Active Minimal Optical Storage Arc (Single-pass hardware accelerated)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(breakdown.usedPercentage, 0.03), 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.65, blue: 1.0),
                                Color(red: 0.20, green: 0.50, blue: 0.98),
                                Color(red: 0.35, green: 0.40, blue: 0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 195, height: 195)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(red: 0.10, green: 0.50, blue: 1.0).opacity(colorScheme == .dark ? 0.35 : 0.20), radius: 8, x: 0, y: 3)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: breakdown.usedPercentage)
                
                // Center Glass Pod with Stats
                VStack(spacing: 4) {
                    Text("\(Int(breakdown.usedPercentage * 100))%")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white, Color(uiColor: .systemGray3)]
                                    : [Color(red: 0.05, green: 0.12, blue: 0.28), Color(red: 0.15, green: 0.25, blue: 0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(red: 0.15, green: 0.95, blue: 0.55))
                            .frame(width: 7, height: 7)
                            .shadow(color: Color.green.opacity(0.8), radius: 4)
                        
                        Text("Active Disk")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6), lineWidth: 0.8)
                            )
                    )
                }
            }
            .padding(.top, 12)
            
            // Storage Stats Bar (Molded Glass Capsule Container)
            HStack(spacing: 0) {
                // Used Stat
                statColumn(
                    title: "Used",
                    value: breakdown.formattedUsedDisk,
                    color: Color(red: 0.1, green: 0.65, blue: 1.0),
                    symbol: "circle.fill"
                )
                
                Divider()
                    .frame(height: 32)
                    .opacity(0.3)
                
                // Free Stat
                statColumn(
                    title: "Free",
                    value: breakdown.formattedFreeDisk,
                    color: colorScheme == .dark ? Color.white.opacity(0.65) : Color.gray,
                    symbol: "circle"
                )
                
                Divider()
                    .frame(height: 32)
                    .opacity(0.3)
                
                // Cleanable Stat
                statColumn(
                    title: "Cleanable",
                    value: breakdown.formattedReclaimable,
                    color: Color(red: 1.0, green: 0.55, blue: 0.15),
                    symbol: "sparkles"
                )
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.75),
                                        Color.cyan.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 3)
            )
        }
        .liquidGlass(cornerRadius: 30, padding: 24)
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
